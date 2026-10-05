import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../jokers/joker_type.dart';
import '../models/age_config.dart';
import '../models/age_group.dart';
import '../models/command.dart';
import '../models/level.dart';
import 'db/app_database.dart';
import 'db/level_session_dao.dart';

/// Bir seviyenin kalıcı oturumu: canlar, kullanılan jokerler, program.
@immutable
class LevelSession {
  const LevelSession({
    required this.lives,
    this.lifeLostAt,
    this.usedJokers = const {},
    this.program = const [],
  });

  final int lives;

  /// Can dolum hesabının başlangıcı; canlar tamsa null.
  final DateTime? lifeLostAt;
  final Set<JokerType> usedJokers;
  final List<Command> program;

  LevelSession copyWith({
    int? lives,
    DateTime? Function()? lifeLostAt,
    Set<JokerType>? usedJokers,
    List<Command>? program,
  }) => LevelSession(
    lives: lives ?? this.lives,
    lifeLostAt: lifeLostAt == null ? this.lifeLostAt : lifeLostAt(),
    usedJokers: usedJokers ?? this.usedJokers,
    program: program ?? this.program,
  );
}

/// Seviye oturumlarını yönetir. Tüm satırlar açılışta belleğe alınır;
/// okumalar eşzamanlıdır, yazmalar arka planda ve hata toleranslıdır.
///
/// Canlar zamanla dolar: başlangıç değerinin altındayken her
/// [AgeSettings.lifeRefill] süresinde 1 can. Hesap okunurken yapılır; arka
/// planda zamanlayıcı yoktur.
class SessionRepository extends ChangeNotifier {
  SessionRepository(this._database, {this._clock = const SystemClock()});

  final AppDatabase _database;
  final Clock _clock;
  final Map<LevelKeyString, LevelSession> _cache = {};

  LevelSessionDao get _dao => LevelSessionDao(_database.db);

  static LevelKeyString _key(AgeGroup age, int id) => '${age.name}/$id';

  Future<void> load() async {
    try {
      for (final row in await _dao.all()) {
        final age = AgeGroup.values
            .where((a) => a.name == row.ageGroup)
            .firstOrNull;
        if (age == null) continue;
        final lives = _clampStoredLives(row.lives, lifeJokerUsed: row.lifeUsed);
        _cache[_key(age, row.levelId)] = LevelSession(
          lives: lives,
          lifeLostAt: row.lifeLostAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(row.lifeLostAt!),
          usedJokers: {
            if (row.skipUsed) JokerType.skip,
            if (row.lifeUsed) JokerType.life,
            if (row.videoUsed) JokerType.video,
          },
          program: _decode(row.program),
        );
      }
    } catch (e) {
      debugPrint('Oturumlar yüklenemedi, bellekteki durumla devam: $e');
    }
  }

  /// Başlangıç canı (tüm seviyelerde aynı).
  int get maxLives => AgeSettings.maxLives;

  /// Eski sürümlerde 5–7 için 5, 8–12 için 4 can vardı. Okunurken başlangıç
  /// değerine düşürülür; Can jokeri kullanılmış kayıt en fazla bir fazlası.
  static int _clampStoredLives(int lives, {required bool lifeJokerUsed}) {
    final limit = AgeSettings.maxLives + (lifeJokerUsed ? 1 : 0);
    return lives > limit ? limit : lives;
  }

  /// Güncel oturum (zamanla dolan canlar uygulanmış).
  LevelSession sessionFor(Level level) {
    final key = _key(level.ageGroup, level.id);
    final stored = _cache[key] ?? LevelSession(lives: maxLives);
    final normalized = _refill(stored, maxLives);
    if (!identical(normalized, stored)) {
      _cache[key] = normalized;
      _persist(level, normalized);
    }
    return normalized;
  }

  /// Bir sonraki canın gelmesine kalan süre (dolum yoksa null).
  Duration? nextLifeIn(Level level) {
    final s = sessionFor(level);
    final lost = s.lifeLostAt;
    if (lost == null || s.lives >= maxLives) return null;
    final left = AgeSettings.lifeRefill - _clock.now().difference(lost);
    return left.isNegative ? Duration.zero : left;
  }

  LevelSession _refill(LevelSession s, int max) {
    final lost = s.lifeLostAt;
    if (s.lives >= max) {
      return lost == null ? s : s.copyWith(lifeLostAt: () => null);
    }
    final now = _clock.now();
    if (lost == null) return s.copyWith(lifeLostAt: () => now);
    // Saat geri alındıysa can verilmez; başlangıç şimdiye çekilir.
    if (now.isBefore(lost)) return s.copyWith(lifeLostAt: () => now);
    final gained =
        now.difference(lost).inMilliseconds ~/
        AgeSettings.lifeRefill.inMilliseconds;
    if (gained <= 0) return s;
    final lives = (s.lives + gained).clamp(0, max);
    return s.copyWith(
      lives: lives,
      lifeLostAt: () =>
          lives >= max ? null : lost.add(AgeSettings.lifeRefill * gained),
    );
  }

  /// Başarısız bitiş: 1 can düşer.
  void loseLife(Level level) {
    final s = sessionFor(level);
    if (s.lives <= 0) return;
    final lives = s.lives - 1;
    _update(
      level,
      s.copyWith(
        lives: lives,
        lifeLostAt: () =>
            lives < maxLives ? (s.lifeLostAt ?? _clock.now()) : null,
      ),
    );
  }

  /// Can jokeri: +1 (başlangıç değerini aşabilir) ve joker harcanır.
  void useLifeJoker(Level level) {
    final s = sessionFor(level);
    final lives = s.lives + 1;
    _update(
      level,
      s.copyWith(
        lives: lives,
        lifeLostAt: () => lives >= maxLives ? null : s.lifeLostAt,
        usedJokers: {...s.usedJokers, JokerType.life},
      ),
    );
  }

  void markJokerUsed(Level level, JokerType type) {
    final s = sessionFor(level);
    _update(level, s.copyWith(usedJokers: {...s.usedJokers, type}));
  }

  void saveProgram(Level level, List<Command> program) {
    final s = sessionFor(level);
    _update(level, s.copyWith(program: List.unmodifiable(program)));
  }

  /// Seviye çözüldü ya da atlandı: oturum silinir (tam can, jokerler yeni).
  void reset(Level level) {
    _cache.remove(_key(level.ageGroup, level.id));
    notifyListeners();
    _guard(
      () => _dao.delete(level.ageGroup.name, level.id),
      'Oturum silinemedi',
    );
  }

  Future<void> clearAll() async {
    _cache.clear();
    notifyListeners();
    await _guard(_dao.deleteAll, 'Oturumlar silinemedi');
  }

  void _update(Level level, LevelSession s) {
    _cache[_key(level.ageGroup, level.id)] = s;
    notifyListeners();
    _persist(level, s);
  }

  void _persist(Level level, LevelSession s) => _guard(
    () => _dao.upsert(
      LevelSessionRow(
        ageGroup: level.ageGroup.name,
        levelId: level.id,
        lives: s.lives,
        lifeLostAt: s.lifeLostAt?.millisecondsSinceEpoch,
        skipUsed: s.usedJokers.contains(JokerType.skip),
        lifeUsed: s.usedJokers.contains(JokerType.life),
        videoUsed: s.usedJokers.contains(JokerType.video),
        program: s.program.map((c) => c.name).join(','),
        updatedAt: _clock.now().millisecondsSinceEpoch,
      ),
    ),
    'Oturum kaydedilemedi',
  );

  /// Veritabanı hatası oyunu çökertmez; bellekteki durumla devam edilir.
  Future<void> _guard(Future<void> Function() action, String what) async {
    try {
      await action();
    } catch (e) {
      debugPrint('$what: $e');
    }
  }

  static List<Command> _decode(String program) => [
    for (final name in program.split(','))
      ?Command.values.where((c) => c.name == name).firstOrNull,
  ];
}

typedef LevelKeyString = String;
