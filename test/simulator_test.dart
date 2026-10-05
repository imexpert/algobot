import 'dart:math';

import 'package:algobot/engine/run_result.dart';
import 'package:algobot/engine/simulator.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/direction.dart';
import 'package:algobot/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

Level _level(List<String> map, {Direction dir = Direction.east}) => Level(
  id: 0,
  ageGroup: AgeGroup.ages13plus,
  textKey: 'test',
  map: map,
  startDirection: dir,
  availableCommands: Command.values,
  maxSlots: 20,
  optimalLength: 1,
  referenceSolution: const [],
);

const f = Command.forward;
const r = Command.turnRight;
const l = Command.turnLeft;
const up = Command.moveUp;
const down = Command.moveDown;
const left = Command.moveLeft;
const right = Command.moveRight;

void main() {
  group('Yön tablosu', () {
    const rightOf = {
      Direction.north: Direction.east,
      Direction.east: Direction.south,
      Direction.south: Direction.west,
      Direction.west: Direction.north,
    };
    const leftOf = {
      Direction.north: Direction.west,
      Direction.west: Direction.south,
      Direction.south: Direction.east,
      Direction.east: Direction.north,
    };
    for (final d in Direction.values) {
      test('$d sağa → ${rightOf[d]}', () => expect(d.turnRight, rightOf[d]));
      test('$d sola → ${leftOf[d]}', () => expect(d.turnLeft, leftOf[d]));
    }

    test('Dönüş komutu yer değiştirmez', () {
      final level = _level(['R..', '...', '..G']);
      final result = Simulator.run(level, [r, l, l]);
      expect(result.steps.map((s) => s.toDirection), [
        Direction.south,
        Direction.east,
        Direction.north,
      ]);
      expect(result.steps.every((s) => s.toPosition == level.start), isTrue);
    });
  });

  group('Temel kurallar', () {
    test('Duvara çarpma programı durdurur, robot yerinde kalır', () {
      final result = Simulator.run(_level(['R#G']), [f, f, f]);
      expect(result.outcome, RunOutcome.crashed);
      expect(result.steps, hasLength(1));
      expect(result.steps.single.crashed, isTrue);
      expect(result.steps.single.toPosition, const Point(0, 0));
    });

    test('Izgara dışına çıkmak çarpma sayılır', () {
      final level = _level(['R.G'], dir: Direction.west);
      final result = Simulator.run(level, [f, r]);
      expect(result.outcome, RunOutcome.crashed);
      expect(result.steps.single.toPosition, level.start);
    });

    test('Hedefe ulaşınca kalan komutlar çalışmaz', () {
      final result = Simulator.run(_level(['RG.']), [f, f, f]);
      expect(result.outcome, RunOutcome.success);
      expect(result.steps, hasLength(1));
      expect(result.programLength, 3);
    });

    test('Program biter ama hedef yoksa stoppedShort', () {
      final result = Simulator.run(_level(['R.G']), [f]);
      expect(result.outcome, RunOutcome.stoppedShort);
    });

    test('Toplanabilir bir kez toplanır', () {
      final result = Simulator.run(_level(['RB.', '..G']), [
        f, r, r, f, r, r, f, f, r, f, //
      ]);
      expect(result.outcome, RunOutcome.success);
      expect(result.collectedCount, 1);
      expect(result.steps.expand((s) => s.collected), hasLength(1));
    });
  });

  group('Mutlak yön komutları', () {
    test('Önce o yöne döner, sonra bir kare ilerler', () {
      final level = _level(['R..', '...', '..G'], dir: Direction.west);
      final result = Simulator.run(level, [down, right, up]);
      final s = result.steps;
      expect(s[0].toDirection, Direction.south);
      expect(s[0].toPosition, const Point(0, 1));
      expect(s[1].toDirection, Direction.east);
      expect(s[1].toPosition, const Point(1, 1));
      expect(s[2].toDirection, Direction.north);
      expect(s[2].toPosition, const Point(1, 0));
    });

    test('Mutlak komutla duvara çarpma; yön yine değişir', () {
      final level = _level(['R.G', '#..']);
      final result = Simulator.run(level, [down, right]);
      expect(result.outcome, RunOutcome.crashed);
      expect(result.steps.single.toPosition, level.start);
      expect(result.steps.single.toDirection, Direction.south);
      expect(Simulator.run(level, [left]).outcome, RunOutcome.crashed);
    });
  });

  group('Buz', () {
    test('Tek komutla birden çok kare kayar, tek adım sayılır', () {
      final result = Simulator.run(_level(['RIII.#', '.....G']), [f]);
      final step = result.steps.single;
      expect(step.toPosition, const Point(4, 0));
      expect(step.motions.map((m) => m.kind), [
        MotionKind.walk,
        MotionKind.slide,
        MotionKind.slide,
        MotionKind.slide,
      ]);
    });

    test('Buz üstünde duvara kayınca çarpmadan durur', () {
      final result = Simulator.run(_level(['RII#', '...G']), [f, r]);
      expect(result.outcome, RunOutcome.stoppedShort);
      expect(result.steps.first.crashed, isFalse);
      expect(result.steps.first.toPosition, const Point(2, 0));
    });

    test('Izgara kenarında da çarpmadan durur', () {
      final result = Simulator.run(_level(['RII', 'G..']), [f]);
      expect(result.steps.single.crashed, isFalse);
      expect(result.steps.single.toPosition, const Point(2, 0));
    });

    test('Kayarken toplanabilir toplar', () {
      final result = Simulator.run(_level(['RIbI.', '....G']), [f]);
      expect(result.steps.single.collected, [const Point(2, 0)]);
      expect(result.steps.single.toPosition, const Point(4, 0));
    });

    test('Kayarak hedefe girerse kazanır', () {
      final result = Simulator.run(_level(['RIIG.']), [f, r]);
      expect(result.outcome, RunOutcome.success);
      expect(result.steps, hasLength(1));
    });

    test('Buzda dönüş yerinde olur, kaymaz', () {
      final result = Simulator.run(_level(['RI.', '..G']), [f, r]);
      expect(result.steps[0].toPosition, const Point(2, 0));
      expect(result.steps[1].toPosition, const Point(2, 0));
    });
  });

  group('Portal', () {
    test('Yönü koruyarak ışınlanır ve varış portalında durur', () {
      final level = _level(['RP..', '#..#', 'G.p.']);
      final result = Simulator.run(level, [f]);
      final step = result.steps.single;
      expect(step.toPosition, const Point(2, 2));
      expect(step.toDirection, Direction.east);
      expect(step.motions.map((m) => m.kind), [
        MotionKind.walk,
        MotionKind.teleport,
      ]);
      // Sonraki komut normal işler: doğuya bir kare.
      final next = Simulator.run(level, [f, f]);
      expect(next.steps[1].toPosition, const Point(3, 2));
    });

    test('Ters yönden de çalışır (p → P)', () {
      final level = _level(['P.G', '...', '.pR'], dir: Direction.west);
      final result = Simulator.run(level, [f]);
      expect(result.steps.single.toPosition, const Point(0, 0));
    });
  });

  group('Anahtar ve kapı', () {
    test('Anahtarsız kapı duvar gibidir', () {
      final result = Simulator.run(_level(['RDG']), [f]);
      expect(result.outcome, RunOutcome.crashed);
    });

    test('Anahtar alınınca kapıdan geçilir', () {
      final level = _level(['RK.', '#D#', '.G.']);
      final result = Simulator.run(level, [f, r, f, f]);
      expect(result.steps[0].keyCollected, const Point(1, 0));
      expect(result.outcome, RunOutcome.success);
      expect(result.collectedCount, 0, reason: 'Anahtar toplanabilir sayılmaz');
    });
  });
}
