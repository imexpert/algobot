import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../state/game_controller.dart';
import 'command_card.dart';

/// "Programın" şeridi: `maxSlots` kadar yuva, gerektiğinde birden çok satır.
class ProgramStrip extends StatefulWidget {
  const ProgramStrip({super.key, required this.game, this.stripKey});

  final GameController game;

  /// Seviye 1 eğitimindeki parmak animasyonu için şeridin konumu.
  final GlobalKey? stripKey;

  static const maxPerRow = 8;
  static const minSlot = 48.0;
  static const gap = 4.0;

  @override
  State<ProgramStrip> createState() => _ProgramStripState();
}

class _ProgramStripState extends State<ProgramStrip> {
  /// Daha önce görülen kartlar; yalnızca yeni eklenenler "belirme"
  /// animasyonu oynatır.
  final Set<int> _seen = {};

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final program = game.program;
    final newIds = program.map((c) => c.id).where((id) => !_seen.contains(id));
    final animateIn = newIds.toSet();
    _seen
      ..retainAll(program.map((c) => c.id))
      ..addAll(animateIn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.program,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              context.l10n.slotCounter(program.length, game.level.maxSlots),
              style: TextStyle(
                color: game.isFull
                    ? AppColors.activeHighlight
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          key: widget.stripKey,
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: game.stripWarning
                ? Color.alphaBlend(
                    AppColors.warning.withValues(alpha: 0.45),
                    AppColors.panel,
                  )
                : AppColors.panel,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _buildSlots(constraints.maxWidth, animateIn),
          ),
        ),
      ],
    );
  }

  Widget _buildSlots(double width, Set<int> animateIn) {
    final game = widget.game;
    final slots = game.level.maxSlots;
    const gap = ProgramStrip.gap;
    final fit = max(1, ((width + gap) / (ProgramStrip.minSlot + gap)).floor());
    final cap = min(ProgramStrip.maxPerRow, fit);
    final rows = (slots / cap).ceil();
    final perRow = (slots / rows).ceil();
    final size = min(
      max(ProgramStrip.minSlot, game.ageSettings.cardSize),
      (width - gap * (perRow - 1)) / perRow,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = r * perRow; i < min(slots, (r + 1) * perRow); i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == r * perRow ? 0 : gap),
                    child: _slot(i, size, animateIn),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _slot(int i, double size, Set<int> animateIn) {
    final game = widget.game;
    final program = game.program;
    final card = i < program.length ? program[i] : null;
    return DragTarget<CardDrag>(
      onWillAcceptWithDetails: (_) => !game.isLocked,
      onAcceptWithDetails: (details) {
        switch (details.data) {
          case PaletteDrag(:final command):
            game.addCommand(command, at: i);
          case StripDrag(:final cardId):
            game.moveCard(cardId, i);
        }
      },
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        Widget child;
        if (card != null) {
          child = _StripCard(
            key: ValueKey(card.id),
            card: card,
            size: size,
            highlighted: game.currentIndex == i,
            locked: game.isLocked,
            animateIn: animateIn.contains(card.id),
            onRemove: () => game.removeCard(card.id),
          );
        } else {
          child = Semantics(
            label: context.l10n.emptySlotLabel(i + 1),
            child: CustomPaint(
              size: Size.square(size),
              painter: _DashedSlotPainter(
                color: hovering
                    ? AppColors.activeHighlight
                    : AppColors.textSecondary.withValues(alpha: 0.45),
              ),
            ),
          );
        }
        if (hovering && card != null) {
          // Bırakılacak konumu belirtmek için sol kenar çizgisi.
          child = Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              Positioned(
                left: -ProgramStrip.gap / 2 - 2,
                top: 4,
                bottom: 4,
                child: Container(width: 4, color: AppColors.activeHighlight),
              ),
            ],
          );
        }
        return SizedBox.square(dimension: size, child: child);
      },
    );
  }
}

class _StripCard extends StatefulWidget {
  const _StripCard({
    super.key,
    required this.card,
    required this.size,
    required this.highlighted,
    required this.locked,
    required this.animateIn,
    required this.onRemove,
  });

  final ProgramCard card;
  final double size;
  final bool highlighted;
  final bool locked;
  final bool animateIn;

  final VoidCallback onRemove;

  @override
  State<_StripCard> createState() => _StripCardState();
}

class _StripCardState extends State<_StripCard> with TickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    value: widget.animateIn ? 0.4 : 1,
  );
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    if (widget.animateIn) _scale.forward();
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    if (_removing || widget.locked) return;
    _removing = true;
    await _scale.animateTo(0, curve: Curves.easeIn);
    if (mounted) widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final command = widget.card.command;
    final card = AnimatedScale(
      scale: widget.highlighted ? 1.08 : 1,
      duration: const Duration(milliseconds: 150),
      child: CommandCard(
        command: command,
        size: widget.size,
        highlighted: widget.highlighted,
      ),
    );
    return Semantics(
      button: true,
      label: context.l10n.stripCardLabel(context.l10n.commandLong(command)),
      excludeSemantics: true,
      onTap: widget.locked ? null : _remove,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _scale, curve: Curves.easeOutBack),
        child: IgnorePointer(
          ignoring: widget.locked,
          child: LongPressDraggable<CardDrag>(
            data: StripDrag(widget.card.id),
            feedback: DragFeedbackCard(command: command, size: widget.size),
            childWhenDragging: Opacity(opacity: 0.3, child: card),
            child: GestureDetector(onTap: _remove, child: card),
          ),
        ),
      ),
    );
  }
}

class _DashedSlotPainter extends CustomPainter {
  _DashedSlotPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1.5),
      const Radius.circular(12),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      const dash = 6.0, space = 5.0;
      for (var d = 0.0; d < metric.length; d += dash + space) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedSlotPainter old) => old.color != color;
}
