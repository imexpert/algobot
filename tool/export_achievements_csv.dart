// Konsollarda (Play Console, App Store Connect) elle oluşturulacak
// başarımların listesini store/achievements.csv olarak üretir. Adlar ve
// açıklamalar uygulamanın ARB dosyalarından gelir (tek kaynak).
//
// Kullanım: flutter test tool/export_achievements_csv.dart
import 'dart:io';
import 'dart:ui';

import 'package:algobot/games/achievement_definitions.dart';
import 'package:algobot/games/game_ids.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

const csvPath = 'store/achievements.csv';

const csvHeader = [
  'sira',
  'anahtar',
  'ad_tr',
  'ad_en',
  'aciklama_tr',
  'aciklama_en',
  'tur',
  'hedef_adim',
  'puan',
  'gizli',
  'ios_kimlik_onerilen',
  'rozet_dosyasi',
];

String _cell(Object v) {
  final s = '$v';
  return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

/// CSV içeriği (testler de kullanır).
String buildAchievementsCsv() {
  final tr = lookupAppLocalizations(const Locale('tr'));
  final en = lookupAppLocalizations(const Locale('en'));
  final rows = <List<Object>>[
    csvHeader,
    for (final (i, d) in Achievements.all.indexed)
      [
        i + 1,
        d.key,
        tr.achievementName(d.key),
        en.achievementName(d.key),
        tr.achievementDesc(d.key),
        en.achievementDesc(d.key),
        d.incremental ? 'artan' : 'tek seferlik',
        d.target,
        d.points,
        'hayır',
        GameIds.suggestedIosAchievementId(d.key),
        'badges/${d.key}.png',
      ],
  ];
  return '${rows.map((r) => r.map(_cell).join(',')).join('\n')}\n';
}

void main() {
  test('store/achievements.csv üret', () {
    File(csvPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(buildAchievementsCsv());
    // ignore: avoid_print
    print(
      'Yazıldı: $csvPath (${Achievements.all.length} başarım, '
      'toplam ${Achievements.totalPoints} puan)',
    );
  });
}
