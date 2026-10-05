import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../characters/base_disc_painter.dart';
import '../../characters/character_def.dart';
import '../../characters/character_painter.dart';
import '../../core/colors.dart';
import '../../models/direction.dart';

/// Tahta dışında animasyonlu karakter (ana ekran, sonuç paneli, seçim).
/// `moving`/`turning` durumları sürekli döngüde oynatılır.
class CharacterView extends StatefulWidget {
  const CharacterView({
    super.key,
    required this.character,
    this.facing = Direction.south,
    this.state = CharacterState.idle,
    this.showDisc = false,
    this.silhouette = false,
    this.animate = true,
  });

  final CharacterDef character;
  final Direction facing;
  final CharacterState state;
  final bool showDisc;

  /// Kilitli karakterler: tek renkli koyu siluet.
  final bool silhouette;
  final bool animate;

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView>
    with SingleTickerProviderStateMixin {
  final _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(
      (elapsed) => _seconds.value = elapsed.inMicroseconds / 1e6,
    );
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(CharacterView old) {
    super.didUpdateWidget(old);
    if (!widget.animate) {
      _ticker.stop();
    } else if (!_ticker.isActive ||
        old.state != widget.state ||
        old.character != widget.character) {
      // Durum değişince animasyon saatini sıfırla.
      _ticker
        ..stop()
        ..start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite, // bulunduğu alanın tamamı
        painter: _CharacterViewPainter(
          character: widget.character,
          facing: widget.facing,
          state: widget.state,
          showDisc: widget.showDisc,
          silhouette: widget.silhouette,
          seconds: _seconds,
        ),
      ),
    );
  }
}

class _CharacterViewPainter extends CustomPainter {
  _CharacterViewPainter({
    required this.character,
    required this.facing,
    required this.state,
    required this.showDisc,
    required this.silhouette,
    required this.seconds,
  }) : super(repaint: seconds);

  final CharacterDef character;
  final Direction facing;
  final CharacterState state;
  final bool showDisc;
  final bool silhouette;
  final ValueNotifier<double> seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final s = seconds.value;
    final t = switch (state) {
      CharacterState.moving => (s / 0.8) % 1,
      CharacterState.turning => (s / 0.6) % 1,
      _ => s,
    };
    final side = size.shortestSide;
    final box = Size.square(side * 0.9);
    final origin = size.center(Offset.zero);
    if (showDisc) {
      paintBaseDisc(
        canvas,
        origin + Offset(0, side * 0.08),
        side,
        facing.index.toDouble(),
      );
    }
    if (silhouette) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..colorFilter = const ColorFilter.mode(
            AppColors.background,
            BlendMode.srcIn,
          ),
      );
    }
    canvas.save();
    canvas.translate(origin.dx - box.width / 2, origin.dy - box.height / 2);
    character.painter.paint(canvas, box, facing, state, t);
    canvas.restore();
    if (silhouette) canvas.restore();
  }

  @override
  bool shouldRepaint(_CharacterViewPainter old) =>
      old.character != character ||
      old.facing != facing ||
      old.state != state ||
      old.silhouette != silhouette ||
      old.showDisc != showDisc;
}
