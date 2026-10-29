import '../data/levels.dart';
import '../models/age_group.dart';
import '../models/cell.dart';
import '../models/level.dart';

/// 13+ mekanikleri ve tanıtım adları (`mechanic_intro_seen_<ad>`).
const mechanicCells = {
  'door': CellType.door,
  'ice': CellType.ice,
  'portal': CellType.portalA,
};

/// Seviye bir 13+ mekaniğinin ilk göründüğü seviyeyse o mekaniğin adı
/// (`door`, `ice`, `portal`); değilse null.
String? mechanicIntroFor(Level level) {
  if (level.ageGroup != AgeGroup.ages13plus) return null;
  final levels = levelsFor(level.ageGroup);
  for (final MapEntry(key: name, value: cell) in mechanicCells.entries) {
    if (!level.hasCell(cell)) continue;
    final first = levels.where((l) => l.hasCell(cell)).firstOrNull;
    if (first?.id == level.id) return name;
  }
  return null;
}
