import 'dart:math';
import 'dart:ui';

import '../core/colors.dart';

/// Tüm karakterlerin altındaki taban diski ve yön oku.
/// `quarterTurns`: kuzey = 0, saat yönünde; dönüş animasyonunda kesirli olur.
void paintBaseDisc(
  Canvas canvas,
  Offset center,
  double cell,
  double quarterTurns,
) {
  final r = cell * 0.4;
  canvas.drawCircle(
    center,
    r,
    Paint()..color = Color.lerp(AppColors.floor, AppColors.background, 0.45)!,
  );
  final a = quarterTurns * pi / 2 - pi / 2; // kuzey = yukarı
  final dir = Offset(cos(a), sin(a));
  final side = Offset(-dir.dy, dir.dx);
  final tip = center + dir * (r + cell * 0.08);
  final baseC = center + dir * (r - cell * 0.06);
  final w = cell * 0.09;
  canvas.drawPath(
    Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseC.dx + side.dx * w, baseC.dy + side.dy * w)
      ..lineTo(baseC.dx - side.dx * w, baseC.dy - side.dy * w)
      ..close(),
    Paint()..color = AppColors.textPrimary,
  );
}
