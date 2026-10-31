import 'dart:io';
import 'dart:typed_data';

import 'package:algobot/games/achievement_definitions.dart';
import 'package:algobot/games/game_ids.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/export_achievements_csv.dart' as csv;
import '../../tool/export_badges.dart' as badges;

/// Basit CSV satır ayrıştırıcı (tırnaklı hücreler).
List<String> _parseLine(String line) {
  final cells = <String>[];
  final buf = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (quoted) {
      if (ch == '"' && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else if (ch == '"') {
        quoted = false;
      } else {
        buf.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      cells.add(buf.toString());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  return cells..add(buf.toString());
}

/// PNG başlığından (IHDR) genişlik, yükseklik ve renk türü.
(int, int, int) _pngInfo(File f) {
  final b = ByteData.sublistView(f.readAsBytesSync());
  expect(b.getUint32(0), 0x89504E47, reason: '${f.path} PNG değil');
  return (b.getUint32(16), b.getUint32(20), b.getUint8(25));
}

void main() {
  final file = File(csv.csvPath);

  test('store/achievements.csv güncel (tool/export_achievements_csv.dart)', () {
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), csv.buildAchievementsCsv());
  });

  test('CSV ile tanımlar aynı anahtarları ve puanları içeriyor', () {
    final lines = file
        .readAsStringSync()
        .trim()
        .split('\n')
        .map(_parseLine)
        .toList();
    expect(lines.first, csv.csvHeader);
    final rows = lines.skip(1).toList();
    final col = {for (final (i, h) in csv.csvHeader.indexed) h: i};
    expect(
      rows.map((r) => r[col['anahtar']!]),
      Achievements.all.map((a) => a.key),
    );
    var total = 0;
    for (final r in rows) {
      final def = Achievements.byKey(r[col['anahtar']!]);
      expect(int.parse(r[col['puan']!]), def.points);
      expect(int.parse(r[col['hedef_adim']!]), def.target);
      expect(r[col['gizli']!], 'hayır');
      total += int.parse(r[col['puan']!]);
      // Play Games sınırları: ad ≤ 100, açıklama ≤ 500 karakter.
      for (final k in ['ad_tr', 'ad_en']) {
        expect(r[col[k]!].length, inInclusiveRange(1, 100), reason: k);
      }
      for (final k in ['aciklama_tr', 'aciklama_en']) {
        expect(r[col[k]!].length, inInclusiveRange(1, 200), reason: k);
      }
    }
    expect(total, Achievements.totalPoints);
    expect(total, lessThanOrEqualTo(1000));
  });

  test('Tüm rozet PNG\'leri üretilmiş (512 ve 1024, saydamlıksız)', () {
    final names = [
      ...Achievements.all.map((a) => a.key),
      badges.leaderboardIconName,
    ];
    for (final (dir, size) in const [
      ('store/badges', 512),
      ('store/badges_1024', 1024),
    ]) {
      for (final name in names) {
        final f = File('$dir/$name.png');
        expect(f.existsSync(), isTrue, reason: f.path);
        final (w, h, colorType) = _pngInfo(f);
        expect((w, h), (size, size), reason: f.path);
        expect(colorType, 2, reason: '${f.path}: RGB (alfa yok) olmalı');
      }
    }
  });

  test('Her başarımın ve skor tablosunun platform kimliği tanımlı', () {
    expect(
      GameIds.achievements.keys.toSet(),
      Achievements.all.map((a) => a.key).toSet(),
    );
    expect(GameIds.leaderboards.keys, [GameIds.totalStarsLeaderboard]);
  });
}
