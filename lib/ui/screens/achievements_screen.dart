import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../games/achievement_definitions.dart';
import '../../games/achievement_sync.dart';
import '../../l10n/l10n.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/game_platform_buttons.dart';

/// Uygulama içi başarımlar: yerel tablodan çalışır, oturum gerektirmez.
/// En altta, oturum açıksa, ebeveyn kapısı arkasında platform butonları.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<AchievementSync?>();
    final l = context.l10n;
    final defs = Achievements.all;
    AchievementState stateOf(AchievementDef d) =>
        sync?.stateOf(d.key) ?? AchievementState.locked;
    final unlocked = defs.where((d) => stateOf(d).unlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l.back,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Text(
                          l.achievements,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.activeHighlight,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$unlocked / ${defs.length}',
                        semanticsLabel: l.achievementsSummary(
                          unlocked,
                          defs.length,
                        ),
                        style: const TextStyle(
                          color: AppColors.activeHighlight,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // İki sütun; satırdaki kartlar aynı yükseklikte ve
                      // yazı büyüyünce kart da uzar (taşma yok).
                      for (var i = 0; i < defs.length; i += 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: AchievementCard(
                                    def: defs[i],
                                    state: stateOf(defs[i]),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: i + 1 < defs.length
                                      ? AchievementCard(
                                          def: defs[i + 1],
                                          state: stateOf(defs[i + 1]),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (sync != null && sync.isSignedIn) ...[
                        const SizedBox(height: 12),
                        Text(
                          l.achievementsParentArea,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GamePlatformButtons(sync: sync, gated: true),
                      ],
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

/// Tek başarım kartı: rozet, ad, açıklama ve (artanlarda) ilerleme.
class AchievementCard extends StatelessWidget {
  const AchievementCard({super.key, required this.def, required this.state});

  final AchievementDef def;
  final AchievementState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final earned = state.unlocked;
    final progress = state.progress.clamp(0, def.target);
    return Semantics(
      container: true,
      label: [
        l.achievementName(def.key),
        l.achievementDesc(def.key),
        if (def.incremental) l.achievementProgress(progress, def.target),
        if (!earned) l.achievementLocked,
      ].join('. '),
      excludeSemantics: true,
      child: Opacity(
        opacity: earned ? 1 : 0.55,
        child: Container(
          key: ValueKey('achievement-${def.key}'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: earned
                ? Border.all(color: def.color.withValues(alpha: 0.7), width: 2)
                : null,
          ),
          child: Column(
            children: [
              AchievementBadge(def: def, earned: earned, size: 64),
              const SizedBox(height: 8),
              Text(
                l.achievementName(def.key),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.achievementDesc(def.key),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (def.incremental) ...[
                const Spacer(),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / def.target,
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    color: earned ? def.color : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.achievementProgress(progress, def.target),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
