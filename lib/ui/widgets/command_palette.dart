import 'dart:math';

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
    this.tutorialRepeat = false,
  });

  final GameController game;

  /// Eğitimdeki parmak animasyonunun işaret ettiği kartın anahtarı.
  final GlobalKey? tutorialKey;

  /// Anahtarın bağlanacağı komut; kart konumu komut türüne göre bulunur.
  final Command? tutorialCommand;

  /// Eğitim parmağı Tekrarla kartını gösterir (Dünya 2'nin ilk seviyesi).
  final bool tutorialRepeat;

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
            // Kartlar sığmazsa küçülür (en az 48 dp): 5–7 Dünya 2'de dört
            // ok + Tekrarla.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count =
                    commands.length + (game.level.allowsLoops ? 1 : 0);
                const gap = 6.0;
                final size = min(
                  game.ageSettings.cardSize,
                  max(48.0, (constraints.maxWidth - gap * (count - 1)) / count),
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final command in commands)
                      _PaletteCard(
                        key:
                            !tutorialRepeat &&
                                command == (tutorialCommand ?? commands.first)
                            ? tutorialKey
                            : null,
                        command: command,
                        size: size,
                        onTap: () => game.addCommand(command),
                      ),
                    if (game.level.allowsLoops)
                      _RepeatCard(
                        key: tutorialRepeat ? tutorialKey : null,
                        size: size,
                        onTap: () => game.addRepeat(),
                      ),
                  ],
                );
              },
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

/// Dünya 2: Tekrarla kartı. 5–7'de son kartın çarpanını artırır,
/// 8–12/13+'da şeride döngü bloğu ekler.
class _RepeatCard extends StatelessWidget {
  const _RepeatCard({super.key, required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final card = LoopCard(icon: Icons.repeat, label: l.cmdRepeat, size: size);
    return Semantics(
      container: true,
      button: true,
      label: l.paletteCardLabel(l.cmdRepeat),
      excludeSemantics: true,
      onTap: onTap,
      child: Draggable<CardDrag>(
        data: const RepeatDrag(),
        feedback: Material(
          type: MaterialType.transparency,
          child: Transform.scale(scale: 1.1, child: card),
        ),
        childWhenDragging: Opacity(opacity: 0.5, child: card),
        child: GestureDetector(onTap: onTap, child: card),
      ),
    );
  }
}
