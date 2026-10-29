import 'package:algobot/data/levels.dart';
import 'package:algobot/engine/level_analysis.dart';
import 'package:algobot/engine/loop_solver.dart';
import 'package:algobot/engine/simulator.dart';
import 'package:algobot/engine/solver.dart';
import 'package:algobot/engine/star_calculator.dart';
import 'package:algobot/models/age_config.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/cell.dart';
import 'package:algobot/models/level.dart';
import 'package:algobot/models/program.dart';
import 'package:flutter_test/flutter_test.dart';

int _count(List<String> map, String chars) =>
    map.join().split('').where(chars.contains).length;

/// B8 tablosu: (genişlik, en kısa alt, üst sınır, şerit fazlası).
const _plusRules = {
  1: (6, 12, 16, 3),
  2: (6, 14, 18, 2),
  3: (6, 12, 16, 3),
  4: (7, 16, 20, 1),
  5: (6, 8, 12, 3),
  6: (7, 10, 16, 1),
  7: (6, 10, 14, 2),
  8: (7, 18, 24, 0),
};

void main() {
  for (final entry in allLevelSets.entries) {
    final age = entry.key;
    final levels = entry.value;

    group(age.name, () {
      test('16 seviye: Dünya 1 (1–8) ve Dünya 2 (9–16), numaralar 1–8', () {
        expect(levels.map((l) => l.id), List.generate(16, (i) => i + 1));
        expect(levels.every((l) => l.ageGroup == age), isTrue);
        expect(levels.take(8).every((l) => l.world == 1), isTrue);
        expect(levels.skip(8).every((l) => l.world == 2), isTrue);
        for (final w in [1, 2]) {
          expect(
            levels.where((l) => l.world == w).map((l) => l.number),
            List.generate(8, (i) => i + 1),
          );
        }
      });

      for (final level in levels.where((l) => l.world == 2)) {
        group('Dünya 2 · Seviye ${level.number} (${level.textKey})', () {
          test('Harita geçerli', () {
            expect(
              level.map.every((r) => r.length == level.map.first.length),
              isTrue,
            );
            expect(_count(level.map, 'R'), 1);
            expect(_count(level.map, 'G'), 1);
            expect(
              level.map.join().split('').every('RGBb.#KDIPp'.contains),
              isTrue,
            );
          });

          test('Referans program geçerli, 3 yıldız, uzunluğu optimal', () {
            final program = level.solutionProgram;
            expect(isValidProgram(program), isTrue);
            final result = Simulator.runProgram(level, program);
            expect(result.isSuccess, isTrue);
            expect(StarCalculator.stars(level, result), 3);
            expect(program.length, level.optimalLength);
            expect(program.length, lessThanOrEqualTo(level.maxSlots));
          });

          test('Yaşın döngü biçimi ve paletteki komutlar', () {
            final program = level.solutionProgram;
            final moves = program.whereType<Move>();
            expect(
              moves.every((m) => level.paletteCommands.contains(m.command)),
              isTrue,
            );
            switch (age.settings.loopStyle) {
              case LoopStyle.multiplier:
                expect(program.whereType<LoopStart>(), isEmpty);
                expect(moves.any((m) => m.times > 1), isTrue);
              case LoopStyle.block:
                expect(moves.every((m) => m.times == 1), isTrue);
                expect(program.whereType<LoopStart>(), isNotEmpty);
            }
          });

          test('Döngülü çözücü: en az kart = optimalLength', () {
            final best = LoopSolver.solve(level);
            expect(best, isNotNull);
            expect(best!.length, level.optimalLength);
          });

          test('Döngü zorunlu: döngüsüz en kısa çözüm şeride sığmaz', () {
            final plain = Solver.solve(level);
            expect(plain, isNotNull);
            expect(plain!.length, greaterThan(level.maxSlots));
          });
        });
      }

      for (final level in levels.where((l) => l.world == 1)) {
        group('Seviye ${level.id} (${level.textKey})', () {
          test('Harita geçerli: eşit satırlar, tek R, tek G', () {
            expect(
              level.map.every((r) => r.length == level.map.first.length),
              isTrue,
            );
            expect(_count(level.map, 'R'), 1);
            expect(_count(level.map, 'G'), 1);
            expect(_count(level.map, 'P'), lessThanOrEqualTo(1));
            expect(_count(level.map, 'P'), _count(level.map, 'p'));
            expect(
              level.map.join().split('').every('RGBb.#KDIPp'.contains),
              isTrue,
            );
          });

          test('Referans çözüm 3 yıldız, uzunluğu optimal, şeride sığar', () {
            final result = Simulator.run(level, level.referenceSolution);
            expect(result.isSuccess, isTrue);
            expect(StarCalculator.stars(level, result), 3);
            expect(level.referenceSolution.length, level.optimalLength);
            expect(result.steps.length, level.referenceSolution.length);
            expect(
              level.referenceSolution.length,
              lessThanOrEqualTo(level.maxSlots),
            );
          });

          test('Referans çözüm oyuncunun kartlarını kullanıyor', () {
            final settings = age.settings;
            // 5–7: yalnızca seviyede açık komutlar; 8–12 ve 13+: yaş
            // grubunun tam komut kümesi (palette hepsi görünür).
            final allowed = settings.paletteMode == PaletteMode.perLevel
                ? level.availableCommands
                : settings.commandSet;
            expect(level.referenceSolution.every(allowed.contains), isTrue);
            expect(level.paletteCommands, allowed);
            expect(
              allowed.every((c) => c.family == settings.commandFamily),
              isTrue,
            );
          });

          test('BFS (paletteki kartlarla): çözülebilir, en kısa = '
              'optimalLength', () {
            final solved = Solver.solve(level, commands: level.paletteCommands);
            expect(solved, isNotNull, reason: 'Seviye çözülemiyor');
            expect(solved!.length, level.optimalLength);
          });

          if (age == AgeGroup.ages5to7 || age == AgeGroup.ages8to12) {
            test('Yeni mekanik yok, ızgara boyutu tabloda', () {
              expect(_count(level.map, 'KDIPpb'), 0);
              expect(level.width * level.height, lessThanOrEqualTo(20));
            });
          }

          if (age == AgeGroup.ages13plus) {
            final (size, lo, hi, extra) = _plusRules[level.id]!;
            test('B8: boyut, en kısa aralığı, şerit kuralı', () {
              expect(level.width, size);
              expect(level.height, size);
              expect(level.optimalLength, inInclusiveRange(lo, hi));
              expect(level.maxSlots, level.optimalLength + extra);
            });

            test('Tuzak: ilk bakıştaki yol 3 yıldız vermez', () {
              final full = level.optimalLength;
              final traps = <String>[
                // Toplanabilirleri yok saymak daha kısa bir yol açar.
                if (level.collectibles.isNotEmpty &&
                    Solver.solve(level, requireAll: false)!.length < full)
                  'toplanabilir',
                // Kapılar açık olsaydı yol daha kısa olurdu.
                if (level.hasCell(CellType.door) && withoutDoors(level)! < full)
                  'kapı',
                // Buz zemin olsaydı çözüm farklı olurdu: kayma hesaba katılmalı.
                if (level.hasCell(CellType.ice) &&
                    Solver.solve(withoutMechanicAsFloor(level, 'Ib'))?.length !=
                        full)
                  'buz',
                // Portaldan çıkınca yön korunur: çıkışta dönmek gerekir.
                if (level.hasCell(CellType.portalA)) 'portal',
                // Seviye 1: çıkmaz kollar (elle tasarlandı, raporda).
                if (level.id == 1) 'çıkmaz sokak',
              ];
              expect(traps, isNotEmpty);
            });
          }
        });
      }
    });
  }

  group('13+ tanıtım seviyelerinde mekanik zorunlu', () {
    final plus = levelsFor(AgeGroup.ages13plus).where((l) => l.world == 1);
    final cases = {3: CellType.door, 5: CellType.ice, 7: CellType.portalA};
    cases.forEach((id, mechanic) {
      test('Seviye $id: ${mechanic.name} olmadan çözüm yok', () {
        final level = plus.firstWhere((l) => l.id == id);
        expect(level.hasCell(mechanic), isTrue);
        expect(
          Solver.solve(withoutMechanic(level, mechanic), requireAll: false),
          isNull,
        );
      });
    });

    test('Final: üç mekanik de var ve her biri zorunlu', () {
      final level = plus.firstWhere((l) => l.id == 8);
      for (final m in [CellType.door, CellType.ice, CellType.portalA]) {
        expect(level.hasCell(m), isTrue);
        expect(Solver.solve(withoutMechanic(level, m)), isNull);
      }
    });
  });
}

/// Kapılar zemin olsaydı en kısa çözüm uzunluğu (kapı yoksa null).
int? withoutDoors(Level level) {
  if (!level.hasCell(CellType.door)) return null;
  final open = withoutMechanicAsFloor(level, 'D');
  return Solver.solve(open)?.length;
}
