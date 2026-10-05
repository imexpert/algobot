import '../models/age_group.dart';
import '../models/command.dart';
import '../models/direction.dart';
import '../models/intro_glyph.dart';
import '../models/level.dart';

const _u = Command.moveUp;
const _d = Command.moveDown;
const _l = Command.moveLeft;
const _r = Command.moveRight;

const _all = [_u, _d, _l, _r];

/// 5–7 yaş · Dünya 1. Mutlak yön komutları (↑ ↓ ← →).
/// Başlangıç yönü yalnızca görseldir; mutlak komutlarda çözümü etkilemez.
final List<Level> levels5to7 = [
  Level(
    ageGroup: AgeGroup.ages5to7,
    id: 1,
    map: const ['R.G'],
    startDirection: Direction.east,
    availableCommands: const [_r],
    maxSlots: 3,
    optimalLength: 2,
    referenceSolution: const [_r, _r],
    textKey: 'level57n01',
    introGlyphs: const [IntroGlyph.cardRight, IntroGlyph.then, IntroGlyph.run],
  ),
  Level(
    ageGroup: AgeGroup.ages5to7,
    id: 2,
    map: const ['R', '.', 'G'],
    startDirection: Direction.east,
    availableCommands: const [_r, _d],
    maxSlots: 3,
    optimalLength: 2,
    referenceSolution: const [_d, _d],
    textKey: 'level57n02',
    introGlyphs: const [IntroGlyph.cardDown, IntroGlyph.cardDown],
  ),
  Level(
    ageGroup: AgeGroup.ages5to7,
    id: 3,
    map: const ['RB', '#.', '#G'],
    startDirection: Direction.east,
    availableCommands: const [_r, _d],
    maxSlots: 4,
    optimalLength: 3,
    referenceSolution: const [_r, _d, _d],
    textKey: 'level57n03',
    introGlyphs: const [
      IntroGlyph.cardRight,
      IntroGlyph.then,
      IntroGlyph.cardDown,
    ],
  ),
  Level(
    ageGroup: AgeGroup.ages5to7,
    id: 4,
    map: const ['.G', 'B#', '.R'],
    startDirection: Direction.west,
    availableCommands: _all,
    maxSlots: 5,
    optimalLength: 4,
    referenceSolution: const [_l, _u, _u, _r],
    textKey: 'level57n04',
    introGlyphs: const [IntroGlyph.wall, IntroGlyph.around, IntroGlyph.goal],
  ),
  Level(
    ageGroup: AgeGroup.ages5to7,
    id: 5,
    map: const ['.B.', 'R.G'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 6,
    optimalLength: 4,
    referenceSolution: const [_u, _r, _r, _d],
    textKey: 'level57n05',
    introGlyphs: const [
      IntroGlyph.collectible,
      IntroGlyph.plus,
      IntroGlyph.goal,
    ],
  ),
  Level(
    ageGroup: AgeGroup.ages5to7,
    id: 6,
    map: const ['GB.', '##.', 'R..'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 7,
    optimalLength: 6,
    referenceSolution: const [_r, _r, _u, _u, _l, _l],
    textKey: 'level57n06',
    introGlyphs: const [IntroGlyph.finger, IntroGlyph.then, IntroGlyph.goal],
  ),
  Level(
    ageGroup: AgeGroup.ages5to7,
    id: 7,
    map: const ['R.B', '.#.', 'B.G'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 10,
    optimalLength: 8,
    referenceSolution: const [_r, _r, _l, _l, _d, _d, _r, _r],
    textKey: 'level57n07',
    introGlyphs: const [
      IntroGlyph.collectible,
      IntroGlyph.collectible,
      IntroGlyph.then,
      IntroGlyph.goal,
    ],
  ),
  Level(
    ageGroup: AgeGroup.ages5to7,
    id: 8,
    map: const ['R..#', '##.#', 'B...', '###G'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 12,
    optimalLength: 10,
    referenceSolution: const [_r, _r, _d, _d, _l, _l, _r, _r, _r, _d],
    textKey: 'level57n08',
    introGlyphs: const [
      IntroGlyph.collectible,
      IntroGlyph.then,
      IntroGlyph.goal,
    ],
  ),
];
