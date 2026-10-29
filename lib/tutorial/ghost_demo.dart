import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import '../engine/run_result.dart';
import '../engine/sim_state.dart';
import '../engine/simulator.dart';
import '../models/cell.dart';
import '../models/command.dart';
import '../models/direction.dart';
import '../models/level.dart';

/// Hayalet karakterin bir hareketi: bir kareden diğerine.
class GhostMove {
  const GhostMove(this.from, this.to, this.kind);
  final Point<int> from;
  final Point<int> to;
  final MotionKind kind;

  /// Saniye cinsinden süre.
  double get duration => switch (kind) {
    MotionKind.walk => 0.45,
    MotionKind.slide => 0.2,
    MotionKind.teleport => 0.45,
  };
}

/// Mekanik tanıtımında yarı saydam "hayalet" karakterin canlandırması:
/// mekaniği bir kez gösterir, sonra kaybolur.
class GhostDemo {
  GhostDemo(this.moves, this.direction, {this.carriesKey = false})
    : assert(moves.isNotEmpty);

  final List<GhostMove> moves;
  final Direction direction;

  /// Kapı tanıtımı: hayalet anahtarı taşır.
  final bool carriesKey;

  static const fadeIn = 0.3;
  static const fadeOut = 0.5;

  double get duration =>
      fadeIn + moves.fold(0.0, (s, m) => s + m.duration) + fadeOut;

  /// [t] saniyesindeki durum: (kare konumu, opaklık 0..1, ölçek).
  /// Canlandırma bittiyse null.
  (Offset, double, double)? at(double t) {
    if (t < 0 || t > duration) return null;
    Offset of(Point<int> p) => Offset(p.x.toDouble(), p.y.toDouble());
    const alpha = 0.55;
    if (t < fadeIn) return (of(moves.first.from), alpha * t / fadeIn, 1);
    var u = t - fadeIn;
    for (final m in moves) {
      if (u <= m.duration) {
        final k = u / m.duration;
        return switch (m.kind) {
          MotionKind.teleport => (
            of(k < 0.5 ? m.from : m.to),
            alpha,
            (1 - 2 * k).abs().clamp(0.15, 1.0),
          ),
          _ => (Offset.lerp(of(m.from), of(m.to), k)!, alpha, 1),
        };
      }
      u -= m.duration;
    }
    final left = (fadeOut - u) / fadeOut;
    return (of(moves.last.to), alpha * left.clamp(0.0, 1.0), 1);
  }

  /// Seviyedeki mekaniği gösteren canlandırma (bulunamazsa null).
  static GhostDemo? forMechanic(Level level, String mechanic) =>
      switch (mechanic) {
        'ice' => _byMotion(level, MotionKind.slide),
        'portal' => _byMotion(level, MotionKind.teleport),
        'door' => _door(level),
        _ => null,
      };

  /// Tek bir "İleri"nin kayma ya da ışınlanma ürettiği başlangıç aranır;
  /// en uzun kayma seçilir. Portalda çıkıştan bir adım daha yürünür
  /// (yönün değişmediği görünsün).
  static GhostDemo? _byMotion(Level level, MotionKind kind) {
    List<GhostMove>? best;
    Direction? bestDir;
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final p = Point(x, y);
        if (level.cellAt(p) != CellType.floor) continue;
        for (final d in Direction.values) {
          final state = SimState(position: p, direction: d, hasKey: true);
          final r = Simulator.step(level, state, Command.forward);
          if (r.crashed || !r.motions.any((m) => m.kind == kind)) continue;
          final moves = <GhostMove>[];
          var prev = p;
          for (final m in r.motions) {
            moves.add(GhostMove(prev, m.to, m.kind));
            prev = m.to;
          }
          if (kind == MotionKind.teleport && !r.reachedGoal) {
            final after = Simulator.step(level, r.state, Command.forward);
            if (!after.crashed && after.motions.isNotEmpty) {
              moves.add(
                GhostMove(prev, after.motions.first.to, MotionKind.walk),
              );
            }
          }
          if (best == null || moves.length > best.length) {
            best = moves;
            bestDir = d;
          }
        }
      }
    }
    return best == null ? null : GhostDemo(best, bestDir!);
  }

  /// Anahtardan kapıya (ve bir kare ötesine) en kısa yürüyüş.
  static GhostDemo? _door(Level level) {
    if (level.keys.isEmpty) return null;
    final start = level.keys.first;
    bool open(Point<int> p) =>
        level.isInside(p) && level.cellAt(p) != CellType.wall;
    final parent = <Point<int>, Point<int>>{};
    final queue = Queue<Point<int>>()..add(start);
    final seen = {start};
    Point<int>? door;
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      if (level.cellAt(p) == CellType.door) {
        door = p;
        break;
      }
      for (final d in Direction.values) {
        final n = Point(p.x + d.dx, p.y + d.dy);
        if (!open(n) || !seen.add(n)) continue;
        parent[n] = p;
        queue.add(n);
      }
    }
    if (door == null) return null;
    final path = <Point<int>>[door];
    while (path.last != start) {
      path.add(parent[path.last]!);
    }
    final cells = path.reversed.toList();
    // Kapının bir kare ötesi (geçildiği görünsün).
    if (cells.length >= 2) {
      final a = cells[cells.length - 2];
      final b = cells.last;
      final beyond = Point(2 * b.x - a.x, 2 * b.y - a.y);
      if (open(beyond)) cells.add(beyond);
    }
    if (cells.length < 2) return null;
    final moves = [
      for (var i = 1; i < cells.length; i++)
        GhostMove(cells[i - 1], cells[i], MotionKind.walk),
    ];
    final last = moves.last;
    final dir = Direction.values.firstWhere(
      (d) =>
          d.dx == (last.to.x - last.from.x).sign &&
          d.dy == (last.to.y - last.from.y).sign,
      orElse: () => Direction.east,
    );
    return GhostDemo(moves, dir, carriesKey: true);
  }
}
