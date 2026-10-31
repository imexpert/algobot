import 'achievement_definitions.dart';

/// Platform kimliği: Android (Play Games) ve iOS (Game Center).
typedef PlatformIds = ({String android, String ios});

/// Tüm başarım ve skor tablosu kimlikleri.
///
/// `REPLACE_...` değerleri yer tutucudur: Play Console'da başarımlar
/// oluşturulunca verilen kimlikler (ör. `CgkI...`) `android` alanına,
/// App Store Connect'te verilen kimlikler `ios` alanına yazılır. Yer tutucu
/// duruyorken o başarım platforma gönderilmez (yalnızca yerelde kalır).
/// Ayrıntılar: `store/KONSOL_KURULUM.md`.
abstract final class GameIds {
  /// Skor tablosunun kod içi anahtarı.
  static const totalStarsLeaderboard = 'total_stars';

  static const Map<String, PlatformIds> achievements = {
    Achievements.tutorialDone: (
      android: 'REPLACE_ANDROID_TUTORIAL_DONE',
      ios: 'REPLACE_IOS_TUTORIAL_DONE',
    ),
    Achievements.firstLevel: (
      android: 'REPLACE_ANDROID_FIRST_LEVEL',
      ios: 'REPLACE_IOS_FIRST_LEVEL',
    ),
    Achievements.firstPerfect: (
      android: 'REPLACE_ANDROID_FIRST_PERFECT',
      ios: 'REPLACE_IOS_FIRST_PERFECT',
    ),
    Achievements.lastLife: (
      android: 'REPLACE_ANDROID_LAST_LIFE',
      ios: 'REPLACE_IOS_LAST_LIFE',
    ),
    Achievements.world5to7: (
      android: 'REPLACE_ANDROID_WORLD_5_7',
      ios: 'REPLACE_IOS_WORLD_5_7',
    ),
    Achievements.world8to12: (
      android: 'REPLACE_ANDROID_WORLD_8_12',
      ios: 'REPLACE_IOS_WORLD_8_12',
    ),
    Achievements.world13plus: (
      android: 'REPLACE_ANDROID_WORLD_13_PLUS',
      ios: 'REPLACE_IOS_WORLD_13_PLUS',
    ),
    Achievements.stars12: (
      android: 'REPLACE_ANDROID_STARS_12',
      ios: 'REPLACE_IOS_STARS_12',
    ),
    Achievements.stars36: (
      android: 'REPLACE_ANDROID_STARS_36',
      ios: 'REPLACE_IOS_STARS_36',
    ),
    Achievements.stars72: (
      android: 'REPLACE_ANDROID_STARS_72',
      ios: 'REPLACE_IOS_STARS_72',
    ),
    Achievements.stars144: (
      android: 'REPLACE_ANDROID_STARS_144',
      ios: 'REPLACE_IOS_STARS_144',
    ),
    Achievements.perfectWorld: (
      android: 'REPLACE_ANDROID_PERFECT_WORLD',
      ios: 'REPLACE_IOS_PERFECT_WORLD',
    ),
    Achievements.friends4: (
      android: 'REPLACE_ANDROID_FRIENDS_4',
      ios: 'REPLACE_IOS_FRIENDS_4',
    ),
    Achievements.friends8: (
      android: 'REPLACE_ANDROID_FRIENDS_8',
      ios: 'REPLACE_IOS_FRIENDS_8',
    ),
    Achievements.iceMaster: (
      android: 'REPLACE_ANDROID_ICE_MASTER',
      ios: 'REPLACE_IOS_ICE_MASTER',
    ),
    Achievements.keyMaster: (
      android: 'REPLACE_ANDROID_KEY_MASTER',
      ios: 'REPLACE_IOS_KEY_MASTER',
    ),
    Achievements.portalMaster: (
      android: 'REPLACE_ANDROID_PORTAL_MASTER',
      ios: 'REPLACE_IOS_PORTAL_MASTER',
    ),
  };

  static const Map<String, PlatformIds> leaderboards = {
    totalStarsLeaderboard: (
      android: 'REPLACE_ANDROID_LB_TOTAL_STARS',
      ios: 'REPLACE_IOS_LB_TOTAL_STARS',
    ),
  };

  /// Henüz doldurulmamış kimlik.
  static bool isPlaceholder(String id) =>
      id.isEmpty || id.startsWith('REPLACE_');

  /// iOS için önerilen kimlik (`store/KONSOL_KURULUM.md`).
  static String suggestedIosAchievementId(String key) =>
      'com.fabsora.algobot.ach.$key';

  static const suggestedIosLeaderboardId = 'com.fabsora.algobot.lb.total_stars';
}
