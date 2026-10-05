import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

/// Hop: tavşan. Belirgin zıplar; çarpınca kulakları kıvrılır.
class HopPainter extends CharacterPainter {
  const HopPainter();

  static const fur = Color(0xFFF1EFE8);
  static const pink = Color(0xFFED93B1);
  static const dark = Color(0xFF444441);

  @override
  void draw(Canvas c, Offset look, CharacterState state, double t) {
    final lift = switch (state) {
      CharacterState.moving => -hop(t) * 14,
      CharacterState.win => -hop((t / 0.6) % 1) * 16,
      _ => 0.0,
    };
    c.save();
    c.translate(0, lift);

    // Pamuk kuyruk (arkada).
    c.drawCircle(const Offset(-20, 24), 7, fill(const Color(0xFFFFFFFF)));

    // Gövde ve ayaklar.
    c.drawOval(const Rect.fromLTRB(-19, 4, 19, 36), fill(fur));
    c.drawOval(const Rect.fromLTRB(-18, 30, -2, 38), fill(fur));
    c.drawOval(const Rect.fromLTRB(2, 30, 18, 38), fill(fur));

    // Kulaklar.
    final curled = state == CharacterState.crash;
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(side * 8, -26);
      if (curled) {
        // Kıvrılmış kulak: kısa, yana bükük.
        c.rotate(side * 1.3);
        final ear = Path()
          ..moveTo(-4, 0)
          ..cubicTo(-6, -18, 10, -22, 8, -8);
        c.drawPath(ear, stroke(fur, 9));
        c.drawPath(ear, stroke(pink, 3));
      } else {
        c.rotate(side * 0.12);
        c.drawOval(const Rect.fromLTRB(-6, -30, 6, 2), fill(fur));
        c.drawOval(const Rect.fromLTRB(-3, -25, 3, -2), fill(pink));
      }
      c.restore();
    }

    // Kafa.
    c.drawCircle(const Offset(0, -10), 19, fill(fur));
    const le = Offset(-7, -14), re = Offset(7, -14);
    if (curled) {
      drawXEye(c, le, 4.5, dark);
      drawXEye(c, re, 4.5, dark);
    } else {
      drawEye(c, le, 5, look, pupil: dark);
      drawEye(c, re, 5, look, pupil: dark);
    }
    // Burun: beklemede oynar.
    final wiggle = state == CharacterState.idle ? sin(t * 14) * 1.2 : 0.0;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, -5 + wiggle * 0.3),
        width: 6 + wiggle,
        height: 4.5,
      ),
      fill(pink),
    );
    if (state == CharacterState.win) {
      drawSmile(c, const Offset(0, -1), 4, dark, width: 1.8);
    }
    c.restore();

    if (curled) drawDizzyStars(c, const Offset(0, -42), t, pink);
  }
}
