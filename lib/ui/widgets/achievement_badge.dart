import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../games/achievement_definitions.dart';

/// Başarım rozeti: yuvarlak madalyon ve ortada başarıma uygun simge.
/// Düz tasarım (gölge ve gradyan yok). Kilitliyken soluk, gri tonlu.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.def,
    this.earned = true,
    this.size = 64,
  });

  final AchievementDef def;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: AchievementBadgePainter(
        icon: def.icon,
        color: def.color,
        earned: earned,
      ),
    ),
  );
}

class AchievementBadgePainter extends CustomPainter {
  const AchievementBadgePainter({
    required this.icon,
    required this.color,
    this.earned = true,
  });

  final BadgeIcon icon;
  final Color color;
  final bool earned;

  static const _lockedDisc = AppColors.floor;
  static const _lockedRing = AppColors.panel;
  static const _lockedIcon = AppColors.textSecondary;

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    // Tüm çizim 100×100 birimlik bir kutuda.
    canvas.scale(s / 100);

    final disc = earned ? color : _lockedDisc;
    final ring = earned ? Color.lerp(color, Colors.black, 0.28)! : _lockedRing;
    final fg = earned
        ? (color.computeLuminance() > 0.45
              ? AppColors.background
              : AppColors.textPrimary)
        : _lockedIcon;

    const c = Offset(50, 50);
    canvas.drawCircle(c, 48, Paint()..color = ring);
    canvas.drawCircle(c, 41, Paint()..color = disc);
    // İnce iç halka: madalyon kenarı.
    canvas.drawCircle(
      c,
      37,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = fg.withValues(alpha: 0.25),
    );

    final fill = Paint()
      ..color = fg
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _IconPainter(canvas, fill, stroke, disc).draw(icon);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AchievementBadgePainter old) =>
      old.icon != icon || old.color != color || old.earned != earned;
}

/// Simgeler 100×100 kutunun ortasında (yaklaşık 26..74 aralığı).
class _IconPainter {
  _IconPainter(this.canvas, this.fill, this.stroke, this.disc);

  final Canvas canvas;
  final Paint fill;
  final Paint stroke;

  /// Simge içindeki "delikler" için zemin rengi.
  final Color disc;

  Paint get _hole => Paint()..color = disc;

  void draw(BadgeIcon icon) => switch (icon) {
    BadgeIcon.bulb => _bulb(),
    BadgeIcon.flag => _flag(),
    BadgeIcon.sparkle => _sparkle(),
    BadgeIcon.heart => _heart(),
    BadgeIcon.gear => _gear(),
    BadgeIcon.factory => _factory(),
    BadgeIcon.code => _code(),
    BadgeIcon.star1 => _star(const Offset(50, 51), 24),
    BadgeIcon.star2 => _stars2(),
    BadgeIcon.star3 => _stars3(),
    BadgeIcon.galaxy => _galaxy(),
    BadgeIcon.trophy => _trophy(),
    BadgeIcon.friend => _robot(const Offset(50, 52), 1),
    BadgeIcon.team => _team(),
    BadgeIcon.snowflake => _snowflake(),
    BadgeIcon.key => _key(),
    BadgeIcon.portal => _portal(),
    BadgeIcon.podium => _podium(),
  };

  Path _starPath(Offset c, double r, {int points = 5, double inner = 0.45}) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : r * inner;
      final a = -pi / 2 + i * pi / points;
      final p = c + Offset(cos(a), sin(a)) * radius;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  void _star(Offset c, double r) => canvas.drawPath(_starPath(c, r), fill);

  void _stars2() {
    _star(const Offset(39, 56), 16);
    _star(const Offset(62, 43), 16);
  }

  void _stars3() {
    _star(const Offset(30, 56), 12);
    _star(const Offset(50, 44), 15);
    _star(const Offset(70, 56), 12);
  }

  void _sparkle() {
    canvas.drawPath(
      _starPath(const Offset(46, 54), 24, points: 4, inner: 0.3),
      fill,
    );
    canvas.drawPath(
      _starPath(const Offset(68, 32), 9, points: 4, inner: 0.3),
      fill,
    );
  }

  void _bulb() {
    canvas.drawCircle(const Offset(50, 44), 16, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 54, 16, 12),
        const Radius.circular(3),
      ),
      fill,
    );
    canvas.drawLine(const Offset(44, 71), const Offset(56, 71), stroke);
    // Işık çizgileri.
    for (final a in [-150.0, -90.0, -30.0]) {
      final r = a * pi / 180;
      canvas.drawLine(
        const Offset(50, 44) + Offset(cos(r), sin(r)) * 21,
        const Offset(50, 44) + Offset(cos(r), sin(r)) * 26,
        stroke..strokeWidth = 4,
      );
    }
    stroke.strokeWidth = 5;
  }

  void _flag() {
    canvas.drawLine(const Offset(36, 26), const Offset(36, 75), stroke);
    final flag = Path()
      ..moveTo(38, 27)
      ..lineTo(70, 37)
      ..lineTo(38, 49)
      ..close();
    canvas.drawPath(flag, fill);
  }

  void _heart() {
    final p = Path()
      ..moveTo(50, 72)
      ..cubicTo(22, 54, 24, 30, 38, 30)
      ..cubicTo(45, 30, 49, 35, 50, 39)
      ..cubicTo(51, 35, 55, 30, 62, 30)
      ..cubicTo(76, 30, 78, 54, 50, 72)
      ..close();
    canvas.drawPath(p, fill);
  }

  void _gear() {
    const c = Offset(50, 50);
    final teeth = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final dir = Offset(cos(a), sin(a));
      final side = Offset(-sin(a), cos(a));
      final base = c + dir * 18;
      final tip = c + dir * 25;
      teeth
        ..moveTo((base + side * 5).dx, (base + side * 5).dy)
        ..lineTo((tip + side * 4).dx, (tip + side * 4).dy)
        ..lineTo((tip - side * 4).dx, (tip - side * 4).dy)
        ..lineTo((base - side * 5).dx, (base - side * 5).dy)
        ..close();
    }
    canvas.drawPath(teeth, fill);
    canvas.drawCircle(c, 19, fill);
    canvas.drawCircle(c, 8, _hole);
  }

  void _factory() {
    final p = Path()
      ..moveTo(26, 72)
      ..lineTo(26, 48)
      ..lineTo(38, 40)
      ..lineTo(38, 48)
      ..lineTo(50, 40)
      ..lineTo(50, 48)
      ..lineTo(60, 41)
      ..lineTo(60, 28)
      ..lineTo(70, 28)
      ..lineTo(70, 72)
      ..close();
    canvas.drawPath(p, fill);
    for (final x in [31.0, 43.0, 55.0]) {
      canvas.drawRect(Rect.fromLTWH(x, 56, 6, 6), _hole);
    }
  }

  void _code() {
    final s = Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(36, 36)
        ..lineTo(24, 50)
        ..lineTo(36, 64),
      s,
    );
    canvas.drawPath(
      Path()
        ..moveTo(64, 36)
        ..lineTo(76, 50)
        ..lineTo(64, 64),
      s,
    );
    canvas.drawLine(const Offset(55, 32), const Offset(45, 68), s);
  }

  void _galaxy() {
    const c = Offset(50, 52);
    canvas.drawCircle(c, 14, fill);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 52, height: 16),
      stroke..strokeWidth = 4,
    );
    canvas.restore();
    stroke.strokeWidth = 5;
    // Gezegen halkanın önünden geçsin diye üst yarısı yeniden.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 14),
      pi + 0.4,
      pi,
      true,
      fill,
    );
    _star(const Offset(30, 30), 6);
    _star(const Offset(72, 30), 4);
    _star(const Offset(70, 72), 5);
  }

  void _trophy() {
    final cup = Path()
      ..moveTo(34, 28)
      ..lineTo(66, 28)
      ..lineTo(64, 46)
      ..quadraticBezierTo(62, 58, 50, 58)
      ..quadraticBezierTo(38, 58, 36, 46)
      ..close();
    canvas.drawPath(cup, fill);
    final handles = Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      const Rect.fromLTWH(25, 31, 14, 14),
      pi / 2,
      pi,
      false,
      handles,
    );
    canvas.drawArc(
      const Rect.fromLTWH(61, 31, 14, 14),
      -pi / 2,
      pi,
      false,
      handles,
    );
    canvas.drawRect(const Rect.fromLTWH(46, 57, 8, 9), fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(37, 65, 26, 7),
        const Radius.circular(2),
      ),
      fill,
    );
  }

  /// Basit robot başı silüeti (karakterler).
  void _robot(Offset c, double k) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(k);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 38, height: 30),
        const Radius.circular(9),
      ),
      fill,
    );
    canvas.drawLine(
      const Offset(0, -15),
      const Offset(0, -22),
      Paint()
        ..color = fill.color
        ..strokeWidth = 4,
    );
    canvas.drawCircle(const Offset(0, -24), 4, fill);
    canvas.drawCircle(const Offset(-8, -2), 4.5, _hole);
    canvas.drawCircle(const Offset(8, -2), 4.5, _hole);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, 6, 14, 3.5),
        const Radius.circular(2),
      ),
      _hole,
    );
    canvas.restore();
  }

  void _team() {
    _robot(const Offset(31, 58), 0.6);
    _robot(const Offset(69, 58), 0.6);
    _robot(const Offset(50, 48), 0.75);
  }

  void _snowflake() {
    const c = Offset(50, 50);
    final s = Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3 - pi / 2;
      final dir = Offset(cos(a), sin(a));
      canvas.drawLine(c, c + dir * 24, s);
      for (final side in [-1, 1]) {
        final b = a + side * pi / 4;
        final from = c + dir * 15;
        canvas.drawLine(from, from + Offset(cos(b), sin(b)) * 8, s);
      }
    }
    canvas.drawCircle(c, 4, fill);
  }

  void _key() {
    canvas.drawCircle(const Offset(36, 50), 13, fill);
    canvas.drawCircle(const Offset(36, 50), 5, _hole);
    canvas.drawRect(const Rect.fromLTWH(46, 46, 30, 8), fill);
    canvas.drawRect(const Rect.fromLTWH(62, 54, 6, 9), fill);
    canvas.drawRect(const Rect.fromLTWH(70, 54, 6, 6), fill);
  }

  /// Kürsü ve üstünde yıldız (Toplam Yıldız skor tablosu).
  void _podium() {
    canvas.drawRect(const Rect.fromLTWH(26, 56, 16, 16), fill);
    canvas.drawRect(const Rect.fromLTWH(42, 46, 16, 26), fill);
    canvas.drawRect(const Rect.fromLTWH(58, 62, 16, 10), fill);
    _star(const Offset(50, 33), 11);
  }

  void _portal() {
    const c = Offset(50, 50);
    final s = Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(c, 22, s);
    canvas.drawCircle(c, 11, s..strokeWidth = 4);
    canvas.drawCircle(c, 3.5, fill);
  }
}
