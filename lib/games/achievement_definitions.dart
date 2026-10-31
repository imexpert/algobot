import 'dart:ui' show Color;

import '../core/colors.dart';

/// Rozetin ortasındaki simge (bkz. `ui/widgets/achievement_badge.dart`).
enum BadgeIcon {
  bulb,
  flag,
  sparkle,
  heart,
  gear,
  factory,
  code,
  star1,
  star2,
  star3,
  galaxy,
  trophy,
  friend,
  team,
  snowflake,
  key,
  portal,

  /// Skor tablosu simgesi (başarım değil; mağaza görseli).
  podium,
}

/// Bir başarımın tanımı. Adı ve açıklaması ARB'de (`achievementName`,
/// `achievementDesc`), platform kimlikleri `game_ids.dart`'tadır.
class AchievementDef {
  const AchievementDef({
    required this.key,
    required this.points,
    required this.icon,
    required this.color,
    this.target = 1,
  });

  /// Kod içi kimlik (veritabanı, ARB, CSV, rozet dosya adı).
  final String key;

  /// Play Games ve Game Center puanı (5'in katı).
  final int points;
  final BadgeIcon icon;
  final Color color;

  /// Artan başarımlarda hedef adım; tek seferlikte 1.
  final int target;

  /// Play Games'te "incremental", Game Center'da yüzde ilerleme.
  bool get incremental => target > 1;
}

/// Tüm başarımlar, ekrandaki ve konsoldaki sırasıyla.
abstract final class Achievements {
  static const tutorialDone = 'tutorial_done';
  static const firstLevel = 'first_level';
  static const firstPerfect = 'first_perfect';
  static const lastLife = 'last_life';
  static const world5to7 = 'world_5_7';
  static const world8to12 = 'world_8_12';
  static const world13plus = 'world_13_plus';
  static const stars12 = 'stars_12';
  static const stars36 = 'stars_36';
  static const stars72 = 'stars_72';
  static const stars144 = 'stars_144';
  static const perfectWorld = 'perfect_world';
  static const friends4 = 'friends_4';
  static const friends8 = 'friends_8';
  static const iceMaster = 'ice_master';
  static const keyMaster = 'key_master';
  static const portalMaster = 'portal_master';

  static const List<AchievementDef> all = [
    AchievementDef(
      key: tutorialDone,
      points: 10,
      icon: BadgeIcon.bulb,
      color: AppColors.activeHighlight,
    ),
    AchievementDef(
      key: firstLevel,
      points: 10,
      icon: BadgeIcon.flag,
      color: AppColors.primaryButton,
    ),
    AchievementDef(
      key: firstPerfect,
      points: 20,
      icon: BadgeIcon.sparkle,
      color: AppColors.starEarned,
    ),
    AchievementDef(
      key: lastLife,
      points: 20,
      icon: BadgeIcon.heart,
      color: AppColors.loopCard,
    ),
    AchievementDef(
      key: world5to7,
      points: 50,
      icon: BadgeIcon.gear,
      color: AppColors.upCard,
    ),
    AchievementDef(
      key: world8to12,
      points: 50,
      icon: BadgeIcon.factory,
      color: AppColors.turnCard,
    ),
    AchievementDef(
      key: world13plus,
      points: 75,
      icon: BadgeIcon.code,
      color: AppColors.downCard,
    ),
    AchievementDef(
      key: stars12,
      points: 25,
      icon: BadgeIcon.star1,
      color: AppColors.rightCard,
      target: 12,
    ),
    AchievementDef(
      key: stars36,
      points: 50,
      icon: BadgeIcon.star2,
      color: AppColors.downCard,
      target: 36,
    ),
    AchievementDef(
      key: stars72,
      points: 75,
      icon: BadgeIcon.star3,
      color: AppColors.forwardCard,
      target: 72,
    ),
    AchievementDef(
      key: stars144,
      points: 100,
      icon: BadgeIcon.galaxy,
      color: AppColors.loopCard,
      target: 144,
    ),
    AchievementDef(
      key: perfectWorld,
      points: 100,
      icon: BadgeIcon.trophy,
      color: AppColors.goalInner,
    ),
    AchievementDef(
      key: friends4,
      points: 25,
      icon: BadgeIcon.friend,
      color: AppColors.primaryButton,
      target: 4,
    ),
    AchievementDef(
      key: friends8,
      points: 75,
      icon: BadgeIcon.team,
      color: AppColors.turnCard,
      target: 8,
    ),
    AchievementDef(
      key: iceMaster,
      points: 25,
      icon: BadgeIcon.snowflake,
      color: AppColors.downCard,
    ),
    AchievementDef(
      key: keyMaster,
      points: 25,
      icon: BadgeIcon.key,
      color: AppColors.door,
    ),
    AchievementDef(
      key: portalMaster,
      points: 25,
      icon: BadgeIcon.portal,
      color: AppColors.portalOuter,
    ),
  ];

  static AchievementDef byKey(String key) =>
      all.firstWhere((a) => a.key == key);

  static int get totalPoints => all.fold(0, (sum, a) => sum + a.points);
}
