// Güncelleme 6: belirgin yön göstergesi ve eğitim modu.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:algobot/characters/base_disc_painter.dart';
import 'package:algobot/characters/character_registry.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/engine/solver.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/direction.dart';
import 'package:algobot/state/game_controller.dart';
import 'package:algobot/state/settings_controller.dart';
import 'package:algobot/tutorial/ghost_demo.dart';
import 'package:algobot/tutorial/mechanic_intro.dart';
import 'package:algobot/tutorial/tutorial_boards.dart';
import 'package:algobot/tutorial/tutorial_scripts.dart';
import 'package:algobot/tutorial/tutorial_step.dart';
import 'package:algobot/ui/screens/game_screen.dart';
import 'package:algobot/ui/screens/home_screen.dart';
import 'package:algobot/ui/screens/level_select_screen.dart';
import 'package:algobot/ui/tutorial/coach_bubble.dart';
import 'package:algobot/ui/tutorial/spotlight_overlay.dart';
import 'package:algobot/ui/tutorial/tutorial_screen.dart';
import 'package:algobot/ui/widgets/character_view.dart';
import 'package:algobot/ui/widgets/game_layout.dart';
import 'package:algobot/ui/widgets/program_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/tutorial_driver.dart';
import 'qa/qa_harness.dart';

Map<String, Object?> _arb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

/// Taşma ve çizim hatalarını toplar; [body] bitince eski işleyici geri
/// yüklenir (test çerçevesi bunu test gövdesi içinde bekler).
Future<List<String>> _withErrors(Future<void> Function() body) async {
  final errors = <String>[];
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    errors.add(d.exceptionAsString().split('\n').first);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = old;
  }
  return errors;
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  // ===================================================================
  // 1. Yön göstergesi
  // ===================================================================
  group('Büyük yön oku', () {
    test('Ok ucu karenin kenarında, uzunluğu karenin ~%35\'i', () {
      const cell = 100.0;
      const center = Offset(50, 50);
      for (final d in Direction.values) {
        final path = directionArrowPath(center, cell, d.index.toDouble());
        final b = path.getBounds();
        final dir = Offset(d.dx.toDouble(), d.dy.toDouble());
        final tip = center + dir * (cell / 2);
        expect(path.contains(tip - dir * 2), isTrue, reason: '$d ucu');
        final along = d.dx != 0 ? b.width : b.height;
        expect(along, closeTo(cell * 0.35, 1), reason: '$d uzunluk');
        // Nabız kayması oku baktığı yöne kaydırır.
        final moved = directionArrowPath(
          center,
          cell,
          d.index.toDouble(),
          nudge: 3,
        ).getBounds();
        expect(moved.center - b.center, offsetMoreOrLessEquals(dir * 3));
      }
      expect(arrowPulse(0), 0);
      expect(
        arrowPulse(arrowPulsePeriod / 4),
        closeTo(arrowPulseAmplitude, 1e-9),
      );
    });

    // Ok karakterin üstünde çizilir: 8 karakter × 4 yönde ok başındaki
    // piksel ok rengindedir (kulak, kanat vb. kapatmaz).
    for (final def in CharacterRegistry.all) {
      testWidgets('${def.id}: ok 4 yönde görünür', (tester) async {
        const side = 200.0;
        for (final d in Direction.values) {
          final key = GlobalKey();
          await tester.pumpWidget(
            Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox.square(
                  dimension: side,
                  child: CharacterView(
                    character: def,
                    facing: d,
                    showDisc: true,
                    animate: false,
                  ),
                ),
              ),
            ),
          );
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final bytes = (await tester.runAsync(() async {
            final image = await boundary.toImage();
            final data = await image.toByteData();
            image.dispose();
            return data!;
          }))!;
          // CharacterView: disk merkezi (100, 116), ok "karesi" 164 px.
          const cell = side * 0.82;
          final center = const Offset(side / 2, side / 2 + side * 0.08);
          final dir = Offset(d.dx.toDouble(), d.dy.toDouble());
          final p = center + dir * (cell / 2 - 12);
          final i = (p.dy.round() * side.toInt() + p.dx.round()) * 4;
          final color = Color.fromARGB(
            bytes.getUint8(i + 3),
            bytes.getUint8(i),
            bytes.getUint8(i + 1),
            bytes.getUint8(i + 2),
          );
          expect(
            color,
            isSameColorAs(arrowFill),
            reason: '${def.id} $d: ok başı kapalı',
          );
        }
      });
    }
  });

  group('Önündeki kare vurgusu', () {
    testWidgets('Açıkken chevron, kapalı/ızgara dışıyken kapalı işareti; '
        'çalışırken gizli; 5–7\'de yok', (tester) async {
      await qaSetUp(tester);
      // 8–12 Seviye 1: başlangıç ve önündeki kare.
      final level = lvl(AgeGroup.ages8to12, 1);
      await push(tester, GameScreen(level: level));
      final controller = _gameOf(tester);
      final front = controller.frontCell;
      expect(front, isNotNull);
      final expected = Point(
        level.start.x + level.startDirection.dx,
        level.start.y + level.startDirection.dy,
      );
      expect(front!.$1, expected);
      expect(front.$2, isTrue);

      // Çalışırken gizli.
      await addAll(tester, level.referenceSolution);
      await tester.tap(find.text(en.run));
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.frontCell, isNull);
      await settle(tester, runtime(level));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Duvara ya da kenara bakarken kapalı', (tester) async {
      await qaSetUp(tester);
      for (final level in levelsFor(AgeGroup.ages8to12)) {
        final next = Point(
          level.start.x + level.startDirection.dx,
          level.start.y + level.startDirection.dy,
        );
        final blocked =
            !level.isInside(next) ||
            level.map[next.y][next.x] == '#' ||
            level.map[next.y][next.x] == 'D';
        await push(tester, GameScreen(level: level));
        expect(_gameOf(tester).frontCell!.$2, !blocked, reason: level.textKey);
        Navigator.of(tester.element(find.byType(GameScreen))).pop();
        await settle(tester, 500);
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5–7\'de önündeki kare vurgusu yok', (tester) async {
      await qaSetUp(tester, age: AgeGroup.ages5to7);
      await push(tester, GameScreen(level: lvl(AgeGroup.ages5to7, 1)));
      expect(_gameOf(tester).frontCell, isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Dönüşte kavisli ok görünür ve solar; seviye başı bakış '
        'zıplaması bir kez', (tester) async {
      await qaSetUp(tester);
      final level = lvl(AgeGroup.ages8to12, 1);
      await push(tester, GameScreen(level: level));
      final game = _gameOf(tester);
      final start = Offset(level.start.x.toDouble(), level.start.y.toDouble());
      // Bakış zıplaması 0,45–0,75 sn arasında.
      expect(game.characterCell, start);
      await tester.tap(find.text(en.levelIntro(level)));
      await addAll(tester, [Command.turnRight]);
      await tester.tap(find.text(en.run));
      var sawArc = false;
      for (var t = 0; t < 1500; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
        final arc = game.turnArc;
        if (arc != null && arc.$2 > 0.5) {
          sawArc = true;
          expect(arc.$1, 1, reason: 'sağa dönüş saat yönünde');
        }
      }
      expect(sawArc, isTrue);
      // Kavis gerçek saatle solar (oturum saati Stopwatch).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump();
      expect(game.turnArc, isNull, reason: 'dönüş bitince solar');
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Kart açıklamaları', () {
    for (final (age, commands) in [
      (
        AgeGroup.ages8to12,
        [Command.forward, Command.turnRight, Command.turnLeft],
      ),
      (AgeGroup.ages5to7, [Command.moveRight]),
    ]) {
      testWidgets('${age.name}: basılı tutunca açıklama, kart eklenmez', (
        tester,
      ) async {
        await qaSetUp(tester, age: age, locale: const Locale('tr'));
        final level = lvl(age, 1);
        await push(tester, GameScreen(level: level));
        await tester.tap(find.text(tr.levelIntro(level)));
        await tester.pump();
        for (final c in commands) {
          await tester.longPress(card(tr, c));
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.text(tr.commandHelp(c)), findsOneWidget);
          expect(_gameOf(tester).program, isEmpty);
          await settle(tester, 3000);
        }
        expect(tr.cardHelpForward, 'Baktığın yöne 1 kare git');
        expect(en.cardHelpForward, "Move 1 square the way you're facing");
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  // ===================================================================
  // 2. Eğitim
  // ===================================================================
  group('Eğitim tahtaları', () {
    test('Her tahta çözülebilir, en kısa = optimal', () {
      for (final MapEntry(key: id, value: b) in tutorialBoards.entries) {
        final age = id.startsWith('A') ? AgeGroup.ages5to7 : AgeGroup.ages8to12;
        final level = tutorialLevel(id, age);
        final s = Solver.solve(level);
        expect(s, isNotNull, reason: id);
        expect(s!.length, b.optimal, reason: id);
        expect(s.length, lessThanOrEqualTo(level.maxSlots), reason: id);
      }
    });

    test('Senaryolar: ilk adım tahta yükler, son adım "Başla"', () {
      for (final script in [relativeTutorial, absoluteTutorial]) {
        expect(script.first.boardId, isNotNull);
        expect(script.last.waitFor.kind, WaitKind.finish);
        expect(script.map((s) => s.id).toSet().length, script.length);
      }
      expect(relativeTutorial.length, 22);
      expect(absoluteTutorial.length, 11);
      expect(
        absoluteTutorial.every((s) => s.glyphs.isNotEmpty),
        isTrue,
        reason: '5–7: her balonda simge',
      );
    });
  });

  group('Otomatik açılma ve tamamlanma', () {
    testWidgets('İlk "Oyna" eğitimi açar; bitince seviye seçimi; ikinci kez '
        'açılmaz', (tester) async {
      final app = await qaSetUp(tester, seenTutorial: false);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      expect(find.byType(TutorialScreen), findsOneWidget);
      final steps = await completeTutorial(tester, en);
      expect(steps, relativeTutorial.length);
      expect(find.byType(LevelSelectScreen), findsOneWidget);
      expect(
        app.settings.tutorialStatus(CommandFamily.relative),
        TutorialStatus.completed,
      );
      // Ana menüye dönüp tekrar "Oyna": doğrudan seviye seçimi.
      Navigator.of(tester.element(find.byType(LevelSelectScreen))).pop();
      await settle(tester, 600);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      expect(find.byType(TutorialScreen), findsNothing);
      expect(find.byType(LevelSelectScreen), findsOneWidget);
      // Eğitimde hiçbir şey kaydedilmedi.
      await flushDb(tester);
      expect(app.progress.totalStarsAll, 0);
      final rows = (await tester.runAsync(
        () => app.db.db.query('level_session'),
      ))!;
      expect(rows, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('8–12\'de tamamlanan eğitim 13+\'da gösterilmez; 5–7\'de '
        'okların eğitimi gösterilir', (tester) async {
      final app = await qaSetUp(
        tester,
        seenTutorial: false,
        prefs: {'tutorial_done_relative': 'completed'},
      );
      await app.settings.setAgeGroup(AgeGroup.ages13plus);
      await settle(tester, 200);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      expect(find.byType(TutorialScreen), findsNothing);
      Navigator.of(tester.element(find.byType(LevelSelectScreen))).pop();
      await settle(tester, 600);

      await app.settings.setAgeGroup(AgeGroup.ages5to7);
      await settle(tester, 200);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      expect(find.byType(TutorialScreen), findsOneWidget);
      expect(tutorialOf(tester).steps, same(absoluteTutorial));
      final steps = await completeTutorial(tester, en);
      expect(steps, absoluteTutorial.length);
      expect(find.byType(LevelSelectScreen), findsOneWidget);
      expect(
        app.settings.tutorialStatus(CommandFamily.absolute),
        TutorialStatus.completed,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Karşılamanın sonunda ("Başla") eğitim açılır', (tester) async {
      await qaSetUp(tester, age: null, seenTutorial: false);
      await settle(tester, 400);
      await tester.tap(find.text(en.ageShortOf(AgeGroup.ages8to12)).first);
      await settle(tester, 800);
      await tapVisible(tester, find.text(en.start));
      await settle(tester, 800);
      expect(find.byType(TutorialScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Eylem süzgeci ve spotlight', () {
    Future<void> openRelative(WidgetTester tester) async {
      await qaSetUp(tester, seenTutorial: false);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
    }

    testWidgets('Spotlight dışına dokunmak ilerletmez; Çalıştır kapalı', (
      tester,
    ) async {
      await openRelative(tester);
      final t = tutorialOf(tester);
      expect(t.step.id, 'meet');
      // Spotlight dışı (palet kartı) dokunmaya kapalı: kart eklenmez.
      final strip = tester.getRect(find.byType(ProgramStrip));
      await tester.tapAt(strip.center);
      await tester.pump(const Duration(milliseconds: 100));
      expect(t.index, 0);
      expect(gameOf(tester).program, isEmpty);
      expect(
        tester
            .hitTestOnBinding(strip.center)
            .path
            .any((e) => e.target is RenderSpotlight),
        isTrue,
        reason: 'dokunuşu karartma katmanı yutar',
      );
      // Denetleyiciye ulaşan eylemler de reddedilir.
      await gameOf(tester).run();
      expect(gameOf(tester).isRunning, isFalse);
      // Balona dokunmak ilerletir.
      await completeStep(tester, en);
      expect(t.index, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Beklenmeyen kart eklenmez, balon doğru kartı söyler', (
      tester,
    ) async {
      await openRelative(tester);
      final t = tutorialOf(tester);
      while (t.step.waitFor.kind != WaitKind.tapCard) {
        await completeStep(tester, en);
      }
      expect(t.step.id, 'firstCard');
      // Spotlight dışındaki karta dokunuş engellenir.
      await tester.tap(card(en, Command.turnRight), warnIfMissed: false);
      await settle(tester, 300);
      expect(gameOf(tester).program, isEmpty);
      // Kart doğrudan denetleyiciye gelse bile eklenmez, ipucu çıkar.
      expect(gameOf(tester).addCommand(Command.turnRight), isFalse);
      await tester.pump();
      expect(find.text(en.tutWrongCard(en.cmdForward)), findsOneWidget);
      expect(t.step.id, 'firstCard');
      await completeStep(tester, en);
      expect(t.step.id, 'strip');
      expect(programMoves(gameOf(tester)), [Command.forward]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Başarısız çalıştırma can düşürmez, program korunur, '
        'hiçbir şey kaydedilmez; 2 denemeden sonra el yardım eder', (
      tester,
    ) async {
      final app = await qaSetUp(tester, seenTutorial: false);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      final t = tutorialOf(tester);
      while (t.step.id != 'yourTurn') {
        await completeStep(tester, en);
      }
      // T3: tek İleri yetmez.
      for (var i = 0; i < 2; i++) {
        if (gameOf(tester).program.isEmpty) {
          await tapVisible(tester, card(en, Command.forward));
          await settle(tester, 200);
        }
        await tapVisible(tester, find.text(en.run));
        await settle(tester, 4000);
        expect(t.fails, i + 1);
        expect(gameOf(tester).lives, 3);
        expect(programMoves(gameOf(tester)), [Command.forward]);
      }
      expect(find.text(en.tutTryAgain), findsOneWidget);
      // El doğru sıradaki kartı gösterir (İleri'den sonra Sağa).
      final hand = t.handTarget;
      expect(hand?.kind, TargetKind.paletteCard);
      expect(hand?.command, Command.turnRight);
      await flushDb(tester);
      final sessions = (await tester.runAsync(
        () => app.db.db.query('level_session'),
      ))!;
      final progress = (await tester.runAsync(
        () => app.db.db.query('level_progress'),
      ))!;
      expect(sessions, isEmpty);
      expect(progress, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Toplamadan hedefe ulaşınca "bir şeyi unuttun"', (
      tester,
    ) async {
      await qaSetUp(tester, seenTutorial: false);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      final t = tutorialOf(tester);
      while (t.step.id != 'practice') {
        await completeStep(tester, en);
      }
      // T4: toplamadan doğrudan hedef (İleri, İleri).
      for (final c in [Command.forward, Command.forward]) {
        await tapVisible(tester, card(en, c));
        await settle(tester, 150);
      }
      await tapVisible(tester, find.text(en.run));
      await settle(tester, 4000);
      expect(t.step.id, 'practice');
      expect(find.text(en.tutForgot), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Atla" onayla eğitimi tamamlanmış sayar (atlandı)', (
      tester,
    ) async {
      final app = await qaSetUp(tester, seenTutorial: false);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      await tester.tap(find.text(en.tutSkip));
      await settle(tester, 400);
      expect(find.text(en.tutSkipConfirm), findsOneWidget);
      // Vazgeç: eğitim sürer.
      await tester.tap(find.text(en.cancel));
      await settle(tester, 400);
      expect(find.byType(TutorialScreen), findsOneWidget);
      await tester.tap(find.text(en.tutSkip));
      await settle(tester, 400);
      await tester.tap(find.text(en.tutSkip).last);
      await settle(tester, 1000);
      expect(find.byType(LevelSelectScreen), findsOneWidget);
      expect(
        app.settings.tutorialStatus(CommandFamily.relative),
        TutorialStatus.skipped,
      );
      // Atlandıysa eski Seviye 1 parmak tanıtımı gösterilir.
      await push(tester, GameScreen(level: lvl(AgeGroup.ages8to12, 1)));
      expect(_gameOf(tester).showTutorial, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Tamamlandıysa eski Seviye 1 tanıtımı gösterilmez', (
      tester,
    ) async {
      await qaSetUp(tester, prefs: {'tutorial_done_relative': 'completed'});
      await push(tester, GameScreen(level: lvl(AgeGroup.ages8to12, 1)));
      expect(_gameOf(tester).showTutorial, isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('"?" ve "Nasıl oynanır?"', () {
    testWidgets('"?" eğitimi açar; dönünce aynı seviye ve program şeridi', (
      tester,
    ) async {
      await qaSetUp(tester);
      final level = lvl(AgeGroup.ages8to12, 4);
      await openLevel(tester, level);
      await addAll(tester, [Command.forward, Command.turnLeft]);
      await tester.tap(find.byTooltip(en.howToPlay));
      await settle(tester, 400);
      expect(find.text(en.tutHelpConfirm), findsOneWidget);
      await tester.tap(find.text(en.tutHelpStart));
      await settle(tester, 800);
      expect(find.byType(TutorialScreen), findsOneWidget);
      // Eğitimi atla → oyun ekranına dön.
      await tester.tap(find.text(en.tutSkip));
      await settle(tester, 400);
      await tester.tap(find.text(en.tutSkip).last);
      await settle(tester, 1000);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text(en.levelTitle(level)), findsOneWidget);
      expect(find.text(en.slotCounter(2, level.maxSlots)), findsOneWidget);
      expect(programMoves(_gameOf(tester)), [
        Command.forward,
        Command.turnLeft,
      ]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Ana menüde "Nasıl oynanır?" eğitimi açar ve geri döner', (
      tester,
    ) async {
      await qaSetUp(tester);
      await tapVisible(tester, find.text(en.howToPlay));
      await settle(tester, 800);
      expect(find.byType(TutorialScreen), findsOneWidget);
      await completeTutorial(tester, en);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(TutorialScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('13+ mekanik tanıtımları', () {
    test('Tanıtım seviyeleri: kapı 3, buz 5, portal 7', () {
      final intros = {
        for (final l in levelsFor(AgeGroup.ages13plus))
          l.id: ?mechanicIntroFor(l),
      };
      expect(intros, {3: 'door', 5: 'ice', 7: 'portal'});
      for (final age in [AgeGroup.ages5to7, AgeGroup.ages8to12]) {
        expect(levelsFor(age).map(mechanicIntroFor).nonNulls, isEmpty);
      }
      for (final (id, m) in [(3, 'door'), (5, 'ice'), (7, 'portal')]) {
        final ghost = GhostDemo.forMechanic(lvl(AgeGroup.ages13plus, id), m);
        expect(ghost, isNotNull, reason: m);
        expect(ghost!.at(0), isNotNull);
        expect(ghost.at(ghost.duration + 0.1), isNull);
      }
    });

    for (final (id, mechanic, text) in [
      (3, 'door', en.tutMechDoor),
      (5, 'ice', en.tutMechIce),
      (7, 'portal', en.tutMechPortal),
    ]) {
      testWidgets('Seviye $id ($mechanic): bir kez gösterilir', (tester) async {
        await qaSetUp(
          tester,
          age: AgeGroup.ages13plus,
          seenTutorial: false,
          prefs: {'tutorial_done_relative': 'completed'},
        );
        final level = lvl(AgeGroup.ages13plus, id);
        await push(tester, GameScreen(level: level));
        await settle(tester, 300);
        expect(find.text(text), findsOneWidget);
        // Tanıtım sürerken kart eklenemez.
        expect(_gameOf(tester).addCommand(Command.forward), isFalse);
        await completeStep(tester, en);
        expect(find.text(en.tutMechWatch), findsOneWidget);
        expect(_gameOf(tester).ghost, isNotNull, reason: 'hayalet oynuyor');
        await tester.tap(find.text(en.tutGotIt));
        await settle(tester, 500);
        expect(find.byType(TutorialOverlay), findsNothing);
        expect(
          (await _prefs()).getBool(SettingsController.mechanicKey(mechanic)),
          isTrue,
        );
        // Tekrar girince gösterilmez; "?" ile yeniden açılır.
        Navigator.of(tester.element(find.byType(GameScreen))).pop();
        await settle(tester, 500);
        await push(tester, GameScreen(level: level));
        expect(find.text(text), findsNothing);
        await tester.tap(find.text(en.levelIntro(level)));
        await tester.tap(find.byTooltip(en.howToPlay));
        await settle(tester, 400);
        await tester.tap(find.text(en.tutHelpMechanic));
        await settle(tester, 500);
        expect(find.text(text), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  // ===================================================================
  // 3. Yerelleştirme ve düzen
  // ===================================================================
  test('Tüm eğitim anahtarları iki ARB dosyasında, metinler boş değil', () {
    final enArb = _arb('lib/l10n/app_en.arb');
    final trArb = _arb('lib/l10n/app_tr.arb');
    final keys = {
      for (final s in [
        ...relativeTutorial,
        ...absoluteTutorial,
        for (final m in mechanicIntros.values) ...m,
      ])
        s.textKey,
    };
    for (final k in keys) {
      expect(enArb[k], isA<String>(), reason: 'en: $k');
      expect(trArb[k], isA<String>(), reason: 'tr: $k');
      for (final l in [en, tr]) {
        expect(l.tutorialText(k, characterId: 'pati'), isNotEmpty, reason: k);
      }
    }
    expect(tr.tutorialText('tutRel17', characterId: 'pati'), contains('balık'));
    expect(
      en.tutorialText('tutRel17', characterId: 'buzi'),
      contains('an ice'),
    );
    expect(en.tutorialText('tutRel21', video: true), contains('video'));
  });

  for (final locale in const [Locale('tr'), Locale('en')]) {
    for (final age in AgeGroup.values) {
      testWidgets('${age.name}/${locale.languageCode}: 360x640 ve 1.3x '
          'yazıda taşma yok, balon hedefi kapatmıyor', (tester) async {
        final covered = <String>[];
        final errors = await _withErrors(() async {
          final l = lookupAppLocalizations(locale);
          await qaSetUp(
            tester,
            age: age,
            locale: locale,
            textScale: 1.3,
            seenTutorial: false,
          );
          await tester.tap(find.text(l.play));
          await settle(tester, 800);
          await completeTutorial(
            tester,
            l,
            onStep: (step) async {
              await settle(tester, 300);
              if (step.highlight.isEmpty) return;
              final spot = tester.renderObject<RenderSpotlight>(
                find.byWidgetPredicate(
                  (w) => w.runtimeType.toString() == '_Spotlight',
                ),
              );
              final holes = [
                for (final h in spot.localHoles())
                  MatrixUtils.transformRect(
                    spot.getTransformTo(null),
                    h.outerRect.deflate(RenderSpotlight.padding),
                  ),
              ];
              final bubble = tester.getRect(find.byType(CoachBubble));
              for (final h in holes) {
                if (bubble.overlaps(h)) covered.add(step.id);
              }
            },
          );
        });
        expect(errors, isEmpty, reason: errors.toSet().join('\n'));
        expect(covered, isEmpty, reason: 'balon hedefi kapatıyor: $covered');
        expect(find.byType(LevelSelectScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('Tablet 800x1280: eğitim taşmasız tamamlanır', (tester) async {
    final errors = await _withErrors(() async {
      await qaSetUp(tester, size: const Size(800, 1280), seenTutorial: false);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      await completeTutorial(tester, en);
    });
    expect(errors, isEmpty, reason: errors.toSet().join('\n'));
    await tester.pumpWidget(const SizedBox());
  });
}

/// Oyun ekranının denetleyicisi.
GameController _gameOf(WidgetTester tester) =>
    tester.widget<GameLayout>(find.byType(GameLayout).first).game;
