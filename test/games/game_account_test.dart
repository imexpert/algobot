import 'package:algobot/games/achievement_definitions.dart';
import 'package:algobot/games/game_config.dart';
import 'package:algobot/games/game_platform_service.dart';
import 'package:algobot/games/games_services_platform.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_game_platform.dart';
import '../qa/qa_harness.dart';

const _connect = ValueKey('game-account-connect');
const _connected = ValueKey('game-account-connected');
const _message = ValueKey('game-account-message');

const _stars = {(AgeGroup.ages8to12, 1): 3, (AgeGroup.ages8to12, 2): 2};

Future<void> _openPanel(WidgetTester tester, AppLocalizations l) async {
  await tester.tap(find.byTooltip(l.parent));
  await settle(tester, 500);
  await answerGate(tester, l);
  expect(find.text(l.settings), findsOneWidget);
}

void main() {
  group('İlerlemeyi sıfırla', () {
    for (final locale in const [Locale('tr'), Locale('en')]) {
      testWidgets('Onayda başarım notu (${locale.languageCode}); '
          'sıfırlama achievement_state\'i korur', (tester) async {
        final l = lookupAppLocalizations(locale);
        final app = await qaSetUp(tester, locale: locale, stars: _stars);
        await settle(tester, 300);
        expect(
          app.achievements.stateOf(Achievements.firstLevel).unlocked,
          true,
        );
        await tester.runAsync(() => app.achievements.idle);

        await _openPanel(tester, l);
        await tester.tap(find.text(l.resetProgress));
        await settle(tester, 400);
        expect(find.text(l.resetConfirmBody), findsOneWidget);
        expect(find.text(l.resetAchievementsKept), findsOneWidget);
        // Ayrı satırda, uyarının altında ve daha küçük.
        final body = tester.getRect(find.text(l.resetConfirmBody));
        final note = tester.getRect(find.text(l.resetAchievementsKept));
        expect(note.top, greaterThanOrEqualTo(body.bottom));
        final noteSize = tester
            .widget<Text>(find.text(l.resetAchievementsKept))
            .style!
            .fontSize!;
        final bodySize = tester
            .widget<Text>(find.text(l.resetConfirmBody))
            .style!
            .fontSize!;
        expect(noteSize, lessThan(bodySize));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(l.reset));
        await flushDb(tester);
        await settle(tester, 400);
        expect(app.progress.totalStarsAll, 0);
        // Başarımlar hem bellekte hem tabloda duruyor.
        expect(
          app.achievements.stateOf(Achievements.firstLevel).unlocked,
          true,
        );
        final rows = (await tester.runAsync(
          () => app.db.db.query('achievement_state'),
        ))!;
        expect(
          rows.any(
            (r) =>
                r['achievement_key'] == Achievements.firstLevel &&
                r['unlocked'] == 1,
          ),
          isTrue,
        );
      });
    }
  });

  group('Oyun hesabı (ebeveyn paneli)', () {
    testWidgets('Oturum kapalıyken buton; başarılı girişte bekleyenler ve '
        'skor gönderilir, "bağlı" görünür', (tester) async {
      final platform = FakeGamePlatform();
      final app = await qaSetUp(tester, gamePlatform: platform, stars: _stars);
      await settle(tester, 300);
      await tester.runAsync(() => app.achievements.idle);
      expect(platform.sends, isEmpty);
      expect(app.achievements.pendingKeys, isNotEmpty);

      await _openPanel(tester, en);
      expect(find.text(en.gameAccount), findsOneWidget);
      expect(find.text(en.connectGamePlatform('playGames')), findsOneWidget);
      expect(find.byKey(_connected), findsNothing);
      // Oturum yokken skor tablosu butonu da yok.
      expect(find.byKey(const ValueKey('platform-leaderboard')), findsNothing);

      await tester.ensureVisible(find.byKey(_connect));
      await tester.tap(find.byKey(_connect));
      await settle(tester, 300);
      await tester.runAsync(() => app.achievements.idle);
      await settle(tester, 100);

      expect(platform.calls, contains('signInInteractive'));
      expect(platform.sends, contains('unlock:${Achievements.firstLevel}'));
      expect(platform.sends, contains('score:total_stars:5'));
      expect(app.achievements.pendingKeys, isEmpty);
      expect(find.byKey(_connect), findsNothing);
      expect(find.byKey(_connected), findsOneWidget);
      expect(find.text(en.connectedGamePlatform('playGames')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('platform-leaderboard')),
        findsOneWidget,
      );
    });

    testWidgets('Oturum zaten açıksa yalnızca "bağlı" durumu', (tester) async {
      final platform = FakeGamePlatform(signInSucceeds: true);
      await qaSetUp(tester, gamePlatform: platform, locale: const Locale('tr'));
      await settle(tester, 300);
      await _openPanel(tester, tr);
      expect(find.text(tr.connectedGamePlatform('playGames')), findsOneWidget);
      expect(find.byKey(_connect), findsNothing);
    });

    testWidgets(
      'Başarısız girişte nazik mesaj; uygulama çalışmaya devam eder',
      (tester) async {
        final platform = FakeGamePlatform()
          ..interactiveResult = GameSignInResult.failed;
        final app = await qaSetUp(
          tester,
          gamePlatform: platform,
          stars: _stars,
        );
        await settle(tester, 300);
        await _openPanel(tester, en);
        await tester.ensureVisible(find.byKey(_connect));
        await tester.tap(find.byKey(_connect));
        await settle(tester, 300);
        expect(find.text(en.connectFailed), findsOneWidget);
        expect(find.byKey(_connect), findsOneWidget); // tekrar denenebilir
        expect(platform.sends, isEmpty);
        expect(app.achievements.pendingKeys, isNotEmpty);
        expect(tester.takeException(), isNull);
        // Panel kapanır, oyun normal sürer.
        await tester.ensureVisible(find.text(en.close).last);
        await tester.tap(find.text(en.close).last);
        await settle(tester, 400);
        expect(find.text(en.play), findsOneWidget);
      },
    );

    testWidgets('iOS: sistem ekranı gösterilmezse Ayarlar ipucu', (
      tester,
    ) async {
      final platform = FakeGamePlatform(kind: GamePlatformKind.gameCenter)
        ..interactiveResult = GameSignInResult.unavailable;
      await qaSetUp(tester, gamePlatform: platform, locale: const Locale('tr'));
      await settle(tester, 300);
      await _openPanel(tester, tr);
      expect(find.text(tr.connectGamePlatform('gameCenter')), findsOneWidget);
      await tester.ensureVisible(find.byKey(_connect));
      await tester.tap(find.byKey(_connect));
      await settle(tester, 300);
      expect(find.text(tr.gameCenterSettingsHint), findsOneWidget);
    });

    testWidgets('Platform anahtarı false iken bölüm görünmez', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = createGamePlatformService(
        await SharedPreferences.getInstance(),
        kind: resolveGamePlatform(
          playGames: false,
          platform: TargetPlatform.android,
          isWeb: false,
        ),
      );
      await qaSetUp(tester, gamePlatform: service);
      await settle(tester, 300);
      await _openPanel(tester, en);
      expect(find.text(en.gameAccount), findsNothing);
      expect(find.byKey(_connect), findsNothing);
      expect(find.byKey(_connected), findsNothing);
    });

    testWidgets('Panel dışında hiçbir yerde bağlanma butonu yok', (
      tester,
    ) async {
      await qaSetUp(tester, gamePlatform: FakeGamePlatform());
      await settle(tester, 300);
      expect(find.byKey(_connect), findsNothing);
      await tester.tap(find.text(en.achievements));
      await settle(tester, 800);
      expect(find.byKey(_connect), findsNothing);
      expect(find.text(en.connectGamePlatform('playGames')), findsNothing);
    });
  });

  group('Taşma yok (360×640, 1.3x yazı)', () {
    for (final locale in const [Locale('tr'), Locale('en')]) {
      for (final kind in const [
        GamePlatformKind.playGames,
        GamePlatformKind.gameCenter,
      ]) {
        testWidgets('Ebeveyn paneli (${locale.languageCode}, ${kind.name})', (
          tester,
        ) async {
          final l = lookupAppLocalizations(locale);
          final platform = FakeGamePlatform(kind: kind)
            ..interactiveResult = kind == GamePlatformKind.gameCenter
                ? GameSignInResult.unavailable
                : GameSignInResult.failed;
          await qaSetUp(
            tester,
            locale: locale,
            textScale: 1.3,
            gamePlatform: platform,
          );
          await settle(tester, 300);
          await _openPanel(tester, l);
          await tester.ensureVisible(find.byKey(_connect));
          await tester.tap(find.byKey(_connect));
          await settle(tester, 300);
          await tester.ensureVisible(find.byKey(_message));
          await tester.pump();
          expect(tester.takeException(), isNull);
          // Bağlı durumu da taşmasın.
          platform.signInSucceeds = true;
          platform.interactiveResult = GameSignInResult.success;
          await tester.ensureVisible(find.byKey(_connect));
          await tester.pump();
          await tester.tap(find.byKey(_connect));
          await settle(tester, 300);
          await tester.ensureVisible(find.byKey(_connected));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
