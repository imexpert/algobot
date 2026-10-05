import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

/// Tosbi: kaplumbağa. Çarpınca kafasını kabuğuna çeker, sonra çıkarır.
class TosbiPainter extends CharacterPainter {
  const TosbiPainter();

  static const shell = Color(0xFF639922);
  static const pattern = Color(0xFF3B6D11);
  static const skin = Color(0xFFC0DD97);

  @override
  void draw(Canvas c, Offset look, CharacterState state, double t) {
    // Kafanın kabuktan çıkma oranı (1 = tam dışarıda).
    final out = switch (state) {
      CharacterState.crash =>
        t < 0.35
            ? 1 - t / 0.35
            : t < 1.1
            ? 0.0
            : ((t - 1.1) / 0.4).clamp(0.0, 1.0),
      _ => 1.0,
    };
    final nod = state == CharacterState.win ? sin(t * 8) * 3 : 0.0;

    // Ayaklar: yürürken sırayla adım atar.
    final step = state == CharacterState.moving ? sin(t * pi * 4) : 0.0;
    for (final (x, phase) in [
      (-22.0, 1.0),
      (-8.0, -1.0),
      (8.0, 1.0),
      (22.0, -1.0),
    ]) {
      final lift = max(0.0, step * phase) * 4;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 5, 22 - lift, 10, 12),
          const Radius.circular(5),
        ),
        fill(skin),
      );
    }

    // Kafa (önde, sağda).
    final head = Offset(14 + 11 * out, -2 + nod);
    c.drawCircle(head, 12, fill(skin));
    final le = head + const Offset(-4, -3), re = head + const Offset(5, -3);
    final closed = state == CharacterState.idle && blinking(t, period: 2.6);
    if (out > 0.3) {
      if (closed) {
        drawClosedEye(c, le, 4, pattern);
        drawClosedEye(c, re, 4, pattern);
      } else {
        drawEye(c, le, 4.2, look, pupil: pattern);
        drawEye(c, re, 4.2, look, pupil: pattern);
      }
      if (state == CharacterState.win) {
        drawSmile(c, head + const Offset(1, 4), 5, pattern, width: 2);
      }
    }
    // Küçük kuyruk.
    c.drawPath(
      Path()
        ..moveTo(-32, 16)
        ..lineTo(-40, 20)
        ..lineTo(-32, 22)
        ..close(),
      fill(skin),
    );

    // Kubbe kabuk.
    final dome = Path()
      ..moveTo(-34, 24)
      ..quadraticBezierTo(-34, -28, -4, -28)
      ..quadraticBezierTo(26, -28, 26, 24)
      ..close();
    c.drawPath(dome, fill(shell));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-36, 18, 28, 26),
        const Radius.circular(4),
      ),
      fill(pattern),
    );
    // Altıgen desen.
    c.save();
    c.clipPath(dome);
    final line = stroke(pattern, 2.2);
    for (final center in [
      const Offset(0, -6),
      const Offset(-19, 8),
      const Offset(19, 8),
      const Offset(-12, -22),
      const Offset(12, -22),
    ]) {
      c.drawPath(_hexagon(center, 9), line);
    }
    c.restore();
  }

  Path _hexagon(Offset center, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = pi / 6 + i * pi / 3;
      final pt = center + Offset(cos(a) * r, sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }
}
