import 'dart:math';
import 'dart:ui';

import '../models/direction.dart';

enum CharacterState { idle, moving, turning, crash, win }

/// Tüm karakterlerin ortak çizim arayüzü.
///
/// Karakterler önden görünüşlüdür ve dönmez. Doğu/batıda yatay aynalanır,
/// gözbebekleri bakış yönüne kayar. Asıl yön bilgisi taban diskindeki oktur.
///
/// `t`: `moving`/`turning` için adım ilerlemesi (0..1); `idle`, `crash` ve
/// `win` için duruma girildiğinden beri geçen saniye.
abstract class CharacterPainter {
  const CharacterPainter();

  void paint(
    Canvas canvas,
    Size size,
    Direction facing,
    CharacterState state,
    double t,
  ) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final s = min(size.width, size.height) / 100;
    canvas.scale(facing == Direction.west ? -s : s, s);
    // Aynalanmış uzayda doğu/batı her zaman +x'e bakar.
    final look = switch (facing) {
      Direction.east || Direction.west => const Offset(1, 0),
      Direction.north => const Offset(0, -1),
      Direction.south => const Offset(0, 1),
    };
    draw(canvas, look, state, t);
    canvas.restore();
  }

  /// -50..50 birimlik kutuda, merkez (0,0) olacak şekilde çizer.
  /// Karakter yaklaşık ±37 birimi (kutunun %75'i) kaplamalıdır.
  void draw(Canvas canvas, Offset look, CharacterState state, double t);
}

// ---------------------------------------------------------------------------
// Ortak çizim yardımcıları
// ---------------------------------------------------------------------------

Paint fill(Color c) => Paint()..color = c;

Paint stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Göz: beyaz + bakış yönüne kaymış gözbebeği.
void drawEye(
  Canvas c,
  Offset center,
  double r,
  Offset look, {
  Color white = const Color(0xFFFFFFFF),
  Color pupil = const Color(0xFF26215C),
  double pupilRatio = 0.55,
}) {
  c.drawCircle(center, r, fill(white));
  final p = center + look * (r * (1 - pupilRatio) * 0.9);
  c.drawCircle(p, r * pupilRatio, fill(pupil));
  c.drawCircle(p + Offset(-r * 0.18, -r * 0.2), r * 0.16, fill(white));
}

/// Kapalı/göz kırpan göz: yay.
void drawClosedEye(Canvas c, Offset center, double r, Color color) {
  final rect = Rect.fromCircle(center: center, radius: r * 0.8);
  c.drawArc(rect, pi * 1.1, pi * 0.8, false, stroke(color, r * 0.35));
}

/// Çarpma gözü: X.
void drawXEye(Canvas c, Offset center, double r, Color color) {
  final d = r * 0.7;
  final p = stroke(color, r * 0.35);
  c.drawLine(center + Offset(-d, -d), center + Offset(d, d), p);
  c.drawLine(center + Offset(-d, d), center + Offset(d, -d), p);
}

/// Sersemleme: başın üstünde dönen küçük yıldızlar.
void drawDizzyStars(Canvas c, Offset center, double t, Color color) {
  for (var i = 0; i < 3; i++) {
    final a = t * 4 + i * 2 * pi / 3;
    final p = center + Offset(cos(a) * 16, sin(a) * 5);
    drawStar(c, p, 4.5, color);
  }
}

/// Beş köşeli yıldız.
void drawStar(
  Canvas c,
  Offset center,
  double r,
  Color color, {
  double inner = 0.45,
}) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r : r * inner;
    final a = -pi / 2 + i * pi / 5;
    final p = center + Offset(cos(a) * rr, sin(a) * rr);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  c.drawPath(path..close(), fill(color));
}

/// Gülümseme yayı.
void drawSmile(
  Canvas c,
  Offset center,
  double w,
  Color color, {
  double width = 2.5,
}) {
  final path = Path()
    ..moveTo(center.dx - w, center.dy)
    ..quadraticBezierTo(
      center.dx,
      center.dy + w * 0.9,
      center.dx + w,
      center.dy,
    );
  c.drawPath(path, stroke(color, width));
}

/// Kalp.
void drawHeart(Canvas c, Offset center, double r, Color color) {
  final path = Path()
    ..moveTo(center.dx, center.dy + r)
    ..cubicTo(
      center.dx - r * 1.6,
      center.dy - r * 0.2,
      center.dx - r * 0.6,
      center.dy - r * 1.4,
      center.dx,
      center.dy - r * 0.4,
    )
    ..cubicTo(
      center.dx + r * 0.6,
      center.dy - r * 1.4,
      center.dx + r * 1.6,
      center.dy - r * 0.2,
      center.dx,
      center.dy + r,
    );
  c.drawPath(path, fill(color));
}

/// 0..1 arası yay (zıplama eğrisi).
double hop(double t) => sin(pi * t.clamp(0.0, 1.0));

/// Periyodik göz kırpma: `period` saniyede bir kısa kapanış.
bool blinking(double seconds, {double period = 3.2}) =>
    (seconds % period) > period - 0.14;
