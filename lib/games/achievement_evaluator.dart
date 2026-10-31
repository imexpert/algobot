import 'package:flutter/foundation.dart';

import '../characters/character_registry.dart';
import '../data/progress_repository.dart';
import '../models/age_group.dart';
import '../models/cell.dart';
import '../models/level.dart';
import 'achievement_definitions.dart';

/// Başarım hesaplamasının girdileri: yerel ilerleme ve olaylar.
@immutable
class AchievementFacts {
  const AchievementFacts({
    required this.sets,
    required this.progressOf,
    this.tutorialCompleted = false,
    this.solvedOnLastLife = false,
  });

  /// Tüm yaş setlerinin seviyeleri.
  final Map<AgeGroup, List<Level>> sets;

  /// Seviyenin kalıcı ilerlemesi.
  final LevelProgress Function(Level level) progressOf;

  /// Herhangi bir eğitim tamamlandı (atlamak sayılmaz).
  final bool tutorialCompleted;

  /// Olay: bu seviye son canla çözüldü.
  final bool solvedOnLastLife;
}

/// Bir başarımın hesaplanan durumu.
@immutable
class AchievementProgress {
  const AchievementProgress(this.key, this.progress, this.target);

  final String key;

  /// 0..[target] (hedefi aşmaz).
  final int progress;
  final int target;

  bool get unlocked => progress >= target;

  @override
  bool operator ==(Object other) =>
      other is AchievementProgress &&
      other.key == key &&
      other.progress == progress &&
      other.target == target;

  @override
  int get hashCode => Object.hash(key, progress, target);

  @override
  String toString() => '$key $progress/$target';
}

/// Yerel ilerlemeden başarımları hesaplar (saf, yan etkisiz).
///
/// Yalnızca gerçekten çözülmüş seviyeler sayılır (`completed`); atlanan
/// seviyeler hiçbir başarıma katkı vermez.
abstract final class AchievementEvaluator {
  /// 13+ mekanik tanıtım başarımları → ilgili kare türü.
  static const mechanicAchievements = {
    Achievements.iceMaster: CellType.ice,
    Achievements.keyMaster: CellType.door,
    Achievements.portalMaster: CellType.portalA,
  };

  static const worldAchievements = {
    Achievements.world5to7: AgeGroup.ages5to7,
    Achievements.world8to12: AgeGroup.ages8to12,
    Achievements.world13plus: AgeGroup.ages13plus,
  };

  static Map<String, AchievementProgress> evaluate(AchievementFacts facts) {
    final levels = [for (final list in facts.sets.values) ...list];
    bool solved(Level l) => facts.progressOf(l).completed;
    int stars(Level l) => solved(l) ? facts.progressOf(l).bestStars : 0;

    final totalStars = levels.fold(0, (sum, l) => sum + stars(l));
    final friends = CharacterRegistry.unlocked(totalStars).length;

    bool setSolved(AgeGroup age) {
      final list = facts.sets[age] ?? const <Level>[];
      return list.isNotEmpty && list.every(solved);
    }

    // Herhangi bir dünyanın (yaş seti + dünya) tüm seviyeleri 3 yıldız.
    bool perfectWorld() {
      for (final list in facts.sets.values) {
        final worlds = <int, List<Level>>{};
        for (final l in list) {
          (worlds[l.world] ??= []).add(l);
        }
        if (worlds.values.any((w) => w.every((l) => stars(l) >= 3))) {
          return true;
        }
      }
      return false;
    }

    // Mekaniğin ilk göründüğü 13+ seviyesi çözüldü mü.
    bool mechanicSolved(CellType cell) {
      final list = facts.sets[AgeGroup.ages13plus] ?? const <Level>[];
      final intro = list.where((l) => l.hasCell(cell)).firstOrNull;
      return intro != null && solved(intro);
    }

    int value(AchievementDef def) => switch (def.key) {
      Achievements.tutorialDone => facts.tutorialCompleted ? 1 : 0,
      Achievements.firstLevel => levels.any(solved) ? 1 : 0,
      Achievements.firstPerfect => levels.any((l) => stars(l) >= 3) ? 1 : 0,
      Achievements.lastLife => facts.solvedOnLastLife ? 1 : 0,
      Achievements.perfectWorld => perfectWorld() ? 1 : 0,
      Achievements.friends4 || Achievements.friends8 => friends,
      final k when worldAchievements.containsKey(k) =>
        setSolved(worldAchievements[k]!) ? 1 : 0,
      final k when mechanicAchievements.containsKey(k) =>
        mechanicSolved(mechanicAchievements[k]!) ? 1 : 0,
      final k when k.startsWith('stars_') => totalStars,
      _ => 0,
    };

    return {
      for (final def in Achievements.all)
        def.key: AchievementProgress(
          def.key,
          value(def).clamp(0, def.target),
          def.target,
        ),
    };
  }
}
