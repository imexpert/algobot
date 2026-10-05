import 'dart:math';
import 'dart:ui';

import '../character_painter.dart';

/// Kıvılcım: küçük ejderha. Burnundan duman halkası; kazanınca zararsız
/// sarı-turuncu kıvılcımlar.
class KivilcimPainter extends CharacterPainter {
  const KivilcimPainter();

  static const body = Color(0xFFD85A30);
  static const light = Color(0xFFF5C4B3);
  static const belly = Color(0xFFFAC775);
  static const dark = Color(0xFF4A1B0C);
  static const smoke = Color(0xFFD3D1C7);

  @override
  void draw(Canvas c, Offset look, CharacterState state, double t) {
    final bob = state == CharacterState.moving ? -hop(t) * 4 : 0.0;
    c.save();
    c.translate(0, bob);

    // Kuyruk (arkada).
    final tail = Path()
      ..moveTo(-16, 22)
      ..quadraticBezierTo(-38, 26, -36, 6);
    c.drawPath(tail, stroke(body, 7));
    c.drawPath(
      Path()
        ..moveTo(-41, 8)
        ..lineTo(-36, -4)
        ..lineTo(-30, 6)
        ..close(),
      fill(body),
    );

    // Kanatçıklar: hareket ve kazanmada çırpar.
    final flap = state == CharacterState.moving
        ? sin(t * pi * 6) * 0.5
        : state == CharacterState.win
        ? sin(t * 12) * 0.4
        : 0.0;
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(side * 16, -2);
      c.rotate(side * (0.5 + flap));
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(side * 16, -14)
          ..lineTo(side * 12, 2)
          ..lineTo(side * 18, 6)
          ..close(),
        fill(light),
      );
      c.restore();
    }

    // Tombul gövde ve karın.
    c.drawOval(const Rect.fromLTRB(-22, -4, 22, 36), fill(body));
    c.drawOval(const Rect.fromLTRB(-13, 6, 13, 34), fill(belly));
    // Ayaklar.
    c.drawOval(const Rect.fromLTRB(-18, 30, -4, 38), fill(body));
    c.drawOval(const Rect.fromLTRB(4, 30, 18, 38), fill(body));

    // Boynuzcuklar.
    for (final side in [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(side * 6, -30)
          ..lineTo(side * 12, -42)
          ..lineTo(side * 15, -28)
          ..close(),
        fill(belly),
      );
    }

    // Kafa ve burun (önde).
    c.drawCircle(const Offset(0, -18), 17, fill(body));
    final snout = Offset(6 + look.dx * 4, -12 + look.dy * 2);
    c.drawOval(
      Rect.fromCenter(center: snout, width: 20, height: 12),
      fill(light),
    );
    c.drawCircle(snout + const Offset(-3, -1), 1.6, fill(dark));
    c.drawCircle(snout + const Offset(4, -1), 1.6, fill(dark));

    const le = Offset(-6, -24), re = Offset(8, -24);
    if (state == CharacterState.crash) {
      drawXEye(c, le, 4.5, dark);
      drawXEye(c, re, 4.5, dark);
    } else {
      drawEye(c, le, 5, look, pupil: dark);
      drawEye(c, re, 5, look, pupil: dark);
    }
    if (state == CharacterState.win) {
      drawSmile(c, snout + const Offset(0, 3), 5, dark, width: 1.8);
    }
    c.restore();

    // Burun dumanı / hapşırık / kıvılcımlar.
    final nose = Offset(16, -14 + bob);
    switch (state) {
      case CharacterState.idle:
        final u = (t % 2.4) / 2.4;
        if (u < 0.6) {
          final k = u / 0.6;
          c.drawCircle(
            nose + Offset(k * 10, -k * 16),
            2 + k * 5,
            stroke(smoke.withValues(alpha: 1 - k), 2),
          );
        }
      case CharacterState.crash:
        for (var i = 0; i < 4; i++) {
          final k = ((t * 1.5) + i * 0.25) % 1;
          c.drawCircle(
            nose + Offset(6 + k * 14, (i - 1.5) * 5 * k),
            3 + k * 4,
            fill(smoke.withValues(alpha: (1 - k) * 0.9)),
          );
        }
      case CharacterState.win:
        for (var i = 0; i < 7; i++) {
          final a = -pi / 2 + (i - 3) * 0.35;
          final k = ((t * 1.3) + i * 0.13) % 1;
          final p = nose + Offset(cos(a) * k * 24 + 6, sin(a) * k * 24);
          c.drawCircle(
            p,
            2.5 * (1 - k) + 0.5,
            fill(
              (i.isEven ? belly : const Color(0xFFEF9F27)).withValues(
                alpha: 1 - k,
              ),
            ),
          );
        }
      case CharacterState.moving || CharacterState.turning:
        break;
    }
  }
}
