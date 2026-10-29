import 'package:flutter/material.dart';

import '../../characters/character_painter.dart';
import '../../core/colors.dart';
import '../../jokers/joker_type.dart';
import '../../l10n/l10n.dart';
import '../../models/age_group.dart';
import '../../models/command.dart';
import '../../state/game_controller.dart';
import 'app_button.dart';
import 'board_view.dart';
import 'character_view.dart';
import 'command_palette.dart';
import 'hint_bubble.dart';
import 'joker_bar.dart';
import 'program_strip.dart';

/// Oyun ekranındaki öğelerin kararlı anahtarları. Eski seviye tanıtım
/// parmağı ve eğitim modundaki vurgular (spotlight) bunlarla konum bulur.
class GameKeys {
  GameKeys({List<Command> commands = Command.values})
    : palette = {for (final c in commands) c: GlobalKey()};

  final board = GlobalKey();
  final strip = GlobalKey();
  final run = GlobalKey();
  final jokerBar = GlobalKey();
  final repeat = GlobalKey();
  final Map<Command, GlobalKey> palette;
}

/// Oyun ekranının gövdesi: tahta, program şeridi, durum satırı, joker
/// çubuğu, palet ve Çalıştır. Oyun ekranı ve eğitim modu aynı bileşeni
/// kullanır.
class GameLayout extends StatelessWidget {
  const GameLayout({
    super.key,
    required this.game,
    required this.keys,
    this.onUseJoker,
    this.videoAvailable = false,
    this.showJokers = true,
    this.showFailurePanel = true,
    this.showIntro = true,
  });

  final GameController game;
  final GameKeys keys;
  final void Function(JokerType type)? onUseJoker;
  final bool videoAvailable;
  final bool showJokers;

  /// Eğitimde başarısız bitişte panel yerine Bip konuşur.
  final bool showFailurePanel;
  final bool showIntro;

  /// Geniş yatay ekran (tablet, katlanabilir): tahta solda, kontroller
  /// sağda. Android 16'da büyük ekranlarda dikey kilit yok sayılır.
  static bool isWide(Size size) =>
      size.width >= 900 && size.width > size.height * 1.2;

  /// Tahtanın okunabilir kalması için en küçük yüksekliği (kare ≥ 28dp).
  double get _minBoardHeight {
    final level = game.level;
    return level.height * 28 + (level.height - 1) * 3 + 24;
  }

  /// Tahta dışındaki öğelerin yaklaşık yüksekliği.
  double _controlsHeight(double width, double textScale) {
    final card = game.ageSettings.cardSize;
    final stripInner = width - 32 - 12;
    const gap = ProgramStrip.gap;
    final fit = ((stripInner + gap) / (ProgramStrip.minSlot + gap)).floor();
    final cap = fit.clamp(1, ProgramStrip.maxPerRow);
    final rows = (game.level.maxSlots / cap).ceil();
    final perRow = (game.level.maxSlots / rows).ceil();
    final slot = ((stripInner - gap * (perRow - 1)) / perRow).clamp(
      0,
      card < 48 ? 48 : card,
    );
    final text = 18 * textScale;
    final jokerBar = showJokers ? 48 + 20.0 + 8 : 0.0;
    return 12 +
        text +
        6 +
        rows * (slot + gap) +
        12 +
        28 +
        jokerBar +
        card +
        19 + // palet alanının iç boşluğu ve kenarlığı
        12 +
        56 +
        12;
  }

  @override
  Widget build(BuildContext context) {
    final failed =
        game.phase == GamePhase.crashed || game.phase == GamePhase.stoppedShort;
    final l = context.l10n;
    final board = Stack(
      children: [
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(20),
            ),
            child: BoardView(game: game, paintKey: keys.board),
          ),
        ),
        if (game.skipping)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.skip_next,
                        color: AppColors.activeHighlight,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.skippedLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (showIntro && game.introVisible)
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: HintBubble(
              text: l.levelIntro(game.level),
              glyphs: game.level.introGlyphs,
              collectible: game.character.collectible,
              onClose: game.dismissIntro,
            ),
          ),
      ],
    );
    final controls = <Widget>[
      const SizedBox(height: 12),
      ProgramStrip(game: game, stripKey: keys.strip),
      _StatusLine(game: game),
      if (failed && showFailurePanel)
        _FailurePanel(game: game)
      else ...[
        if (showJokers) ...[
          KeyedSubtree(
            key: keys.jokerBar,
            child: JokerBar(
              game: game,
              onUse: onUseJoker ?? (_) {},
              videoAvailable: videoAvailable,
            ),
          ),
          const SizedBox(height: 8),
        ],
        CommandPalette(
          game: game,
          cardKeys: keys.palette,
          repeatKey: keys.repeat,
        ),
        const SizedBox(height: 12),
        _Controls(game: game, runKey: keys.run),
      ],
    ];

    if (isWide(MediaQuery.sizeOf(context))) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: board),
            const SizedBox(width: 16),
            SizedBox(
              width: 460,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: controls,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final rest = _controlsHeight(constraints.maxWidth, scale);
        final fits = constraints.maxHeight - rest >= _minBoardHeight;
        if (fits) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Expanded(child: board),
                ...controls,
              ],
            ),
          );
        }
        // Küçük ekran + büyük tahta: tahta sabit yükseklikte, sayfa kayar.
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              SizedBox(height: _minBoardHeight, child: board),
              ...controls,
            ],
          ),
        );
      },
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final index = game.currentIndex;
    final message = game.message;
    String? text;
    var color = AppColors.textSecondary;
    if (message != null) {
      text = l.gameMessage(message);
      color = switch (message) {
        GameMessage.lastLife || GameMessage.videoFailed => AppColors.warning,
        _ => AppColors.activeHighlight,
      };
    } else if (index != null && game.currentStep != null) {
      final step = game.currentStep!;
      final command = l.commandLong(step.command);
      // Döngü ya da çarpanlı kartta tur bilgisi de gösterilir.
      text = step.iterations > 1
          ? l.stepInfoRound(
              game.currentStepNumber,
              game.totalSteps,
              command,
              step.iteration,
              step.iterations,
            )
          : l.stepInfo(game.currentStepNumber, game.totalSteps, command);
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.game, required this.runKey});

  final GameController game;
  final GlobalKey runKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final running = game.isRunning;
    final Widget left;
    final Widget right;

    if (running || game.phase == GamePhase.success) {
      left = TogglePill(
        label: l.fast,
        icon: Icons.fast_forward,
        value: game.fast,
        onChanged: game.setFast,
      );
      right = AppButton(
        key: runKey,
        label: l.stop,
        icon: Icons.stop,
        onPressed: running ? game.stop : null,
      );
    } else {
      left = AppButton(
        label: l.clear,
        primary: false,
        onPressed: game.program.isEmpty ? null : game.clear,
      );
      right = AppButton(
        key: runKey,
        label: l.run,
        icon: Icons.play_arrow,
        onPressed: game.run,
      );
    }

    return Row(
      children: [
        Expanded(
          child: left is TogglePill
              ? Align(alignment: Alignment.centerLeft, child: left)
              : SizedBox(width: double.infinity, child: left),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: right),
      ],
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final crashed = game.phase == GamePhase.crashed;
    // 5–7: okumadan anlaşılsın diye büyük karakter; çarpma animasyonu
    // yeniden oynar.
    final young = game.level.ageGroup == AgeGroup.ages5to7;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (young)
            SizedBox.square(
              dimension: 88,
              child: CharacterView(
                key: ValueKey(game.lifeLostCount),
                character: game.character,
                state: crashed ? CharacterState.crash : CharacterState.idle,
                facing: game.facing,
                showDisc: true,
              ),
            ),
          Semantics(
            liveRegion: true,
            child: Text(
              crashed ? l.crashMessage : l.stoppedShortMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: l.tryAgain,
              icon: Icons.replay,
              onPressed: game.retry,
            ),
          ),
        ],
      ),
    );
  }
}
