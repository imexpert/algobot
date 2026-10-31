import 'package:sqflite/sqflite.dart';

/// `achievement_state` tablosunun bir satırı.
class AchievementStateRow {
  const AchievementStateRow({
    required this.key,
    required this.unlocked,
    required this.progress,
    required this.target,
    required this.reported,
    this.unlockedAt,
  });

  final String key;
  final bool unlocked;
  final int progress;
  final int target;

  /// Bu son durum platforma gönderildi mi.
  final bool reported;

  /// Açıldığı an (ms); kilitliyse null.
  final int? unlockedAt;

  factory AchievementStateRow.fromMap(Map<String, Object?> m) =>
      AchievementStateRow(
        key: m['achievement_key']! as String,
        unlocked: m['unlocked'] == 1,
        progress: m['progress']! as int,
        target: m['target']! as int,
        reported: m['reported'] == 1,
        unlockedAt: m['unlocked_at'] as int?,
      );

  Map<String, Object?> toMap() => {
    'achievement_key': key,
    'unlocked': unlocked ? 1 : 0,
    'progress': progress,
    'target': target,
    'reported': reported ? 1 : 0,
    'unlocked_at': unlockedAt,
  };
}

class AchievementStateDao {
  const AchievementStateDao(this._db);

  final DatabaseExecutor _db;

  static const table = 'achievement_state';

  Future<List<AchievementStateRow>> all() async =>
      (await _db.query(table)).map(AchievementStateRow.fromMap).toList();

  Future<void> upsert(AchievementStateRow row) => _db.insert(
    table,
    row.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  /// Gönderilen durum hâlâ güncelse `reported = 1`. Gönderim sırasında
  /// ilerleme değiştiyse satır bekleyen olarak kalır.
  Future<bool> markReported(String key, int progress, bool unlocked) async =>
      await _db.update(
        table,
        {'reported': 1},
        where: 'achievement_key = ? AND progress = ? AND unlocked = ?',
        whereArgs: [key, progress, unlocked ? 1 : 0],
      ) >
      0;
}
