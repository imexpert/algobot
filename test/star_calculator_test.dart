import 'package:algobot/engine/simulator.dart';
import 'package:algobot/engine/star_calculator.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/direction.dart';
import 'package:algobot/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

const f = Command.forward;
const r = Command.turnRight;
const l = Command.turnLeft;

Level _level(List<String> map, int optimal) => Level(
  id: 0,
  ageGroup: AgeGroup.ages8to12,
  textKey: 'test',
  map: map,
  startDirection: Direction.east,
  availableCommands: Command.values,
  maxSlots: 20,
  optimalLength: optimal,
  referenceSolution: const [],
);

int _stars(Level level, List<Command> program) =>
    StarCalculator.stars(level, Simulator.run(level, program));

void main() {
  final level = _level(['.B.', 'R.G'], 7);

  test('Başarısız çalışma 0 yıldız', () {
    expect(_stars(level, [f]), 0);
    expect(_stars(level, [r, f]), 0);
  });

  test('1 yıldız: hedefe ulaştı, toplanabilir eksik', () {
    expect(_stars(level, [f, f]), 1);
  });

  test('2 yıldız: hepsi toplandı, fazla komut', () {
    expect(_stars(level, [f, l, f, r, f, r, l, r, f]), 2);
  });

  test('3 yıldız: hepsi toplandı ve en kısa uzunluk', () {
    expect(_stars(level, [f, l, f, r, f, r, f]), 3);
  });

  test('Toplanabilirsiz seviyede 2. yıldız otomatik', () {
    final none = _level(['R.G'], 2);
    expect(_stars(none, [f, f]), 3);
    expect(_stars(none, [r, l, f, f]), 2);
  });

  test('Hedef sonrası fazladan kartlar da uzunluğa sayılır', () {
    expect(_stars(_level(['R.G'], 2), [f, f, f]), 2);
  });
}
