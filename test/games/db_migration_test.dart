import 'dart:io';

import 'package:algobot/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'sürüm 1 → 2: mevcut veriler korunur, achievement_state oluşur',
    () async {
      sqfliteFfiInit();
      final dir = Directory.systemTemp.createTempSync('algobot_mig');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = p.join(dir.path, 'algobot.db');

      // Sürüm 1 şemasıyla eski bir veritabanı.
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
            CREATE TABLE level_progress (
              age_group TEXT NOT NULL, level_id INTEGER NOT NULL,
              best_stars INTEGER NOT NULL DEFAULT 0,
              completed INTEGER NOT NULL DEFAULT 0,
              skipped INTEGER NOT NULL DEFAULT 0,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (age_group, level_id))''');
            await db.execute('''
            CREATE TABLE level_session (
              age_group TEXT NOT NULL, level_id INTEGER NOT NULL,
              lives INTEGER NOT NULL, life_lost_at INTEGER,
              joker_skip_used INTEGER NOT NULL DEFAULT 0,
              joker_life_used INTEGER NOT NULL DEFAULT 0,
              joker_video_used INTEGER NOT NULL DEFAULT 0,
              program TEXT NOT NULL DEFAULT '',
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (age_group, level_id))''');
          },
        ),
      );
      await old.insert('level_progress', {
        'age_group': 'ages8to12',
        'level_id': 3,
        'best_stars': 2,
        'completed': 1,
        'skipped': 0,
        'updated_at': 1,
      });
      await old.insert('level_session', {
        'age_group': 'ages8to12',
        'level_id': 4,
        'lives': 2,
        'program': 'F',
        'updated_at': 1,
      });
      await old.close();

      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      addTearDown(db.close);
      expect(await db.db.getVersion(), 2);
      final progress = await db.db.query('level_progress');
      expect(progress.single['best_stars'], 2);
      final session = await db.db.query('level_session');
      expect(session.single['lives'], 2);
      final tables = (await db.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      )).map((t) => t['name']);
      expect(tables, contains('achievement_state'));
      await db.db.insert('achievement_state', {
        'achievement_key': 'first_level',
        'unlocked': 1,
        'progress': 1,
        'target': 1,
      });
      final row = (await db.db.query('achievement_state')).single;
      expect(row['reported'], 0);
      expect(row['unlocked_at'], isNull);
    },
  );
}
