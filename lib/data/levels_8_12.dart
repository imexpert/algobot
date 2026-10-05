import '../models/age_group.dart';
import '../models/command.dart';
import '../models/direction.dart';
import '../models/level.dart';

const _f = Command.forward;
const _r = Command.turnRight;
const _l = Command.turnLeft;

const _all = [_f, _r, _l];

/// 8–12 yaş · Dünya 1 (Fabrika). İlk sürümdeki 8 seviye, değişmeden.
final List<Level> levels8to12 = [
  Level(
    ageGroup: AgeGroup.ages8to12,
    id: 1,
    map: const ['RBG'],
    startDirection: Direction.east,
    availableCommands: const [_f],
    maxSlots: 4,
    optimalLength: 2,
    referenceSolution: const [_f, _f],
    textKey: 'level812n01',
  ),
  Level(
    ageGroup: AgeGroup.ages8to12,
    id: 2,
    map: const ['R.B', '##.', '##G'],
    startDirection: Direction.east,
    availableCommands: const [_f, _r],
    maxSlots: 6,
    optimalLength: 5,
    referenceSolution: const [_f, _f, _r, _f, _f],
    textKey: 'level812n02',
  ),
  Level(
    ageGroup: AgeGroup.ages8to12,
    id: 3,
    map: const ['##G', '##.', 'R.B'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 6,
    optimalLength: 5,
    referenceSolution: const [_f, _f, _l, _f, _f],
    textKey: 'level812n03',
  ),
  Level(
    ageGroup: AgeGroup.ages8to12,
    id: 4,
    map: const ['R.##', '#.##', '#.BG'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 8,
    optimalLength: 7,
    referenceSolution: const [_f, _r, _f, _f, _l, _f, _f],
    textKey: 'level812n04',
  ),
  Level(
    ageGroup: AgeGroup.ages8to12,
    id: 5,
    map: const ['.B.', 'R.G'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 8,
    optimalLength: 7,
    referenceSolution: const [_f, _l, _f, _r, _f, _r, _f],
    textKey: 'level812n05',
  ),
  Level(
    ageGroup: AgeGroup.ages8to12,
    id: 6,
    map: const ['GB.', '##.', 'R..'],
    startDirection: Direction.west,
    availableCommands: _all,
    maxSlots: 12,
    optimalLength: 10,
    referenceSolution: const [_r, _r, _f, _f, _l, _f, _f, _l, _f, _f],
    textKey: 'level812n06',
  ),
  Level(
    ageGroup: AgeGroup.ages8to12,
    id: 7,
    map: const ['R.#G', '#.#B', '#.B.'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 10,
    optimalLength: 10,
    referenceSolution: const [_f, _r, _f, _f, _l, _f, _f, _l, _f, _f],
    textKey: 'level812n07',
  ),
  Level(
    ageGroup: AgeGroup.ages8to12,
    id: 8,
    map: const ['R..#', '##.#', 'B..#', '.###', '..BG'],
    startDirection: Direction.east,
    availableCommands: _all,
    maxSlots: 16,
    optimalLength: 15,
    referenceSolution: const [
      _f, _f, _r, _f, _f, _r, _f, _f, _l, _f, _f, _l, _f, _f, _f, //
    ],
    textKey: 'level812n08',
  ),
];
