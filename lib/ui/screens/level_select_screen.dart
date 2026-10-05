import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../core/colors.dart';
import '../../data/session_repository.dart';
import '../../jokers/joker_type.dart';
import '../../l10n/l10n.dart';
import '../../models/level.dart';
import '../../rewards/rewarded_video_service.dart';
import '../../characters/character_registry.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/joker_bar.dart';
import '../widgets/lives_indicator.dart';
import '../widgets/out_of_lives_sheet.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final age = context.watch<SettingsController>().ageGroup;
    final levels = progress.levelsFor(age);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: context.l10n.back,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Text(
                          context.l10n.worldTitle(context.l10n.ageRangeOf(age)),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent:
                                    150 *
                                    max(
                                      1.0,
                                      MediaQuery.textScalerOf(
                                            context,
                                          ).scale(16) /
                                          16,
                                    ),
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _LevelCard(level: levels[i]),
                            childCount: levels.length,
                          ),
                        ),
                      ),
                      if (progress.worldCompleted(age))
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverToBoxAdapter(child: _NextWorldCard()),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.starEarned,
                        size: 28,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          context.l10n.totalStars(
                            progress.totalFor(age),
                            progress.maxFor(age),
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  const _LevelCard({required this.level});

  final Level level;

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  /// Can geri sayımı için saniyelik yenileme (yalnızca canı bitmişken).
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _syncTicker(bool counting) {
    if (counting && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!counting && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  void _openGame() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => GameScreen(level: widget.level)),
  );

  Future<void> _onTap(bool locked) async {
    context.read<SoundService>().play(Sound.tap);
    if (locked) {
      _shake.forward(from: 0);
      return;
    }
    final sessions = context.read<SessionRepository>();
    if (sessions.sessionFor(widget.level).lives > 0) {
      _openGame();
      return;
    }
    await _outOfLives(sessions);
  }

  /// Canı bitmiş seviye: oyun açılmaz, jokerler ve geri sayım paneli.
  Future<void> _outOfLives(SessionRepository sessions) async {
    final level = widget.level;
    final video = context.read<RewardedVideoService>();
    final progress = context.read<ProgressController>();
    final character = CharacterRegistry.byId(
      context.read<SettingsController>().characterId,
    );
    while (sessions.sessionFor(level).lives <= 0) {
      if (!mounted) return;
      final action = await OutOfLivesSheet.show(
        context,
        level: level,
        character: character,
        sessions: sessions,
        videoAvailable: video.isAvailable,
      );
      if (!mounted) return;
      switch (action) {
        case OutOfLivesAction.useLife:
          sessions.useLifeJoker(level);
          _openGame();
          return;
        case OutOfLivesAction.lifeRestored:
          _openGame();
          return;
        case OutOfLivesAction.skip:
          if (await confirmSkip(context)) {
            progress.markSkipped(level);
            sessions.reset(level);
            return;
          }
        case OutOfLivesAction.video:
          final result = await video.show(context);
          if (result == RewardedVideoResult.completed) {
            progress.markSkipped(level);
            sessions.reset(level);
            return;
          }
          if (result == RewardedVideoResult.failed && mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.l10n.videoFailed)));
          }
        case OutOfLivesAction.mainMenu:
          Navigator.popUntil(context, (route) => route.isFirst);
          return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final sessions = context.watch<SessionRepository>();
    final l = context.l10n;
    final level = widget.level;
    final title = l.levelTitle(level);
    final locked = !progress.isUnlocked(level);
    final stars = progress.starsFor(level);
    final skipped = progress.isSkipped(level);
    final lives = sessions.sessionFor(level).lives;
    final maxLives = sessions.maxLives;
    final noLives = !locked && lives <= 0;
    final nextLife = noLives ? sessions.nextLifeIn(level) : null;
    final countdown = l.countdown(nextLife ?? Duration.zero);
    _syncTicker(noLives);
    final fg = locked ? AppColors.textSecondary.withValues(alpha: 0.5) : null;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 6) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      child: Semantics(
        button: true,
        label: locked
            ? l.levelCardLockedLabel(level.id, title)
            : noLives
            ? l.levelCardNoLivesLabel(level.id, title, countdown)
            : skipped
            ? l.levelCardSkippedLabel(level.id, title)
            : lives < maxLives
            // Eksik canlar ekran okuyucuda da duyulsun.
            ? '${l.levelCardLabel(level.id, title, stars)}, '
                  '${l.livesLabel(lives)}'
            : l.levelCardLabel(level.id, title, stars),
        excludeSemantics: true,
        onTap: () => _onTap(locked),
        child: Material(
          color: locked
              ? AppColors.panel.withValues(alpha: 0.45)
              : AppColors.panel,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _onTap(locked),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${level.id}',
                        style: TextStyle(
                          color: fg ?? AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (locked)
                        Icon(Icons.lock, color: fg, size: 24)
                      else if (noLives)
                        // Canı bitmiş: kırık kalp ve bir sonraki can.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.heart_broken,
                              color: LivesIndicator.filledColor,
                              size: 20,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              countdown,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        )
                      else if (lives < maxLives)
                        Flexible(
                          child: LivesIndicator(
                            left: lives,
                            max: maxLives,
                            lostCount: 0,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg ?? AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (skipped && !locked)
                    // Atlanan seviye: yıldızların yerinde ⏭.
                    Icon(
                      jokerIcon(JokerType.skip),
                      size: 28,
                      color: AppColors.textSecondary,
                    )
                  else
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(
                            Icons.star_rounded,
                            size: 26,
                            color: locked
                                ? AppColors.starEmpty.withValues(alpha: 0.5)
                                : i < stars
                                ? AppColors.starEarned
                                : AppColors.starEmpty,
                          ),
                      ],
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

class _NextWorldCard extends StatelessWidget {
  const _NextWorldCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.floor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.activeHighlight, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.loop, color: AppColors.activeHighlight, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.nextWorldTeaser,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
