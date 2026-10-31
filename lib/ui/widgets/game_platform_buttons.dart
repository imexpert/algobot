import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../games/achievement_sync.dart';
import '../../games/game_platform_service.dart';
import '../../l10n/l10n.dart';
import 'app_button.dart';
import 'parent_gate_dialog.dart';

/// Platformun kendi başarımlar ekranı ve skor tablosu butonları.
///
/// Bu ekranlar çocuğu uygulama dışı içeriğe ve diğer oyunculara
/// götürebileceği için yalnızca ebeveyn içindir: [gated] ise her dokunuşta
/// ebeveyn kapısı sorulur (ebeveyn panelinde zaten kapıdan geçilmiştir).
/// Oturum yoksa hiçbir şey göstermez.
class GamePlatformButtons extends StatelessWidget {
  const GamePlatformButtons({
    super.key,
    required this.sync,
    required this.gated,
    this.showAchievements = true,
  });

  final AchievementSync sync;
  final bool gated;

  /// false ise yalnızca skor tablosu butonu (ebeveyn paneli).
  final bool showAchievements;

  Future<void> _open(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    if (gated && !await ParentGateDialog.verify(context)) return;
    await action();
  }

  @override
  Widget build(BuildContext context) {
    if (!sync.isSignedIn) return const SizedBox.shrink();
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAchievements) ...[
          AppButton(
            key: const ValueKey('platform-achievements'),
            label: l.viewOnGamePlatform(sync.platformKind.name),
            primary: false,
            icon: Icons.emoji_events,
            onPressed: () => _open(context, sync.showAchievementsUI),
          ),
          const SizedBox(height: 8),
        ],
        AppButton(
          key: const ValueKey('platform-leaderboard'),
          label: l.openLeaderboard,
          primary: false,
          icon: Icons.leaderboard,
          onPressed: () => _open(context, sync.showLeaderboardUI),
        ),
      ],
    );
  }
}

/// Ebeveyn panelindeki "Oyun hesabı" bölümü: oturum kapalıysa elle
/// bağlanma butonu, açıksa "bağlı" durumu. Oyunun başka hiçbir yerinde
/// giriş daveti yoktur.
class GameAccountSection extends StatefulWidget {
  const GameAccountSection({super.key, required this.sync});

  final AchievementSync sync;

  @override
  State<GameAccountSection> createState() => _GameAccountSectionState();
}

class _GameAccountSectionState extends State<GameAccountSection> {
  bool _busy = false;
  GameSignInResult? _result;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await widget.sync.connect();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sync = widget.sync;
    final service = sync.platformKind.name;
    final message = switch (_result) {
      GameSignInResult.failed => l.connectFailed,
      GameSignInResult.unavailable => l.gameCenterSettingsHint,
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.gameAccount,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (sync.isSignedIn)
          Row(
            key: const ValueKey('game-account-connected'),
            children: [
              const Icon(Icons.check_circle, color: AppColors.primaryButton),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.connectedGamePlatform(service),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          )
        else ...[
          AppButton(
            key: const ValueKey('game-account-connect'),
            label: l.connectGamePlatform(service),
            primary: false,
            icon: Icons.sports_esports,
            onPressed: _busy ? null : _connect,
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                key: const ValueKey('game-account-message'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.activeHighlight,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
