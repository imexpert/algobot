import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../characters/character_registry.dart';
import '../../core/colors.dart';
import '../../data/session_repository.dart';
import '../../games/achievement_sync.dart';
import '../../jokers/joker_type.dart';
import '../../l10n/l10n.dart';
import '../../models/age_config.dart';
import '../../models/level.dart';
import '../../review/review_service.dart';
import '../../rewards/rewarded_video_service.dart';
import '../../state/game_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../tutorial/mechanic_intro.dart';
import '../../tutorial/tutorial_controller.dart';
import '../../tutorial/tutorial_scripts.dart';
import '../tutorial/tutorial_screen.dart';
import '../widgets/achievement_toast.dart';
import '../widgets/game_layout.dart';
import '../widgets/hint_bubble.dart';
import '../widgets/joker_bar.dart';
import '../widgets/lives_indicator.dart';
import '../widgets/new_friend_dialog.dart';
import '../widgets/out_of_lives_sheet.dart';
import '../widgets/parent_gate_dialog.dart';
import '../widgets/result_sheet.dart';
import '../widgets/review_prompt_dialog.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final GameController _game;

  final _keys = GameKeys();

  /// Bu seviye oturumu başladığında toplam yıldız (yeni karakter tespiti).
  late int _starsBefore;

  /// Bu oturum başladığında üç yıldızlı seviye sayısı (değerlendirme sorusu).
  late int _threeStarsBefore;

  @override
  void initState() {
    super.initState();
    final progress = context.read<ProgressController>();
    final settings = context.read<SettingsController>();
    _game =
        GameController(
            level: widget.level,
            character: CharacterRegistry.byId(settings.characterId),
            vsync: this,
            sound: context.read<SoundService>(),
            progress: progress,
            sessions: context.read<SessionRepository>(),
            // Eğitim tamamlandıysa Seviye 1–2 parmak tanıtımı tekrarlanmaz
            // (atlandıysa gösterilir).
            suppressLevelTutorial:
                settings.tutorialStatus(
                  widget.level.ageGroup.settings.commandFamily,
                ) ==
                TutorialStatus.completed,
          )
          ..onSuccess = _showResult
          ..onOutOfLives = _showOutOfLives
          ..onSkipped = _goToNextLevel;
    // Canı bitmiş bir seviyeye girildiyse panel hemen açılır.
    if (_game.outOfLives) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOutOfLives());
    }
    _starsBefore = progress.totalStarsAll;
    _threeStarsBefore = progress.threeStarCount;
    // 13+: mekaniğin ilk göründüğü seviyede, başlamadan kısa tanıtım.
    final mechanic = _mechanic;
    if (mechanic != null &&
        !_game.outOfLives &&
        !settings.mechanicIntroSeen(mechanic)) {
      _startIntro();
    }
  }

  /// Bu seviye bir 13+ mekaniğini tanıtıyorsa adı (`ice`, `door`, `portal`).
  late final String? _mechanic = mechanicIntroFor(widget.level);

  /// Mekanik tanıtımı (oyun ekranının üstünde, seviyenin kendi tahtasında).
  TutorialController? _intro;

  void _startIntro() {
    if (_game.isRunning) _game.stop();
    _game.dismissIntro();
    final intro = TutorialController(
      steps: mechanicIntros[_mechanic]!,
      onFinished: _endIntro,
    )..attach(_game);
    _intro = intro;
  }

  void _endIntro() {
    final intro = _intro;
    if (intro == null) return;
    intro.detach(_game);
    _game.playGhost(null);
    context.read<SettingsController>().setMechanicIntroSeen(_mechanic!);
    setState(() => _intro = null);
    // Katman bu kareden sonra kalkar; denetleyici sonra bırakılır.
    WidgetsBinding.instance.addPostFrameCallback((_) => intro.dispose());
  }

  /// "?": onaydan sonra eğitim (ve 13+ tanıtım seviyesinde kısa tanıtım).
  /// Eğitimden dönünce aynı seviye ve aynı program şeridi korunur.
  Future<void> _help() async {
    if (_game.isRunning) _game.stop();
    final l = context.l10n;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        content: Text(
          l.tutHelpConfirm,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (_mechanic != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'mechanic'),
              child: Text(
                l.tutHelpMechanic,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'tutorial'),
            child: Text(
              l.tutHelpStart,
              style: const TextStyle(
                color: AppColors.primaryButton,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'tutorial':
        await openTutorial(context, widget.level.ageGroup);
      case 'mechanic':
        setState(_startIntro);
    }
  }

  @override
  void dispose() {
    // Geri tuşu dahil: devam eden animasyon güvenle iptal edilir.
    _intro?.dispose();
    _game.dispose();
    super.dispose();
  }

  Future<void> _showResult() async {
    final result = _game.lastResult;
    if (result == null || !mounted) return;
    final progress = context.read<ProgressController>();
    // Başarımlar hemen hesaplanıp kaydedilir; bildirim panelden sonra.
    final sync = context.read<AchievementSync?>();
    final achieved =
        sync?.update(
          achievementFacts(
            progress,
            context.read<SettingsController>(),
            solvedOnLastLife: _game.solvedOnLastLife,
          ),
        ) ??
        const [];
    sync?.submitTotalStars(progress.totalStarsAll);
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
    AchievementToast.show(context, achieved);
    if (!switched) await _maybeAskForReview();
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

  /// Kilometre taşında (dünya bitti ya da 5/15/30. üç yıldız) ve
  /// [ReviewService] kuralları uygunsa ebeveyne değerlendirme sorulur.
  /// Yalnızca gerçek başarıdan sonra çağrılır (atlama ya da video değil).
  Future<void> _maybeAskForReview() async {
    final progress = context.read<ProgressController>();
    final review = context.read<ReviewService>();
    final threeStars = progress.threeStarCount;
    final milestone =
        _isWorldFinal(widget.level) ||
        ReviewService.crossedStarMilestone(_threeStarsBefore, threeStars);
    _threeStarsBefore = threeStars;
    if (!review.shouldPrompt(milestone: milestone)) return;
    await review.markPrompted();
    if (!mounted) return;
    if (!await ReviewPromptDialog.show(context, _game.character)) return;
    if (!mounted) return;
    if (!await ParentGateDialog.verify(context)) return;
    await review.requestReview();
  }

  /// Dünyanın son seviyesi mi (aynı dünyada sonraki seviye yok).
  bool _isWorldFinal(Level level) {
    final next = context.read<ProgressController>().levelAfter(level);
    return next == null || next.world != level.world;
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
            constraints: BoxConstraints(
              maxWidth: GameLayout.isWide(MediaQuery.sizeOf(context))
                  ? 1200
                  : 600,
            ),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _game,
                context.read<SessionRepository>(),
              ]),
              builder: (context, _) => Stack(
                children: [
                  Column(
                    children: [
                      _TopBar(game: _game, onHelp: _help),
                      Expanded(
                        child: GameLayout(
                          game: _game,
                          keys: _keys,
                          onUseJoker: _useJoker,
                          videoAvailable: context
                              .read<RewardedVideoService>()
                              .isAvailable,
                        ),
                      ),
                    ],
                  ),
                  if (_game.showTutorial && _intro == null)
                    Positioned.fill(
                      child: TutorialFinger(
                        // Çözümün ilk kartı (8–12 Seviye 1: İleri) ya da
                        // Dünya 2'nin ilk seviyesinde Tekrarla.
                        fromKey: _game.tutorialPointsToRepeat
                            ? _keys.repeat
                            : _keys.palette[_game.tutorialCommand]!,
                        toKey: _keys.strip,
                        runKey: _keys.run,
                      ),
                    ),
                  if (_intro case final intro?)
                    Positioned.fill(
                      child: TutorialOverlay(
                        tutorial: intro,
                        game: _game,
                        keys: _keys,
                        finishLabel: context.l10n.tutGotIt,
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.game, required this.onHelp});

  final GameController game;
  final VoidCallback onHelp;

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
                  l.levelHeader(level.world, level.number),
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
          IconButton(
            tooltip: l.howToPlay,
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
            onPressed: onHelp,
          ),
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
