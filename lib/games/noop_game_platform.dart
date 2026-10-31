import 'game_config.dart';
import 'game_platform_service.dart';

/// Platform yoksa, kapalıysa, web'de ve testlerde: hiçbir şey yapmaz.
/// Oturum hiçbir zaman açılmaz; bu yüzden gönderimler `false` döner ve
/// başarımlar yalnızca yerelde kalır.
class NoopGamePlatform implements GamePlatformService {
  const NoopGamePlatform();

  @override
  GamePlatformKind get kind => GamePlatformKind.none;

  @override
  bool get isSignedIn => false;

  @override
  Future<bool> trySilentSignIn() async => false;

  @override
  Future<GameSignInResult> interactiveSignIn() async => GameSignInResult.failed;

  @override
  Future<bool> unlockAchievement(String achievementKey) async => false;

  @override
  Future<bool> setAchievementProgress(
    String achievementKey,
    int current,
    int target,
  ) async => false;

  @override
  Future<bool> submitScore(String leaderboardKey, int score) async => false;

  @override
  Future<void> showAchievementsUI() async {}

  @override
  Future<void> showLeaderboardUI(String leaderboardKey) async {}
}
