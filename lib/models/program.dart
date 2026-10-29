import 'command.dart';

/// Program şeridindeki tek bir kart. Her talimat bir yuva kaplar.
sealed class Instruction {
  const Instruction();

  /// Kalıcı kayıt biçimi: `forward`, `forward*3`, `loop4`, `end`.
  String encode();
}

/// Bir komut; 5–7'de çarpanla tekrarlanabilir (→ ×3).
final class Move extends Instruction {
  const Move(this.command, {this.times = 1})
    : assert(times >= 1 && times <= Move.maxTimes);

  final Command command;
  final int times;

  static const maxTimes = 5;

  Move withTimes(int t) => Move(command, times: t);

  @override
  String encode() => times == 1 ? command.name : '${command.name}*$times';

  @override
  bool operator ==(Object other) =>
      other is Move && other.command == command && other.times == times;

  @override
  int get hashCode => Object.hash(command, times);

  @override
  String toString() => times == 1 ? command.name : '${command.name}×$times';
}

/// Döngü başı: kendisiyle eşleşen [LoopEnd] arasındaki kartlar [count]
/// kez çalışır (8–12 ve 13+). Döngüler iç içe olamaz.
final class LoopStart extends Instruction {
  const LoopStart(this.count)
    : assert(count >= LoopStart.minCount && count <= LoopStart.maxCount);

  final int count;

  static const minCount = 2;
  static const maxCount = 5;

  @override
  String encode() => 'loop$count';

  @override
  bool operator ==(Object other) => other is LoopStart && other.count == count;

  @override
  int get hashCode => count.hashCode;

  @override
  String toString() => '↻$count[';
}

final class LoopEnd extends Instruction {
  const LoopEnd();

  @override
  String encode() => 'end';

  @override
  bool operator ==(Object other) => other is LoopEnd;

  @override
  int get hashCode => 0;

  @override
  String toString() => ']';
}

/// Açılmış programın tek bir adımı: hangi komut, hangi karttan, kaçıncı tur.
class ExpandedStep {
  const ExpandedStep(
    this.command,
    this.token, {
    this.loopToken,
    this.iteration = 1,
    this.iterations = 1,
  });

  final Command command;

  /// Komutun geldiği kartın şeritteki sırası.
  final int token;

  /// İçinde bulunduğu döngünün başlangıç kartı (yoksa null).
  final int? loopToken;
  final int iteration;
  final int iterations;
}

/// Programı tek tek komutlara açar. Eşleşmeyen döngü başı programın
/// sonuna kadar sürer; eşleşmeyen döngü sonu yok sayılır.
List<ExpandedStep> expandProgram(List<Instruction> program) {
  final out = <ExpandedStep>[];
  void emitMove(Move m, int token, {int? loop, int it = 1, int its = 1}) {
    for (var t = 0; t < m.times; t++) {
      out.add(
        ExpandedStep(
          m.command,
          token,
          loopToken: loop,
          iteration: loop == null ? t + 1 : it,
          iterations: loop == null ? m.times : its,
        ),
      );
    }
  }

  var i = 0;
  while (i < program.length) {
    final ins = program[i];
    switch (ins) {
      case Move():
        emitMove(ins, i);
        i++;
      case LoopEnd():
        i++;
      case LoopStart(:final count):
        var end = i + 1;
        while (end < program.length && program[end] is! LoopEnd) {
          end++;
        }
        for (var it = 1; it <= count; it++) {
          for (var j = i + 1; j < end; j++) {
            final body = program[j];
            if (body is Move) {
              emitMove(body, j, loop: i, it: it, its: count);
            }
          }
        }
        i = end + 1;
    }
  }
  return out;
}

/// Döngüler dengeli ve iç içe değil mi.
bool isValidProgram(List<Instruction> program) {
  var open = false;
  for (final ins in program) {
    if (ins is LoopStart) {
      if (open) return false;
      open = true;
    } else if (ins is LoopEnd) {
      if (!open) return false;
      open = false;
    }
  }
  return !open;
}

/// [index]'teki kart bir döngünün içinde mi (başı ile sonu arasında).
bool isInsideLoop(List<Instruction> program, int index) {
  var open = false;
  for (var i = 0; i < program.length && i < index; i++) {
    if (program[i] is LoopStart) open = true;
    if (program[i] is LoopEnd) open = false;
  }
  return open;
}

String encodeProgram(List<Instruction> program) =>
    program.map((i) => i.encode()).join(',');

List<Instruction> decodeProgram(String text) {
  final out = <Instruction>[];
  for (final part in text.split(',')) {
    if (part.isEmpty) continue;
    if (part == 'end') {
      out.add(const LoopEnd());
      continue;
    }
    final loop = RegExp(r'^loop(\d)$').firstMatch(part);
    if (loop != null) {
      final n = int.parse(loop[1]!);
      if (n >= LoopStart.minCount && n <= LoopStart.maxCount) {
        out.add(LoopStart(n));
      }
      continue;
    }
    final m = RegExp(r'^(\w+?)(?:\*(\d))?$').firstMatch(part);
    final command = Command.values.where((c) => c.name == m?[1]).firstOrNull;
    if (command == null) continue;
    final times = int.tryParse(m?[2] ?? '1') ?? 1;
    out.add(Move(command, times: times.clamp(1, Move.maxTimes)));
  }
  return out;
}
