import 'package:algobot/app.dart';
import 'package:algobot/app_services.dart';
import 'package:algobot/audio/sound_service.dart';
import 'package:algobot/data/db/app_database.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/data/progress_repository.dart';
import 'package:algobot/data/session_repository.dart';
import 'package:algobot/jokers/joker_type.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/level.dart';
import 'package:algobot/rewards/rewarded_video_service.dart';
import 'package:algobot/rewards/stub_rewarded_video_service.dart';
import 'package:algobot/state/progress_controller.dart';
import 'package:algobot/state/settings_controller.dart';
import 'package:algobot/ui/screens/character_select_screen.dart';
import 'package:algobot/ui/screens/game_screen.dart';
import 'package:algobot/ui/screens/home_screen.dart';
import 'package:algobot/ui/screens/level_select_screen.dart';
import 'package:algobot/ui/widgets/command_card.dart';
import 'package:algobot/ui/widgets/command_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

final en = lookupAppLocalizations(const Locale('en'));
final tr = lookupAppLocalizations(const Locale('tr'));

/// Sonucu ayarlanabilen sahte video servisi.
class FakeVideo implements RewardedVideoService {
  FakeVideo(this.result);
  RewardedVideoResult result;
  int shown = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<void> preload() async {}

  @override
  Future<RewardedVideoResult> show(BuildContext context) async {
    shown++;
    return result;
  }
}

class _App {
  _App(this.settings, this.progress, this.sessions, this.db, this.clock);
  final SettingsController settings;
  final ProgressController progress;
  final SessionRepository sessions;
  final AppDatabase db;
  final FakeClock clock;
}

Future<_App> _setUp(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double textScale = 1.0,
  AgeGroup? age = AgeGroup.ages8to12,
  Locale locale = const Locale('en'),
  Map<String, Object> prefs = const {},
  Map<(AgeGroup, int), int> stars = const {},
  RewardedVideoService? video,
  AppDatabase? database,
  FakeClock? clock,
}) async {
  // Testlerde efekt sesleri kapalı: ses eklentisi test ortamında yok.
  SharedPreferences.setMockInitialValues({
    'sound_on': false,
    'age_group': ?age?.name,
    ProgressRepository.migratedKey: true,
    ...prefs,
  });
  final sp = await SharedPreferences.getInstance();
  final settings = SettingsController(sp);
  final c = clock ?? FakeClock();
  final db =
      database ??
      (await tester.runAsync(() => openTestDatabase(noIsolate: true)))!;
  final repo = ProgressRepository(db, clock: c);
  final progress = ProgressController(repo, allLevelSets);
  final sessions = SessionRepository(db, clock: c);
  await tester.runAsync(() async {
    for (final e in stars.entries) {
      await repo.save(
        e.key.$1,
        e.key.$2,
        LevelProgress(bestStars: e.value, completed: e.value > 0),
      );
    }
    await Future.wait([progress.load(), sessions.load()]);
  });
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    AlgoBotApp(
      settings: settings,
      sound: SoundService(settings),
      services: SynchronousFuture(
        AppServices(
          progress: progress,
          sessions: sessions,
          video: video ?? StubRewardedVideoService(available: false),
        ),
      ),
      showSplash: false,
      locale: locale,
    ),
  );
  await tester.pump();
  return _App(settings, progress, sessions, db, c);
}

/// Arka plandaki veritabanı yazmalarının bitmesini bekler.
Future<void> _flushDb(WidgetTester tester) => tester.runAsync(
  () => Future<void>.delayed(const Duration(milliseconds: 50)),
);

/// Sonsuz animasyonlar olduğu için pumpAndSettle kullanılamaz.
Future<void> _settle(WidgetTester tester, [int ms = 1500]) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _push(WidgetTester tester, Widget page) async {
  final ctx = tester.element(find.byType(Navigator).first);
  Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => page));
  await _settle(tester, 800);
}

Future<void> _openLevel(WidgetTester tester, Level level) =>
    _push(tester, GameScreen(level: level));

Future<void> _pop(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(GameScreen))).pop();
  await _settle(tester, 600);
}

/// Küçük ekranda büyük tahtalarda sayfa kayar; önce görünür yap.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Finder _card(AppLocalizations l, Command c) =>
    find.bySemanticsLabel(l.paletteCardLabel(l.commandShort(c)));

Future<void> _addAll(
  WidgetTester tester,
  List<Command> commands, [
  AppLocalizations? l,
]) async {
  for (final c in commands) {
    await _tap(tester, _card(l ?? en, c));
    await tester.pump();
  }
  await _settle(tester, 400);
}

/// Programın tamamını oynatmaya yetecek süre.
int _runtime(Level level) => level.maxSlots * 1200 + 1500;

Level _lvl(AgeGroup age, int id) =>
    levelsFor(age).firstWhere((l) => l.id == id);

Future<void> _run(WidgetTester tester, Level level) async {
  await _tap(tester, find.text(en.run));
  await _settle(tester, _runtime(level));
}

Finder _lives(int n, [AppLocalizations? l]) =>
    find.bySemanticsLabel((l ?? en).livesLabel(n));

void main() {
  const sizes = {'küçük telefon': Size(360, 640), 'tablet': Size(800, 1280)};

  for (final age in AgeGroup.values) {
    for (final locale in const [Locale('tr'), Locale('en')]) {
      for (final entry in sizes.entries) {
        for (final scale in [1.0, 1.3]) {
          testWidgets('${age.name}/${locale.languageCode}: seviyeler taşmadan '
              'açılır (${entry.key}, ${scale}x)', (tester) async {
            final l = lookupAppLocalizations(locale);
            await _setUp(
              tester,
              age: age,
              locale: locale,
              size: entry.value,
              textScale: scale,
              video: FakeVideo(RewardedVideoResult.completed),
              stars: {for (var i = 1; i <= 8; i++) (age, i): 2},
            );
            expect(find.bySemanticsLabel(l.appTitle), findsOneWidget);
            await tester.tap(find.text(l.play));
            await _settle(tester, 800);
            expect(find.text(l.worldTitle(l.ageRangeOf(age))), findsOneWidget);
            expect(find.text(l.totalStars(16, 24)), findsOneWidget);

            for (final level in levelsFor(age)) {
              await _openLevel(tester, level);
              expect(find.text(l.levelTitle(level)), findsWidgets);
              final first = level.availableCommands.first;
              for (var k = 0; k < level.maxSlots; k++) {
                await _tap(tester, _card(l, first));
              }
              await _settle(tester, 400);
              expect(tester.takeException(), isNull);
              await _pop(tester);
            }
          });
        }
      }
    }
  }

  group('Sade oyun ekranı', () {
    List<Command> paletteOf(WidgetTester tester) => tester
        .widgetList<CommandCard>(
          find.descendant(
            of: find.byType(CommandPalette),
            matching: find.byType(CommandCard),
          ),
        )
        .map((c) => c.command)
        .toList();

    for (final locale in const [Locale('tr'), Locale('en')]) {
      testWidgets('${locale.languageCode}: "Adım adım" ve "Komutlar" '
          'görünmüyor; palet erişilebilirlik etiketi duruyor', (tester) async {
        await _setUp(tester, locale: locale);
        await _openLevel(tester, _lvl(AgeGroup.ages8to12, 4));
        for (final text in [
          'Adım adım',
          'Step by step',
          'Komutlar',
          'Commands',
          'Sonraki adım',
          'Next step',
        ]) {
          expect(find.text(text), findsNothing, reason: text);
        }
        final l = lookupAppLocalizations(locale);
        expect(find.bySemanticsLabel(l.paletteSemanticsLabel), findsOneWidget);
        expect(find.text(l.program), findsOneWidget);
        expect(find.text(l.slotCounter(0, 8)), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('8–12 ve 13+ Seviye 1: tam üç kart (İleri, Sağa, Sola)', (
      tester,
    ) async {
      const full = [Command.forward, Command.turnRight, Command.turnLeft];
      for (final age in [AgeGroup.ages8to12, AgeGroup.ages13plus]) {
        await _setUp(tester, age: age);
        await _openLevel(tester, _lvl(age, 1));
        expect(paletteOf(tester), full, reason: age.name);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('5–7 Seviye 1: yalnızca o seviyenin kartları', (tester) async {
      await _setUp(tester, age: AgeGroup.ages5to7);
      await _openLevel(tester, _lvl(AgeGroup.ages5to7, 1));
      expect(paletteOf(tester), [Command.moveRight]);
      await tester.pumpWidget(const SizedBox());
      await _setUp(tester, age: AgeGroup.ages5to7);
      await _openLevel(tester, _lvl(AgeGroup.ages5to7, 2));
      expect(paletteOf(tester), [Command.moveRight, Command.moveDown]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Seviye 1 eğitimi İleri kartını işaret eder', (tester) async {
      await _setUp(tester);
      await _openLevel(tester, _lvl(AgeGroup.ages8to12, 1));
      final keyed = tester
          .widgetList<Widget>(
            find.descendant(
              of: find.byType(CommandPalette),
              matching: find.byWidgetPredicate((w) => w.key is GlobalKey),
            ),
          )
          .single;
      expect(
        find.descendant(
          of: find.byWidget(keyed),
          matching: find.byWidgetPredicate(
            (w) => w is CommandCard && w.command == Command.forward,
          ),
        ),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('8–12 Seviye 1 baştan sona (Türkçe): 3 yıldız, Seviye 2 açılır', (
    tester,
  ) async {
    final app = await _setUp(tester, locale: const Locale('tr'));
    final level = _lvl(AgeGroup.ages8to12, 1);
    await _openLevel(tester, level);

    await tester.tap(find.text(tr.run));
    await tester.pump();
    expect(find.text(tr.emptyProgram), findsOneWidget);

    await _addAll(tester, level.referenceSolution, tr);
    await tester.tap(find.text(tr.run));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(tr.stop), findsOneWidget);
    await _settle(tester, _runtime(level));

    expect(find.text(tr.resultThreeStars), findsOneWidget);
    expect(find.text('Piller: 1 / 1'), findsOneWidget);
    expect(app.progress.starsFor(level), 3);
    expect(app.progress.isUnlocked(_lvl(AgeGroup.ages8to12, 2)), isTrue);

    await tester.tap(find.text(tr.next));
    await _settle(tester, 800);
    expect(
      find.text(tr.levelTitle(_lvl(AgeGroup.ages8to12, 2))),
      findsOneWidget,
    );
  });

  testWidgets('5–7 ve 13+ Final baştan sona', (tester) async {
    var app = await _setUp(tester, age: AgeGroup.ages5to7);
    var level = _lvl(AgeGroup.ages5to7, 5);
    await _openLevel(tester, level);
    await _addAll(tester, level.referenceSolution);
    await _run(tester, level);
    expect(find.text(en.resultThreeStars), findsOneWidget);
    expect(app.progress.starsFor(level), 3);
    await tester.pumpWidget(const SizedBox());

    app = await _setUp(
      tester,
      age: AgeGroup.ages13plus,
      prefs: {'character_id': 'vizviz'},
    );
    level = levelsFor(AgeGroup.ages13plus).last;
    await _openLevel(tester, level);
    await tester.tap(find.text(en.levelIntro(level)));
    await _addAll(tester, level.referenceSolution);
    await _run(tester, level);
    expect(find.text(en.resultThreeStars), findsOneWidget);
    expect(find.text('Honey drops: 1 / 1'), findsOneWidget);
    expect(app.progress.starsFor(level), 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  group('Canlar', () {
    testWidgets('Üç yaş grubunda da başlangıç canı 3', (tester) async {
      for (final age in AgeGroup.values) {
        await _setUp(tester, age: age);
        await _openLevel(tester, levelsFor(age).first);
        expect(_lives(3), findsOneWidget, reason: age.name);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('Çarpma ve eksik program can düşürür; Durdur/Temizle '
        'düşürmez; çıkıp girmek ve yeniden açmak canı ve programı korur', (
      tester,
    ) async {
      final app = await _setUp(tester, age: AgeGroup.ages13plus);
      final level = _lvl(AgeGroup.ages13plus, 1); // R.#... (doğu)
      await _openLevel(tester, level);
      await tester.tap(find.text(en.levelIntro(level)));

      await _addAll(tester, [Command.forward, Command.forward]);
      await _tap(tester, find.text(en.run));
      await tester.pump(const Duration(milliseconds: 100));
      await _tap(tester, find.text(en.stop));
      await _settle(tester, 300);
      await _tap(tester, find.text(en.clear));
      await _settle(tester, 300);
      expect(_lives(3), findsOneWidget);

      // Çarpma: 3 → 2.
      await _addAll(tester, [Command.forward, Command.forward]);
      await _run(tester, level);
      expect(find.text(en.crashMessage), findsOneWidget);
      expect(_lives(2), findsOneWidget);
      await _tap(tester, find.text(en.tryAgain));
      await _settle(tester, 300);

      // Eksik program: 2 → 1 ve "Son can!".
      await _tap(tester, find.text(en.clear));
      await _settle(tester, 300);
      await _addAll(tester, [Command.forward]);
      await _tap(tester, find.text(en.run));
      await _settle(tester, 900);
      expect(find.text(en.stoppedShortMessage), findsOneWidget);
      expect(_lives(1), findsOneWidget);
      expect(find.text(en.lastLife), findsOneWidget);
      await _tap(tester, find.text(en.tryAgain));
      await _settle(tester, 300);
      await _addAll(tester, [Command.turnRight]);

      // Seviyeden çık, tekrar gir: canlar yenilenmez, program yerinde.
      await _pop(tester);
      await _openLevel(tester, level);
      expect(_lives(1), findsOneWidget);
      expect(find.text(en.slotCounter(2, 18)), findsOneWidget);
      await _pop(tester);
      await _flushDb(tester);

      // "Uygulamayı kapatıp aç": aynı veritabanından yeni depolar.
      await tester.pumpWidget(const SizedBox());
      await _setUp(
        tester,
        age: AgeGroup.ages13plus,
        database: app.db,
        clock: app.clock,
      );
      await _openLevel(tester, level);
      expect(_lives(1), findsOneWidget);
      expect(find.text(en.slotCounter(2, 18)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Başarılı çözüm canları tam doldurur', (tester) async {
      final app = await _setUp(tester);
      final level = _lvl(AgeGroup.ages8to12, 1);
      await _openLevel(tester, level);
      await _addAll(tester, [Command.forward]);
      await _run(tester, level);
      expect(_lives(2), findsOneWidget);
      await _tap(tester, find.text(en.tryAgain));
      await _settle(tester, 300);
      await _addAll(tester, [Command.forward]);
      await _run(tester, level);
      expect(find.text(en.resultThreeStars), findsOneWidget);
      expect(app.sessions.sessionFor(level).lives, 3);
      await tester.tap(find.text(en.again));
      await _settle(tester, 800);
      expect(_lives(3), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Canlar bitince', () {
    Future<_App> exhaust(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      RewardedVideoService? video,
      Set<JokerType> used = const {},
      double textScale = 1.0,
    }) async {
      final app = await _setUp(
        tester,
        age: AgeGroup.ages13plus,
        locale: locale,
        video: video,
        textScale: textScale,
      );
      final level = _lvl(AgeGroup.ages13plus, 1);
      for (var i = 0; i < 3; i++) {
        app.sessions.loseLife(level);
      }
      for (final t in used) {
        app.sessions.markJokerUsed(level, t);
      }
      await _flushDb(tester);
      return app;
    }

    for (final locale in const [Locale('tr'), Locale('en')]) {
      testWidgets('Panel (${locale.languageCode}, 360×640, 1.3x): jokerler, '
          'canlı geri sayım, Can jokeri', (tester) async {
        final l = lookupAppLocalizations(locale);
        final app = await exhaust(
          tester,
          locale: locale,
          video: FakeVideo(RewardedVideoResult.completed),
          textScale: 1.3,
        );
        await _openLevel(tester, _lvl(AgeGroup.ages13plus, 1));
        await _settle(tester, 600);
        expect(find.text(l.outOfLivesTitle), findsOneWidget);
        expect(find.text(l.useLifeJoker), findsOneWidget);
        expect(find.text(l.skipLevelAction), findsOneWidget);
        expect(find.text(l.watchVideoAction), findsOneWidget);
        expect(find.text(l.nextLife('10:00')), findsOneWidget);

        app.clock.advance(const Duration(seconds: 28));
        await _settle(tester, 1100);
        expect(find.text(l.nextLife('09:32')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(l.useLifeJoker));
        await _settle(tester, 800);
        expect(_lives(1, l), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('Tüm jokerler kullanılmışsa yalnızca "Ana menü": ana ekrana '
        'döner, geri tuşu oyun ekranına dönmez', (tester) async {
      await exhaust(
        tester,
        used: {JokerType.life, JokerType.skip, JokerType.video},
        video: FakeVideo(RewardedVideoResult.completed),
      );
      await tester.tap(find.text(en.play));
      await _settle(tester, 800);
      await _openLevel(tester, _lvl(AgeGroup.ages13plus, 1));
      await _settle(tester, 600);
      expect(find.text(en.outOfLivesTitle), findsOneWidget);
      expect(find.text(en.useLifeJoker), findsNothing);
      expect(find.text(en.skipLevelAction), findsNothing);
      await tester.tap(find.text(en.mainMenu));
      await _settle(tester, 1000);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
      expect(find.byType(LevelSelectScreen), findsNothing);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(nav.canPop(), isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Canı sıfır seviye kartı geri sayım gösterir, dokununca panel; '
        'can dolunca oyun açılır', (tester) async {
      final app = await exhaust(tester);
      app.clock.advance(const Duration(minutes: 2, seconds: 28));
      await tester.tap(find.text(en.play));
      await _settle(tester, 800);
      expect(find.text('07:32'), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel(
          en.levelCardNoLivesLabel(
            1,
            en.levelTitle(_lvl(AgeGroup.ages13plus, 1)),
            '07:32',
          ),
        ),
      );
      await _settle(tester, 600);
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text(en.outOfLivesTitle), findsOneWidget);
      expect(find.text(en.nextLife('07:32')), findsOneWidget);

      app.clock.advance(const Duration(minutes: 8));
      await _settle(tester, 2000);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(_lives(1), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Can başlangıcın altındaysa kartta kalpler görünür', (
      tester,
    ) async {
      final app = await _setUp(tester, age: AgeGroup.ages13plus);
      app.sessions.loseLife(_lvl(AgeGroup.ages13plus, 1));
      await tester.tap(find.text(en.play));
      await _settle(tester, 800);
      expect(find.bySemanticsLabel(RegExp(en.livesLabel(2))), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Jokerler', () {
    testWidgets(
      'Tur Atla: onay, atlandı (0 yıldız), sonraki seviye; kartta ⏭',
      (tester) async {
        final app = await _setUp(tester);
        final level = _lvl(AgeGroup.ages8to12, 3);
        app.progress
          ..markSkipped(_lvl(AgeGroup.ages8to12, 1))
          ..markSkipped(_lvl(AgeGroup.ages8to12, 2));
        await _openLevel(tester, level);
        await tester.tap(find.text(en.levelIntro(level)));

        // Vazgeç: hiçbir şey olmaz.
        await _tap(tester, find.bySemanticsLabel(en.jokerSkip));
        await _settle(tester, 300);
        expect(find.text(en.skipConfirm), findsOneWidget);
        await tester.tap(find.text(en.cancel));
        await _settle(tester, 300);
        expect(app.progress.isSkipped(level), isFalse);

        await _tap(tester, find.bySemanticsLabel(en.jokerSkip));
        await _settle(tester, 300);
        await tester.tap(find.text(en.skipConfirmYes).last);
        await _settle(tester, 300);
        expect(find.text(en.skippedLabel), findsOneWidget);
        await _settle(tester, 2000);
        expect(app.progress.isSkipped(level), isTrue);
        expect(app.progress.starsFor(level), 0);
        final next = _lvl(AgeGroup.ages8to12, 4);
        expect(app.progress.isUnlocked(next), isTrue);
        expect(find.text(en.levelTitle(next)), findsOneWidget);

        await _pop(tester);
        await _push(tester, const LevelSelectScreen());
        expect(
          find.bySemanticsLabel(
            en.levelCardSkippedLabel(3, en.levelTitle(level)),
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Can jokeri 3 → 4 (başlangıcı aşar), bir kez kullanılır, kalıcı',
      (tester) async {
        final app = await _setUp(tester, age: AgeGroup.ages5to7);
        final level = _lvl(AgeGroup.ages5to7, 3);
        await _openLevel(tester, level);
        await _tap(tester, find.bySemanticsLabel(en.jokerLife));
        await _settle(tester, 300);
        expect(_lives(4), findsOneWidget);
        final used = find.bySemanticsLabel(en.jokerUsedLabel(en.jokerLife));
        expect(used, findsOneWidget);
        await _tap(tester, used);
        await _settle(tester, 300);
        expect(_lives(4), findsOneWidget);
        await _pop(tester);
        await _openLevel(tester, level);
        expect(used, findsOneWidget);
        expect(app.sessions.sessionFor(level).usedJokers, {JokerType.life});
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Video: tamamlanırsa atlanır; kapatılır ya da yüklenemezse '
        'harcanmaz', (tester) async {
      final video = FakeVideo(RewardedVideoResult.dismissed);
      final app = await _setUp(tester, video: video);
      final level = _lvl(AgeGroup.ages8to12, 1);
      await _openLevel(tester, level);
      await tester.tap(find.text(en.levelIntro(level)));

      await _tap(tester, find.bySemanticsLabel(en.jokerVideo));
      await _settle(tester, 300);
      expect(video.shown, 1);
      expect(find.text(en.videoFailed), findsNothing);
      expect(app.progress.isSkipped(level), isFalse);
      expect(app.sessions.sessionFor(level).usedJokers, isEmpty);

      video.result = RewardedVideoResult.failed;
      await _tap(tester, find.bySemanticsLabel(en.jokerVideo));
      await _settle(tester, 300);
      expect(find.text(en.videoFailed), findsOneWidget);
      expect(app.progress.isSkipped(level), isFalse);
      expect(app.sessions.sessionFor(level).usedJokers, isEmpty);

      video.result = RewardedVideoResult.completed;
      await _tap(tester, find.bySemanticsLabel(en.jokerVideo));
      await _settle(tester, 2500);
      expect(app.progress.isSkipped(level), isTrue);
      expect(app.progress.isUnlocked(_lvl(AgeGroup.ages8to12, 2)), isTrue);
      expect(
        find.text(en.levelTitle(_lvl(AgeGroup.ages8to12, 2))),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'Stub video: Kapat → dismissed; geri sayım bitince tamamlanır',
      (tester) async {
        final stub = StubRewardedVideoService(
          available: true,
          duration: const Duration(seconds: 2),
        );
        final app = await _setUp(tester, video: stub);
        final level = _lvl(AgeGroup.ages8to12, 1);
        await _openLevel(tester, level);
        await tester.tap(find.text(en.levelIntro(level)));

        await _tap(tester, find.bySemanticsLabel(en.jokerVideo));
        await _settle(tester, 500);
        expect(find.text(en.videoPlaceholder), findsOneWidget);
        await tester.tap(find.text(en.close));
        await _settle(tester, 1200);
        expect(find.text(en.videoPlaceholder), findsNothing);
        expect(app.progress.isSkipped(level), isFalse);

        await _tap(tester, find.bySemanticsLabel(en.jokerVideo));
        await _settle(tester, 4500);
        expect(app.progress.isSkipped(level), isTrue);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Video kapalı: buton görünür ama pasif; sayaç metni yok', (
      tester,
    ) async {
      final stub = StubRewardedVideoService(available: false);
      expect(stub.isAvailable, isFalse);
      final app = await _setUp(tester, video: stub);
      final level = _lvl(AgeGroup.ages8to12, 1);
      await _openLevel(tester, level);
      await tester.tap(find.text(en.levelIntro(level)));
      final videoButton = find.bySemanticsLabel(en.jokerVideo);
      expect(videoButton, findsOneWidget);
      expect(
        tester.getSemantics(videoButton),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      // Dokunmak hiçbir şey yapmaz: video açılmaz, seviye atlanmaz.
      await _tap(tester, videoButton);
      await _settle(tester, 1000);
      expect(find.text(en.videoPlaceholder), findsNothing);
      expect(app.progress.isSkipped(level), isFalse);
      expect(app.sessions.sessionFor(level).usedJokers, isEmpty);
      expect(find.bySemanticsLabel(en.jokerSkip), findsOneWidget);
      expect(find.bySemanticsLabel(en.jokerLife), findsOneWidget);
      expect(find.textContaining('Hints'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Çalışırken geri tuşu animasyonu güvenle iptal eder', (
    tester,
  ) async {
    await _setUp(tester, age: AgeGroup.ages13plus);
    final level = _lvl(AgeGroup.ages13plus, 5); // buz
    await _openLevel(tester, level);
    await _addAll(tester, level.referenceSolution);
    await _tap(tester, find.text(en.run));
    await tester.pump(const Duration(milliseconds: 700));
    await _pop(tester);
    expect(find.byType(GameScreen), findsNothing);
    await _settle(tester, 3000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('İlk açılış: yaş → arkadaş → seviye seçimi', (tester) async {
    final app = await _setUp(tester, age: null);
    expect(find.text(en.welcomeAge), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(en.ageRangeOf(AgeGroup.ages13plus)));
    await _settle(tester, 400);
    await tester.tap(find.text('Whiskers'));
    await _settle(tester, 300);
    await tester.tap(find.text(en.start));
    await _settle(tester, 1000);
    expect(
      find.text(en.worldTitle(en.ageRangeOf(AgeGroup.ages13plus))),
      findsOneWidget,
    );
    expect(app.settings.characterId, 'pati');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Yeni karakter açılınca kutlama; "Şimdi dene" seçer', (
    tester,
  ) async {
    final app = await _setUp(
      tester,
      locale: const Locale('tr'),
      stars: {(AgeGroup.ages5to7, 1): 3, (AgeGroup.ages5to7, 2): 1},
    );
    expect(app.progress.totalStarsAll, 4);
    final level = _lvl(AgeGroup.ages8to12, 1);
    await _openLevel(tester, level);
    await _addAll(tester, level.referenceSolution, tr);
    await tester.tap(find.text(tr.run));
    await _settle(tester, _runtime(level));
    await tester.tap(find.text(tr.next));
    await _settle(tester, 800);
    expect(find.text(tr.newFriend('Buzi')), findsOneWidget);
    await tester.tap(find.text(tr.tryNow));
    await _settle(tester, 800);
    expect(app.settings.characterId, 'buzi');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Karakter seçimi: kilitli kart, önizleme, Seç', (tester) async {
    final app = await _setUp(tester);
    await _push(tester, const CharacterSelectScreen());
    expect(find.text(en.unlockAt(5)), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Whiskers'));
    await _settle(tester, 300);
    await tester.tap(find.text(en.select));
    await _settle(tester, 300);
    expect(app.settings.characterId, 'pati');
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in const [Locale('tr'), Locale('en')]) {
    testWidgets('Ebeveyn kapısı (${locale.languageCode}): ayarlar ve '
        'ilerleme sıfırlama', (tester) async {
      final l = lookupAppLocalizations(locale);
      final app = await _setUp(
        tester,
        locale: locale,
        stars: {(AgeGroup.ages8to12, 1): 3},
      );
      app.sessions.loseLife(_lvl(AgeGroup.ages8to12, 2));
      await tester.tap(find.byTooltip(l.parent));
      await _settle(tester, 500);
      final pattern = RegExp(r'(\d+) \+ (\d+)');
      final q = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere(pattern.hasMatch);
      final m = pattern.firstMatch(q)!;
      expect(q, l.parentQuestion(int.parse(m[1]!), int.parse(m[2]!)));
      for (final d in '${int.parse(m[1]!) + int.parse(m[2]!)}'.split('')) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.tap(find.text(l.ok));
      await _settle(tester, 500);
      expect(find.text(l.settings), findsOneWidget);
      expect(find.text(l.about), findsOneWidget);

      await tester.tap(find.text(l.resetProgress));
      await _settle(tester, 400);
      await tester.tap(find.text(l.reset));
      await _flushDb(tester);
      await _settle(tester, 400);
      expect(app.progress.totalStarsAll, 0);
      expect(app.sessions.sessionFor(_lvl(AgeGroup.ages8to12, 2)).lives, 3);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
