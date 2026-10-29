import 'package:algobot/data/db/app_database.dart';
import 'package:algobot/data/db/level_progress_dao.dart';
import 'package:algobot/data/db/level_session_dao.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/data/progress_repository.dart';
import 'package:algobot/data/session_repository.dart';
import 'package:algobot/jokers/joker_type.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/level.dart';
import 'package:algobot/models/program.dart';
import 'package:algobot/state/progress_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

Level _lvl(AgeGroup age, int id) =>
    levelsFor(age).firstWhere((l) => l.id == id);

/// Yazmalar arka planda; kısa bir bekleme ile tamamlanmalarını sağlar.
Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late AppDatabase db;
  late FakeClock clock;

  setUp(() async {
    db = await openTestDatabase();
    clock = FakeClock();
  });
  tearDown(() => db.close());

  group('Veritabanı', () {
    test('Tablolar oluşuyor', () async {
      final tables = await db.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      expect(
        tables.map((t) => t['name']),
        containsAll(['level_progress', 'level_session']),
      );
    });

    test('İlerleme ve oturum yazılıp okunuyor; SUM toplam yıldız', () async {
      final repo = ProgressRepository(db, clock: clock);
      await repo.save(
        AgeGroup.ages5to7,
        1,
        const LevelProgress(bestStars: 3, completed: true),
      );
      await repo.save(
        AgeGroup.ages13plus,
        2,
        const LevelProgress(bestStars: 2, completed: true),
      );
      final all = await repo.loadAll();
      expect(all[(AgeGroup.ages5to7, 1)]!.bestStars, 3);
      expect(await repo.totalStars(), 5);

      await LevelSessionDao(db.db).upsert(
        const LevelSessionRow(
          ageGroup: 'ages8to12',
          levelId: 4,
          lives: 2,
          lifeLostAt: 1000,
          skipUsed: false,
          lifeUsed: true,
          videoUsed: false,
          program: 'forward,turnRight',
          updatedAt: 1000,
        ),
      );
      final sessions = SessionRepository(db, clock: clock);
      await sessions.load();
      final s = sessions.sessionFor(_lvl(AgeGroup.ages8to12, 4));
      expect(s.usedJokers, {JokerType.life});
      // Eski biçim (yalnızca komut adları) aynen okunur.
      expect(s.program, const [Move(Command.forward), Move(Command.turnRight)]);
    });

    test('Çözülünce oturum silinir; best_stars yalnızca artar', () async {
      final progress = ProgressController(
        ProgressRepository(db, clock: clock),
        allLevelSets,
      );
      final sessions = SessionRepository(db, clock: clock);
      final level = _lvl(AgeGroup.ages8to12, 1);
      sessions.loseLife(level);
      await _flush();
      expect(await LevelSessionDao(db.db).all(), hasLength(1));

      progress.record(level, 3);
      sessions.reset(level);
      progress.record(level, 1);
      await _flush();
      expect(await LevelSessionDao(db.db).all(), isEmpty);
      final row = await LevelProgressDao(db.db).find('ages8to12', 1);
      expect(row!.bestStars, 3);
      expect(row.completed, isTrue);
    });

    test('Atlanan seviye: skipped=1, sonra çözülünce 0 ve completed=1; '
        'sonraki seviye açık', () async {
      final progress = ProgressController(
        ProgressRepository(db, clock: clock),
        allLevelSets,
      );
      final l1 = _lvl(AgeGroup.ages13plus, 1);
      final l2 = _lvl(AgeGroup.ages13plus, 2);
      final l3 = _lvl(AgeGroup.ages13plus, 3);
      expect(progress.isUnlocked(l2), isFalse);

      progress.markSkipped(l1);
      await _flush();
      var row = await LevelProgressDao(db.db).find('ages13plus', 1);
      expect(row!.skipped, isTrue);
      expect(row.bestStars, 0);
      expect(progress.isUnlocked(l2), isTrue);
      expect(progress.isUnlocked(l3), isFalse);

      progress.record(l1, 2);
      await _flush();
      row = await LevelProgressDao(db.db).find('ages13plus', 1);
      expect(row!.skipped, isFalse);
      expect(row.completed, isTrue);

      // Çözülmüş seviyeyi atlamak ilerlemeyi bozmaz.
      progress.markSkipped(l1);
      expect(progress.isSkipped(l1), isFalse);

      // Yeniden yükleme aynı durumu verir.
      final reloaded = ProgressController(
        ProgressRepository(db, clock: clock),
        allLevelSets,
      );
      await reloaded.load();
      expect(reloaded.starsFor(l1), 2);
      expect(reloaded.isUnlocked(l2), isTrue);
    });
  });

  group('shared_preferences göçü', () {
    test('Yıldızlar aktarılır, iki kez çalıştırmak çoğaltmaz', () async {
      SharedPreferences.setMockInitialValues({
        'stars_ages5to7_1': 3,
        'stars_ages13plus_2': 1,
        'stars_4': 2, // ilk sürümün anahtarı → 8–12
        'sound_on': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = ProgressRepository(db, clock: clock);

      expect(await repo.migrateFromPrefs(prefs), 3);
      final all = await repo.loadAll();
      expect(all[(AgeGroup.ages5to7, 1)]!.bestStars, 3);
      expect(all[(AgeGroup.ages13plus, 2)]!.completed, isTrue);
      expect(all[(AgeGroup.ages8to12, 4)]!.bestStars, 2);
      expect(prefs.getBool(ProgressRepository.migratedKey), isTrue);
      expect(prefs.containsKey('stars_ages5to7_1'), isFalse);
      expect(prefs.getBool('sound_on'), isFalse);

      // İkinci çalıştırma: bayrak var, hiçbir şey eklenmez.
      await prefs.setInt('stars_ages5to7_1', 1);
      expect(await repo.migrateFromPrefs(prefs), 0);
      expect(await LevelProgressDao(db.db).all(), hasLength(3));
      expect(await repo.totalStars(), 6);
    });

    test(
      'Bayrak yoksa tekrar çalışsa da satır çoğalmaz, yıldız düşmez',
      () async {
        SharedPreferences.setMockInitialValues({'stars_ages8to12_1': 2});
        final prefs = await SharedPreferences.getInstance();
        final repo = ProgressRepository(db, clock: clock);
        await repo.save(
          AgeGroup.ages8to12,
          1,
          const LevelProgress(bestStars: 3, completed: true),
        );
        await repo.migrateFromPrefs(prefs);
        final rows = await LevelProgressDao(db.db).all();
        expect(rows, hasLength(1));
        expect(rows.single.bestStars, 3);
      },
    );

    test(
      'Hata olursa eski anahtarlar silinmez, sonra yeniden denenir',
      () async {
        SharedPreferences.setMockInitialValues({'stars_ages8to12_1': 2});
        final prefs = await SharedPreferences.getInstance();
        final broken = await openTestDatabase();
        await broken.close();
        expect(
          await ProgressRepository(
            broken,
            clock: clock,
          ).migrateFromPrefs(prefs),
          0,
        );
        expect(prefs.getInt('stars_ages8to12_1'), 2);
        expect(prefs.getBool(ProgressRepository.migratedKey), isNull);

        expect(
          await ProgressRepository(db, clock: clock).migrateFromPrefs(prefs),
          1,
        );
        expect(prefs.containsKey('stars_ages8to12_1'), isFalse);
      },
    );
  });

  group('Canlar', () {
    final level = _lvl(AgeGroup.ages13plus, 1); // 3 can

    Future<SessionRepository> reopen() async {
      final s = SessionRepository(db, clock: clock);
      await s.load();
      return s;
    }

    test('Seviyeden çıkıp girmek (yeniden açmak) canları yenilemez', () async {
      final a = await reopen();
      a
        ..loseLife(level)
        ..loseLife(level)
        ..saveProgram(level, const [
          LoopStart(3),
          Move(Command.forward),
          LoopEnd(),
          Move(Command.turnLeft),
        ]);
      await _flush();
      final b = await reopen();
      expect(b.sessionFor(level).lives, 1);
      expect(b.sessionFor(level).program, const [
        LoopStart(3),
        Move(Command.forward),
        LoopEnd(),
        Move(Command.turnLeft),
      ]);
    });

    test('10 dakikada 1 can; 25 dakikada 2; başlangıcı aşmaz', () async {
      final s = await reopen();
      s
        ..loseLife(level)
        ..loseLife(level)
        ..loseLife(level);
      expect(s.sessionFor(level).lives, 0);
      expect(s.nextLifeIn(level), const Duration(minutes: 10));

      clock.advance(const Duration(minutes: 9, seconds: 59));
      expect(s.sessionFor(level).lives, 0);
      clock.advance(const Duration(seconds: 1));
      expect(s.sessionFor(level).lives, 1);
      expect(s.nextLifeIn(level), const Duration(minutes: 10));

      clock.advance(const Duration(minutes: 15));
      expect(s.sessionFor(level).lives, 2);
      expect(s.nextLifeIn(level), const Duration(minutes: 5));

      clock.advance(const Duration(hours: 3));
      expect(s.sessionFor(level).lives, 3);
      expect(s.nextLifeIn(level), isNull);
    });

    test('25 dakika tek seferde: 2 can', () async {
      final s = await reopen();
      for (var i = 0; i < 3; i++) {
        s.loseLife(level);
      }
      clock.advance(const Duration(minutes: 25));
      expect(s.sessionFor(level).lives, 2);
    });

    test(
      'Saat geri alınırsa can verilmez, başlangıç şimdiye çekilir',
      () async {
        final s = await reopen();
        s.loseLife(level);
        clock.advance(const Duration(minutes: -30));
        expect(s.sessionFor(level).lives, 2);
        expect(s.sessionFor(level).lifeLostAt, clock.now());
        clock.advance(const Duration(minutes: 10));
        expect(s.sessionFor(level).lives, 3);
      },
    );

    test(
      'Çözüm/atlama (reset) canları tam doldurur, jokerleri yeniler',
      () async {
        final s = await reopen();
        s
          ..loseLife(level)
          ..markJokerUsed(level, JokerType.skip)
          ..reset(level);
        await _flush();
        final again = await reopen();
        expect(again.sessionFor(level).lives, 3);
        expect(again.sessionFor(level).usedJokers, isEmpty);
      },
    );
  });

  group('Tek can değeri (3)', () {
    Future<SessionRepository> loadWith(List<LevelSessionRow> rows) async {
      for (final r in rows) {
        await LevelSessionDao(db.db).upsert(r);
      }
      final s = SessionRepository(db, clock: clock);
      await s.load();
      return s;
    }

    LevelSessionRow row(
      AgeGroup age,
      int id,
      int lives, {
      bool lifeUsed = false,
      int? lostAt,
    }) => LevelSessionRow(
      ageGroup: age.name,
      levelId: id,
      lives: lives,
      lifeLostAt: lostAt,
      skipUsed: false,
      lifeUsed: lifeUsed,
      videoUsed: false,
      program: '',
      updatedAt: 0,
    );

    test('Üç yaş grubunda da başlangıç canı 3', () {
      final s = SessionRepository(db, clock: clock);
      for (final age in AgeGroup.values) {
        for (final level in levelsFor(age)) {
          expect(
            s.sessionFor(level).lives,
            3,
            reason: '${age.name} ${level.id}',
          );
        }
      }
      expect(s.maxLives, 3);
    });

    test('Eski 5 ve 4 canlı kayıtlar 3 olarak okunur', () async {
      final s = await loadWith([
        row(AgeGroup.ages5to7, 1, 5),
        row(AgeGroup.ages8to12, 1, 4),
        row(
          AgeGroup.ages5to7,
          2,
          2,
          lostAt: clock.now().millisecondsSinceEpoch,
        ),
      ]);
      expect(s.sessionFor(_lvl(AgeGroup.ages5to7, 1)).lives, 3);
      expect(s.sessionFor(_lvl(AgeGroup.ages5to7, 1)).lifeLostAt, isNull);
      expect(s.sessionFor(_lvl(AgeGroup.ages8to12, 1)).lives, 3);
      // 3'ün altındaki kayıt olduğu gibi kalır.
      expect(s.sessionFor(_lvl(AgeGroup.ages5to7, 2)).lives, 2);
    });

    test('Can jokeri kullanılmış eski kayıt en fazla 4', () async {
      final s = await loadWith([
        row(AgeGroup.ages5to7, 3, 6, lifeUsed: true),
        row(AgeGroup.ages8to12, 3, 4, lifeUsed: true),
        row(AgeGroup.ages13plus, 3, 4, lifeUsed: false),
      ]);
      expect(s.sessionFor(_lvl(AgeGroup.ages5to7, 3)).lives, 4);
      expect(s.sessionFor(_lvl(AgeGroup.ages8to12, 3)).lives, 4);
      expect(s.sessionFor(_lvl(AgeGroup.ages13plus, 3)).lives, 3);
    });

    test('5–7 ve 8–12\'de de dolum 3\'te durur', () async {
      final s = SessionRepository(db, clock: clock);
      for (final age in [AgeGroup.ages5to7, AgeGroup.ages8to12]) {
        final level = levelsFor(age).first;
        for (var i = 0; i < 3; i++) {
          s.loseLife(level);
        }
        expect(s.sessionFor(level).lives, 0);
      }
      clock.advance(const Duration(hours: 5));
      for (final age in [AgeGroup.ages5to7, AgeGroup.ages8to12]) {
        final level = levelsFor(age).first;
        expect(s.sessionFor(level).lives, 3);
        expect(s.nextLifeIn(level), isNull);
      }
    });
  });

  group('Jokerler (kalıcılık)', () {
    final level = _lvl(AgeGroup.ages8to12, 2); // 3 can

    test('Can jokeri +1, 3\'ü aşabilir (4); kullanım kalıcı', () async {
      final s = SessionRepository(db, clock: clock);
      s.useLifeJoker(level);
      expect(s.sessionFor(level).lives, 4);
      expect(s.sessionFor(level).lifeLostAt, isNull);
      await _flush();
      final again = SessionRepository(db, clock: clock);
      await again.load();
      expect(again.sessionFor(level).usedJokers, {JokerType.life});
      expect(again.sessionFor(level).lives, 4);
    });

    test('Can düşünce başlangıcın üstündeyken dolum başlamaz', () async {
      final s = SessionRepository(db, clock: clock)..useLifeJoker(level);
      s.loseLife(level); // 4 → 3 (tam)
      expect(s.sessionFor(level).lifeLostAt, isNull);
      s.loseLife(level); // 3 → 2
      expect(s.nextLifeIn(level), const Duration(minutes: 10));
    });
  });
}
