import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

/// Buzi: penguen. Paytak paytak yürür, çarpınca poposunun üstüne oturur.
class BuziPainter extends CharacterPainter {
  const BuziPainter();

  static const dark = Color(0xFF2C2C2A);
  static const belly = Color(0xFFF1EFE8);
  static const orange = Color(0xFFEF9F27);

  @override
  void draw(Canvas c, Offset look, CharacterState state, double t) {
    final tilt = switch (state) {
      CharacterState.idle => sin(t * 2.2) * 0.07,
      CharacterState.moving => sin(t * pi * 4) * 0.16,
      _ => 0.0,
    };
    final sit = state == CharacterState.crash;
    c.save();
    c.translate(0, sit ? 8 : 0);
    // Ayak tabanı etrafında sallanma.
    c.translate(0, 34);
    c.rotate(tilt);
    c.translate(0, -34);

    // Ayaklar: otururken öne uzanır.
    if (sit) {
      c.drawOval(const Rect.fromLTRB(-20, 22, -4, 32), fill(orange));
      c.drawOval(const Rect.fromLTRB(4, 22, 20, 32), fill(orange));
    } else {
      c.drawOval(const Rect.fromLTRB(-16, 29, -3, 37), fill(orange));
      c.drawOval(const Rect.fromLTRB(3, 29, 16, 37), fill(orange));
    }

    // Kanatlar: kazanınca çırpar.
    final flap = state == CharacterState.win ? sin(t * 14) * 0.6 : 0.0;
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(side * 20, -2);
      c.rotate(side * (0.25 + flap.abs()));
      c.drawOval(const Rect.fromLTRB(-5, -2, 5, 26), fill(dark));
      c.restore();
    }

    // Gövde.
    final body = sit
        ? const Rect.fromLTRB(-24, -30, 24, 30)
        : const Rect.fromLTRB(-23, -36, 23, 32);
    c.drawOval(body, fill(dark));
    c.drawOval(
      Rect.fromLTRB(-16, body.top + 18, 16, body.bottom - 2),
      fill(belly),
    );

    // Yüz.
    final eyeY = body.top + 16;
    final le = Offset(-8, eyeY), re = Offset(8, eyeY);
    if (sit) {
      drawXEye(c, le, 4.5, belly);
      drawXEye(c, re, 4.5, belly);
    } else {
      drawEye(c, le, 5.5, look, pupil: dark);
      drawEye(c, re, 5.5, look, pupil: dark);
    }
    // Gaga, bakış yönüne hafif kayar.
    final beak = Offset(look.dx * 3, eyeY + 8 + look.dy * 2);
    c.drawPath(
      Path()
        ..moveTo(beak.dx - 6, beak.dy - 2)
        ..lineTo(beak.dx + 6, beak.dy - 2)
        ..lineTo(beak.dx + look.dx * 3, beak.dy + 6)
        ..close(),
      fill(orange),
    );
    c.restore();

    if (sit) drawDizzyStars(c, const Offset(0, -30), t, orange);
  }
}
