import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

/// Zorp: tek gözlü uzaylı. Yerden yüksekte süzülür.
class ZorpPainter extends CharacterPainter {
  const ZorpPainter();

  static const body = Color(0xFF7F77DD);
  static const light = Color(0xFFCECBF6);
  static const dark = Color(0xFF26215C);
  static const glow = Color(0xFFFAC775);

  @override
  void draw(Canvas c, Offset look, CharacterState state, double t) {
    final float = switch (state) {
      CharacterState.moving => -6 - hop(t) * 3,
      CharacterState.crash => 0.0,
      _ => -4 + sin(t * 2.5) * 2,
    };
    // Gölge (yerde).
    c.drawOval(
      const Rect.fromLTRB(-16, 31, 16, 37),
      fill(dark.withValues(alpha: 0.35)),
    );

    c.save();
    c.translate(0, float);

    // Kazanınca renk değiştirip parlar.
    var color = body;
    if (state == CharacterState.win) {
      final u = (sin(t * 6) + 1) / 2;
      color = Color.lerp(body, glow, u)!;
      c.drawCircle(
        const Offset(0, 4),
        36,
        stroke(glow.withValues(alpha: 0.6), 3),
      );
    }

    // Antenler: dalgalanır.
    for (final side in [-1.0, 1.0]) {
      final sway = state == CharacterState.idle || state == CharacterState.win
          ? sin(t * 4 + side) * 5
          : 0.0;
      final base = Offset(side * 8, -24);
      final tip = Offset(side * 15 + sway, -40);
      c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(side * 6 + sway, -34, tip.dx, tip.dy),
        stroke(color, 3),
      );
      c.drawCircle(tip, 4, fill(light));
    }

    // Damla gövde.
    final drop = Path()
      ..moveTo(0, -30)
      ..cubicTo(18, -18, 28, 6, 26, 16)
      ..quadraticBezierTo(22, 32, 0, 32)
      ..quadraticBezierTo(-22, 32, -26, 16)
      ..cubicTo(-28, 6, -18, -18, 0, -30)
      ..close();
    c.drawPath(drop, fill(color));
    c.drawOval(
      const Rect.fromLTRB(-14, 16, 14, 28),
      fill(light.withValues(alpha: 0.5)),
    );

    // Tek büyük göz.
    const eye = Offset(0, 2);
    if (state == CharacterState.crash) {
      c.drawCircle(eye, 12, fill(light));
      final spiral = Path();
      for (var i = 0; i <= 40; i++) {
        final a = i * 0.45 + t * 5;
        final r = i * 0.26;
        final p = eye + Offset(cos(a) * r, sin(a) * r);
        i == 0 ? spiral.moveTo(p.dx, p.dy) : spiral.lineTo(p.dx, p.dy);
      }
      c.drawPath(spiral, stroke(dark, 2));
    } else {
      drawEye(c, eye, 12, look, white: light, pupil: dark, pupilRatio: 0.45);
    }
    if (state == CharacterState.win) {
      drawSmile(c, const Offset(0, 18), 7, dark);
    }
    c.restore();
  }
}
