import '../models/age_group.dart';
import '../models/command.dart';
import '../models/direction.dart';
import '../models/level.dart';

const _f = Command.forward;
const _r = Command.turnRight;
const _l = Command.turnLeft;

const _all = [_f, _r, _l];

/// 13+ · Dünya 1. Büyük haritalar; anahtar/kapı, buz ve portal.
/// Haritalar `tool/level_report.dart` ile doğrulandı.
final List<Level> levels13plus = [
  Level(
    ageGroup: AgeGroup.ages13plus,
    id: 1,
    map: const ['R.#...', '#...#.', '#.#.#.', '..#...', '.##.#.', '...#.G'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 18,
    optimalLength: 15,
    referenceSolution: const [
      _f, _r, _f, _l, _f, _f, _r, _f, _f, _l, _f, _f, _r, _f, _f, //
    ],
    textKey: 'level13n01',
  ),
  Level(
    ageGroup: AgeGroup.ages13plus,
    id: 2,
    map: const ['###.#G', '..#.#.', '#.#.#.', '#B#.#.', '#.#.#.', '#R.B..'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 20,
    optimalLength: 18,
    referenceSolution: const [
      _l, _f, _f, _r, _r, _f, _f, _l, _f, _f, _f, _f, _l, _f, _f, _f, _f, _f, //
    ],
    textKey: 'level13n02',
  ),
  Level(
    ageGroup: AgeGroup.ages13plus,
    id: 3,
    map: const ['#.....', '#.###.', '#D...G', '#.#.##', 'KR#...', '###.#.'],
    startDirection: Direction.north,
    availableCommands: _all,
    maxSlots: 16,
    optimalLength: 13,
    referenceSolution: const [
      _l, _f, _r, _r, _f, _l, _f, _f, _r, _f, _f, _f, _f, //
    ],
    textKey: 'level13n03',
  ),
  Level(
    ageGroup: AgeGroup.ages13plus,
    id: 4,
    map: const [
      'G#.....',
      'D#.#.#.',
      '.R...#.',
      '.#B###.',
      '.....#.',
      '.#.###.',
      'K#.....',
    ],
    startDirection: Direction.north,
    availableCommands: _all,
    maxSlots: 20,
    optimalLength: 19,
    referenceSolution: const [
      _r,
      _f,
      _r,
      _f,
      _f,
      _r,
      _f,
      _f,
      _l,
      _f,
      _f,
      _r,
      _r,
      _f,
      _f,
      _f,
      _f,
      _f,
      _f, //
    ],
    textKey: 'level13n04',
  ),
  Level(
    ageGroup: AgeGroup.ages13plus,
    id: 5,
    map: const ['#.G...', '#.###.', '#IIIII', '#.#.##', '#.#R..', '#####.'],
    startDirection: Direction.north,
    availableCommands: _all,
    maxSlots: 12,
    optimalLength: 9,
    referenceSolution: const [
      _f, _f, _l, _f, _r, _f, _f, _r, _f, //
    ],
    textKey: 'level13n05',
  ),
  Level(
    ageGroup: AgeGroup.ages13plus,
    id: 6,
    map: const [
      '....III',
      '######.',
      '.#BG.#.',
      '.#.#.#.',
      '...#...',
      '.#####.',
      '..RIII.',
    ],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 16,
    optimalLength: 15,
    referenceSolution: const [
      _r, _r, _f, _f, _r, _f, _f, _r, _f, _f, _l, _f, _f, _r, _f, //
    ],
    textKey: 'level13n06',
  ),
  Level(
    ageGroup: AgeGroup.ages13plus,
    id: 7,
    map: const ['....P.', '####G#', '...p.#', '.#.###', '.R#..#', '######'],
    startDirection: Direction.north,
    availableCommands: _all,
    maxSlots: 13,
    optimalLength: 11,
    referenceSolution: const [
      _l, _f, _r, _f, _f, _r, _f, _f, _f, _r, _f, //
    ],
    textKey: 'level13n07',
  ),
  Level(
    ageGroup: AgeGroup.ages13plus,
    id: 8,
    map: const [
      '..#..D.',
      'G#.#P#.',
      'I#.#.#.',
      'I###B#K',
      'I...p#I',
      '##.###R',
      '...#..I',
    ],
    startDirection: Direction.north,
    availableCommands: _all,
    maxSlots: 21,
    optimalLength: 21,
    referenceSolution: const [
      _f,
      _f,
      _f,
      _f,
      _l,
      _f,
      _f,
      _l,
      _f,
      _r,
      _r,
      _f,
      _f,
      _f,
      _l,
      _f,
      _f,
      _f,
      _f,
      _r,
      _f, //
    ],
    textKey: 'level13n08',
  ),
];
