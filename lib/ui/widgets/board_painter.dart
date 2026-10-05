import 'dart:math';

import 'package:flutter/material.dart';

import '../../characters/base_disc_painter.dart';
import '../../characters/collectibles/collectible_painter.dart';
import '../../core/colors.dart';
import '../../models/cell.dart';
import '../../state/game_controller.dart';

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.game,
    required this.frame,
    required this.cellSize,
  }) : super(repaint: Listenable.merge([game, game.animation, frame]));

  static const gap = 3.0;

  final GameController game;

  /// Her karede tetiklenir (bekleme animasyonları için).
  final Listenable frame;
  final double cellSize;

  double get _pitch => cellSize + gap;

  Offset _center(double x, double y) =>
      Offset(x * _pitch + cellSize / 2, y * _pitch + cellSize / 2);

  Offset _centerOf(Point<int> p) => _center(p.x.toDouble(), p.y.toDouble());

  @override
  void paint(Canvas canvas, Size size) {
    final level = game.level;
    final c = cellSize;
    final now = game.now;
    final radius = Radius.circular(c * 0.15);

    // Kareler.
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final p = Point(x, y);
        final rect = Rect.fromLTWH(x * _pitch, y * _pitch, c, c);
        final rrect = RRect.fromRectAndRadius(rect, radius);
        switch (level.cellAt(p)) {
          case CellType.wall:
            canvas.drawRRect(rrect, Paint()..color = AppColors.wall);
          case CellType.ice:
            _paintIce(canvas, rrect);
          case CellType.door:
            canvas.drawRRect(rrect, Paint()..color = AppColors.floor);
            _paintDoor(canvas, rect, game.doorsOpen);
          case CellType.portalA || CellType.portalB:
            canvas.drawRRect(rrect, Paint()..color = AppColors.floor);
            _paintPortal(canvas, rect.center, c, now);
          case CellType.floor:
            canvas.drawRRect(rrect, Paint()..color = AppColors.floor);
        }
      }
    }

    // Başlangıç karesi halkası.
    canvas.drawCircle(
      _centerOf(level.start),
      c * 0.44,
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, c * 0.03),
    );

    // İz noktaları.
    final trailPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35);
    for (final p in game.trail) {
      canvas.drawCircle(_centerOf(p), c * 0.07, trailPaint);
    }

    // Hedef: nabız gibi büyüyüp küçülen iki daire (1,5 sn döngü).
    final beat = 1 + 0.08 * sin(now / 1.5 * 2 * pi);
    final goal = _centerOf(level.goal);
    canvas.drawCircle(
      goal,
      c * 0.34 * beat,
      Paint()..color = AppColors.goalOuter,
    );
    canvas.drawCircle(goal, c * 0.2, Paint()..color = AppColors.goalInner);

    // Toplanabilirler ve anahtar (hafifçe süzülür).
    final kind = game.character.collectible;
    for (final p in game.remainingCollectibles) {
      paintCollectible(canvas, kind, _centerOf(p), c * 0.55, bob: now + p.x);
    }
    for (final p in game.remainingKeys) {
      _paintKey(canvas, _centerOf(p), c, now, 1);
    }

    final cell = game.characterCell;
    final charCenter = _center(cell.dx, cell.dy);

    // Toplanan nesneler küçülerek karaktere doğru uçar.
    for (final item in game.flyingItems) {
      if (item.progress >= 1) continue;
      final pos = Offset.lerp(
        _centerOf(item.cell),
        charCenter - Offset(0, c * 0.1),
        item.progress,
      )!;
      final scale = 1 - item.progress;
      if (item.isKey) {
        _paintKey(canvas, pos, c, 0, scale);
      } else {
        paintCollectible(canvas, kind, pos, c * 0.55, scale: scale);
      }
    }

    // Taban diski + yön oku, üstünde karakter.
    final scale = game.characterScale;
    canvas.save();
    canvas.translate(charCenter.dx, charCenter.dy);
    canvas.scale(scale);
    paintBaseDisc(canvas, Offset.zero, c, game.discQuarterTurns);
    final box =
        c * 1.0; // karakter kutunun ~%75ini, yani karenin ~%75ini kaplar
    canvas.translate(-box / 2, -box / 2 - c * 0.05);
    game.character.painter.paint(
      canvas,
      Size.square(box),
      game.facing,
      game.characterState,
      game.characterTime,
    );
    canvas.restore();
  }

  void _paintIce(Canvas canvas, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = AppColors.ice);
    final r = rrect.outerRect;
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = max(1.5, r.width * 0.05)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      r.topLeft + Offset(r.width * 0.22, r.height * 0.45),
      r.topLeft + Offset(r.width * 0.45, r.height * 0.22),
      shine,
    );
    canvas.drawLine(
      r.topLeft + Offset(r.width * 0.5, r.height * 0.78),
      r.topLeft + Offset(r.width * 0.78, r.height * 0.5),
      shine,
    );
  }

  /// Kapı: anahtar alınınca aşağı kayıp kaybolur.
  void _paintDoor(Canvas canvas, Rect cell, double open) {
    if (open >= 1) return;
    canvas.save();
    canvas.clipRect(cell);
    final inset = cell.width * 0.08;
    final door = Rect.fromLTRB(
      cell.left + inset,
      cell.top + inset + cell.height * open,
      cell.right - inset,
      cell.bottom + cell.height * open,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, Radius.circular(cell.width * 0.1)),
      Paint()..color = AppColors.door,
    );
    // Kilit deliği.
    final k = door.center;
    final dark = Paint()..color = AppColors.wall;
    canvas.drawCircle(
      k - Offset(0, cell.width * 0.06),
      cell.width * 0.08,
      dark,
    );
    canvas.drawPath(
      Path()
        ..moveTo(k.dx - cell.width * 0.05, k.dy - cell.width * 0.04)
        ..lineTo(k.dx + cell.width * 0.05, k.dy - cell.width * 0.04)
        ..lineTo(k.dx + cell.width * 0.03, k.dy + cell.width * 0.14)
        ..lineTo(k.dx - cell.width * 0.03, k.dy + cell.width * 0.14)
        ..close(),
      dark,
    );
    canvas.restore();
  }

  /// Portal: iç içe, yavaşça dönen halkalar. Çiftin iki ucu aynı renkte.
  void _paintPortal(Canvas canvas, Offset center, double c, double now) {
    for (final (r, color, speed) in [
      (c * 0.36, AppColors.portalOuter, 0.8),
      (c * 0.22, AppColors.portalInner, -1.3),
    ]) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, c * 0.08)
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCircle(center: center, radius: r);
      for (var i = 0; i < 3; i++) {
        canvas.drawArc(
          rect,
          now * speed + i * 2 * pi / 3,
          pi / 2,
          false,
          paint,
        );
      }
    }
    canvas.drawCircle(center, c * 0.08, Paint()..color = AppColors.portalInner);
  }

  void _paintKey(
    Canvas canvas,
    Offset center,
    double c,
    double bob,
    double scale,
  ) {
    if (scale <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy + sin(bob * 3) * c * 0.03);
    canvas.scale(scale);
    canvas.rotate(-pi / 4);
    final paint = Paint()..color = AppColors.key;
    final s = c * 0.5;
    canvas.drawCircle(Offset(-s * 0.3, 0), s * 0.22, paint);
    canvas.drawCircle(
      Offset(-s * 0.3, 0),
      s * 0.09,
      Paint()..color = AppColors.floor,
    );
    canvas.drawRect(
      Rect.fromLTRB(-s * 0.12, -s * 0.06, s * 0.45, s * 0.06),
      paint,
    );
    canvas.drawRect(Rect.fromLTRB(s * 0.25, 0, s * 0.33, s * 0.18), paint);
    canvas.drawRect(Rect.fromLTRB(s * 0.37, 0, s * 0.45, s * 0.13), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.game != game || old.cellSize != cellSize || old.frame != frame;
}
