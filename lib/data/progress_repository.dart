import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import '../models/age_group.dart';
import 'db/app_database.dart';
import 'db/level_progress_dao.dart';

/// Bir seviyenin kalıcı ilerlemesi.
@immutable
class LevelProgress {
  const LevelProgress({
    this.bestStars = 0,
    this.completed = false,
    this.skipped = false,
  });

  final int bestStars;

  /// En az bir kez çözüldü.
  final bool completed;

  /// Atlandı ve henüz çözülmedi.
  final bool skipped;

  /// Sonraki seviyenin kilidini açar mı.
  bool get passed => completed || skipped;

  LevelProgress copyWith({int? bestStars, bool? completed, bool? skipped}) =>
      LevelProgress(
        bestStars: bestStars ?? this.bestStars,
        completed: completed ?? this.completed,
        skipped: skipped ?? this.skipped,
      );

  @override
  bool operator ==(Object other) =>
      other is LevelProgress &&
      other.bestStars == bestStars &&
      other.completed == completed &&
      other.skipped == skipped;

  @override
  int get hashCode => Object.hash(bestStars, completed, skipped);
}

typedef LevelKey = (AgeGroup, int);

/// Seviye ilerlemesinin tek arayüzü (UI ve denetleyiciler SQL görmez).
class ProgressRepository {
  ProgressRepository(this._database, {this._clock = const SystemClock()});

  final AppDatabase _database;
  final Clock _clock;

  LevelProgressDao get _dao => LevelProgressDao(_database.db);

  static const migratedKey = 'migrated_to_sqlite_v1';
  static final _starsKey = RegExp(r'^stars_(?:(\w+?)_)?(\d+)$');

  static AgeGroup? _age(String name) =>
      AgeGroup.values.where((a) => a.name == name).firstOrNull;

  Future<Map<LevelKey, LevelProgress>> loadAll() async {
    final result = <LevelKey, LevelProgress>{};
    for (final row in await _dao.all()) {
      final age = _age(row.ageGroup);
      if (age == null) continue;
      result[(age, row.levelId)] = LevelProgress(
        bestStars: row.bestStars,
        completed: row.completed,
        skipped: row.skipped,
      );
    }
    return result;
  }

  Future<void> save(AgeGroup age, int levelId, LevelProgress progress) =>
      _dao.upsert(
        LevelProgressRow(
          ageGroup: age.name,
          levelId: levelId,
          bestStars: progress.bestStars,
          completed: progress.completed,
          skipped: progress.skipped,
          updatedAt: _clock.now().millisecondsSinceEpoch,
        ),
      );

  /// Tüm setlerdeki toplam yıldız (SQL `SUM`).
  Future<int> totalStars() => _dao.totalStars();

  Future<void> clearAll() => _dao.deleteAll();

  /// `shared_preferences`'taki eski yıldız kayıtlarını (`stars_<yaş>_<id>`
  /// ve ilk sürümün `stars_<id>` anahtarları → 8–12) bir kez aktarır.
  /// Başarılıysa eski anahtarlar silinir; hata olursa bir sonraki açılışta
  /// yeniden denenir. Aktarılan kayıt sayısını döndürür.
  Future<int> migrateFromPrefs(SharedPreferences prefs) async {
    if (prefs.getBool(migratedKey) ?? false) return 0;
    final entries = <(String, AgeGroup, int, int)>[];
    for (final key in prefs.getKeys()) {
      final m = _starsKey.firstMatch(key);
      if (m == null) continue;
      final age = m[1] == null ? AgeGroup.ages8to12 : _age(m[1]!);
      final stars = prefs.get(key);
      if (age == null || stars is! int) continue;
      entries.add((key, age, int.parse(m[2]!), stars));
    }
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      await _database.db.transaction((txn) async {
        final dao = LevelProgressDao(txn);
        for (final (_, age, id, stars) in entries) {
          final existing = await dao.find(age.name, id);
          final best = existing == null || stars > existing.bestStars
              ? stars
              : existing.bestStars;
          await dao.upsert(
            LevelProgressRow(
              ageGroup: age.name,
              levelId: id,
              bestStars: best,
              completed: best > 0 || (existing?.completed ?? false),
              skipped: false,
              updatedAt: now,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('SQLite göçü başarısız, sonra tekrar denenecek: $e');
      return 0;
    }
    await prefs.setBool(migratedKey, true);
    for (final (key, _, _, _) in entries) {
      await prefs.remove(key);
    }
    return entries.length;
  }
}
