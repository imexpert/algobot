import 'package:sqflite/sqflite.dart';

class LevelSessionRow {
  const LevelSessionRow({
    required this.ageGroup,
    required this.levelId,
    required this.lives,
    required this.lifeLostAt,
    required this.skipUsed,
    required this.lifeUsed,
    required this.videoUsed,
    required this.program,
    required this.updatedAt,
  });

  final String ageGroup;
  final int levelId;
  final int lives;

  /// Can dolum hesabının başlangıcı (epoch ms); canlar tamsa null.
  final int? lifeLostAt;
  final bool skipUsed;
  final bool lifeUsed;
  final bool videoUsed;

  /// Komut adları, virgülle ayrılmış (ör. `forward,turnRight`).
  final String program;
  final int updatedAt;

  factory LevelSessionRow.fromMap(Map<String, Object?> m) => LevelSessionRow(
    ageGroup: m['age_group']! as String,
    levelId: m['level_id']! as int,
    lives: m['lives']! as int,
    lifeLostAt: m['life_lost_at'] as int?,
    skipUsed: m['joker_skip_used'] == 1,
    lifeUsed: m['joker_life_used'] == 1,
    videoUsed: m['joker_video_used'] == 1,
    program: m['program']! as String,
    updatedAt: m['updated_at']! as int,
  );

  Map<String, Object?> toMap() => {
    'age_group': ageGroup,
    'level_id': levelId,
    'lives': lives,
    'life_lost_at': lifeLostAt,
    'joker_skip_used': skipUsed ? 1 : 0,
    'joker_life_used': lifeUsed ? 1 : 0,
    'joker_video_used': videoUsed ? 1 : 0,
    'program': program,
    'updated_at': updatedAt,
  };
}

class LevelSessionDao {
  const LevelSessionDao(this._db);

  final DatabaseExecutor _db;

  Future<List<LevelSessionRow>> all() async =>
      (await _db.query('level_session')).map(LevelSessionRow.fromMap).toList();

  Future<void> upsert(LevelSessionRow row) => _db.insert(
    'level_session',
    row.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> delete(String ageGroup, int levelId) => _db.delete(
    'level_session',
    where: 'age_group = ? AND level_id = ?',
    whereArgs: [ageGroup, levelId],
  );

  Future<void> deleteAll() => _db.delete('level_session');
}
