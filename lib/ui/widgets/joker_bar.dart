import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../jokers/joker_type.dart';
import '../../l10n/l10n.dart';
import '../../state/game_controller.dart';

IconData jokerIcon(JokerType type) => switch (type) {
  JokerType.skip => Icons.skip_next,
  JokerType.life => Icons.favorite,
  JokerType.video => Icons.ondemand_video,
};

/// Komut paletinin üstündeki joker çubuğu. Sayaç metni yok: kullanılmış
/// joker gri ve onay işaretli görünür. Video servisi kullanılamıyorsa Video
/// butonu görünür ama pasiftir.
class JokerBar extends StatelessWidget {
  const JokerBar({
    super.key,
    required this.game,
    required this.onUse,
    required this.videoAvailable,
  });

  final GameController game;
  final ValueChanged<JokerType> onUse;
  final bool videoAvailable;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        for (final type in JokerType.values)
          Expanded(
            child: _JokerButton(
              type: type,
              label: l.jokerLabel(type),
              used: game.isJokerUsed(type),
              enabled:
                  game.canUseJoker(type) &&
                  (type != JokerType.video || videoAvailable),
              onTap: () => onUse(type),
            ),
          ),
      ],
    );
  }
}

/// Tur Atla onayı. "Atla" seçilirse true.
Future<bool> confirmSkip(BuildContext context) async {
  final l = context.l10n;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.panel,
          content: Text(
            l.skipConfirm,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l.skipConfirmYes,
                style: const TextStyle(
                  color: AppColors.primaryButton,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

class _JokerButton extends StatelessWidget {
  const _JokerButton({
    required this.type,
    required this.label,
    required this.used,
    required this.enabled,
    required this.onTap,
  });

  final JokerType type;
  final String label;
  final bool used;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = used
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : type == JokerType.life
        ? const Color(0xFFE24B4A)
        : AppColors.activeHighlight;
    return Semantics(
      button: true,
      enabled: enabled,
      label: used ? context.l10n.jokerUsedLabel(label) : label,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled || used ? 1 : 0.45,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(jokerIcon(type), color: color, size: 24),
                  ),
                  if (used)
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.selected,
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: AppColors.primaryButtonText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: used ? color : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
