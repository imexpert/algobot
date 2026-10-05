import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/l10n.dart';
import '../../state/game_controller.dart';
import 'board_painter.dart';

/// Izgarayı mevcut alana sığacak şekilde ölçekler; kare üst sınırı yaşa göre.
class BoardView extends StatefulWidget {
  const BoardView({super.key, required this.game});

  final GameController game;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _frame.value++)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.game.level;
    final maxCell = widget.game.ageSettings.maxCell;
    const gap = BoardPainter.gap;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = [
          maxCell,
          (constraints.maxWidth - gap * (level.width - 1)) / level.width,
          (constraints.maxHeight - gap * (level.height - 1)) / level.height,
        ].reduce(min).clamp(8.0, maxCell);
        final size = Size(
          cell * level.width + gap * (level.width - 1),
          cell * level.height + gap * (level.height - 1),
        );
        return Center(
          child: Semantics(
            label: context.l10n.board,
            image: true,
            child: CustomPaint(
              size: size,
              painter: BoardPainter(
                game: widget.game,
                frame: _frame,
                cellSize: cell,
              ),
            ),
          ),
        );
      },
    );
  }
}
