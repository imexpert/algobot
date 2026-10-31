import 'package:algobot/games/game_config.dart';
import 'package:algobot/games/game_platform_service.dart';

/// Çağrıları kaydeden sahte oyun platformu.
class FakeGamePlatform implements GamePlatformService {
  FakeGamePlatform({
    this.kind = GamePlatformKind.playGames,
    this.signInSucceeds = false,
  });

  @override
  final GamePlatformKind kind;

  /// Bir sonraki [trySilentSignIn] sonucu.
  bool signInSucceeds;

  /// Bir sonraki [interactiveSignIn] sonucu.
  GameSignInResult interactiveResult = GameSignInResult.success;

  /// true iken tüm gönderimler başarısız olur.
  bool failSends = false;

  bool _signedIn = false;

  /// Kayıtlı çağrılar: `unlock:<anahtar>`, `progress:<anahtar>:<n>/<hedef>`,
  /// `score:<anahtar>:<n>`, `signIn`, `showAchievements`, `showLeaderboard`.
  final calls = <String>[];

  List<String> get sends =>
      calls.where((c) => !c.startsWith('signIn')).toList();

  @override
  bool get isSignedIn => _signedIn;

  set signedIn(bool v) => _signedIn = v;

  @override
  Future<bool> trySilentSignIn() async {
    calls.add('signIn');
    return _signedIn = signInSucceeds;
  }

  @override
  Future<GameSignInResult> interactiveSignIn() async {
    calls.add('signInInteractive');
    _signedIn = interactiveResult == GameSignInResult.success;
    return interactiveResult;
  }

  @override
  Future<bool> unlockAchievement(String achievementKey) async {
    calls.add('unlock:$achievementKey');
    return !failSends;
  }

  @override
  Future<bool> setAchievementProgress(
    String achievementKey,
    int current,
    int target,
  ) async {
    calls.add('progress:$achievementKey:$current/$target');
    return !failSends;
  }

  @override
  Future<bool> submitScore(String leaderboardKey, int score) async {
    calls.add('score:$leaderboardKey:$score');
    return !failSends;
  }

  @override
  Future<void> showAchievementsUI() async => calls.add('showAchievements');

  @override
  Future<void> showLeaderboardUI(String leaderboardKey) async =>
      calls.add('showLeaderboard');
}
