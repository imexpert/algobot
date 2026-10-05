import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../models/age_config.dart';
import '../../models/command.dart';
import '../../state/game_controller.dart';
import 'command_card.dart';

/// Komut kartları. Dokununca sona ekler, sürükleyince bırakılan yuvaya
/// ekler. Görünür başlığı yok; ayrı zeminli bir alan olarak durur.
class CommandPalette extends StatelessWidget {
  const CommandPalette({
    super.key,
    required this.game,
    this.tutorialKey,
    this.tutorialCommand,
  });

  final GameController game;

  /// Eğitimdeki parmak animasyonunun işaret ettiği kartın anahtarı.
  final GlobalKey? tutorialKey;

  /// Anahtarın bağlanacağı komut; kart konumu komut türüne göre bulunur.
  final Command? tutorialCommand;

  @override
  Widget build(BuildContext context) {
    final locked = game.isLocked;
    final commands = game.level.paletteCommands;
    return Semantics(
      container: true,
      label: context.l10n.paletteSemanticsLabel,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.panel, width: 1.5),
        ),
        child: IgnorePointer(
          ignoring: locked,
          child: AnimatedOpacity(
            opacity: locked ? 0.45 : 1,
            duration: const Duration(milliseconds: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final command in commands)
                  _PaletteCard(
                    key: command == (tutorialCommand ?? commands.first)
                        ? tutorialKey
                        : null,
                    command: command,
                    size: game.ageSettings.cardSize,
                    onTap: () => game.addCommand(command),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    super.key,
    required this.command,
    required this.onTap,
    required this.size,
  });

  final Command command;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      // Kendi düğümü: tek kartlı palette etiket paletle birleşmesin.
      container: true,
      button: true,
      label: l.paletteCardLabel(l.commandShort(command)),
      excludeSemantics: true,
      onTap: onTap,
      child: Draggable<CardDrag>(
        data: PaletteDrag(command),
        feedback: DragFeedbackCard(command: command, size: size),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: CommandCard(command: command, size: size),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: CommandCard(command: command, size: size),
        ),
      ),
    );
  }
}
