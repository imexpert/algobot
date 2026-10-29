import '../models/age_config.dart';
import '../models/command.dart';
import '../models/level.dart';
import '../models/program.dart';
import 'sim_state.dart';
import 'simulator.dart';

/// Bir program parçası: şeritte [cards] kart, çalışınca [expanded] komutlar.
class _Segment {
  _Segment(this.cards, this.expanded);
  final List<Instruction> cards;
  final List<Command> expanded;
  int get cost => cards.length;
}

/// En az kartlı çözümü (döngüler ve çarpanlar dahil) bulur.
///
/// Oyun durumları üzerinde Dijkstra: her kenar bir program parçasıdır
/// (tek kart, 5–7'de çarpanlı kart, 8–12/13+'da gövdesi en fazla
/// [maxBody] kart olan döngü); maliyet, parçanın kart sayısıdır. Parçalar
/// art arda çalıştığı için toplam maliyet tam olarak şeritteki kart
/// sayısıdır. Hedefe döngünün ortasında girilirse program orada biter.
class LoopSolver {
  const LoopSolver._();

  static List<Instruction>? solve(
    Level level, {
    bool requireAll = true,
    bool allowLoops = true,
    int maxBody = 4,
    int maxCost = 40,
  }) {
    final segments = _segments(level, allowLoops, maxBody);
    final fullMask = (1 << level.collectibles.length) - 1;
    final start = Simulator.initialState(level);

    final best = <SimState, int>{start: 0};
    final prev = <SimState, (SimState, _Segment)>{};
    final buckets = List.generate(maxCost + 1, (_) => <SimState>[]);
    buckets[0].add(start);

    List<Instruction>? bestProgram;
    var bestCost = maxCost + 1;

    for (var cost = 0; cost <= maxCost && cost < bestCost; cost++) {
      for (final s in buckets[cost]) {
        if (best[s] != cost) continue;
        for (final seg in segments) {
          final next = cost + seg.cost;
          if (next >= bestCost || next > maxCost) continue;
          var st = s;
          var dead = false;
          var goal = false;
          for (final c in seg.expanded) {
            final r = Simulator.step(level, st, c);
            if (r.crashed) {
              dead = true;
              break;
            }
            st = r.state;
            if (r.reachedGoal) {
              goal = true;
              break;
            }
          }
          if (dead) continue;
          if (goal) {
            if (!requireAll || st.collectedMask == fullMask) {
              bestCost = next;
              bestProgram = [..._path(prev, s), ...seg.cards];
            }
            continue;
          }
          if (next < (best[st] ?? maxCost + 1)) {
            best[st] = next;
            prev[st] = (s, seg);
            buckets[next].add(st);
          }
        }
      }
    }
    return bestProgram;
  }

  static List<Instruction> _path(
    Map<SimState, (SimState, _Segment)> prev,
    SimState end,
  ) {
    final parts = <List<Instruction>>[];
    var s = end;
    while (prev.containsKey(s)) {
      final (p, seg) = prev[s]!;
      parts.add(seg.cards);
      s = p;
    }
    return [for (final part in parts.reversed) ...part];
  }

  static List<_Segment> _segments(Level level, bool allowLoops, int maxBody) {
    final cmds = level.paletteCommands;
    final out = [
      for (final c in cmds) _Segment([Move(c)], [c]),
    ];
    if (!allowLoops) return out;
    switch (level.ageGroup.settings.loopStyle) {
      case LoopStyle.multiplier:
        for (final c in cmds) {
          for (var k = 2; k <= Move.maxTimes; k++) {
            out.add(_Segment([Move(c, times: k)], List.filled(k, c)));
          }
        }
      case LoopStyle.block:
        var bodies = <List<Command>>[[]];
        for (var len = 1; len <= maxBody; len++) {
          bodies = [
            for (final b in bodies)
              for (final c in cmds) [...b, c],
          ];
          for (final body in bodies) {
            for (var k = LoopStart.minCount; k <= LoopStart.maxCount; k++) {
              out.add(
                _Segment(
                  [
                    LoopStart(k),
                    for (final c in body) Move(c),
                    const LoopEnd(),
                  ],
                  [for (var i = 0; i < k; i++) ...body],
                ),
              );
            }
          }
        }
    }
    return out;
  }
}
