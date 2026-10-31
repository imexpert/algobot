import 'package:algobot/games/achievement_definitions.dart';
import 'package:algobot/games/game_config.dart';
import 'package:algobot/games/games_services_platform.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/ui/screens/achievements_screen.dart';
import 'package:algobot/ui/screens/home_screen.dart';
import 'package:algobot/ui/tutorial/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_game_platform.dart';
import '../helpers/tutorial_driver.dart';
import '../qa/qa_harness.dart';

/// Gerçek platform sınıfına verilen ve her çağrıyı sayan sahte API.
class _CountingApi extends GamesServicesApi {
  final calls = <String>[];

  @override
  Future<bool> isSignedIn() async {
    calls.add('isSignedIn');
    return true;
  }

  @override
  Future<void> signIn() async => calls.add('signIn');

  @override
  Future<void> unlock(gs.Achievement a) async => calls.add('unlock');

  @override
  Future<void> setSteps(gs.Achievement a) async => calls.add('setSteps');

  @override
  Future<void> submitScore(gs.Score s) async => calls.add('score');

  @override
  Future<void> showAchievements() async => calls.add('showAchievements');

  @override
  Future<void> showLeaderboard({
    required String android,
    required String ios,
  }) async => calls.add('showLeaderboard');
}

Finder _cardOf(String key) => find.byKey(ValueKey('achievement-$key'));

double _opacityOf(WidgetTester tester, String key) => tester
    .widget<Opacity>(
      find.ancestor(of: _cardOf(key), matching: find.byType(Opacity)).first,
    )
    .opacity;

const _platformAchievements = ValueKey('platform-achievements');
const _platformLeaderboard = ValueKey('platform-leaderboard');

/// 8–12 setinin ilk üç seviyesi üç yıldız: 9 yıldız.
const _nineStars = {
  (AgeGroup.ages8to12, 1): 3,
  (AgeGroup.ages8to12, 2): 3,
  (AgeGroup.ages8to12, 3): 3,
};

Future<void> _openAchievements(WidgetTester tester, AppLocalizations l) async {
  await tester.tap(find.text(l.achievements));
  await settle(tester, 800);
  expect(find.byType(AchievementsScreen), findsOneWidget);
}

void main() {
  testWidgets('Başarımlar ekranı oturumsuz çalışır: kilitli/açık, ilerleme', (
    tester,
  ) async {
    final app = await qaSetUp(tester, stars: _nineStars);
    await settle(tester, 300);
    await _openAchievements(tester, en);

    // Açık: ilk seviye, ilk üç yıldız. Kilitli: eğitim (atlanmış), set.
    expect(_opacityOf(tester, Achievements.firstLevel), 1);
    expect(_opacityOf(tester, Achievements.firstPerfect), 1);
    expect(_opacityOf(tester, Achievements.tutorialDone), lessThan(1));
    expect(_opacityOf(tester, Achievements.world8to12), lessThan(1));
    // 9 yıldız Buzi'yi de açar (5 yıldız): 4 karakter.
    expect(find.text('3 / 17'), findsOneWidget);

    // Artan başarımlar: ilerleme çubuğu ve sayı.
    await tester.scrollUntilVisible(_cardOf(Achievements.stars12), 300);
    expect(
      find.descendant(
        of: _cardOf(Achievements.stars12),
        matching: find.text(en.achievementProgress(9, 12)),
      ),
      findsOneWidget,
    );
    final bar = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: _cardOf(Achievements.stars12),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(bar.value, closeTo(9 / 12, 1e-9));
    expect(
      find.descendant(
        of: _cardOf(Achievements.world8to12),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNothing,
    );
    // Karakterler: 4 / 8.
    await tester.scrollUntilVisible(_cardOf(Achievements.friends8), 300);
    expect(_opacityOf(tester, Achievements.friends4), 1);
    expect(_opacityOf(tester, Achievements.friends8), lessThan(1));
    expect(
      find.descendant(
        of: _cardOf(Achievements.friends8),
        matching: find.text(en.achievementProgress(4, 8)),
      ),
      findsOneWidget,
    );

    // Oturum yok: platform butonları gizli.
    await tester.scrollUntilVisible(_cardOf(Achievements.portalMaster), 300);
    expect(find.byKey(_platformAchievements), findsNothing);
    expect(find.byKey(_platformLeaderboard), findsNothing);
    expect(find.text(en.achievementsParentArea), findsNothing);
    expect(app.achievements.isSignedIn, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Oturum yokken platform butonları ebeveyn panelinde de gizli', (
    tester,
  ) async {
    final platform = FakeGamePlatform();
    await qaSetUp(tester, gamePlatform: platform, stars: _nineStars);
    await settle(tester, 300);
    expect(platform.calls, ['signIn']); // sessiz deneme, başarısız
    await tester.tap(find.byTooltip(en.parent));
    await settle(tester, 500);
    await answerGate(tester, en);
    expect(find.text(en.settings), findsOneWidget);
    expect(find.byKey(_platformLeaderboard), findsNothing);
    expect(platform.sends, isEmpty);
  });

  testWidgets('Oturum varken platform butonları ebeveyn kapısı olmadan '
      'açılamaz', (tester) async {
    final platform = FakeGamePlatform(signInSucceeds: true);
    final app = await qaSetUp(
      tester,
      gamePlatform: platform,
      stars: _nineStars,
    );
    await settle(tester, 300);
    expect(app.achievements.isSignedIn, isTrue);
    await _openAchievements(tester, en);

    final button = find.byKey(_platformAchievements);
    await tester.scrollUntilVisible(button, 300);
    expect(find.text(en.viewOnGamePlatform('playGames')), findsOneWidget);
    expect(find.text(en.achievementsParentArea), findsOneWidget);

    // Kapı kapatılırsa ya da yanlış cevaplanırsa ekran açılmaz.
    await tester.tap(button);
    await settle(tester, 500);
    expect(find.text(en.parentGateTitle), findsOneWidget);
    await answerGate(tester, en, correct: false);
    await tester.tap(find.text(en.close));
    await settle(tester, 500);
    expect(platform.calls, isNot(contains('showAchievements')));

    // Doğru cevapla açılır.
    await tester.tap(button);
    await settle(tester, 500);
    await answerGate(tester, en);
    expect(platform.calls, contains('showAchievements'));

    await tester.tap(find.byKey(_platformLeaderboard));
    await settle(tester, 500);
    expect(platform.calls, isNot(contains('showLeaderboard')));
    await answerGate(tester, en);
    expect(platform.calls, contains('showLeaderboard'));
  });

  testWidgets('Ebeveyn panelinde skor tablosu (oturum açıkken)', (
    tester,
  ) async {
    final platform = FakeGamePlatform(signInSucceeds: true);
    await qaSetUp(tester, gamePlatform: platform, locale: const Locale('tr'));
    await settle(tester, 300);
    await tester.tap(find.byTooltip(tr.parent));
    await settle(tester, 500);
    await answerGate(tester, tr);
    // Panel zaten kapı arkasında: ikinci kapı sorulmaz.
    final lb = find.byKey(_platformLeaderboard);
    await tester.ensureVisible(lb);
    expect(find.byKey(_platformAchievements), findsNothing);
    expect(find.text(tr.openLeaderboard), findsOneWidget);
    await tester.tap(lb);
    await settle(tester, 300);
    expect(platform.calls, contains('showLeaderboard'));
    // Gizlilik metni platform adını gösterir.
    expect(find.text(tr.about(tr.aboutPrivacy('playGames'))), findsOneWidget);
  });

  testWidgets('Platform kapalıyken (kGamePlatformEnabled = false) hiçbir '
      'platform çağrısı yapılmaz; yerel başarımlar çalışır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = _CountingApi();
    final service = createGamePlatformService(
      await SharedPreferences.getInstance(),
      kind: resolveGamePlatform(
        enabled: false,
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      api: api,
    );
    final app = await qaSetUp(tester, gamePlatform: service);
    await settle(tester, 300);
    final level = lvl(AgeGroup.ages8to12, 1);
    await openLevel(tester, level);
    await addAll(tester, level.referenceSolution);
    await tapIt(tester, find.text(en.run));
    await settle(tester, runtime(level));
    await tester.tap(find.text(en.next));
    await settle(tester, 6000);
    expect(app.achievements.stateOf(Achievements.firstLevel).unlocked, true);
    expect(api.calls, isEmpty);
    expect(app.achievements.isSignedIn, isFalse);
  });

  testWidgets('Başarım bildirimi seviye sonu panelinden sonra çıkar', (
    tester,
  ) async {
    final platform = FakeGamePlatform(signInSucceeds: true);
    final app = await qaSetUp(tester, gamePlatform: platform);
    await settle(tester, 300);
    final toast = find.byKey(const ValueKey('achievement-toast'));
    final level = lvl(AgeGroup.ages8to12, 1);
    await openLevel(tester, level);
    await addAll(tester, level.referenceSolution);
    await tapIt(tester, find.text(en.run));
    await settle(tester, runtime(level));

    // Panel açıkken bildirim yok; başarım ise çoktan kaydedildi.
    expect(find.text(en.resultThreeStars), findsOneWidget);
    expect(toast, findsNothing);
    expect(app.achievements.stateOf(Achievements.firstLevel).unlocked, true);

    await tester.tap(find.text(en.next));
    await settle(tester, 600);
    expect(toast, findsOneWidget);
    expect(
      find.text(en.achievementName(Achievements.firstLevel)),
      findsOneWidget,
    );
    // Sırayla ikincisi (üç yıldız) ve sonra kaybolur.
    await settle(tester, 2500);
    expect(
      find.text(en.achievementName(Achievements.firstPerfect)),
      findsOneWidget,
    );
    await settle(tester, 2600);
    expect(toast, findsNothing);

    // Platforma da gönderildi; skor da.
    await tester.runAsync(() => app.achievements.idle);
    expect(platform.sends, contains('unlock:${Achievements.firstLevel}'));
    expect(platform.sends, contains('score:total_stars:3'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tamamlanan eğitim "Öğrenmeye Hazır"ı açar; atlanan açmaz', (
    tester,
  ) async {
    final app = await qaSetUp(tester, seenTutorial: false);
    await settle(tester, 300);
    final toast = find.byKey(const ValueKey('achievement-toast'));

    // Atlanan eğitim sayılmaz.
    await tester.tap(find.text(en.howToPlay));
    await settle(tester, 800);
    expect(find.byType(TutorialScreen), findsOneWidget);
    await tester.tap(find.text(en.tutSkip));
    await settle(tester, 400);
    await tester.tap(find.text(en.tutSkip).last);
    await settle(tester, 800);
    expect(find.byType(TutorialScreen), findsNothing);
    expect(app.achievements.stateOf(Achievements.tutorialDone).unlocked, false);
    expect(toast, findsNothing);

    // Baştan sona tamamlanan eğitim açar ve bildirim gösterir.
    await tester.tap(find.text(en.howToPlay));
    await settle(tester, 800);
    await completeTutorial(tester, en);
    expect(app.achievements.stateOf(Achievements.tutorialDone).unlocked, true);
    await settle(tester, 300);
    expect(
      find.text(en.achievementName(Achievements.tutorialDone)),
      findsOneWidget,
    );
    await settle(tester, 3000);
    expect(toast, findsNothing);
  });

  group('Taşma yok (360×640, 1.3x yazı)', () {
    for (final locale in const [Locale('tr'), Locale('en')]) {
      testWidgets('Ana ekran ve başarımlar (${locale.languageCode})', (
        tester,
      ) async {
        final l = lookupAppLocalizations(locale);
        final platform = FakeGamePlatform(signInSucceeds: true);
        await qaSetUp(
          tester,
          locale: locale,
          textScale: 1.3,
          gamePlatform: platform,
          stars: _nineStars,
        );
        await settle(tester, 300);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text(l.achievements), findsOneWidget);
        expect(find.text(l.characters), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _openAchievements(tester, l);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.byKey(_platformLeaderboard), 300);
        await tester.pump();
        expect(tester.takeException(), isNull);
        for (final def in Achievements.all) {
          expect(
            l.achievementName(def.key),
            isNot('?'),
            reason: '${locale.languageCode}: ${def.key}',
          );
          expect(l.achievementDesc(def.key), isNot('?'));
        }
      });
    }
  });
}
