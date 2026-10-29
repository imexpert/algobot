import 'dart:math';

import '../models/cell.dart';
import '../models/command.dart';
import '../models/level.dart';
import '../models/program.dart';
import 'run_result.dart';
import 'sim_state.dart';

/// Tek bir komutun sonucu.
class StepOutcome {
  const StepOutcome({
    required this.state,
    required this.motions,
    required this.collected,
    required this.keyCollected,
    required this.crashed,
    required this.reachedGoal,
  });

  final SimState state;
  final List<Motion> motions;
  final List<Point<int>> collected;
  final Point<int>? keyCollected;
  final bool crashed;
  final bool reachedGoal;
}

/// Programı çalıştırıp adım listesini üreten saf Dart simülatörü.
/// Çözücü de aynı [step] fonksiyonunu kullanır.
class Simulator {
  const Simulator._();

  static SimState initialState(Level level) =>
      SimState(position: level.start, direction: level.startDirection);

  static bool _passable(Level level, Point<int> p, bool hasKey) {
    if (!level.isInside(p)) return false;
    return switch (level.cellAt(p)) {
      CellType.wall => false,
      CellType.door => hasKey,
      _ => true,
    };
  }

  static StepOutcome step(Level level, SimState state, Command command) {
    if (command.isTurn) {
      final dir = command == Command.turnRight
          ? state.direction.turnRight
          : state.direction.turnLeft;
      return StepOutcome(
        state: state.copyWith(direction: dir),
        motions: const [],
        collected: const [],
        keyCollected: null,
        crashed: false,
        reachedGoal: false,
      );
    }

    final dir = command.absoluteDirection ?? state.direction;
    var pos = state.position;
    var mask = state.collectedMask;
    var hasKey = state.hasKey;
    final motions = <Motion>[];
    final collected = <Point<int>>[];
    Point<int>? keyCollected;
    var reachedGoal = false;

    void enter(Point<int> p, MotionKind kind) {
      pos = p;
      motions.add(Motion(p, kind));
      final i = level.collectibles.indexOf(p);
      if (i >= 0 && mask & (1 << i) == 0) {
        mask |= 1 << i;
        collected.add(p);
      }
      if (!hasKey && level.keys.contains(p)) {
        hasKey = true;
        keyCollected = p;
      }
      if (p == level.goal) reachedGoal = true;
    }

    Point<int> ahead(Point<int> p) => Point(p.x + dir.dx, p.y + dir.dy);

    final target = ahead(pos);
    if (!_passable(level, target, hasKey)) {
      return StepOutcome(
        state: state.copyWith(direction: dir),
        motions: const [],
        collected: const [],
        keyCollected: null,
        crashed: true,
        reachedGoal: false,
      );
    }

    enter(target, MotionKind.walk);
    while (!reachedGoal) {
      final partner = level.portalPartner(pos);
      if (partner != null) {
        // Işınlanır, yönü korur ve varış portalında durur.
        enter(partner, MotionKind.teleport);
        break;
      }
      if (level.cellAt(pos) != CellType.ice) break;
      // Buzda kaymaya devam; önü kapalıysa çarpmadan durur.
      final next = ahead(pos);
      if (!_passable(level, next, hasKey)) break;
      enter(next, MotionKind.slide);
    }

    return StepOutcome(
      state: SimState(
        position: pos,
        direction: dir,
        collectedMask: mask,
        hasKey: hasKey,
      ),
      motions: motions,
      collected: collected,
      keyCollected: keyCollected,
      crashed: false,
      reachedGoal: reachedGoal,
    );
  }

  /// Düz komut listesi (Dünya 1 ve testler).
  static RunResult run(Level level, List<Command> program) =>
      runProgram(level, [for (final c in program) Move(c)]);

  /// Döngülü/çarpanlı programı açıp çalıştırır. Adımlar hangi karttan
  /// geldiğini ([RunStep.index]) ve kaçıncı turda olduğunu bilir.
  /// `programLength` şeritteki kart sayısıdır.
  static RunResult runProgram(Level level, List<Instruction> program) {
    var state = initialState(level);
    final steps = <RunStep>[];
    var outcome = RunOutcome.stoppedShort;

    for (final e in expandProgram(program)) {
      final r = step(level, state, e.command);
      steps.add(
        RunStep(
          index: e.token,
          command: e.command,
          fromPosition: state.position,
          toPosition: r.state.position,
          fromDirection: state.direction,
          toDirection: r.state.direction,
          motions: r.motions,
          collected: r.collected,
          keyCollected: r.keyCollected,
          crashed: r.crashed,
          reachedGoal: r.reachedGoal,
          loopToken: e.loopToken,
          iteration: e.iteration,
          iterations: e.iterations,
        ),
      );
      state = r.state;
      if (r.crashed) {
        outcome = RunOutcome.crashed;
        break;
      }
      if (r.reachedGoal) {
        outcome = RunOutcome.success;
        break;
      }
    }

    return RunResult(
      steps: steps,
      outcome: outcome,
      collectedCount: _bitCount(state.collectedMask),
      programLength: program.length,
    );
  }

  static int _bitCount(int v) {
    var c = 0;
    for (var x = v; x != 0; x &= x - 1) {
      c++;
    }
    return c;
  }
}
