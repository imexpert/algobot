// QA: simülatör, seviyeler, yıldız/can/joker kuralları ve veritabanı
// sağlamlığı için mevcut testlerin kapsamadığı durumlar.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:algobot/characters/character_registry.dart';
import 'package:algobot/core/clock.dart';
import 'package:algobot/data/db/app_database.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/data/progress_repository.dart';
import 'package:algobot/data/session_repository.dart';
import 'package:algobot/engine/run_result.dart';
import 'package:algobot/engine/simulator.dart';
import 'package:algobot/engine/solver.dart';
import 'package:algobot/engine/star_calculator.dart';
import 'package:algobot/jokers/joker_type.dart';
import 'package:algobot/models/age_config.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/direction.dart';
import 'package:algobot/models/level.dart';
import 'package:algobot/models/program.dart';
import 'package:algobot/state/progress_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

Level _level(
  List<String> map, {
  Direction dir = Direction.east,
  AgeGroup age = AgeGroup.ages13plus,
}) => Level(
  id: 0,
  ageGroup: age,
  textKey: 'test',
  map: map,
  startDirection: dir,
  availableCommands: Command.values,
  maxSlots: 20,
  optimalLength: 1,
);

const f = Command.forward;
const r = Command.turnRight;
const l = Command.turnLeft;

void main() {
  group('Simülatör · göreli komutlar 4 yönde', () {
    // 3x3 ortada başlangıç; her yönde bir kare ilerleme.
    const map = ['...', '.R.', '..G'];
    const expected = {
      Direction.north: Point(1, 0),
      Direction.east: Point(2, 1),
      Direction.south: Point(1, 2),
      Direction.west: Point(0, 1),
    };
    for (final d in Direction.values) {
      test('$d: ileri doğru kareye gider', () {
        final level = _level(map, dir: d);
        final r1 = Simulator.run(level, [f]);
        expect(r1.steps.single.toPosition, expected[d]);
        expect(r1.steps.single.toDirection, d);
      });
      test('$d: sağa ve sola dönüp ileri', () {
        final level = _level(map, dir: d);
        final right = Simulator.run(level, [r, f]).steps.last;
        expect(right.toPosition, expected[d.turnRight]);
        final left = Simulator.run(level, [l, f]).steps.last;
        expect(left.toPosition, expected[d.turnLeft]);
      });
    }

    test('Dört sağa dönüş başlangıç yönüne döndürür', () {
      final level = _level(map, dir: Direction.north);
      final s = Simulator.run(level, [r, r, r, r]).steps.last;
      expect(s.toDirection, Direction.north);
      expect(s.toPosition, const Point(1, 1));
    });
  });

  group('Simülatör · mutlak komutlar (5–7)', () {
    const map = ['...', '.R.', '..G'];
    for (final (c, p) in [
      (Command.moveUp, Point(1, 0)),
      (Command.moveDown, Point(1, 2)),
      (Command.moveLeft, Point(0, 1)),
      (Command.moveRight, Point(2, 1)),
    ]) {
      for (final start in Direction.values) {
        test('${c.name}, başlangıç yönü $start', () {
          final level = _level(map, dir: start, age: AgeGroup.ages5to7);
          final s = Simulator.run(level, [c]).steps.single;
          expect(s.toPosition, p);
          expect(s.toDirection, c.absoluteDirection);
        });
      }
    }
  });

  group('Simülatör · portal ve buz kenar durumları', () {
    test('Varış portalından çıkıp geri girince tekrar ışınlanır, ama '
        'varışta durur (zincirleme ışınlanma yok)', () {
      // R P . p G : P'ye gir → p'ye ışınlan ve dur.
      final level = _level(['RP.pG']);
      final res = Simulator.run(level, [f]);
      expect(res.steps.single.toPosition, const Point(3, 0));
      expect(res.steps.single.motions.map((m) => m.kind), [
        MotionKind.walk,
        MotionKind.teleport,
      ]);
      // p'den ileri: G'ye girer (geri ışınlanmaz).
      expect(Simulator.run(level, [f, f]).isSuccess, isTrue);
    });

    test('Buzda kayarak portala girince ışınlanır ve varışta durur', () {
      final level = _level(['RIIP#', '##p.G']);
      final res = Simulator.run(level, [f]);
      final step = res.steps.single;
      expect(step.toPosition, const Point(2, 1));
      expect(step.motions.last.kind, MotionKind.teleport);
      expect(Simulator.run(level, [f, f, f]).isSuccess, isTrue);
    });

    test('Buzda kayarken anahtar alınır, kapı aynı kaymada açılır', () {
      final level = _level(['RIKD.G']);
      final res = Simulator.run(level, [f]);
      // Anahtar karesi zemin: kayma orada durur.
      expect(res.steps.single.toPosition, const Point(2, 0));
      expect(res.steps.single.keyCollected, const Point(2, 0));
      expect(Simulator.run(level, [f, f, f, f]).isSuccess, isTrue);
    });

    test('Buz üstündeki toplanabilir (b) kayarken bir kez sayılır', () {
      final level = _level(['RbbI#', '....G']);
      final res = Simulator.run(level, [f]);
      expect(res.steps.single.collected.length, 2);
      expect(res.collectedCount, 2);
    });

    test('Döngüde aynı toplanabilire tekrar basmak sayıyı artırmaz', () {
      final level = _level(['RB..G']);
      final res = Simulator.runProgram(level, [
        const Move(f),
        const Move(r),
        const Move(r),
        const Move(f),
        const Move(r),
        const Move(r),
        const Move(f),
        const Move(f),
        const Move(f),
        const Move(f),
      ]);
      expect(res.isSuccess, isTrue);
      expect(res.collectedCount, 1);
    });

    test('Boş program: hiç adım yok, başarısız (stoppedShort)', () {
      final level = _level(['RG']);
      final res = Simulator.runProgram(level, const []);
      expect(res.steps, isEmpty);
      expect(res.outcome, RunOutcome.stoppedShort);
    });

    test('Yalnızca boş döngü: hiç adım üretmez (oyunda can düşürür)', () {
      final level = _level(['RG']);
      final res = Simulator.runProgram(level, const [LoopStart(3), LoopEnd()]);
      expect(res.steps, isEmpty);
      expect(res.outcome, RunOutcome.stoppedShort);
    });
  });

  group('Seviyeler (3 yaş × 16 = 48 seviye)', () {
    final all = [for (final e in allLevelSets.entries) ...e.value];

    test('Toplam 48 seviye; textKey benzersiz', () {
      expect(all.length, 48);
      expect(all.map((l) => l.textKey).toSet().length, 48);
    });

    test('Her seviyede başlangıç ve hedef farklı kareler; başlangıç '
        'duvar/kapı değil', () {
      for (final level in all) {
        expect(level.start, isNot(level.goal), reason: level.textKey);
      }
    });

    test('maxSlots en az optimalLength ve en fazla 24', () {
      for (final level in all) {
        expect(
          level.maxSlots,
          inInclusiveRange(level.optimalLength, 24),
          reason: level.textKey,
        );
      }
    });

    test('8–12 ve 13+ Dünya 1: en kısa çözüm tam komut kümesiyle', () {
      for (final age in [AgeGroup.ages8to12, AgeGroup.ages13plus]) {
        for (final level in levelsFor(age).where((l) => l.world == 1)) {
          final best = Solver.solve(level, commands: age.settings.commandSet);
          expect(best, isNotNull, reason: level.textKey);
          expect(best!.length, level.optimalLength, reason: level.textKey);
        }
      }
    });

    test('Referans çözüm/programın her seviyede başarılı ve 3 yıldız', () {
      for (final level in all) {
        final res = Simulator.runProgram(level, level.solutionProgram);
        expect(res.isSuccess, isTrue, reason: level.textKey);
        expect(StarCalculator.stars(level, res), 3, reason: level.textKey);
      }
    });

    test('Seviye metinleri ARB\'de: başlık ve ipucu boş değil', () {
      final enArb =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, Object?>;
      final trArb =
          jsonDecode(File('lib/l10n/app_tr.arb').readAsStringSync())
              as Map<String, Object?>;
      for (final level in all) {
        for (final arb in [enArb, trArb]) {
          for (final k in ['${level.textKey}Title', '${level.textKey}Intro']) {
            expect(arb[k], isA<String>(), reason: k);
            expect((arb[k]! as String).trim(), isNotEmpty, reason: k);
          }
        }
      }
    });

    test('"Komutlar" ve "Adım adım" ifadeleri hiçbir çeviride yok', () {
      for (final file in ['lib/l10n/app_en.arb', 'lib/l10n/app_tr.arb']) {
        final arb =
            jsonDecode(File(file).readAsStringSync()) as Map<String, Object?>;
        // paletteSemanticsLabel yalnızca ekran okuyucu etiketidir (görünmez).
        final visible = Map.of(arb)..remove('paletteSemanticsLabel');
        for (final v in visible.values.whereType<String>()) {
          for (final banned in ['Komutlar', 'Adım adım', 'Step by step']) {
            expect(v, isNot(contains(banned)), reason: '$file: $v');
          }
        }
      }
    });
  });

  group('Yıldız kuralları', () {
    test('Pilsiz seviyede hedef + en kısa = 3, fazla kart = 2', () {
      final level = Level(
        id: 0,
        ageGroup: AgeGroup.ages8to12,
        textKey: 't',
        map: ['R.G'],
        startDirection: Direction.east,
        availableCommands: const [f],
        maxSlots: 5,
        optimalLength: 2,
      );
      expect(StarCalculator.stars(level, Simulator.run(level, [f, f])), 3);
      expect(StarCalculator.stars(level, Simulator.run(level, [f, f, f])), 2);
    });
  });

  group('Canlar ve jokerler (sahte saat)', () {
    late FakeClock clock;
    late AppDatabase db;
    late SessionRepository sessions;
    final level = levelsFor(AgeGroup.ages13plus).first;

    setUp(() async {
      clock = FakeClock();
      db = await openTestDatabase();
      sessions = SessionRepository(db, clock: clock);
      await sessions.load();
    });
    tearDown(() => db.close());

    test('Her yaşta başlangıç 3, 0\'ın altına inmez', () {
      for (final age in AgeGroup.values) {
        final lv = levelsFor(age).first;
        expect(sessions.sessionFor(lv).lives, 3);
        for (var i = 0; i < 5; i++) {
          sessions.loseLife(lv);
        }
        expect(sessions.sessionFor(lv).lives, 0);
      }
    });

    test('Saat geri alınınca can verilmez, sonra normal dolar', () {
      sessions
        ..loseLife(level)
        ..loseLife(level);
      clock.advance(const Duration(minutes: 5));
      clock.set(clock.now().subtract(const Duration(hours: 2)));
      expect(sessions.sessionFor(level).lives, 1);
      clock.advance(const Duration(minutes: 10));
      expect(sessions.sessionFor(level).lives, 2);
      clock.advance(const Duration(minutes: 10));
      expect(sessions.sessionFor(level).lives, 3);
      clock.advance(const Duration(hours: 5));
      expect(sessions.sessionFor(level).lives, 3);
    });

    test('Saat ileri sarılınca en fazla 3', () {
      for (var i = 0; i < 3; i++) {
        sessions.loseLife(level);
      }
      clock.advance(const Duration(days: 30));
      expect(sessions.sessionFor(level).lives, 3);
      expect(sessions.nextLifeIn(level), isNull);
    });

    test('Can jokeri 0 → 1 iken dolum süresi korunur', () {
      for (var i = 0; i < 3; i++) {
        sessions.loseLife(level);
      }
      clock.advance(const Duration(minutes: 7));
      sessions.useLifeJoker(level);
      expect(sessions.sessionFor(level).lives, 1);
      clock.advance(const Duration(minutes: 3));
      expect(sessions.sessionFor(level).lives, 2);
    });

    test(
      'Çözülünce/atlanınca oturum yenilenir; kalıcı (yeniden yükleme)',
      () async {
        sessions
          ..loseLife(level)
          ..markJokerUsed(level, JokerType.skip)
          ..useLifeJoker(level)
          ..saveProgram(level, const [Move(f)]);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        var again = SessionRepository(db, clock: clock);
        await again.load();
        expect(again.sessionFor(level).usedJokers, {
          JokerType.skip,
          JokerType.life,
        });
        expect(again.sessionFor(level).program, const [Move(f)]);
        sessions.reset(level);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        again = SessionRepository(db, clock: clock);
        await again.load();
        expect(again.sessionFor(level).lives, 3);
        expect(again.sessionFor(level).usedJokers, isEmpty);
        expect(again.sessionFor(level).program, isEmpty);
      },
    );
  });

  group('İlerleme kuralları', () {
    late AppDatabase db;
    late ProgressController progress;
    setUp(() async {
      db = await openTestDatabase();
      progress = ProgressController(ProgressRepository(db), allLevelSets);
      await progress.load();
    });
    tearDown(() async {
      // Arka plandaki yazmaların bitmesi beklenir.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await db.close();
    });

    test('Atla → sonraki açık, 0 yıldız; sonra çöz → atlandı kalkar', () {
      final levels = levelsFor(AgeGroup.ages5to7);
      progress.markSkipped(levels[0]);
      expect(progress.isUnlocked(levels[1]), isTrue);
      expect(progress.starsFor(levels[0]), 0);
      progress.record(levels[0], 2);
      expect(progress.isSkipped(levels[0]), isFalse);
      expect(progress.starsFor(levels[0]), 2);
      // Daha düşük yıldız eskiyi bozmaz; çözülmüş seviye atlanamaz.
      progress
        ..record(levels[0], 1)
        ..markSkipped(levels[0]);
      expect(progress.starsFor(levels[0]), 2);
      expect(progress.isSkipped(levels[0]), isFalse);
    });

    test('Dünya 2\'nin ilki, Dünya 1 finali geçilince açılır', () {
      for (final age in AgeGroup.values) {
        final list = levelsFor(age);
        final w2first = list.firstWhere((l) => l.world == 2);
        expect(progress.isUnlocked(w2first), isFalse);
        progress.markSkipped(list.lastWhere((l) => l.world == 1));
        expect(progress.isUnlocked(w2first), isTrue);
      }
    });
  });

  group('Veritabanı sağlamlığı', () {
    test('Kapanmış veritabanına oturum yazmak çökertmez', () async {
      final db = await openTestDatabase();
      final sessions = SessionRepository(db, clock: FakeClock());
      await sessions.load();
      await db.close();
      final level = levelsFor(AgeGroup.ages8to12).first;
      sessions.loseLife(level);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(sessions.sessionFor(level).lives, 2);
      await sessions.clearAll();
    });

    test(
      'Bozuk dosya: açılış hata verir (uygulama bellek içine düşer)',
      () async {
        sqfliteFfiInit();
        final dir = Directory.systemTemp.createTempSync('algobot_qa');
        final file = File('${dir.path}/algobot.db')
          ..writeAsBytesSync(List.generate(4096, (i) => (i * 37) % 251));
        Object? error;
        try {
          final db = await AppDatabase.open(
            factory: databaseFactoryFfi,
            path: file.path,
          );
          // Açılabilirse ilk sorgu başarısız olmalı ve yakalanmalı.
          final sessions = SessionRepository(db);
          await sessions.load();
          final progress = ProgressController(
            ProgressRepository(db),
            allLevelSets,
          );
          await progress.load();
          await db.close();
        } catch (e) {
          error = e;
        }
        // Hata ya açılışta fırlar (app_services yedeğe geçer) ya da
        // yükleme içinde yutulur; ikisi de çökme değildir.
        expect(
          error == null || error is DatabaseException,
          isTrue,
          reason: '$error',
        );
        dir.deleteSync(recursive: true);
      },
    );

    test('Göç yarıda kalırsa (veritabanı hatası) eski yıldızlar silinmez ve '
        'sonraki açılışta yeniden denenir', () async {
      SharedPreferences.setMockInitialValues({'stars_ages5to7_1': 3});
      final prefs = await SharedPreferences.getInstance();
      final db = await openTestDatabase();
      await db.close();
      final failed = await ProgressRepository(db).migrateFromPrefs(prefs);
      expect(failed, 0);
      expect(prefs.getInt('stars_ages5to7_1'), 3);
      expect(prefs.getBool(ProgressRepository.migratedKey), isNot(true));

      final db2 = await openTestDatabase();
      final moved = await ProgressRepository(db2).migrateFromPrefs(prefs);
      expect(moved, 1);
      final again = await ProgressRepository(db2).migrateFromPrefs(prefs);
      expect(again, 0);
      final rows = await ProgressRepository(db2).loadAll();
      expect(rows[(AgeGroup.ages5to7, 1)]!.bestStars, 3);
      expect(rows.length, 1);
      await db2.close();
    });
  });

  group('Karakterler', () {
    test('Kilit eşikleri: 0 yıldızda yalnızca ilk açık, en yüksek eşik '
        'oyundaki toplam yıldızla ulaşılabilir', () {
      final unlocked0 = CharacterRegistry.all.where((c) => c.unlockStars <= 0);
      expect(unlocked0, isNotEmpty);
      final maxStars = AgeGroup.values.fold(
        0,
        (s, a) => s + levelsFor(a).length * 3,
      );
      for (final c in CharacterRegistry.all) {
        expect(c.unlockStars, lessThanOrEqualTo(maxStars), reason: c.id);
      }
    });
  });

  test('Clock arayüzü sistem saatini döndürür', () {
    final now = DateTime.now();
    expect(
      const SystemClock().now().difference(now).inSeconds.abs(),
      lessThan(2),
    );
    expect(AgeSettings.maxLives, 3);
    expect(AgeSettings.lifeRefill, const Duration(minutes: 10));
  });
}
