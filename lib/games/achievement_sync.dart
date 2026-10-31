import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import '../data/db/achievement_state_dao.dart';
import '../data/db/app_database.dart';
import '../models/age_group.dart';
import '../state/progress_controller.dart';
import '../state/settings_controller.dart';
import 'achievement_definitions.dart';
import 'achievement_evaluator.dart';
import 'game_config.dart';
import 'game_ids.dart';
import 'game_platform_service.dart';

/// Bir başarımın uygulama içindeki durumu.
@immutable
class AchievementState {
  const AchievementState({required this.progress, required this.unlocked});

  static const locked = AchievementState(progress: 0, unlocked: false);

  final int progress;
  final bool unlocked;
}

/// İlerleme ve ayarlardan başarım girdileri.
AchievementFacts achievementFacts(
  ProgressController progress,
  SettingsController settings, {
  bool solvedOnLastLife = false,
}) => AchievementFacts(
  sets: progress.sets,
  progressOf: progress.progressFor,
  tutorialCompleted: CommandFamily.values.any(
    (f) => settings.tutorialStatus(f) == TutorialStatus.completed,
  ),
  solvedOnLastLife: solvedOnLastLife,
);

/// Başarımların ve skorun tek kaynağı: yerel veritabanı.
///
/// Kazanılan ya da ilerleyen başarım önce `achievement_state` tablosuna
/// `reported = 0` olarak yazılır, sonra platforma gönderilmeye çalışılır.
/// Gönderim başarılıysa `reported = 1` olur. Oturum yoksa ya da gönderim
/// başarısızsa kayıt bekler; oturum açıldığında ([signInAndSync]) yeniden
/// gönderilir. Gönderimler tekrarlanabilir: platformlar ilerlemeyi
/// azaltmaz, açık başarımı yeniden açmak bir şey değiştirmez.
///
/// Başarımlar hiçbir zaman geri gitmez (ilerleme sıfırlansa bile).
class AchievementSync extends ChangeNotifier {
  AchievementSync({
    required this._database,
    required this.platform,
    required this._prefs,
    this._clock = const SystemClock(),
  });

  final AppDatabase _database;
  final GamePlatformService platform;
  final SharedPreferences _prefs;
  final Clock _clock;

  static const pendingStarsKey = 'pending_total_stars';
  static const reportedStarsKey = 'reported_total_stars';

  final Map<String, AchievementStateRow> _rows = {};
  bool _started = false;
  bool _disposed = false;

  AchievementStateDao get _dao => AchievementStateDao(_database.db);

  /// Platform açık ve oturum var: platform butonları gösterilebilir.
  bool get isSignedIn =>
      platform.kind != GamePlatformKind.none && platform.isSignedIn;

  GamePlatformKind get platformKind => platform.kind;

  AchievementState stateOf(String key) {
    final row = _rows[key];
    return row == null
        ? AchievementState.locked
        : AchievementState(progress: row.progress, unlocked: row.unlocked);
  }

  int get unlockedCount => _rows.values.where((r) => r.unlocked).length;

  /// Platforma gönderilmeyi bekleyen başarım anahtarları.
  List<String> get pendingKeys => [
    for (final r in _rows.values)
      if (!r.reported) r.key,
  ];

  int? get pendingTotalStars => _prefs.getInt(pendingStarsKey);

  Future<void> load() async {
    try {
      _rows
        ..clear()
        ..addEntries((await _dao.all()).map((r) => MapEntry(r.key, r)));
    } catch (e) {
      debugPrint('Başarımlar yüklenemedi: $e');
    }
    _notify();
  }

  /// Açılıştan sonra bir kez: mevcut ilerlemeden tüm başarımlar hesaplanır
  /// (önceki sürümlerde kazanılanlar da kaydedilir), skor bekletilir ve
  /// sessiz oturum denenir.
  Future<void> start(AchievementFacts facts, int totalStars) async {
    if (_started) return;
    _started = true;
    update(facts);
    await submitTotalStars(totalStars);
    await signInAndSync();
  }

  /// [start] çağrıldı mı (uygulama öne gelince oturum kontrolü için).
  bool get started => _started;

  /// Sıralı veritabanı yazmaları (arayüz beklemez).
  Future<void> _writes = Future<void>.value();

  void _write(String what, Future<void> Function(AchievementStateDao) op) {
    _writes = _writes.then((_) async {
      try {
        await op(_dao);
      } catch (e) {
        debugPrint('Başarım kaydı yazılamadı ($what): $e');
      }
    });
  }

  /// Bekleyen yazmalar ve gönderim bitince tamamlanır.
  Future<void> get idle async {
    while (true) {
      final writes = _writes;
      final flushing = _flushing;
      await writes;
      await flushing;
      if (identical(writes, _writes) && _flushing == null) return;
    }
  }

  /// İlerlemeden başarımları yeniden hesaplar, değişenleri yerelde kaydeder
  /// ve gönderimi başlatır. Bu çağrıyla yeni açılan başarımları hemen
  /// döndürür (veritabanı yazması arka planda, sırayla).
  List<AchievementDef> update(AchievementFacts facts) {
    final computed = AchievementEvaluator.evaluate(facts);
    final newly = <AchievementDef>[];
    final now = _clock.now().millisecondsSinceEpoch;
    for (final def in Achievements.all) {
      final c = computed[def.key]!;
      final old = _rows[def.key];
      final progress = c.progress > (old?.progress ?? 0)
          ? c.progress
          : old?.progress ?? 0;
      final unlocked = (old?.unlocked ?? false) || c.unlocked;
      if (progress == 0 && !unlocked) continue;
      if (old != null && old.progress == progress && old.unlocked == unlocked) {
        continue;
      }
      final row = AchievementStateRow(
        key: def.key,
        unlocked: unlocked,
        progress: progress,
        target: def.target,
        reported: false,
        unlockedAt: old?.unlockedAt ?? (unlocked ? now : null),
      );
      _rows[def.key] = row;
      if (unlocked && !(old?.unlocked ?? false)) newly.add(def);
      _write(def.key, (dao) => dao.upsert(row));
    }
    if (newly.isNotEmpty || pendingKeys.isNotEmpty) _notify();
    unawaited(flush());
    return newly;
  }

  /// Toplam yıldız değiştiyse skor gönderilir; çevrimdışıyken son değer
  /// bekletilir.
  Future<void> submitTotalStars(int total) async {
    if (total <= 0 || total == _prefs.getInt(reportedStarsKey)) return;
    await _prefs.setInt(pendingStarsKey, total);
    unawaited(flush());
  }

  /// Sessiz oturum dener; açıksa bekleyenleri gönderir (açılış ve uygulama
  /// öne geldiğinde).
  Future<void> signInAndSync() async {
    if (platform.kind == GamePlatformKind.none) return;
    final wasSignedIn = isSignedIn;
    try {
      await platform.trySilentSignIn();
    } catch (e) {
      debugPrint('Oyun platformu oturumu açılamadı: $e');
    }
    if (isSignedIn != wasSignedIn) _notify();
    await flush();
  }

  /// Ebeveyn panelindeki "bağlan" butonu: etkileşimli giriş; başarılıysa
  /// bekleyen tüm başarımlar ve skor hemen gönderilir.
  Future<GameSignInResult> connect() async {
    if (platform.kind == GamePlatformKind.none) return GameSignInResult.failed;
    GameSignInResult result;
    try {
      result = await platform.interactiveSignIn();
    } catch (e) {
      debugPrint('Oyun platformuna bağlanılamadı: $e');
      result = GameSignInResult.failed;
    }
    _notify();
    if (result == GameSignInResult.success) await flush();
    return result;
  }

  Future<void>? _flushing;
  bool _flushAgain = false;

  /// Bekleyen tüm başarımları ve skoru gönderir. Aynı anda tek gönderim
  /// yürür; sırada istek varsa bittikten sonra bir tur daha yapılır.
  Future<void> flush() {
    if (_flushing != null) {
      _flushAgain = true;
      return _flushing!;
    }
    return _flushing = _flushLoop().whenComplete(() => _flushing = null);
  }

  Future<void> _flushLoop() async {
    do {
      _flushAgain = false;
      if (!isSignedIn) return;
      await _writes;
      await _sendAchievements();
      await _sendScore();
    } while (_flushAgain && !_disposed);
  }

  Future<void> _sendAchievements() async {
    for (final row in _rows.values.where((r) => !r.reported).toList()) {
      if (_disposed || !isSignedIn) return;
      final def = Achievements.all.where((a) => a.key == row.key).firstOrNull;
      if (def == null) continue;
      bool ok;
      try {
        ok = def.incremental
            ? await platform.setAchievementProgress(
                row.key,
                row.progress,
                row.target,
              )
            : row.unlocked && await platform.unlockAchievement(row.key);
      } catch (e) {
        debugPrint('Başarım gönderilemedi (${row.key}): $e');
        ok = false;
      }
      if (!ok) continue;
      final current = _rows[row.key];
      if (current == null ||
          current.progress != row.progress ||
          current.unlocked != row.unlocked) {
        continue; // gönderim sırasında değişti; sonraki turda gider
      }
      _rows[row.key] = AchievementStateRow(
        key: row.key,
        unlocked: row.unlocked,
        progress: row.progress,
        target: row.target,
        reported: true,
        unlockedAt: row.unlockedAt,
      );
      _write(
        'reported ${row.key}',
        (dao) => dao.markReported(row.key, row.progress, row.unlocked),
      );
    }
  }

  Future<void> _sendScore() async {
    final pending = _prefs.getInt(pendingStarsKey);
    if (pending == null || _disposed || !isSignedIn) return;
    bool ok;
    try {
      ok = await platform.submitScore(GameIds.totalStarsLeaderboard, pending);
    } catch (e) {
      debugPrint('Skor gönderilemedi: $e');
      ok = false;
    }
    if (!ok) return;
    await _prefs.setInt(reportedStarsKey, pending);
    if (_prefs.getInt(pendingStarsKey) == pending) {
      await _prefs.remove(pendingStarsKey);
    }
  }

  /// Platformun kendi başarımlar ekranı (yalnızca ebeveyn kapısından sonra).
  Future<void> showAchievementsUI() async {
    if (!isSignedIn) return;
    try {
      await platform.showAchievementsUI();
    } catch (e) {
      debugPrint('Başarımlar ekranı açılamadı: $e');
    }
  }

  /// Platformun skor tablosu (yalnızca ebeveyn kapısından sonra).
  Future<void> showLeaderboardUI() async {
    if (!isSignedIn) return;
    try {
      await platform.showLeaderboardUI(GameIds.totalStarsLeaderboard);
    } catch (e) {
      debugPrint('Skor tablosu açılamadı: $e');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
