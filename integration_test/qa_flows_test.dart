// QA: gerçek uygulamayı cihazda/emülatörde başlatıp kullanıcı gibi gezer.
// İki ayrı süreçte çalıştırılır (yeniden açılışı test etmek için):
//   flutter drive --driver test_driver/integration_test.dart \
//     --target integration_test/qa_flows_test.dart -d <cihaz> \
//     --dart-define=PHASE=1 --keep-app-running
//   ... --dart-define=PHASE=2
// 1. aşama: temiz kurulum → açılış → karşılama (yaş, arkadaş) → seviye
//    seçimi; 8–12 Seviye 1 kazan; Seviye 2'de can kaybet ve kart ekle;
//    ebeveyn panelinden 5–7 ve 13+'a geçip her birinde Seviye 1'i kazan.
// 2. aşama: yeniden açılış → doğrudan ana menü; can, program ve yıldızlar
//    korunmuş.
import 'package:algobot/data/db/app_database.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/engine/run_result.dart';
import 'package:algobot/engine/simulator.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/main.dart' as app;
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/level.dart';
import 'package:algobot/ui/screens/game_screen.dart';
import 'package:algobot/ui/screens/home_screen.dart';
import 'package:algobot/ui/screens/level_select_screen.dart';
import 'package:algobot/ui/screens/onboarding_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const phase = int.fromEnvironment('PHASE', defaultValue: 1);

Future<void> _wait(WidgetTester tester, [int ms = 1500]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Koşul sağlanana kadar bekler (en fazla [maxMs]).
Future<void> _until(
  WidgetTester tester,
  bool Function() done, {
  int maxMs = 15000,
}) async {
  for (var t = 0; t < maxMs && !done(); t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

AppLocalizations _l(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

Level _lvl(AgeGroup age, int id) =>
    levelsFor(age).firstWhere((l) => l.id == id);

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
}

Future<void> _addCards(
  WidgetTester tester,
  AppLocalizations l,
  List<Command> commands,
) async {
  for (final c in commands) {
    await _tapVisible(
      tester,
      find.bySemanticsLabel(l.paletteCardLabel(l.commandShort(c))),
    );
    await _wait(tester, 200);
  }
}

/// Seviye seçiminden seviyeyi açar ve ipucu balonunu kapatır.
Future<void> _openFromSelect(
  WidgetTester tester,
  AppLocalizations l,
  Level level,
) async {
  final title = find.text(l.levelTitle(level));
  await tester.scrollUntilVisible(
    title,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(title);
  await _until(tester, () => find.byType(GameScreen).evaluate().isNotEmpty);
  await _wait(tester, 800);
  final intro = find.text(l.levelIntro(level));
  if (intro.evaluate().isNotEmpty) {
    await tester.tap(intro.first);
    await _wait(tester, 300);
  }
}

Future<void> _winLevel1(
  WidgetTester tester,
  AppLocalizations l,
  AgeGroup age,
) async {
  final level = _lvl(age, 1);
  await _openFromSelect(tester, l, level);
  await _addCards(tester, l, level.referenceSolution);
  await tester.tap(find.text(l.run));
  await _until(
    tester,
    () => find.text(l.resultThreeStars).evaluate().isNotEmpty,
  );
  expect(find.text(l.resultThreeStars), findsOneWidget, reason: age.name);
  await _wait(tester, 1500);
  await tester.tap(find.text(l.next));
  await _wait(tester, 1500);
  // Yeni arkadaş kutlaması çıkarsa kapat.
  if (find.text(l.later).evaluate().isNotEmpty) {
    await tester.tap(find.text(l.later).first);
    await _wait(tester, 800);
  }
  expect(
    find.text(l.levelTitle(_lvl(age, 2))),
    findsWidgets,
    reason: '${age.name}: Devam → Seviye 2',
  );
}

Future<void> _solveGate(WidgetTester tester, AppLocalizations l) async {
  final pattern = RegExp(r'(\d+) \+ (\d+)');
  final q = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere(pattern.hasMatch);
  final m = pattern.firstMatch(q)!;
  for (final d in '${int.parse(m[1]!) + int.parse(m[2]!)}'.split('')) {
    await tester.tap(find.text(d).last);
    await tester.pump();
  }
  await tester.tap(find.text(l.ok));
  await _wait(tester, 800);
}

/// Ana menüye dönüp ebeveyn panelinden yaş grubunu değiştirir.
Future<void> _switchAge(
  WidgetTester tester,
  AppLocalizations l,
  AgeGroup age,
) async {
  final nav = Navigator.of(tester.element(find.byType(Scaffold).first));
  nav.popUntil((r) => r.isFirst);
  await _wait(tester, 1000);
  expect(find.byType(HomeScreen), findsOneWidget);
  await tester.tap(find.byTooltip(l.parent));
  await _wait(tester, 800);
  await _solveGate(tester, l);
  await tester.tap(find.text(l.ageShortOf(age)));
  await _wait(tester, 500);
  await _tapVisible(tester, find.text(l.close).last);
  await _wait(tester, 800);
  await tester.tap(find.text(l.play));
  await _wait(tester, 1200);
  expect(find.byType(LevelSelectScreen), findsOneWidget);
}

/// Başlangıçta çarpan kısa program.
List<Command> _crashProgram(Level level) {
  for (final p in [
    [Command.forward],
    [Command.turnLeft, Command.forward],
    [Command.turnRight, Command.forward],
    [Command.turnLeft, Command.turnLeft, Command.forward],
  ]) {
    if (Simulator.run(level, p).outcome == RunOutcome.crashed) return p;
  }
  throw StateError('Çarpan program yok: ${level.textKey}');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QA akışları, aşama $phase', (tester) async {
    final errors = <String>[];
    if (phase == 1) {
      // Temiz kurulum benzetimi: ayarlar ve veritabanı boş.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Bu akış eğitimi ayrıca test etmez (bkz. test/tutorial_test.dart):
      // oyuncu eğitimi daha önce atlamış sayılır.
      for (final f in ['relative', 'absolute']) {
        await prefs.setString('tutorial_done_$f', 'skipped');
      }
      for (final m in ['ice', 'door', 'portal']) {
        await prefs.setBool('mechanic_intro_seen_$m', true);
      }
      // Varsayılan ses kapalı (emülatörde gürültü olmasın).
      // --dart-define=SOUND=true ile açık çalıştırılır; QA-6 düzeltmesinden
      // sonra bekleyen kare geri çağrısı 0 olmalı.
      if (!const bool.fromEnvironment('SOUND')) {
        await prefs.setBool('sound_on', false);
      }
      final db = await AppDatabase.open();
      await db.db.delete('level_progress');
      await db.db.delete('level_session');
      await db.close();
    }

    app.main();
    // Konsoldaki çizim/çerçeve hatalarını topla (testi bozmadan).
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      errors.add(d.exceptionAsString().split('\n').first);
      old?.call(d);
    };

    // Açılış ekranı yükleme bitmeden geçmez; dokunmak atlatır.
    await _wait(tester, 600);
    await tester.tapAt(const Offset(200, 300));
    await _until(
      tester,
      () =>
          find.byType(OnboardingScreen).evaluate().isNotEmpty ||
          find.byType(HomeScreen).evaluate().isNotEmpty,
    );
    final l = _l(tester);
    debugPrint('QA: dil=${l.localeName} aşama=$phase');

    if (phase == 1) {
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.tap(find.text(l.ageShortOf(AgeGroup.ages8to12)).first);
      await _wait(tester, 1000);
      expect(find.text(l.pickFriend), findsOneWidget);
      await tester.tap(find.text(l.start));
      await _wait(tester, 1500);
      expect(find.byType(LevelSelectScreen), findsOneWidget);
      // Geri: açılış ya da karşılama ekranına değil ana menüye döner.
      final nav = Navigator.of(tester.element(find.byType(LevelSelectScreen)));
      expect(nav.canPop(), isTrue);
      nav.pop();
      await _wait(tester, 800);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
        isFalse,
      );
      await tester.tap(find.text(l.play));
      await _wait(tester, 1200);

      // Kazan: 8–12 Seviye 1.
      await _winLevel1(tester, l, AgeGroup.ages8to12);

      // Kaybet ve kart ekle: Seviye 2 (şu an açık).
      final l2 = _lvl(AgeGroup.ages8to12, 2);
      final intro = find.text(l.levelIntro(l2));
      if (intro.evaluate().isNotEmpty) await tester.tap(intro.first);
      await _wait(tester, 300);
      final crash = _crashProgram(l2);
      await _addCards(tester, l, crash);
      await tester.tap(find.text(l.run));
      await _until(tester, () => find.text(l.tryAgain).evaluate().isNotEmpty);
      expect(find.bySemanticsLabel(l.livesLabel(2)), findsOneWidget);
      await tester.tap(find.text(l.tryAgain));
      await _wait(tester, 500);
      await _addCards(tester, l, [Command.forward]);
      await _wait(tester, 1000); // 300 ms gecikmeli kayıt
      expect(
        find.text(l.slotCounter(crash.length + 1, l2.maxSlots)),
        findsOneWidget,
      );
      await (await SharedPreferences.getInstance()).setInt(
        'qa_l2_cards',
        crash.length + 1,
      );

      // Diğer yaş grupları: ebeveyn panelinden geçip Seviye 1.
      await _switchAge(tester, l, AgeGroup.ages5to7);
      await _winLevel1(tester, l, AgeGroup.ages5to7);
      await _switchAge(tester, l, AgeGroup.ages13plus);
      await _winLevel1(tester, l, AgeGroup.ages13plus);
      // 2. aşama 8–12 ile açılsın.
      await _switchAge(tester, l, AgeGroup.ages8to12);
      binding.reportData = {'phase1': 'ok'};

      // Boşta kare ölçümü (seviye seçimi; ölçüm yalnızca raporlanır).
      await _wait(tester, 2000);
      var frames = 0;
      void count(List<FrameTiming> t) => frames += t.length;
      SchedulerBinding.instance.addTimingsCallback(count);
      final callbacks = SchedulerBinding.instance.transientCallbackCount;
      await Future<void>.delayed(const Duration(seconds: 3));
      SchedulerBinding.instance.removeTimingsCallback(count);
      debugPrint(
        'QA: boşta 3 sn: $frames kare, $callbacks bekleyen kare geri çağrısı',
      );
    } else {
      // Yeniden açılış: karşılama yok, doğrudan ana menü.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      await tester.tap(find.text(l.play));
      await _wait(tester, 1200);
      final l1 = _lvl(AgeGroup.ages8to12, 1);
      expect(
        find.bySemanticsLabel(l.levelCardLabel(1, l.levelTitle(l1), 3)),
        findsOneWidget,
        reason: 'Seviye 1: 3 yıldız korunmalı',
      );
      final l2 = _lvl(AgeGroup.ages8to12, 2);
      await _openFromSelect(tester, l, l2);
      expect(find.bySemanticsLabel(l.livesLabel(2)), findsOneWidget);
      final cards =
          (await SharedPreferences.getInstance()).getInt('qa_l2_cards') ?? -1;
      expect(find.text(l.slotCounter(cards, l2.maxSlots)), findsOneWidget);
    }

    FlutterError.onError = old;
    debugPrint('QA: konsol hataları (${errors.length}): ${errors.toSet()}');
    expect(errors, isEmpty, reason: errors.toSet().join('\n'));
    if (kDebugMode) debugPrint('QA: aşama $phase tamam');
  });
}
