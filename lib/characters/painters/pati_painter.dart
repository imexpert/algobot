import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

/// Pati: turuncu kedi. Kuyruk sallar, zıplayarak yürür.
class PatiPainter extends CharacterPainter {
  const PatiPainter();

  static const fur = Color(0xFFEF9F27);
  static const cream = Color(0xFFFAEEDA);
  static const dark = Color(0xFF412402);
  static const heart = Color(0xFFE24B4A);

  @override
  void draw(Canvas c, Offset look, CharacterState state, double t) {
    final lift = switch (state) {
      CharacterState.moving => -hop(t) * 9,
      _ => 0.0,
    };
    c.save();
    c.translate(0, lift);

    // Kuyruk (arkada, solda).
    final wag = switch (state) {
      CharacterState.idle => sin(t * 4) * 0.35,
      CharacterState.moving => sin(t * pi * 2) * 0.3,
      _ => 0.0,
    };
    if (state == CharacterState.win) {
      drawHeart(c, const Offset(-27, 8), 9, heart);
      c.drawLine(const Offset(-20, 24), const Offset(-26, 14), stroke(fur, 5));
    } else {
      c.save();
      c.translate(-18, 24);
      c.rotate(-0.4 + wag);
      final tail = Path()
        ..moveTo(0, 0)
        ..cubicTo(-14, -2, -18, -18, -8, -24);
      c.drawPath(tail, stroke(fur, 6));
      c.restore();
    }

    // Gövde.
    c.drawOval(const Rect.fromLTRB(-20, 6, 20, 36), fill(fur));
    c.drawOval(const Rect.fromLTRB(-11, 14, 11, 34), fill(cream));
    // Patiler.
    c.drawOval(const Rect.fromLTRB(-16, 29, -4, 37), fill(cream));
    c.drawOval(const Rect.fromLTRB(4, 29, 16, 37), fill(cream));

    // Kulaklar: çarpmada yatar.
    final flat = state == CharacterState.crash;
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(side * 15, -24);
      c.rotate(side * (flat ? 1.1 : 0.15));
      final ear = Path()
        ..moveTo(-9, 4)
        ..lineTo(0, -14)
        ..lineTo(9, 4)
        ..close();
      c.drawPath(ear, fill(fur));
      c.drawPath(
        Path()
          ..moveTo(-5, 2)
          ..lineTo(0, -8)
          ..lineTo(5, 2)
          ..close(),
        fill(cream),
      );
      c.restore();
    }

    // Kafa.
    c.drawCircle(const Offset(0, -10), 23, fill(fur));
    c.drawOval(const Rect.fromLTRB(-12, -6, 12, 10), fill(cream));

    // Gözler.
    const le = Offset(-9, -14), re = Offset(9, -14);
    if (state == CharacterState.crash) {
      drawXEye(c, le, 5, dark);
      drawXEye(c, re, 5, dark);
    } else if (state == CharacterState.win) {
      drawClosedEye(c, le, 5.5, dark); // göz kırpma
      drawEye(c, re, 5.5, look, pupil: dark);
    } else if (state == CharacterState.idle && blinking(t)) {
      drawClosedEye(c, le, 5.5, dark);
      drawClosedEye(c, re, 5.5, dark);
    } else {
      drawEye(c, le, 5.5, look, pupil: dark);
      drawEye(c, re, 5.5, look, pupil: dark);
    }

    // Burun, ağız ve bıyıklar.
    c.drawPath(
      Path()
        ..moveTo(-3, -3)
        ..lineTo(3, -3)
        ..lineTo(0, 0.5)
        ..close(),
      fill(dark),
    );
    if (state == CharacterState.win) {
      drawSmile(c, const Offset(0, 3), 5, dark, width: 2);
    } else {
      c.drawLine(const Offset(0, 0.5), const Offset(0, 4), stroke(dark, 1.5));
    }
    final w = stroke(dark, 1.2);
    for (final side in [-1.0, 1.0]) {
      c.drawLine(Offset(side * 8, 0), Offset(side * 22, -3), w);
      c.drawLine(Offset(side * 8, 3), Offset(side * 22, 5), w);
    }
    c.restore();

    if (state == CharacterState.crash) {
      drawDizzyStars(c, Offset(0, -40 + lift), t, const Color(0xFFFAC775));
    }
  }
}
