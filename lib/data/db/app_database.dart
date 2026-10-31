import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Oyun veritabanı (`algobot.db`). Uygulama boyunca tek örnek açılır ve
/// provider ile verilir. Şema değişiklikleri [_migrations]'a yeni bir sürüm
/// olarak eklenir; `onUpgrade` eksik adımları sırayla çalıştırır.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const fileName = 'algobot.db';
  static const version = 2;

  /// Sürüm → o sürüme geçişte çalışacak SQL komutları.
  static const Map<int, List<String>> _migrations = {
    1: [
      '''
      CREATE TABLE level_progress (
        age_group   TEXT    NOT NULL,
        level_id    INTEGER NOT NULL,
        best_stars  INTEGER NOT NULL DEFAULT 0,
        completed   INTEGER NOT NULL DEFAULT 0,
        skipped     INTEGER NOT NULL DEFAULT 0,
        updated_at  INTEGER NOT NULL,
        PRIMARY KEY (age_group, level_id)
      )''',
      '''
      CREATE TABLE level_session (
        age_group        TEXT    NOT NULL,
        level_id         INTEGER NOT NULL,
        lives            INTEGER NOT NULL,
        life_lost_at     INTEGER,
        joker_skip_used  INTEGER NOT NULL DEFAULT 0,
        joker_life_used  INTEGER NOT NULL DEFAULT 0,
        joker_video_used INTEGER NOT NULL DEFAULT 0,
        program          TEXT    NOT NULL DEFAULT '',
        updated_at       INTEGER NOT NULL,
        PRIMARY KEY (age_group, level_id)
      )''',
    ],
    // Başarımlar: yerel durum ve platforma gönderildi mi (`reported`).
    2: [
      '''
      CREATE TABLE achievement_state (
        achievement_key TEXT PRIMARY KEY,
        unlocked        INTEGER NOT NULL DEFAULT 0,
        progress        INTEGER NOT NULL DEFAULT 0,
        target          INTEGER NOT NULL DEFAULT 1,
        reported        INTEGER NOT NULL DEFAULT 0,
        unlocked_at     INTEGER
      )''',
    ],
  };

  /// `factory` ve `path` testler içindir (ör. ffi + bellek içi veritabanı).
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, v) => _migrate(db, 0, v),
        onUpgrade: _migrate,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      for (final sql in _migrations[v] ?? const <String>[]) {
        await db.execute(sql);
      }
    }
  }

  Future<void> close() => db.close();
}
