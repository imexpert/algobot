import '../models/age_config.dart';
import '../models/command.dart';
import '../models/level.dart';
import 'sim_state.dart';
import 'simulator.dart';

class SolveResult {
  const SolveResult(this.solution, this.count);

  /// Bulunan en kısa çözümlerden biri.
  final List<Command> solution;

  /// Aynı uzunluktaki farklı en kısa komut dizilerinin sayısı.
  final int count;

  int get length => solution.length;
}

/// Katman katman BFS. Durum = (konum, yön, toplananlar, anahtar);
/// geçişler simülatörün [Simulator.step] fonksiyonuyla hesaplanır.
class Solver {
  const Solver._();

  /// `requireAll`: hedefe tüm toplanabilirlerle mi ulaşılmalı.
  /// `commands`: varsayılan, oyuncunun paletteki kartları.
  /// `from`: aramanın başladığı durum (varsayılan: seviye başlangıcı).
  /// `maxDepth`: bulunacak çözümün en fazla uzunluğu.
  static SolveResult? solve(
    Level level, {
    bool requireAll = true,
    List<Command>? commands,
    int maxDepth = 60,
    SimState? from,
  }) {
    final cmds = commands ?? level.paletteCommands;
    final fullMask = (1 << level.collectibles.length) - 1;
    final start = from ?? Simulator.initialState(level);

    final depthOf = <SimState, int>{start: 0};
    final ways = <SimState, int>{start: 1};
    final parent = <SimState, (SimState, Command)>{};
    var frontier = [start];

    for (var depth = 0; depth < maxDepth && frontier.isNotEmpty; depth++) {
      var count = 0;
      List<Command>? first;
      final next = <SimState>[];
      for (final s in frontier) {
        for (final c in cmds) {
          final r = Simulator.step(level, s, c);
          if (r.crashed) continue;
          if (r.reachedGoal) {
            // Hedefe girince program biter; eksik toplama çıkmaz sokaktır.
            if (!requireAll || r.state.collectedMask == fullMask) {
              count += ways[s]!;
              first ??= [..._path(parent, s), c];
            }
            continue;
          }
          final ns = r.state;
          final d = depthOf[ns];
          if (d == null) {
            depthOf[ns] = depth + 1;
            ways[ns] = ways[s]!;
            parent[ns] = (s, c);
            next.add(ns);
          } else if (d == depth + 1) {
            ways[ns] = ways[ns]! + ways[s]!;
          }
        }
      }
      if (first != null) return SolveResult(first, count);
      frontier = next;
    }
    return null;
  }

  static List<Command> _path(
    Map<SimState, (SimState, Command)> parent,
    SimState end,
  ) {
    final result = <Command>[];
    var s = end;
    while (parent.containsKey(s)) {
      final (prev, c) = parent[s]!;
      result.add(c);
      s = prev;
    }
    return result.reversed.toList();
  }
}
