import 'package:algobot/games/game_config.dart';
import 'package:algobot/games/game_ids.dart';
import 'package:algobot/games/games_services_platform.dart';
import 'package:algobot/games/noop_game_platform.dart';
import 'package:flutter/services.dart';
import 'package:algobot/games/game_platform_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:shared_preferences/shared_preferences.dart';

/// `games_services` çağrılarını kaydeden sahte API.
class _FakeApi extends GamesServicesApi {
  bool signedIn = false;
  bool signInThrows = false;
  Object? signInError;
  final calls = <String>[];

  @override
  Future<bool> isSignedIn() async {
    calls.add('isSignedIn');
    return signedIn;
  }

  @override
  Future<void> signIn() async {
    calls.add('signIn');
    if (signInError != null) throw signInError!;
    if (signInThrows) throw Exception('cancelled');
    signedIn = true;
  }

  @override
  Future<void> unlock(gs.Achievement a) async =>
      calls.add('unlock:${a.androidID}${a.iOSID}:${a.percentComplete}');

  @override
  Future<void> setSteps(gs.Achievement a) async =>
      calls.add('steps:${a.androidID}:${a.steps}');

  @override
  Future<void> submitScore(gs.Score s) async => calls.add(
    'score:${s.androidLeaderboardID}/${s.iOSLeaderboardID}:${s.value}',
  );

  @override
  Future<void> showAchievements() async => calls.add('showAchievements');

  @override
  Future<void> showLeaderboard({
    required String android,
    required String ios,
  }) async => calls.add('showLeaderboard');
}

const _ids = <String, PlatformIds>{
  'first_level': (android: 'CgkFirst', ios: 'com.x.ach.first_level'),
  'stars_12': (android: 'CgkStars', ios: 'com.x.ach.stars_12'),
  'placeholder': (android: 'REPLACE_ANDROID_X', ios: 'REPLACE_IOS_X'),
};
const _lb = <String, PlatformIds>{
  'total_stars': (android: 'CgkLb', ios: 'com.x.lb.total_stars'),
};

void main() {
  late SharedPreferences prefs;
  late _FakeApi api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = _FakeApi();
  });

  GamesServicesPlatform make(GamePlatformKind kind) => GamesServicesPlatform(
    kind: kind,
    prefs: prefs,
    api: api,
    achievementIds: _ids,
    leaderboardIds: _lb,
  );

  group('Açma/kapama', () {
    test('kGamePlatformEnabled=false: noop servis, hiçbir çağrı yok', () async {
      final kind = resolveGamePlatform(
        enabled: false,
        platform: TargetPlatform.android,
        isWeb: false,
      );
      expect(kind, GamePlatformKind.none);
      final service = createGamePlatformService(prefs, kind: kind, api: api);
      expect(service, isA<NoopGamePlatform>());
      await service.trySilentSignIn();
      await service.unlockAchievement('first_level');
      await service.setAchievementProgress('stars_12', 3, 12);
      await service.submitScore('total_stars', 3);
      await service.showAchievementsUI();
      await service.showLeaderboardUI('total_stars');
      expect(api.calls, isEmpty);
    });

    test('platform başına ayrı anahtarlar', () {
      expect(
        resolveGamePlatform(
          playGames: false,
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        GamePlatformKind.none,
      );
      expect(
        resolveGamePlatform(
          playGames: false,
          platform: TargetPlatform.iOS,
          isWeb: false,
        ),
        GamePlatformKind.gameCenter,
      );
      expect(
        resolveGamePlatform(
          gameCenter: false,
          platform: TargetPlatform.iOS,
          isWeb: false,
        ),
        GamePlatformKind.none,
      );
      expect(
        resolveGamePlatform(platform: TargetPlatform.android, isWeb: false),
        GamePlatformKind.playGames,
      );
      expect(resolveGamePlatform(isWeb: true), GamePlatformKind.none);
    });

    test('testlerde varsayılan servis noop', () {
      expect(createGamePlatformService(prefs), isA<NoopGamePlatform>());
    });
  });

  group('Android (Play Games)', () {
    test('yalnızca sessiz kontrol; giriş penceresi hiç açılmaz', () async {
      final p = make(GamePlatformKind.playGames);
      expect(await p.trySilentSignIn(), false);
      expect(await p.trySilentSignIn(), false);
      expect(api.calls, ['isSignedIn', 'isSignedIn']);
    });

    test('oturum yokken gönderim yapılmaz', () async {
      final p = make(GamePlatformKind.playGames);
      expect(await p.unlockAchievement('first_level'), false);
      expect(api.calls, isEmpty);
    });

    test('oturum varken: unlock, setSteps (mutlak), skor', () async {
      api.signedIn = true;
      final p = make(GamePlatformKind.playGames);
      await p.trySilentSignIn();
      api.calls.clear();
      expect(await p.unlockAchievement('first_level'), true);
      expect(await p.setAchievementProgress('stars_12', 9, 12), true);
      expect(await p.setAchievementProgress('stars_12', 40, 12), true);
      expect(await p.submitScore('total_stars', 9), true);
      expect(api.calls, [
        'unlock:CgkFirst:100.0',
        'steps:CgkStars:9',
        'steps:CgkStars:12',
        'score:CgkLb/com.x.lb.total_stars:9',
      ]);
    });

    test('yer tutucu kimlikler gönderilmez', () async {
      api.signedIn = true;
      final p = GamesServicesPlatform(
        kind: GamePlatformKind.playGames,
        prefs: prefs,
        api: api,
      );
      await p.trySilentSignIn();
      api.calls.clear();
      expect(await p.unlockAchievement('first_level'), false);
      expect(await p.submitScore(GameIds.totalStarsLeaderboard, 3), false);
      await p.showLeaderboardUI(GameIds.totalStarsLeaderboard);
      expect(api.calls, isEmpty);
    });

    test('platform hatası dışarı sızmaz', () async {
      final p = GamesServicesPlatform(
        kind: GamePlatformKind.playGames,
        prefs: prefs,
        api: _ThrowingApi(),
        achievementIds: _ids,
        leaderboardIds: _lb,
      );
      expect(await p.trySilentSignIn(), false);
    });
  });

  group('iOS (Game Center)', () {
    test(
      'ilk açılışta giriş bir kez denenir; başarılıysa oturum açık',
      () async {
        final p = make(GamePlatformKind.gameCenter);
        expect(await p.trySilentSignIn(), true);
        // Aynı oturumda (uygulama öne gelince) yalnızca sessiz kontrol.
        expect(await p.trySilentSignIn(), true);
        expect(api.calls, ['signIn', 'isSignedIn']);
        expect(await p.setAchievementProgress('stars_12', 3, 12), true);
        expect(api.calls.last, 'unlock:com.x.ach.stars_12:25.0');
      },
    );

    test('kullanıcı kapatırsa tercih saklanır, bir daha denenmez', () async {
      api.signInThrows = true;
      final p = make(GamePlatformKind.gameCenter);
      expect(await p.trySilentSignIn(), false);
      expect(prefs.getBool(GamesServicesPlatform.gameCenterDeclinedKey), true);

      // Uygulama yeniden açıldı: giriş ekranı yerine sessiz kontrol.
      api.calls.clear();
      final next = make(GamePlatformKind.gameCenter);
      await next.trySilentSignIn();
      expect(api.calls, ['isSignedIn']);
    });
  });

  group('Elle bağlanma (ebeveyn paneli)', () {
    test('iOS: butona basmak "bir daha deneme" tercihini temizler', () async {
      await prefs.setBool(GamesServicesPlatform.gameCenterDeclinedKey, true);
      final p = make(GamePlatformKind.gameCenter);
      expect(await p.interactiveSignIn(), GameSignInResult.success);
      expect(
        prefs.getBool(GamesServicesPlatform.gameCenterDeclinedKey),
        isNull,
      );
      expect(p.isSignedIn, isTrue);
      expect(api.calls, ['signIn']);
    });

    test('iOS: sistem ekranı gösterilmezse "unavailable"', () async {
      api.signInError = PlatformException(code: 'sign_in_unavailable');
      final p = make(GamePlatformKind.gameCenter);
      expect(await p.interactiveSignIn(), GameSignInResult.unavailable);
      expect(p.isSignedIn, isFalse);
    });

    test('Android: etkileşimli giriş; vazgeçilirse "failed"', () async {
      final p = make(GamePlatformKind.playGames);
      expect(await p.interactiveSignIn(), GameSignInResult.success);
      expect(api.calls, ['signIn']);
      api.signInError = PlatformException(code: 'failed_to_authenticate');
      final q = make(GamePlatformKind.playGames);
      expect(await q.interactiveSignIn(), GameSignInResult.failed);
      expect(q.isSignedIn, isFalse);
      // Android'de "bir daha deneme" tercihi kullanılmaz.
      expect(
        prefs.getBool(GamesServicesPlatform.gameCenterDeclinedKey),
        isNull,
      );
    });

    test(
      'Android: sessiz kontrol giriş penceresi açmamaya devam eder',
      () async {
        final p = make(GamePlatformKind.playGames);
        await p.trySilentSignIn();
        expect(api.calls, ['isSignedIn']);
      },
    );
  });
}

class _ThrowingApi extends GamesServicesApi {
  @override
  Future<bool> isSignedIn() async => throw Exception('no play services');
}
