import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../models/command.dart';

/// Sürükle-bırak yükü: paletten yeni kart ya da şeritteki bir kart.
sealed class CardDrag {
  const CardDrag();
}

class PaletteDrag extends CardDrag {
  const PaletteDrag(this.command);
  final Command command;
}

class StripDrag extends CardDrag {
  const StripDrag(this.cardId);
  final int cardId;
}

IconData commandIcon(Command c) => switch (c) {
  Command.forward || Command.moveUp => Icons.arrow_upward,
  Command.turnRight => Icons.rotate_right,
  Command.turnLeft => Icons.rotate_left,
  Command.moveDown => Icons.arrow_downward,
  Command.moveLeft => Icons.arrow_back,
  Command.moveRight => Icons.arrow_forward,
};

Color commandColor(Command c) => switch (c) {
  Command.forward => AppColors.forwardCard,
  Command.turnRight || Command.turnLeft => AppColors.turnCard,
  Command.moveUp => AppColors.upCard,
  Command.moveDown => AppColors.downCard,
  Command.moveLeft => AppColors.leftCard,
  Command.moveRight => AppColors.rightCard,
};

Color commandIconColor(Command c) => switch (c) {
  Command.forward => AppColors.forwardIcon,
  Command.turnRight || Command.turnLeft => AppColors.turnIcon,
  Command.moveUp => AppColors.upIcon,
  Command.moveDown => AppColors.downIcon,
  Command.moveLeft => AppColors.leftIcon,
  Command.moveRight => AppColors.rightIcon,
};

/// Kare komut kartı: simge + altında Türkçe etiket.
class CommandCard extends StatelessWidget {
  const CommandCard({
    super.key,
    required this.command,
    this.size = 64,
    this.highlighted = false,
  });

  final Command command;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fg = commandIconColor(command);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: commandColor(command),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppColors.activeHighlight : Colors.transparent,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: FittedBox(child: Icon(commandIcon(command), color: fg)),
          ),
          Expanded(
            flex: 2,
            child: FittedBox(
              child: Text(
                context.l10n.commandShort(command),
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sürüklenirken parmağın altında görünen kart.
class DragFeedbackCard extends StatelessWidget {
  const DragFeedbackCard({super.key, required this.command, this.size = 64});

  final Command command;
  final double size;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Transform.scale(
      scale: 1.1,
      child: CommandCard(command: command, size: size),
    ),
  );
}
