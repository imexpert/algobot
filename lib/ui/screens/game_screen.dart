import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../characters/character_painter.dart';
import '../../characters/character_registry.dart';
import '../../core/colors.dart';
import '../../data/session_repository.dart';
import '../../jokers/joker_type.dart';
import '../../l10n/l10n.dart';
import '../../models/age_group.dart';
import '../../models/level.dart';
import '../../rewards/rewarded_video_service.dart';
import '../../state/game_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/board_view.dart';
import '../widgets/character_view.dart';
import '../widgets/command_palette.dart';
import '../widgets/hint_bubble.dart';
import '../widgets/joker_bar.dart';
import '../widgets/lives_indicator.dart';
import '../widgets/new_friend_dialog.dart';
import '../widgets/out_of_lives_sheet.dart';
import '../widgets/program_strip.dart';
import '../widgets/result_sheet.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final GameController _game;

  final _paletteKey = GlobalKey();
  final _stripKey = GlobalKey();
  final _runKey = GlobalKey();

  /// Bu seviye oturumu başladığında toplam yıldız (yeni karakter tespiti).
  late int _starsBefore;

  @override
  void initState() {
    super.initState();
    final progress = context.read<ProgressController>();
    _game =
        GameController(
            level: widget.level,
            character: CharacterRegistry.byId(
              context.read<SettingsController>().characterId,
            ),
            vsync: this,
            sound: context.read<SoundService>(),
            progress: progress,
            sessions: context.read<SessionRepository>(),
          )
          ..onSuccess = _showResult
          ..onOutOfLives = _showOutOfLives
          ..onSkipped = _goToNextLevel;
    // Canı bitmiş bir seviyeye girildiyse panel hemen açılır.
    if (_game.outOfLives) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOutOfLives());
    }
    _starsBefore = progress.totalStarsAll;
  }

  @override
  void dispose() {
    // Geri tuşu dahil: devam eden animasyon güvenle iptal edilir.
    _game.dispose();
    super.dispose();
  }

  Future<void> _showResult() async {
    final result = _game.lastResult;
    if (result == null || !mounted) return;
    final progress = context.read<ProgressController>();
    final action = await ResultSheet.show(
      context,
      level: widget.level,
      character: _game.character,
      result: result,
      stars: _game.lastStars,
    );
    if (!mounted) return;

    // Yeni karakter açıldıysa seviye sonundan sonra kutla.
    final after = progress.totalStarsAll;
    final unlocked = CharacterRegistry.newlyUnlocked(_starsBefore, after);
    _starsBefore = after;
    var switched = false;
    for (final friend in unlocked) {
      if (!mounted) return;
      if (await NewFriendDialog.show(context, friend)) {
        if (!mounted) return;
        await context.read<SettingsController>().setCharacter(friend.id);
        switched = true;
      }
    }
    if (!mounted) return;
    if (switched && action != ResultAction.next) {
      // Yeni arkadaşla aynı seviyeyi tekrar dene.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(level: widget.level),
        ),
      );
      return;
    }
    if (action != ResultAction.next) {
      _game.retry();
      return;
    }
    _goToNextLevel();
  }

  /// Sonraki seviyeye geçer; son seviyedeyse seviye seçimine döner.
  void _goToNextLevel() {
    if (!mounted) return;
    final next = context.read<ProgressController>().levelAfter(widget.level);
    if (next == null) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => GameScreen(level: next)),
      );
    }
  }

  /// Ana menü: yığın temizlenir, geri tuşu oyun ekranına dönmez.
  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  bool _showingOutOfLives = false;

  /// Canlar bitti: kullanılmamış jokerler, geri sayım ve "Ana menü".
  Future<void> _showOutOfLives() async {
    if (_showingOutOfLives) return;
    _showingOutOfLives = true;
    try {
      while (_game.outOfLives) {
        if (!mounted) return;
        final video = context.read<RewardedVideoService>();
        final action = await OutOfLivesSheet.show(
          context,
          level: widget.level,
          character: _game.character,
          sessions: context.read<SessionRepository>(),
          videoAvailable: video.isAvailable,
        );
        if (!mounted) return;
        switch (action) {
          case OutOfLivesAction.useLife:
            _game
              ..useLifeJoker()
              ..retry();
          case OutOfLivesAction.lifeRestored:
            _game.retry();
          case OutOfLivesAction.skip:
            if (await confirmSkip(context)) {
              await _game.skipLevel(JokerType.skip);
              return;
            }
          case OutOfLivesAction.video:
            if (await _playVideo()) return;
          case OutOfLivesAction.mainMenu:
            _goHome();
            return;
        }
      }
    } finally {
      _showingOutOfLives = false;
    }
  }

  /// Video jokeri: yalnızca tamamlanırsa seviye atlanır. Tamamlandıysa true.
  Future<bool> _playVideo() async {
    final result = await context.read<RewardedVideoService>().show(context);
    if (!mounted) return false;
    if (result == RewardedVideoResult.completed) {
      await _game.skipLevel(JokerType.video);
      return true;
    }
    _game.videoNotCompleted(failed: result == RewardedVideoResult.failed);
    return false;
  }

  Future<void> _useJoker(JokerType type) async {
    switch (type) {
      case JokerType.life:
        _game.useLifeJoker();
      case JokerType.skip:
        if (await confirmSkip(context) && mounted) {
          await _game.skipLevel(JokerType.skip);
        }
      case JokerType.video:
        await _playVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _game,
                context.read<SessionRepository>(),
              ]),
              builder: (context, _) => Stack(
                children: [
                  Column(
                    children: [
                      _TopBar(game: _game),
                      Expanded(child: _body()),
                    ],
                  ),
                  if (_game.showTutorial)
                    Positioned.fill(
                      child: TutorialFinger(
                        fromKey: _paletteKey,
                        toKey: _stripKey,
                        runKey: _runKey,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tahtanın okunabilir kalması için en küçük yüksekliği (kare ≥ 28dp).
  double get _minBoardHeight {
    final level = widget.level;
    return level.height * 28 + (level.height - 1) * 3 + 24;
  }

  /// Tahta dışındaki öğelerin yaklaşık yüksekliği.
  double _controlsHeight(double width, double textScale) {
    final game = _game;
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
    const jokerBar = 48 + 20.0 + 8;
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

  Widget _body() {
    final game = _game;
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
            child: BoardView(game: game),
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
        if (game.introVisible)
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
      ProgramStrip(game: game, stripKey: _stripKey),
      _StatusLine(game: game),
      if (failed)
        _FailurePanel(game: game)
      else ...[
        JokerBar(
          game: game,
          onUse: _useJoker,
          videoAvailable: context.read<RewardedVideoService>().isAvailable,
        ),
        const SizedBox(height: 8),
        CommandPalette(
          game: game,
          tutorialKey: _paletteKey,
          // Eğitim parmağı çözümün ilk kartını (8–12 Seviye 1: İleri)
          // işaret eder; konum komut türüne göre bulunur.
          tutorialCommand: game.level.referenceSolution.first,
        ),
        const SizedBox(height: 12),
        _Controls(game: game, runKey: _runKey),
      ],
    ];

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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final level = game.level;
    final l = context.l10n;
    // Geri butonu solda, seviye bilgisi ortada, canlar sağda (denge için).
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
      child: Row(
        children: [
          IconButton(
            tooltip: l.back,
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.levelHeader(level.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l.levelTitle(level),
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, maxWidth: 76),
            child: LivesIndicator(
              left: game.lives,
              max: game.livesMax,
              lostCount: game.lifeLostCount,
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
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
    } else if (index != null && index < game.program.length) {
      text = l.stepInfo(
        index + 1,
        game.program.length,
        l.commandLong(game.program[index].command),
      );
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
