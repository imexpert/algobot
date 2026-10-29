import '../models/cell.dart';
import '../models/level.dart';

/// Seviyeyi, verilen mekaniğin kareleri duvara çevrilmiş haliyle üretir.
/// "Bu mekanik olmadan çözüm var mı?" sorusu için kullanılır.
Level withoutMechanic(Level level, CellType mechanic) =>
    _remap(level, switch (mechanic) {
      CellType.ice => 'Ib',
      CellType.door => 'D',
      CellType.portalA || CellType.portalB => 'Pp',
      _ => '',
    }, '#');

/// Verilen harita karakterlerini zemine çevirir (ör. kapıları açık say).
Level withoutMechanicAsFloor(Level level, String chars) =>
    _remap(level, chars, '.');

Level _remap(Level level, String chars, String to) => Level(
  id: level.id,
  ageGroup: level.ageGroup,
  textKey: level.textKey,
  map: [
    for (final row in level.map)
      row.split('').map((c) => chars.contains(c) ? to : c).join(),
  ],
  startDirection: level.startDirection,
  availableCommands: level.availableCommands,
  maxSlots: level.maxSlots,
  optimalLength: level.optimalLength,
  referenceSolution: level.referenceSolution,
  referenceProgram: level.referenceProgram,
  world: level.world,
  number: level.number,
  introGlyphs: level.introGlyphs,
);
