import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

/// Bip: robot. Çarpmada gözler X, kazanınca anten ucu yanıp söner.
class BipPainter extends CharacterPainter {
  const BipPainter();

  static const body = Color(0xFF5DCAA5);
  static const detail = Color(0xFF04342C);
  static const bulb = Color(0xFFFAC775);

  @override
  void draw(Canvas c, Offset look, CharacterState state, double t) {
    final bob = switch (state) {
      CharacterState.moving => -hop(t) * 5,
      CharacterState.idle => sin(t * 2.4) * 1.2,
      CharacterState.win => -hop((t * 2) % 1) * 6,
      _ => 0.0,
    };
    final squash = state == CharacterState.turning ? 1 - hop(t) * 0.06 : 1.0;
    c.save();
    c.translate(0, bob);
    c.scale(1 / squash, squash);

    // Anten: bekleme ve kazanmada hafifçe sallanır.
    final wobble = switch (state) {
      CharacterState.idle => sin(t * 3) * 0.18,
      CharacterState.win => sin(t * 10) * 0.25,
      CharacterState.crash => 0.5,
      _ => 0.0,
    };
    c.save();
    c.translate(0, -24);
    c.rotate(wobble);
    c.drawLine(Offset.zero, const Offset(0, -12), stroke(detail, 3));
    final lit = state != CharacterState.win || (t * 6).floor().isEven;
    c.drawCircle(const Offset(0, -14), 5, fill(lit ? bulb : detail));
    c.restore();

    // Gövde ve ayaklar.
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, 22, 10, 10),
        const Radius.circular(3),
      ),
      fill(detail),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 22, 10, 10),
        const Radius.circular(3),
      ),
      fill(detail),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-28, -26, 28, 26),
        const Radius.circular(14),
      ),
      fill(body),
    );
    // Yüz paneli.
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-21, -17, 21, 11),
        const Radius.circular(9),
      ),
      fill(detail),
    );

    const le = Offset(-9, -4), re = Offset(9, -4);
    if (state == CharacterState.crash) {
      drawXEye(c, le, 5.5, body);
      drawXEye(c, re, 5.5, body);
    } else {
      for (final e in [le, re]) {
        drawEye(c, e, 6, look, white: body, pupil: detail, pupilRatio: 0.45);
      }
    }
    if (state == CharacterState.win) {
      drawSmile(c, const Offset(0, 5), 6, body);
    } else {
      c.drawLine(const Offset(-4, 6), const Offset(4, 6), stroke(body, 2));
    }
    c.restore();
  }
}
