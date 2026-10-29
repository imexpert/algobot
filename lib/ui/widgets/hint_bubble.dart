import 'dart:math';

import 'package:flutter/material.dart';

import '../../characters/collectibles/collectible_painter.dart';
import '../../core/colors.dart';
import '../../models/command.dart';
import '../../models/intro_glyph.dart';
import 'command_card.dart';
import '../../l10n/l10n.dart';

/// Seviye başında tahtanın üstünde görünen konuşma balonu.
class HintBubble extends StatelessWidget {
  const HintBubble({
    super.key,
    required this.text,
    required this.onClose,
    this.glyphs = const [],
    this.collectible = CollectibleKind.battery,
  });

  final String text;
  final VoidCallback onClose;

  /// 5–7 yaş: metnin yanında ipucunu anlatan simgeler.
  final List<IntroGlyph> glyphs;
  final CollectibleKind collectible;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$text. ${context.l10n.tapToClose}',
      excludeSemantics: true,
      onTap: onClose,
      child: GestureDetector(
        onTap: onClose,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (glyphs.isNotEmpty) ...[
                    _GlyphRow(glyphs: glyphs, collectible: collectible),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.tapToClose,
                    style: TextStyle(
                      color: AppColors.background.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(size: const Size(20, 10), painter: _TailPainter()),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.textPrimary);
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

/// Seviye 1 eğitimi: parmak "İleri" kartından şeride kayar,
/// ardından "Çalıştır" butonunu işaret eder.
class TutorialFinger extends StatefulWidget {
  const TutorialFinger({
    super.key,
    required this.fromKey,
    required this.toKey,
    required this.runKey,
  });

  final GlobalKey fromKey;
  final GlobalKey toKey;
  final GlobalKey runKey;

  @override
  State<TutorialFinger> createState() => _TutorialFingerState();
}

class _TutorialFingerState extends State<TutorialFinger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Offset? _centerOf(GlobalKey key, RenderBox origin) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return origin.globalToLocal(
      box.localToGlobal(box.size.center(Offset.zero)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final origin = context.findRenderObject() as RenderBox?;
          if (origin == null || !origin.hasSize) return const SizedBox.expand();
          final from = _centerOf(widget.fromKey, origin);
          final to = _centerOf(widget.toKey, origin);
          final run = _centerOf(widget.runKey, origin);
          if (from == null || to == null || run == null) {
            return const SizedBox.expand();
          }
          final t = _anim.value;
          Offset pos;
          double opacity;
          if (t < 0.6) {
            // Karttan şeride kayma.
            final u = Curves.easeInOut.transform((t / 0.6).clamp(0, 1));
            pos = Offset.lerp(from, to, u)!;
            opacity = t < 0.08 ? t / 0.08 : (t > 0.52 ? (0.6 - t) / 0.08 : 1);
          } else {
            // Çalıştır butonuna iki kez "dokunma".
            final u = (t - 0.6) / 0.4;
            pos = run + Offset(0, 6 * sin(u * 4 * pi).abs());
            opacity = u < 0.15 ? u / 0.15 : (u > 0.85 ? (1 - u) / 0.15 : 1);
          }
          return Stack(
            children: [
              Positioned(
                left: pos.dx - 8,
                top: pos.dy - 4,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: const Icon(
                    Icons.touch_app,
                    size: 48,
                    color: AppColors.textPrimary,
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

/// İpucunu okumadan anlatan simge dizisi.
class _GlyphRow extends StatelessWidget {
  const _GlyphRow({required this.glyphs, required this.collectible});

  final List<IntroGlyph> glyphs;
  final CollectibleKind collectible;

  static const size = 36.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [for (final g in glyphs) _glyph(g)],
      ),
    );
  }

  Widget _glyph(IntroGlyph g) {
    const dark = AppColors.background;
    return switch (g) {
      IntroGlyph.cardUp => const CommandCard(
        command: Command.moveUp,
        size: size,
      ),
      IntroGlyph.cardDown => const CommandCard(
        command: Command.moveDown,
        size: size,
      ),
      IntroGlyph.cardLeft => const CommandCard(
        command: Command.moveLeft,
        size: size,
      ),
      IntroGlyph.cardRight => const CommandCard(
        command: Command.moveRight,
        size: size,
      ),
      IntroGlyph.run => const CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primaryButton,
        child: Icon(Icons.play_arrow, color: AppColors.primaryButtonText),
      ),
      IntroGlyph.collectible => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _CollectibleGlyph(collectible)),
      ),
      IntroGlyph.goal => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GoalGlyph()),
      ),
      IntroGlyph.wall => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.wall,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      IntroGlyph.finger => const Icon(Icons.touch_app, color: dark, size: size),
      IntroGlyph.then => const Icon(Icons.arrow_forward, color: dark, size: 24),
      IntroGlyph.plus => const Icon(Icons.add, color: dark, size: 24),
      IntroGlyph.around => const Icon(Icons.alt_route, color: dark, size: 28),
      IntroGlyph.repeat => LoopCard(icon: Icons.repeat, label: '×', size: size),
    };
  }
}

class _CollectibleGlyph extends CustomPainter {
  _CollectibleGlyph(this.kind);
  final CollectibleKind kind;

  @override
  void paint(Canvas canvas, Size size) => paintCollectible(
    canvas,
    kind,
    size.center(Offset.zero),
    size.shortestSide,
  );

  @override
  bool shouldRepaint(_CollectibleGlyph old) => old.kind != kind;
}

class _GoalGlyph extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      size.shortestSide * 0.46,
      Paint()..color = AppColors.goalOuter,
    );
    canvas.drawCircle(
      c,
      size.shortestSide * 0.26,
      Paint()..color = AppColors.goalInner,
    );
  }

  @override
  bool shouldRepaint(_GoalGlyph old) => false;
}
