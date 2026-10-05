import '../models/age_group.dart';
import '../models/level.dart';
import 'levels_13_plus.dart';
import 'levels_5_7.dart';
import 'levels_8_12.dart';

/// Yaş grubuna göre Dünya 1 seviyeleri. Yeni seviye eklemek için ilgili
/// dosyadaki listeye bir `Level` eklemek yeterlidir.
List<Level> levelsFor(AgeGroup age) => switch (age) {
  AgeGroup.ages5to7 => levels5to7,
  AgeGroup.ages8to12 => levels8to12,
  AgeGroup.ages13plus => levels13plus,
};

Map<AgeGroup, List<Level>> get allLevelSets => {
  for (final age in AgeGroup.values) age: levelsFor(age),
};
