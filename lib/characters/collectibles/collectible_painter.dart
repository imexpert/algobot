import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

enum CollectibleKind {
  battery,
  fish,
  honey,
  crystal,
  strawberry,
  carrot,
  star,
  coin,
}

/// Toplanabilir nesneyi `center` merkezli, yaklaşık `size` boyunda çizer.
/// `bob`: yukarı-aşağı süzülme için saniye (0 verilirse durağan).
void paintCollectible(
  Canvas canvas,
  CollectibleKind kind,
  Offset center,
  double size, {
  double bob = 0,
  double scale = 1,
}) {
  if (scale <= 0) return;
  canvas.save();
  canvas.translate(center.dx, center.dy + sin(bob * 3) * size * 0.04);
  final s = size / 100 * scale;
  canvas.scale(s, s);
  switch (kind) {
    case CollectibleKind.battery:
      _battery(canvas);
    case CollectibleKind.fish:
      _fish(canvas);
    case CollectibleKind.honey:
      _honey(canvas);
    case CollectibleKind.crystal:
      _crystal(canvas);
    case CollectibleKind.strawberry:
      _strawberry(canvas);
    case CollectibleKind.carrot:
      _carrot(canvas);
    case CollectibleKind.star:
      drawStar(canvas, Offset.zero, 40, const Color(0xFFFAC775));
      drawStar(canvas, Offset.zero, 18, const Color(0xFFFFF3D6));
    case CollectibleKind.coin:
      canvas.drawCircle(Offset.zero, 36, fill(const Color(0xFFEF9F27)));
      canvas.drawCircle(Offset.zero, 26, fill(const Color(0xFFFAC775)));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(-5, -14, 5, 14),
          const Radius.circular(4),
        ),
        fill(const Color(0xFFEF9F27)),
      );
  }
  canvas.restore();
}

void _battery(Canvas c) {
  const body = Color(0xFFFAC775), tip = Color(0xFF633806);
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(-17, -24, 17, 38),
      const Radius.circular(6),
    ),
    fill(body),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(-8, -34, 8, -22),
      const Radius.circular(3),
    ),
    fill(tip),
  );
  c.drawRect(const Rect.fromLTRB(-9, 4, 9, 10), fill(tip));
}

void _fish(Canvas c) {
  const color = Color(0xFF85B7EB), dark = Color(0xFF185FA5);
  c.drawPath(
    Path()
      ..moveTo(-22, 0)
      ..lineTo(-40, -16)
      ..lineTo(-40, 16)
      ..close(),
    fill(dark),
  );
  c.drawOval(const Rect.fromLTRB(-30, -20, 36, 20), fill(color));
  c.drawCircle(const Offset(20, -4), 4.5, fill(dark));
  c.drawArc(
    const Rect.fromLTRB(-6, -14, 14, 14),
    -0.9,
    1.8,
    false,
    stroke(dark, 3),
  );
}

void _honey(Canvas c) {
  const honey = Color(0xFFEF9F27), shine = Color(0xFFFAC775);
  c.drawPath(
    Path()
      ..moveTo(0, -38)
      ..cubicTo(10, -18, 30, 2, 30, 14)
      ..arcToPoint(const Offset(-30, 14), radius: const Radius.circular(30))
      ..cubicTo(-30, 2, -10, -18, 0, -38)
      ..close(),
    fill(honey),
  );
  c.drawOval(const Rect.fromLTRB(-18, 2, -8, 20), fill(shine));
}

void _crystal(Canvas c) {
  const ice = Color(0xFF85B7EB), core = Color(0xFFE6F1FB);
  for (var i = 0; i < 6; i++) {
    final a = i * pi / 3;
    final dir = Offset(cos(a), sin(a));
    c.drawLine(Offset.zero, dir * 36, stroke(ice, 7));
    final side = Offset(-dir.dy, dir.dx);
    c.drawLine(dir * 22, dir * 30 + side * 9, stroke(ice, 4));
    c.drawLine(dir * 22, dir * 30 - side * 9, stroke(ice, 4));
  }
  final hex = Path();
  for (var i = 0; i < 6; i++) {
    final a = i * pi / 3 + pi / 6;
    final p = Offset(cos(a) * 12, sin(a) * 12);
    i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
  }
  c.drawPath(hex..close(), fill(core));
}

void _strawberry(Canvas c) {
  const red = Color(0xFFE24B4A),
      seed = Color(0xFFFAC775),
      leaf = Color(0xFF639922);
  c.drawPath(
    Path()
      ..moveTo(0, 38)
      ..cubicTo(-38, 10, -34, -26, 0, -20)
      ..cubicTo(34, -26, 38, 10, 0, 38)
      ..close(),
    fill(red),
  );
  for (final p in const [
    Offset(-12, -6),
    Offset(10, -8),
    Offset(0, 6),
    Offset(-14, 12),
    Offset(14, 10),
    Offset(0, 22),
  ]) {
    c.drawOval(Rect.fromCenter(center: p, width: 4, height: 6), fill(seed));
  }
  for (var i = -2; i <= 2; i++) {
    c.save();
    c.translate(0, -22);
    c.rotate(i * 0.55);
    c.drawOval(const Rect.fromLTRB(-5, -18, 5, 0), fill(leaf));
    c.restore();
  }
}

void _carrot(Canvas c) {
  const orange = Color(0xFFEF9F27),
      dark = Color(0xFFBA7517),
      leaf = Color(0xFF639922);
  for (var i = -1; i <= 1; i++) {
    c.save();
    c.translate(0, -20);
    c.rotate(i * 0.4);
    c.drawOval(const Rect.fromLTRB(-5, -22, 5, 0), fill(leaf));
    c.restore();
  }
  c.drawPath(
    Path()
      ..moveTo(-16, -22)
      ..quadraticBezierTo(0, -28, 16, -22)
      ..lineTo(2, 38)
      ..quadraticBezierTo(0, 40, -2, 38)
      ..close(),
    fill(orange),
  );
  for (final y in [-8.0, 6.0, 20.0]) {
    c.drawLine(Offset(-8 + y * 0.12, y), Offset(-2, y + 2), stroke(dark, 2.5));
  }
}
