import 'dart:math';

import 'age_group.dart';
import 'cell.dart';
import 'command.dart';
import 'direction.dart';
import 'intro_glyph.dart';

/// Bir seviyenin değişmez tanımı. Harita karakterleri:
/// `R` başlangıç, `G` hedef, `B` toplanabilir, `K` anahtar (hepsi zemin),
/// `.` zemin, `#` duvar, `I` buz, `b` buz üstünde toplanabilir,
/// `D` kapı, `P`/`p` portal çifti.
class Level {
  Level({
    required this.id,
    required this.ageGroup,
    required this.textKey,
    required this.map,
    required this.startDirection,
    required this.availableCommands,
    required this.maxSlots,
    required this.optimalLength,
    required this.referenceSolution,
    this.introGlyphs = const [],
  }) : assert(map.isNotEmpty, 'Harita boş olamaz'),
       assert(
         map.every((row) => row.length == map.first.length),
         'Harita satırları aynı uzunlukta olmalı',
       ) {
    for (var y = 0; y < map.length; y++) {
      for (var x = 0; x < map[y].length; x++) {
        final p = Point(x, y);
        switch (map[y][x]) {
          case 'R':
            _start = p;
          case 'G':
            _goal = p;
          case 'B' || 'b':
            _collectibles.add(p);
          case 'K':
            _keys.add(p);
          case 'P':
            _portalA = p;
          case 'p':
            _portalB = p;
        }
      }
    }
    assert(_start != null, 'Haritada R olmalı');
    assert(_goal != null, 'Haritada G olmalı');
    assert(
      (_portalA == null) == (_portalB == null),
      'Portallar çift olmalı (P ve p)',
    );
    assert(_keys.length <= 1, 'Seviye başına en fazla bir anahtar');
  }

  final int id;
  final AgeGroup ageGroup;

  /// Yerelleştirme anahtarı öneki: ARB'de `<textKey>Title` ve
  /// `<textKey>Intro` bulunur (bkz. `l10n/level_texts.dart`).
  final String textKey;
  final List<String> map;
  final Direction startDirection;

  /// Seviyede açık komutlar. Yalnızca 5–7'de (`PaletteMode.perLevel`)
  /// kullanılır; 8–12 ve 13+ paleti yaş grubunun tam komut kümesini
  /// gösterdiği için bu gruplarda oyunda bir anlamı kalmadı (bkz.
  /// `LevelPalette.paletteCommands`).
  final List<Command> availableCommands;
  final int maxSlots;
  final int optimalLength;
  final List<Command> referenceSolution;

  /// İpucu balonundaki görsel anlatım (5–7 yaş).
  final List<IntroGlyph> introGlyphs;

  Point<int>? _start;
  Point<int>? _goal;
  Point<int>? _portalA;
  Point<int>? _portalB;
  final List<Point<int>> _collectibles = [];
  final List<Point<int>> _keys = [];

  int get width => map.first.length;
  int get height => map.length;

  Point<int> get start => _start!;
  Point<int> get goal => _goal!;
  List<Point<int>> get collectibles => List.unmodifiable(_collectibles);
  List<Point<int>> get keys => List.unmodifiable(_keys);
  Point<int>? get portalA => _portalA;
  Point<int>? get portalB => _portalB;

  bool isInside(Point<int> p) =>
      p.x >= 0 && p.y >= 0 && p.x < width && p.y < height;

  CellType cellAt(Point<int> p) => switch (map[p.y][p.x]) {
    '#' => CellType.wall,
    'I' || 'b' => CellType.ice,
    'D' => CellType.door,
    'P' => CellType.portalA,
    'p' => CellType.portalB,
    _ => CellType.floor,
  };

  /// Portal karesinin eşi (portal değilse null).
  Point<int>? portalPartner(Point<int> p) => switch (cellAt(p)) {
    CellType.portalA => _portalB,
    CellType.portalB => _portalA,
    _ => null,
  };

  bool hasCell(CellType type) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (cellAt(Point(x, y)) == type) return true;
      }
    }
    return false;
  }
}
