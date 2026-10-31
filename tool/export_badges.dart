// Başarım rozetlerini ve skor tablosu simgesini mağaza için PNG olarak
// üretir. Uygulamadaki rozet çizimini (AchievementBadgePainter) kullanır.
//
// Kullanım: flutter test tool/export_badges.dart
//
// Çıktı (kazanılmış görünüm, şeffaf olmayan #26215C zemin):
//   store/badges/<anahtar>.png                 512×512 (Play Games, Game Center)
//   store/badges_1024/<anahtar>.png            1024×1024 (Game Center)
//   store/badges/leaderboard_total_stars.png   512×512 skor tablosu simgesi
//   store/badges_1024/leaderboard_total_stars.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:algobot/core/colors.dart';
import 'package:algobot/games/achievement_definitions.dart';
import 'package:algobot/ui/widgets/achievement_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Skor tablosu simgesinin dosya adı (uzantısız).
const leaderboardIconName = 'leaderboard_total_stars';

Future<void> _write(CustomPainter painter, int size, String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  canvas.drawRect(
    Rect.fromLTWH(0, 0, s, s),
    Paint()..color = AppColors.background,
  );
  // Madalyonun çevresinde biraz boşluk (platformlar yuvarlak kırpabilir).
  const inset = 0.06;
  canvas.save();
  canvas.translate(s * inset, s * inset);
  painter.paint(canvas, Size.square(s * (1 - 2 * inset)));
  canvas.restore();
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  // Alfa kanalı olmadan (RGB): App Store Connect saydamlık kabul etmez.
  final rgb = img
      .decodePng(bytes!.buffer.asUint8List())!
      .convert(numChannels: 3);
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(rgb));
}

void main() {
  test('Rozet PNG dosyalarını üret', () async {
    for (final (dir, size) in const [
      ('store/badges', 512),
      ('store/badges_1024', 1024),
    ]) {
      for (final def in Achievements.all) {
        await _write(
          AchievementBadgePainter(icon: def.icon, color: def.color),
          size,
          '$dir/${def.key}.png',
        );
      }
      await _write(
        const AchievementBadgePainter(
          icon: BadgeIcon.podium,
          color: AppColors.goalOuter,
        ),
        size,
        '$dir/$leaderboardIconName.png',
      );
    }
    // ignore: avoid_print
    print('Üretildi: ${Achievements.all.length + 1} görsel × 2 boyut');
  });
}
