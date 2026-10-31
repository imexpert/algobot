import 'game_config.dart';

/// Ebeveynin elle başlattığı girişin sonucu.
enum GameSignInResult {
  success,

  /// Vazgeçildi ya da başarısız oldu.
  failed,

  /// iOS sistem giriş ekranını göstermedi (Ayarlar > Game Center gerekir).
  unavailable,
}

/// Oyun platformunun (Play Games / Game Center) tek arayüzü.
///
/// Uygulamalar hiçbir zaman hata fırlatmaz: platform hataları yakalanıp
/// `debugPrint` ile kaydedilir. Gönderim metotları başarıyı `bool` olarak
/// döndürür; böylece başarısız gönderim daha sonra yeniden denenebilir.
abstract class GamePlatformService {
  /// Kullanılan platform; [GamePlatformKind.none] ise hiçbir çağrı yapılmaz.
  GamePlatformKind get kind;

  /// Sessiz oturum denemesi. Hiçbir zaman ısrarcı bir pencere açmaz
  /// (Game Center sistem ekranı en fazla bir kez görünebilir).
  Future<bool> trySilentSignIn();

  bool get isSignedIn;

  /// Etkileşimli giriş: yalnızca ebeveyn panelindeki "bağlan" butonundan.
  /// Android'de Play Games giriş penceresini açar; iOS'ta Game Center
  /// girişini yeniden dener ve "bir daha deneme" tercihini temizler.
  Future<GameSignInResult> interactiveSignIn();

  /// Tek seferlik başarımı açar.
  Future<bool> unlockAchievement(String achievementKey);

  /// Artan başarımın mutlak ilerlemesi ([current] / [target]). Platformlar
  /// ilerlemeyi hiçbir zaman azaltmaz; aynı değer tekrar gönderilebilir.
  Future<bool> setAchievementProgress(
    String achievementKey,
    int current,
    int target,
  );

  Future<bool> submitScore(String leaderboardKey, int score);

  Future<void> showAchievementsUI();

  Future<void> showLeaderboardUI(String leaderboardKey);
}
