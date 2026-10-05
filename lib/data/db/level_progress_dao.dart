import 'package:sqflite/sqflite.dart';

class LevelProgressRow {
  const LevelProgressRow({
    required this.ageGroup,
    required this.levelId,
    required this.bestStars,
    required this.completed,
    required this.skipped,
    required this.updatedAt,
  });

  final String ageGroup;
  final int levelId;
  final int bestStars;
  final bool completed;
  final bool skipped;
  final int updatedAt;

  factory LevelProgressRow.fromMap(Map<String, Object?> m) => LevelProgressRow(
    ageGroup: m['age_group']! as String,
    levelId: m['level_id']! as int,
    bestStars: m['best_stars']! as int,
    completed: m['completed'] == 1,
    skipped: m['skipped'] == 1,
    updatedAt: m['updated_at']! as int,
  );

  Map<String, Object?> toMap() => {
    'age_group': ageGroup,
    'level_id': levelId,
    'best_stars': bestStars,
    'completed': completed ? 1 : 0,
    'skipped': skipped ? 1 : 0,
    'updated_at': updatedAt,
  };
}

class LevelProgressDao {
  const LevelProgressDao(this._db);

  final DatabaseExecutor _db;

  Future<List<LevelProgressRow>> all() async => (await _db.query(
    'level_progress',
  )).map(LevelProgressRow.fromMap).toList();

  Future<LevelProgressRow?> find(String ageGroup, int levelId) async {
    final rows = await _db.query(
      'level_progress',
      where: 'age_group = ? AND level_id = ?',
      whereArgs: [ageGroup, levelId],
    );
    return rows.isEmpty ? null : LevelProgressRow.fromMap(rows.first);
  }

  Future<void> upsert(LevelProgressRow row) => _db.insert(
    'level_progress',
    row.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  /// Karakter kilitleri için tüm setlerin toplam yıldızı.
  Future<int> totalStars() async {
    final r = await _db.rawQuery(
      'SELECT COALESCE(SUM(best_stars), 0) AS total FROM level_progress',
    );
    return r.first['total']! as int;
  }

  Future<void> deleteAll() => _db.delete('level_progress');
}
