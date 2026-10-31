import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:games_services/games_services.dart' as gs;
import 'package:shared_preferences/shared_preferences.dart';

import 'game_config.dart';
import 'game_ids.dart';
import 'game_platform_service.dart';
import 'noop_game_platform.dart';

/// `games_services` paketinin kullanılan çağrıları (testlerde sahtesi).
class GamesServicesApi {
  const GamesServicesApi();

  /// Sessiz kontrol: oturum açık mı. Android'de Play Games v2'nin açılışta
  /// kendiliğinden yaptığı oturumu okur; hiçbir pencere açmaz.
  Future<bool> isSignedIn() async {
    final completer = Completer<bool>();
    late final StreamSubscription<gs.PlayerData?> sub;
    sub = gs.GameAuth.player.listen(
      (player) {
        if (!completer.isCompleted) completer.complete(player != null);
        sub.cancel();
      },
      onError: (Object _) {
        if (!completer.isCompleted) completer.complete(false);
        sub.cancel();
      },
    );
    return completer.future;
  }

  /// Etkileşimli giriş. iOS'ta Game Center (oturum yoksa sistem ekranını
  /// gösterebilir), Android'de Play Games giriş penceresi. Android'de
  /// yalnızca ebeveyn panelindeki butondan çağrılır.
  Future<void> signIn() => gs.GameAuth.signIn();

  Future<void> unlock(gs.Achievement a) =>
      gs.Achievements.unlock(achievement: a);

  Future<void> setSteps(gs.Achievement a) =>
      gs.Achievements.setSteps(achievement: a);

  Future<void> submitScore(gs.Score s) => gs.Leaderboards.submitScore(score: s);

  Future<void> showAchievements() => gs.Achievements.showAchievements();

  Future<void> showLeaderboard({
    required String android,
    required String ios,
  }) => gs.Leaderboards.showLeaderboards(
    androidLeaderboardID: android,
    iOSLeaderboardID: ios,
  );
}

/// Anahtarlara ve cihaza göre oyun platformu servisi. Platform kapalıysa,
/// desteklenmiyorsa ya da testlerde [NoopGamePlatform] döner.
GamePlatformService createGamePlatformService(
  SharedPreferences prefs, {
  GamePlatformKind? kind,
  GamesServicesApi api = const GamesServicesApi(),
}) {
  final resolved =
      kind ??
      (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')
          ? GamePlatformKind.none
          : resolveGamePlatform());
  return resolved == GamePlatformKind.none
      ? const NoopGamePlatform()
      : GamesServicesPlatform(kind: resolved, prefs: prefs, api: api);
}

/// Play Games Services (v2) ve Game Center, `games_services` paketiyle.
///
/// - Android: yalnızca sessiz kontrol yapılır; giriş penceresi hiç açılmaz.
/// - iOS: Game Center girişi ilk kez denenir; sistem ekranı kapatılır ya da
///   giriş başarısız olursa bu tercih saklanır ve bir daha otomatik giriş
///   denenmez (yalnızca sessiz kontrol).
/// - Yer tutucu kimlikli başarımlar gönderilmez.
/// - Hiçbir hata dışarı sızmaz.
class GamesServicesPlatform implements GamePlatformService {
  GamesServicesPlatform({
    required this.kind,
    required this._prefs,
    this._api = const GamesServicesApi(),
    this._timeout = const Duration(seconds: 15),
    this._achievementIds = GameIds.achievements,
    this._leaderboardIds = GameIds.leaderboards,
  }) : assert(kind != GamePlatformKind.none);

  @override
  final GamePlatformKind kind;
  final SharedPreferences _prefs;
  final GamesServicesApi _api;
  final Duration _timeout;
  final Map<String, PlatformIds> _achievementIds;
  final Map<String, PlatformIds> _leaderboardIds;

  /// iOS: otomatik Game Center girişi bir kez denendi ve başarısız oldu.
  static const gameCenterDeclinedKey = 'game_center_signin_declined';

  bool _signedIn = false;
  bool _signInAttempted = false;

  bool get _android => kind == GamePlatformKind.playGames;

  @override
  bool get isSignedIn => _signedIn;

  @override
  Future<bool> trySilentSignIn() async {
    try {
      if (!_android &&
          !_signInAttempted &&
          !(_prefs.getBool(gameCenterDeclinedKey) ?? false)) {
        _signInAttempted = true;
        try {
          // Kullanıcı sistem ekranında beklerken zaman aşımı kısa tutulmaz.
          await _api.signIn().timeout(const Duration(minutes: 3));
          return _signedIn = true;
        } catch (e) {
          await _prefs.setBool(gameCenterDeclinedKey, true);
          debugPrint('Game Center girişi yapılmadı, tekrar denenmeyecek: $e');
          return _signedIn = false;
        }
      }
      return _signedIn = await _api.isSignedIn().timeout(_timeout);
    } catch (e) {
      debugPrint('Oyun platformu oturumu kontrol edilemedi: $e');
      return _signedIn = false;
    }
  }

  /// eklentinin iOS hata kodu: sistem giriş ekranı gösterilmedi.
  static const signInUnavailableCode = 'sign_in_unavailable';

  @override
  Future<GameSignInResult> interactiveSignIn() async {
    if (!_android) {
      // Ebeveyn elle istedi: "bir daha deneme" tercihi temizlenir.
      await _prefs.remove(gameCenterDeclinedKey);
      _signInAttempted = true;
    }
    try {
      await _api.signIn().timeout(const Duration(minutes: 3));
      _signedIn = true;
      return GameSignInResult.success;
    } on PlatformException catch (e) {
      debugPrint('Oyun platformu girişi başarısız: ${e.code} ${e.message}');
      _signedIn = false;
      await _rememberDecline();
      return !_android && e.code == signInUnavailableCode
          ? GameSignInResult.unavailable
          : GameSignInResult.failed;
    } catch (e) {
      debugPrint('Oyun platformu girişi başarısız: $e');
      _signedIn = false;
      await _rememberDecline();
      return GameSignInResult.failed;
    }
  }

  /// iOS: elle giriş de başarısız olursa otomatik deneme yine yapılmaz.
  Future<void> _rememberDecline() async {
    if (!_android) await _prefs.setBool(gameCenterDeclinedKey, true);
  }

  String? _achievementId(String key) {
    final ids = _achievementIds[key];
    final id = ids == null ? null : (_android ? ids.android : ids.ios);
    return id == null || GameIds.isPlaceholder(id) ? null : id;
  }

  PlatformIds? _leaderboard(String key) {
    final ids = _leaderboardIds[key];
    if (ids == null) return null;
    return GameIds.isPlaceholder(_android ? ids.android : ids.ios) ? null : ids;
  }

  Future<bool> _call(String what, Future<void> Function() action) async {
    if (!_signedIn) return false;
    try {
      await action().timeout(_timeout);
      return true;
    } catch (e) {
      debugPrint('Oyun platformu çağrısı başarısız ($what): $e');
      return false;
    }
  }

  @override
  Future<bool> unlockAchievement(String achievementKey) async {
    final id = _achievementId(achievementKey);
    if (id == null) return false;
    return _call(
      'unlock $achievementKey',
      () => _api.unlock(
        _android ? gs.Achievement(androidID: id) : gs.Achievement(iOSID: id),
      ),
    );
  }

  @override
  Future<bool> setAchievementProgress(
    String achievementKey,
    int current,
    int target,
  ) async {
    final id = _achievementId(achievementKey);
    if (id == null || target <= 0) return false;
    final steps = current.clamp(0, target);
    if (steps == 0) return _signedIn; // gönderilecek ilerleme yok
    return _call(
      'progress $achievementKey',
      () => _android
          // setSteps mutlak değerdir ve ilerlemeyi azaltmaz (tekrarlanabilir).
          ? _api.setSteps(gs.Achievement(androidID: id, steps: steps))
          : _api.unlock(
              gs.Achievement(iOSID: id, percentComplete: steps * 100 / target),
            ),
    );
  }

  @override
  Future<bool> submitScore(String leaderboardKey, int score) async {
    final ids = _leaderboard(leaderboardKey);
    if (ids == null) return false;
    return _call(
      'score $leaderboardKey',
      () => _api.submitScore(
        gs.Score(
          androidLeaderboardID: ids.android,
          iOSLeaderboardID: ids.ios,
          value: score,
        ),
      ),
    );
  }

  @override
  Future<void> showAchievementsUI() async {
    await _call('showAchievements', _api.showAchievements);
  }

  @override
  Future<void> showLeaderboardUI(String leaderboardKey) async {
    final ids = _leaderboard(leaderboardKey);
    if (ids == null) return;
    await _call(
      'showLeaderboard',
      () => _api.showLeaderboard(android: ids.android, ios: ids.ios),
    );
  }
}
