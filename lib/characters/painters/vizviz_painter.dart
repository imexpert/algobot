import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

/// Vızvız: arı. Kanat çırpar, süzülür; hareket ederken dalgalı yay çizer.
class VizvizPainter extends CharacterPainter {
  const VizvizPainter();

  static const yellow = Color(0xFFFAC775);
  static const dark = Color(0xFF2C2C2A);
  static const wing = Color(0xFFE6F1FB);

  @override
  void draw(Canvas c, Offset look, CharacterState state, double t) {
    final (dy, spin) = switch (state) {
      CharacterState.idle => (sin(t * 3) * 3.5, 0.0),
      CharacterState.moving => (-sin(t * 2 * pi) * 7 - hop(t) * 4, 0.0),
      CharacterState.crash => (4.0, sin(t * 7) * 0.6 * exp(-t * 0.8)),
      // Küçük bir takla.
      CharacterState.win => (-hop((t / 0.9) % 1) * 8, ((t / 0.9) % 1) * 2 * pi),
      CharacterState.turning => (0.0, 0.0),
    };
    c.save();
    c.translate(0, dy - 2);
    c.rotate(spin);

    // Kanatlar: hızlı çırpma (kanat yüksekliği salınır).
    final flap = state == CharacterState.crash
        ? 0.5
        : 0.55 + 0.45 * sin(t * (state == CharacterState.idle ? 40 : 60)).abs();
    final wingPaint = fill(wing.withValues(alpha: 0.85));
    final wingEdge = stroke(const Color(0xFF9FC3E6), 1.5);
    for (final side in [-1.0, 1.0]) {
      final r = Rect.fromCenter(
        center: Offset(side * 12, -22),
        width: 20,
        height: 28 * flap,
      );
      c.save();
      c.translate(r.center.dx, r.center.dy + 6);
      c.rotate(side * 0.35);
      c.translate(-r.center.dx, -r.center.dy - 6);
      c.drawOval(r, wingPaint);
      c.drawOval(r, wingEdge);
      c.restore();
    }

    // Gövde: çizgili oval, arkada iğne.
    c.drawPath(
      Path()
        ..moveTo(-30, 6)
        ..lineTo(-38, 8)
        ..lineTo(-30, 12)
        ..close(),
      fill(dark),
    );
    final bodyRect = const Rect.fromLTRB(-32, -12, 30, 28);
    c.save();
    c.clipPath(Path()..addOval(bodyRect));
    c.drawRect(bodyRect, fill(yellow));
    for (final x in [-20.0, -6.0]) {
      c.drawRect(Rect.fromLTWH(x, -14, 7, 44), fill(dark));
    }
    c.restore();

    // Kafa (önde).
    const head = Offset(14, 6);
    c.drawCircle(head, 15, fill(yellow));
    // Antenler.
    for (final side in [-1.0, 1.0]) {
      final base = head + Offset(side * 5, -13);
      final tip = base + Offset(side * 5, -9);
      c.drawLine(base, tip, stroke(dark, 2));
      c.drawCircle(tip, 2.5, fill(dark));
    }
    const le = Offset(8, 4), re = Offset(20, 4);
    if (state == CharacterState.crash) {
      drawXEye(c, le, 4.5, dark);
      drawXEye(c, re, 4.5, dark);
    } else {
      drawEye(c, le, 5, look, pupil: dark);
      drawEye(c, re, 5, look, pupil: dark);
    }
    if (state == CharacterState.win) {
      drawSmile(c, head + const Offset(0, 8), 5, dark, width: 2);
    }
    c.restore();

    if (state == CharacterState.crash) {
      drawDizzyStars(c, Offset(0, -38 + dy), t, yellow);
    }
  }
}
