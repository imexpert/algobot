import 'dart:math';

import '../models/command.dart';
import '../models/direction.dart';

enum RunOutcome { success, crashed, stoppedShort }

enum MotionKind { walk, slide, teleport }

/// Bir adım içindeki tek kare hareketi (animasyon için ara konumlar).
class Motion {
  const Motion(this.to, this.kind);
  final Point<int> to;
  final MotionKind kind;
}

class RunStep {
  const RunStep({
    required this.index,
    required this.command,
    required this.fromPosition,
    required this.toPosition,
    required this.fromDirection,
    required this.toDirection,
    this.motions = const [],
    this.collected = const [],
    this.keyCollected,
    this.crashed = false,
    this.reachedGoal = false,
    this.loopToken,
    this.iteration = 1,
    this.iterations = 1,
  });

  /// Program şeridindeki kartın sırası.
  final int index;
  final Command command;
  final Point<int> fromPosition;
  final Point<int> toPosition;
  final Direction fromDirection;
  final Direction toDirection;

  /// Yürüme, buz kayması ve ışınlanma adımları, sırasıyla.
  final List<Motion> motions;

  /// Bu adımda toplanan toplanabilirlerin konumları.
  final List<Point<int>> collected;

  /// Bu adımda alınan anahtarın konumu.
  final Point<int>? keyCollected;
  final bool crashed;
  final bool reachedGoal;

  /// Döngü içindeyse döngü başı kartının sırası; çarpanlı kartta null.
  final int? loopToken;

  /// Kaçıncı tur / toplam tur (döngü ya da çarpan; tek komutta 1/1).
  final int iteration;
  final int iterations;
}

class RunResult {
  const RunResult({
    required this.steps,
    required this.outcome,
    required this.collectedCount,
    required this.programLength,
  });

  final List<RunStep> steps;
  final RunOutcome outcome;
  final int collectedCount;
  final int programLength;

  bool get isSuccess => outcome == RunOutcome.success;
}
