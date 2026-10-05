// Tüm yaş setlerinin tüm seviyelerini çözer ve raporlar.
// Kullanım: dart run tool/level_report.dart
import 'dart:convert';
import 'dart:io';

import 'package:algobot/data/levels.dart';
import 'package:algobot/engine/level_analysis.dart';
import 'package:algobot/engine/solver.dart';
import 'package:algobot/models/cell.dart';
import 'package:algobot/models/age_config.dart';
import 'package:algobot/models/command.dart';

String _cmd(Command c) => switch (c) {
  Command.forward => 'İ',
  Command.turnRight => 'S',
  Command.turnLeft => 'L',
  Command.moveUp => '↑',
  Command.moveDown => '↓',
  Command.moveLeft => '←',
  Command.moveRight => '→',
};

String _seq(List<Command>? s) => s == null ? '—' : s.map(_cmd).join(' ');

void main() {
  final out = stdout;
  // Başlıklar Türkçe ARB'den (araç saf Dart'ta çalışır).
  final tr =
      jsonDecode(File('lib/l10n/app_tr.arb').readAsStringSync())
          as Map<String, dynamic>;
  for (final entry in allLevelSets.entries) {
    out.writeln('═' * 60);
    out.writeln('SET ${entry.key.name}');
    out.writeln('═' * 60);
    for (final level in entry.value) {
      final full = Solver.solve(level);
      final any = Solver.solve(level, requireAll: false);
      out.writeln(
        '\nSeviye ${level.id} — "${tr['${level.textKey}Title'] ?? level.textKey}"',
      );
      for (final row in level.map) {
        out.writeln('    $row');
      }
      out.writeln('  Palet: ${level.paletteCommands.map(_cmd).join(' ')}');
      out.writeln(
        '  Boyut: ${level.width}×${level.height}'
        '   Başlangıç yönü: ${level.startDirection.name}'
        '   Toplanabilir: ${level.collectibles.length}',
      );
      out.writeln(
        '  En kısa (hepsiyle): ${full?.length ?? '—'}  : ${_seq(full?.solution)}',
      );
      out.writeln('  En kısa çözüm sayısı: ${full?.count ?? 0}');
      out.writeln(
        '  Toplanabilirsiz en kısa: ${any?.length ?? '—'}  : ${_seq(any?.solution)}',
      );
      out.writeln(
        '  Şerit: ${level.maxSlots}   optimalLength: ${level.optimalLength}'
        '${full != null && full.length != level.optimalLength ? '   ⚠ UYUŞMAZLIK' : ''}',
      );
      for (final m in [CellType.door, CellType.ice, CellType.portalA]) {
        if (!level.hasCell(m)) continue;
        final without = Solver.solve(
          withoutMechanic(level, m),
          requireAll: false,
        );
        out.writeln(
          '  ${m.name} olmadan: ${without == null ? 'çözümsüz ✓' : '${without.length} komutla çözülebilir'}',
        );
      }
    }
  }
}
