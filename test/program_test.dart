import 'package:algobot/engine/loop_solver.dart';
import 'package:algobot/engine/run_result.dart';
import 'package:algobot/engine/simulator.dart';
import 'package:algobot/engine/star_calculator.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/direction.dart';
import 'package:algobot/models/level.dart';
import 'package:algobot/models/program.dart';
import 'package:flutter_test/flutter_test.dart';

const f = Move(Command.forward);
const r = Move(Command.turnRight);
const l = Move(Command.turnLeft);

Level _level(
  List<String> map, {
  AgeGroup age = AgeGroup.ages8to12,
  List<Command>? commands,
  int optimal = 1,
}) => Level(
  id: 9,
  world: 2,
  number: 1,
  ageGroup: age,
  textKey: 'test',
  map: map,
  startDirection: Direction.east,
  availableCommands:
      commands ?? const [Command.forward, Command.turnRight, Command.turnLeft],
  maxSlots: 20,
  optimalLength: optimal,
  referenceProgram: const [f],
);

void main() {
  group('Programı açma', () {
    test('Döngü gövdesi tur sayısı kadar, kart sırası ve tur bilgisiyle', () {
      final steps = expandProgram(const [f, LoopStart(3), r, f, LoopEnd(), l]);
      expect(steps.map((s) => s.command), [
        Command.forward,
        Command.turnRight, Command.forward, //
        Command.turnRight, Command.forward,
        Command.turnRight, Command.forward,
        Command.turnLeft,
      ]);
      expect(steps.map((s) => s.token), [0, 2, 3, 2, 3, 2, 3, 5]);
      expect(steps[3].loopToken, 1);
      expect(steps[3].iteration, 2);
      expect(steps[3].iterations, 3);
      expect(steps.last.loopToken, isNull);
    });

    test('Çarpanlı kart kendini tekrarlar', () {
      final steps = expandProgram(const [Move(Command.moveRight, times: 3)]);
      expect(steps, hasLength(3));
      expect(steps.map((s) => s.iteration), [1, 2, 3]);
      expect(steps.every((s) => s.token == 0), isTrue);
    });

    test('Eşleşmeyen parantezler programı bozmaz', () {
      expect(expandProgram(const [LoopStart(2), f]), hasLength(2));
      expect(expandProgram(const [LoopEnd(), f]), hasLength(1));
      expect(isValidProgram(const [LoopStart(2), f]), isFalse);
      expect(isValidProgram(const [LoopEnd()]), isFalse);
      expect(
        isValidProgram(const [LoopStart(2), LoopStart(2), LoopEnd()]),
        isFalse,
        reason: 'İç içe döngü yok',
      );
      expect(isValidProgram(const [LoopStart(2), f, LoopEnd(), r]), isTrue);
    });

    test('Döngü içi konumu', () {
      const p = [f, LoopStart(2), r, LoopEnd(), l];
      expect(isInsideLoop(p, 1), isFalse);
      expect(isInsideLoop(p, 2), isTrue);
      expect(isInsideLoop(p, 3), isTrue, reason: 'Döngü sonu da içeride');
      expect(isInsideLoop(p, 4), isFalse);
    });
  });

  group('Kayıt biçimi', () {
    test('Yaz ve oku', () {
      const p = [
        Move(Command.moveRight, times: 3),
        LoopStart(4),
        f,
        r,
        LoopEnd(),
        l,
      ];
      expect(
        encodeProgram(p),
        'moveRight*3,loop4,forward,turnRight,end,turnLeft',
      );
      expect(decodeProgram(encodeProgram(p)), p);
    });

    test('Eski biçim (yalnızca komut adları) ve bozuk parçalar', () {
      expect(decodeProgram('forward,turnRight'), const [f, r]);
      expect(decodeProgram(''), isEmpty);
      expect(decodeProgram('forward,bogus,loop9,turnLeft'), const [f, l]);
    });
  });

  group('Döngülü çalıştırma', () {
    test('Hedefe döngünün ortasında girilince program biter', () {
      final level = _level(['R...G..']);
      final result = Simulator.runProgram(level, const [
        LoopStart(5),
        f,
        LoopEnd(),
        r,
      ]);
      expect(result.outcome, RunOutcome.success);
      expect(result.steps, hasLength(4));
      expect(result.steps.last.iteration, 4);
      expect(result.programLength, 4);
    });

    test('Döngü içinde çarpınca program durur', () {
      final level = _level(['R.#G']);
      final result = Simulator.runProgram(level, const [
        LoopStart(3),
        f,
        LoopEnd(),
      ]);
      expect(result.outcome, RunOutcome.crashed);
      expect(result.steps, hasLength(2));
      expect(result.steps.last.index, 1, reason: 'Döngü içindeki kart');
    });

    test('Yıldızlar kart sayısına göre (döngüler ödüllenir)', () {
      final level = _level(['R....G'], optimal: 3);
      final loop = Simulator.runProgram(level, const [
        LoopStart(5),
        f,
        LoopEnd(),
      ]);
      final plain = Simulator.runProgram(level, const [f, f, f, f, f]);
      expect(StarCalculator.stars(level, loop), 3);
      expect(StarCalculator.stars(level, plain), 2);
    });
  });

  group('Döngülü çözücü', () {
    test('5–7 çarpan: düz yol tek kart', () {
      final level = _level(
        ['R....G'],
        age: AgeGroup.ages5to7,
        commands: const [Command.moveRight],
      );
      expect(LoopSolver.solve(level), const [
        Move(Command.moveRight, times: 5),
      ]);
    });

    test('8–12 blok: merdiven tek döngü', () {
      final level = _level(['R.###', '#..##', '##..#', '###.G']);
      final best = LoopSolver.solve(level)!;
      expect(best.length, 6);
      expect(best.whereType<LoopStart>(), hasLength(1));
      expect(Simulator.runProgram(level, best).outcome, RunOutcome.success);
    });

    test('Döngü kapalıyken döngüsüz en kısa çözümle aynı', () {
      final level = _level(['R.###', '#..##', '##..#', '###.G']);
      expect(LoopSolver.solve(level, allowLoops: false)!.length, 13);
    });
  });
}
