// QA: oyun akışları, hızlı/çift dokunma ve kenar durumları (widget seviyesi).
import 'package:algobot/audio/sound_service.dart';
import 'package:algobot/jokers/joker_type.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/level.dart';
import 'package:algobot/ui/screens/game_screen.dart';
import 'package:algobot/ui/screens/home_screen.dart';
import 'package:algobot/ui/screens/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qa_harness.dart';

void main() {
  testWidgets('"Devam"a çift dokunma tek seviye ilerletir', (tester) async {
    await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 1);
    await openLevel(tester, level);
    await addAll(tester, level.referenceSolution);
    await tester.tap(find.text(en.run));
    await settle(tester, runtime(level));
    expect(find.text(en.resultThreeStars), findsOneWidget);

    final next = find.text(en.next);
    await tester.tap(next);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(next, warnIfMissed: false);
    await settle(tester, 1500);

    expect(
      find.text(en.levelTitle(lvl(AgeGroup.ages8to12, 2))),
      findsOneWidget,
    );
    expect(find.byType(GameScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Çalıştır"a çift dokunma tek can düşürür', (tester) async {
    final app = await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 2);
    await openLevel(tester, level);
    await addAll(tester, crashProgram(level));
    await tester.tap(find.text(en.run));
    await tester.tap(find.text(en.run), warnIfMissed: false);
    await settle(tester, runtime(level));
    expect(app.sessions.sessionFor(level).lives, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Can jokerine çift dokunma tek can verir', (tester) async {
    final app = await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 2);
    await openLevel(tester, level);
    final joker = find.bySemanticsLabel(en.jokerLife);
    await tapIt(tester, joker);
    await tester.tap(
      find.bySemanticsLabel(RegExp(en.jokerLife)),
      warnIfMissed: false,
    );
    await settle(tester, 300);
    expect(app.sessions.sessionFor(level).lives, 4);
    await tester.pumpWidget(const SizedBox());
  });

  group('Çalıştırma kontrolleri', () {
    testWidgets('Durdur: başa alır, can düşürmez, program korunur', (
      tester,
    ) async {
      final app = await qaSetUp(tester);
      final level = lvl(AgeGroup.ages8to12, 4);
      await openLevel(tester, level);
      await addAll(tester, level.referenceSolution);
      await tester.tap(find.text(en.run));
      await settle(tester, 900);
      expect(find.text(en.stop), findsOneWidget);
      await tester.tap(find.text(en.stop));
      await settle(tester, 300);
      expect(find.text(en.run), findsOneWidget);
      expect(app.sessions.sessionFor(level).lives, 3);
      expect(
        find.text(
          en.slotCounter(level.referenceSolution.length, level.maxSlots),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Temizle can düşürmez', (tester) async {
      final app = await qaSetUp(tester);
      final level = lvl(AgeGroup.ages8to12, 2);
      await openLevel(tester, level);
      await addAll(tester, [Command.forward, Command.forward]);
      await tester.tap(find.text(en.clear));
      await settle(tester, 400);
      expect(app.sessions.sessionFor(level).lives, 3);
      expect(find.text(en.slotCounter(0, level.maxSlots)), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Kaybet: can düşer, mesaj doğru, "Tekrar dene" programı '
        'korur', (tester) async {
      final app = await qaSetUp(tester, locale: const Locale('tr'));
      final level = lvl(AgeGroup.ages8to12, 2);
      await push(tester, GameScreen(level: level));
      await tester.tap(find.text(tr.levelIntro(level)));
      final program = crashProgram(level);
      await addAll(tester, program, tr);
      await tester.tap(find.text(tr.run));
      await settle(tester, runtime(level));
      expect(find.text(tr.crashMessage), findsOneWidget);
      expect(app.sessions.sessionFor(level).lives, 2);
      await tester.tap(find.text(tr.tryAgain));
      await settle(tester, 400);
      expect(
        find.text(tr.slotCounter(program.length, level.maxSlots)),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Hızlı mod adımları yarı sürede oynatır', (tester) async {
      await qaSetUp(tester);
      final level = lvl(AgeGroup.ages8to12, 4);
      Future<int> measure(bool fast) async {
        await openLevel(tester, level);
        await addAll(tester, level.referenceSolution);
        await tester.tap(find.text(en.run));
        await tester.pump();
        if (fast) {
          await tester.tap(find.text(en.fast));
          await tester.pump();
        }
        var ms = 0;
        while (find.text(en.resultThreeStars).evaluate().isEmpty &&
            ms < 30000) {
          await tester.pump(const Duration(milliseconds: 50));
          ms += 50;
        }
        await tester.tap(find.text(en.again));
        await settle(tester, 600);
        Navigator.of(tester.element(find.byType(GameScreen))).pop();
        await settle(tester, 600);
        return ms;
      }

      final normal = await measure(false);
      final fast = await measure(true);
      expect(
        fast,
        lessThan(normal * 0.75),
        reason: 'normal=$normal hızlı=$fast',
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Çalışırken arka plana alıp geri dönmek çökertmez; program '
      'tamamlanır', (tester) async {
    final app = await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 4);
    await openLevel(tester, level);
    await addAll(tester, level.referenceSolution);
    await tester.tap(find.text(en.run));
    await settle(tester, 700);
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await settle(tester, 2000);
    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await settle(tester, runtime(level));
    expect(tester.takeException(), isNull);
    expect(app.progress.starsFor(level), 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Çalışırken geri ve hemen tekrar giriş: hata yok, can düşmez', (
    tester,
  ) async {
    final app = await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 4);
    await openLevel(tester, level);
    await addAll(tester, crashProgram(level));
    await tester.tap(find.text(en.run));
    await tester.pump(const Duration(milliseconds: 200));
    Navigator.of(tester.element(find.byType(GameScreen))).pop();
    await tester.pump(const Duration(milliseconds: 100));
    await openLevel(tester, level);
    await settle(tester, runtime(level));
    expect(tester.takeException(), isNull);
    expect(app.sessions.sessionFor(level).lives, 3);
    await tester.pumpWidget(const SizedBox());
  });

  group('Canlar bitince', () {
    Future<void> failThreeTimes(WidgetTester tester, Level level) async {
      await addAll(tester, crashProgram(level));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text(en.run));
        await settle(tester, runtime(level));
        if (i < 2) {
          await tester.tap(find.text(en.tryAgain));
          await settle(tester, 300);
        }
      }
    }

    testWidgets('Jokerler bitmişse "Ana menü" ana ekrana götürür; geri tuşu '
        'oyuna dönmez', (tester) async {
      final app = await qaSetUp(tester);
      final level = lvl(AgeGroup.ages8to12, 2);
      app.sessions
        ..markJokerUsed(level, JokerType.skip)
        ..markJokerUsed(level, JokerType.life);
      await openLevel(tester, level);
      await failThreeTimes(tester, level);
      await settle(tester, 1200);
      expect(find.text(en.outOfLivesTitle), findsOneWidget);
      // Countdown: mm:ss biçiminde bir sayaç görünür.
      expect(find.textContaining(RegExp(r'\d+:\d\d')), findsWidgets);
      await tester.tap(find.text(en.mainMenu));
      await settle(tester, 800);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
      final nav = Navigator.of(tester.element(find.byType(HomeScreen)));
      expect(nav.canPop(), isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Canı sıfır seviyeye seviye seçiminden girilmez; panel '
        'açılır', (tester) async {
      final app = await qaSetUp(tester, stars: {(AgeGroup.ages8to12, 1): 3});
      final level = lvl(AgeGroup.ages8to12, 2);
      for (var i = 0; i < 3; i++) {
        app.sessions.loseLife(level);
      }
      await push(tester, const LevelSelectScreen());
      await tester.tap(find.text(en.levelTitle(level)));
      await settle(tester, 600);
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text(en.outOfLivesTitle), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Kilitli seviyeye dokunmak açmaz; atlanınca sonraki açılır', (
    tester,
  ) async {
    final app = await qaSetUp(tester);
    await push(tester, const LevelSelectScreen());
    final l3 = lvl(AgeGroup.ages8to12, 3);
    await tester.tap(find.text(en.levelTitle(l3)), warnIfMissed: false);
    await settle(tester, 600);
    expect(find.byType(GameScreen), findsNothing);
    app.progress
      ..markSkipped(lvl(AgeGroup.ages8to12, 1))
      ..record(lvl(AgeGroup.ages8to12, 2), 1);
    await settle(tester, 300);
    await tester.tap(find.text(en.levelTitle(l3)));
    await settle(tester, 800);
    expect(find.byType(GameScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  group('Ebeveyn kapısı', () {
    Future<void> openGate(WidgetTester tester) async {
      await tester.tap(find.byTooltip(en.parent));
      await settle(tester, 500);
    }

    testWidgets('Yanlış cevap paneli açmaz', (tester) async {
      await qaSetUp(tester);
      await openGate(tester);
      await answerGate(tester, en, correct: false);
      expect(find.text(en.wrongAnswer), findsOneWidget);
      expect(find.text(en.settings), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Yaş değişimi anında uygulanır, diğer yaşın ilerlemesi '
        'silinmez; ses ayarı kalıcı', (tester) async {
      final app = await qaSetUp(
        tester,
        stars: {(AgeGroup.ages8to12, 1): 3, (AgeGroup.ages5to7, 1): 2},
      );
      await openGate(tester);
      await answerGate(tester, en);
      await tester.tap(find.text(en.ageShortOf(AgeGroup.ages5to7)));
      await settle(tester, 300);
      expect(app.settings.ageGroup, AgeGroup.ages5to7);
      expect(app.progress.starsFor(lvl(AgeGroup.ages8to12, 1)), 3);
      expect(app.progress.starsFor(lvl(AgeGroup.ages5to7, 1)), 2);
      await tester.tap(find.text(en.sound));
      await settle(tester, 300);
      expect(app.settings.soundOn, isTrue);
      await tester.tap(find.text(en.close).last);
      await settle(tester, 400);
      await tester.tap(find.text(en.play));
      await settle(tester, 800);
      expect(
        find.text(en.levelSelectTitle(en.ageRangeOf(AgeGroup.ages5to7))),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Sıfırlama onayında Vazgeç hiçbir şey silmez', (tester) async {
      final app = await qaSetUp(tester, stars: {(AgeGroup.ages8to12, 1): 3});
      await openGate(tester);
      await answerGate(tester, en);
      await tapIt(tester, find.text(en.resetProgress));
      await settle(tester, 300);
      await tester.tap(find.text(en.cancel));
      await settle(tester, 300);
      expect(app.progress.totalStarsAll, 3);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Ses', () {
    testWidgets('Ses kapalıyken bir seviye boyunca hiç ses çalmaz', (
      tester,
    ) async {
      final app = await qaSetUp(tester, soundOn: false);
      final level = lvl(AgeGroup.ages8to12, 1);
      await openLevel(tester, level);
      await addAll(tester, level.referenceSolution);
      await tester.tap(find.text(en.run));
      await settle(tester, runtime(level));
      expect(app.sound.played, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Ses açıkken kart, adım ve kazanma sesleri çalar', (
      tester,
    ) async {
      final app = await qaSetUp(tester, soundOn: true);
      final level = lvl(AgeGroup.ages8to12, 1);
      await openLevel(tester, level);
      await addAll(tester, level.referenceSolution);
      await tester.tap(find.text(en.run));
      await settle(tester, runtime(level));
      expect(
        app.sound.played,
        containsAll([Sound.cardAdd, Sound.step, Sound.win]),
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Dil', () {
    for (final (code, expected) in [
      ('tr', 'tr'),
      ('en', 'en'),
      ('de', 'en'),
      ('ar', 'en'),
    ]) {
      testWidgets('Cihaz dili $code → $expected', (tester) async {
        tester.platformDispatcher.localesTestValue = [Locale(code)];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await qaSetUp(tester, locale: null);
        final l = expected == 'tr' ? tr : en;
        expect(find.text(l.play), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
