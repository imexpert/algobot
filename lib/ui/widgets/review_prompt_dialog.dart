import 'package:flutter/material.dart';

import '../../characters/character_def.dart';
import '../../characters/character_painter.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import 'app_button.dart';
import 'character_view.dart';

/// Kilometre taşından sonra gösterilen kart: çocuktan bir yetişkine
/// göstermesi istenir. "Ebeveyn" seçilirse true döner (ardından ebeveyn
/// kapısı açılır); çocuk doğrudan mağazaya yönlendirilmez.
class ReviewPromptDialog extends StatelessWidget {
  const ReviewPromptDialog({super.key, required this.character});

  final CharacterDef character;

  static Future<bool> show(
    BuildContext context,
    CharacterDef character,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => ReviewPromptDialog(character: character),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 120,
                child: CharacterView(
                  character: character,
                  state: CharacterState.win,
                  showDisc: true,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  context.l10n.reviewPromptTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.reviewPromptBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.l10n.later,
                      primary: false,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: context.l10n.reviewPromptParent,
                      icon: Icons.lock_outline,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
