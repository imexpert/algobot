import 'dart:math';

import 'package:flutter/material.dart';

/// Hedefe doğru kayıp hafifçe "dokunan" döngüsel el animasyonu.
/// [target]: işaret edilen noktanın genel ekran koordinatı (her karede
/// yeniden hesaplanır).
class PointingHand extends StatefulWidget {
  const PointingHand({super.key, required this.target});

  final Offset? Function() target;

  static const size = 56.0;

  @override
  State<PointingHand> createState() => _PointingHandState();
}

class _PointingHandState extends State<PointingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final box = context.findRenderObject() as RenderBox?;
          final global = widget.target();
          if (box == null || !box.hasSize || global == null) {
            return const SizedBox.expand();
          }
          final tip = box.globalToLocal(global);
          final t = _anim.value;
          // 0–0.5: aşağı-sağdan hedefe kayar; 0.5–0.7: dokunma; sonra solar.
          final approach = Curves.easeOut.transform((t / 0.5).clamp(0, 1));
          final offset = Offset(28, 36) * (1 - approach);
          final press = t > 0.5 && t < 0.7 ? sin((t - 0.5) / 0.2 * pi) : 0.0;
          final opacity = t < 0.1
              ? t / 0.1
              : t > 0.85
              ? (1 - t) / 0.15
              : 1.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                // Parmak ucu çizimin sol üstüne yakın.
                left: tip.dx + offset.dx - PointingHand.size * 0.28,
                top: tip.dy + offset.dy - PointingHand.size * 0.08,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 1 - 0.12 * press,
                    alignment: Alignment.topLeft,
                    child: const CustomPaint(
                      size: Size.square(PointingHand.size),
                      painter: HandPainter(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Sade, yukarı bakan işaret parmağı (beyaz dolgu, koyu kontur).
class HandPainter extends CustomPainter {
  const HandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);
    final path = Path()
      // İşaret parmağı
      ..moveTo(22, 8)
      ..quadraticBezierTo(22, 0, 30, 0)
      ..quadraticBezierTo(38, 0, 38, 8)
      ..lineTo(38, 44)
      // Diğer parmaklar (kıvrık)
      ..quadraticBezierTo(46, 38, 52, 44)
      ..quadraticBezierTo(60, 38, 66, 46)
      ..quadraticBezierTo(76, 42, 80, 52)
      ..lineTo(80, 74)
      ..quadraticBezierTo(80, 96, 58, 96)
      ..lineTo(40, 96)
      ..quadraticBezierTo(26, 96, 18, 84)
      // Başparmak
      ..lineTo(6, 62)
      ..quadraticBezierTo(2, 54, 10, 52)
      ..quadraticBezierTo(16, 50, 22, 58)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF26215C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(HandPainter old) => false;
}
