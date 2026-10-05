import 'package:flutter/material.dart';

import '../../characters/character_def.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import 'character_view.dart';

/// Karakter ızgarasındaki kart: bekleme animasyonu ve ad; kilitliyse siluet,
/// kilit eşiği ve ilerleme çubuğu; seçiliyse çerçeve ve onay işareti.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.character,
    required this.totalStars,
    required this.selected,
    required this.onTap,
    this.focused = false,
  });

  final CharacterDef character;
  final int totalStars;
  final bool selected;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = l.characterName(character.id);
    final locked = !character.isUnlocked(totalStars);
    final need = character.unlockStars;
    return Semantics(
      button: true,
      selected: selected,
      label: locked
          ? l.characterCardLocked(name)
          : selected
          ? l.characterCardSelected(name)
          : name,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: focused ? AppColors.floor : AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? AppColors.selected : Colors.transparent,
            width: 3,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Expanded(
                      child: CharacterView(
                        character: character,
                        silhouette: locked,
                        animate: !locked,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: locked
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (locked) ...[
                      Text(
                        context.l10n.unlockAt(need),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (totalStars / need).clamp(0.0, 1.0),
                                minHeight: 6,
                                color: AppColors.starEarned,
                                backgroundColor: AppColors.background,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.unlockProgress(totalStars, need),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.selected,
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.primaryButtonText,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
