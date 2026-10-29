import 'dart:math';
import 'dart:ui';

import '../core/colors.dart';

/// Yön okunun dolgu ve kontur renkleri (açık ve koyu zeminde görünür).
const arrowFill = Color(0xFFFAC775);
const arrowStroke = Color(0xFF412402);

/// Taban diskinin koyu halkası: karakteri zeminden ayırır.
const discRing = Color(0xFF26215C);

/// Okun nabız periyodu (sn) ve ileri-geri kayma genliği (dp).
const arrowPulsePeriod = 1.2;
const arrowPulseAmplitude = 2.5;

/// Nabız kayması: `seconds` anında okun baktığı yöne doğru kayması (dp).
double arrowPulse(double seconds) =>
    arrowPulseAmplitude * sin(seconds / arrowPulsePeriod * 2 * pi);

/// `quarterTurns` (kuzey = 0, saat yönünde; kesirli olabilir) için birim
/// yön vektörü (ekran koordinatlarında, kuzey = yukarı).
Offset directionVector(double quarterTurns) {
  final a = quarterTurns * pi / 2 - pi / 2;
  return Offset(cos(a), sin(a));
}

/// Tüm karakterlerin altındaki taban diski ve koyu halkası.
/// Yön oku ayrıca, karakterden sonra [paintDirectionArrow] ile çizilir.
void paintBaseDisc(Canvas canvas, Offset center, double cell) {
  final r = cell * 0.4;
  canvas.drawCircle(
    center,
    r,
    Paint()..color = Color.lerp(AppColors.floor, AppColors.background, 0.45)!,
  );
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..color = discRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}

/// Büyük yön okunun yolu. Uzunluğu karenin ~%35'i; ucu karenin kenarına
/// (merkezden `cell / 2`) uzanır. [nudge]: nabız kayması (dp).
Path directionArrowPath(
  Offset center,
  double cell,
  double quarterTurns, {
  double nudge = 0,
}) {
  final dir = directionVector(quarterTurns);
  final side = Offset(-dir.dy, dir.dx);
  final length = cell * 0.35;
  final tip = center + dir * (cell * 0.5 + nudge);
  final tail = tip - dir * length;
  final neck = tip - dir * (length * 0.5);
  final head = cell * 0.13; // ok başının yarı genişliği
  final shaft = cell * 0.055; // gövdenin yarı genişliği
  Offset p(Offset base, double s) => base + side * s;
  return Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(p(neck, head).dx, p(neck, head).dy)
    ..lineTo(p(neck, shaft).dx, p(neck, shaft).dy)
    ..lineTo(p(tail, shaft).dx, p(tail, shaft).dy)
    ..lineTo(p(tail, -shaft).dx, p(tail, -shaft).dy)
    ..lineTo(p(neck, -shaft).dx, p(neck, -shaft).dy)
    ..lineTo(p(neck, -head).dx, p(neck, -head).dy)
    ..close();
}

/// Büyük yön oku: karakterin üstünde (z sırasında en önde) çizilir.
void paintDirectionArrow(
  Canvas canvas,
  Offset center,
  double cell,
  double quarterTurns, {
  double nudge = 0,
}) {
  final path = directionArrowPath(center, cell, quarterTurns, nudge: nudge);
  canvas.drawPath(path, Paint()..color = arrowFill);
  canvas.drawPath(
    path,
    Paint()
      ..color = arrowStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round,
  );
}

/// Dönüş sırasında karakterin çevresindeki kavisli ok. [sign]: +1 saat
/// yönü (sağa), -1 ters (sola). [opacity]: 0..1.
void paintTurnArc(
  Canvas canvas,
  Offset center,
  double cell,
  int sign,
  double opacity,
) {
  if (opacity <= 0 || sign == 0) return;
  final r = cell * 0.46;
  final color = arrowFill.withValues(alpha: opacity.clamp(0.0, 1.0));
  final start = -pi / 2 - sign * pi * 0.35; // üstün biraz gerisinden
  final sweep = sign * pi * 0.7;
  final rect = Rect.fromCircle(center: center, radius: r);
  canvas.drawArc(
    rect,
    start,
    sweep,
    false,
    Paint()
      ..color = arrowStroke.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.09 + 3
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawArc(
    rect,
    start,
    sweep,
    false,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.09
      ..strokeCap = StrokeCap.round,
  );
  // Ok başı yayın ucunda, teğet yönünde.
  final end = start + sweep;
  final tipBase = center + Offset(cos(end), sin(end)) * r;
  final tangent = Offset(-sin(end), cos(end)) * sign.toDouble();
  final normal = Offset(cos(end), sin(end));
  final h = cell * 0.12;
  final tip = tipBase + tangent * h;
  final head = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo((tipBase + normal * h).dx, (tipBase + normal * h).dy)
    ..lineTo((tipBase - normal * h).dx, (tipBase - normal * h).dy)
    ..close();
  canvas.drawPath(head, Paint()..color = color);
  canvas.drawPath(
    head,
    Paint()
      ..color = arrowStroke.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round,
  );
}
