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

/// Paletten sürüklenen Tekrarla kartı.
class RepeatDrag extends CardDrag {
  const RepeatDrag();
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
    this.times = 1,
  });

  final Command command;
  final double size;
  final bool highlighted;

  /// 5–7 çarpanı (×3); 1 ise rozet yok.
  final int times;

  @override
  Widget build(BuildContext context) {
    final fg = commandIconColor(command);
    final card = Container(
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
    if (times <= 1) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          right: -4,
          top: -6,
          child: LoopBadge(text: '×$times', size: size),
        ),
      ],
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

/// Döngü kartlarındaki küçük pembe rozet (×3, 2/4).
class LoopBadge extends StatelessWidget {
  const LoopBadge({super.key, required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.08, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.loopCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.loopIcon, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.loopIcon,
          fontSize: (size * 0.24).clamp(11, 15),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Pembe döngü kartı: palette "Tekrarla", şeritte "↻ ×N" ya da "] Son".
class LoopCard extends StatelessWidget {
  const LoopCard({
    super.key,
    required this.icon,
    required this.label,
    this.size = 64,
    this.highlighted = false,
    this.glowing = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final double size;

  /// Çalışırken etkin döngü (sarı çerçeve).
  final bool highlighted;

  /// Açık döngünün sonu: yeni kartların içine girdiğini gösterir.
  final bool glowing;

  /// Tur bilgisi (2/4).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: AppColors.loopCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted || glowing
              ? AppColors.activeHighlight
              : Colors.transparent,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: FittedBox(child: Icon(icon, color: AppColors.loopIcon)),
          ),
          Expanded(
            flex: 2,
            child: FittedBox(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.loopIcon,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (badge == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          right: -4,
          top: -6,
          child: LoopBadge(text: badge!, size: size),
        ),
      ],
    );
  }
}
