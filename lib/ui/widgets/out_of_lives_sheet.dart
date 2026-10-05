import 'dart:async';

import 'package:flutter/material.dart';

import '../../characters/character_def.dart';
import '../../characters/character_painter.dart';
import '../../core/colors.dart';
import '../../data/session_repository.dart';
import '../../jokers/joker_type.dart';
import '../../l10n/l10n.dart';
import '../../models/level.dart';
import 'app_button.dart';
import 'character_view.dart';
import 'joker_bar.dart';

enum OutOfLivesAction { useLife, skip, video, mainMenu, lifeRestored }

/// Canlar bittiğinde gösterilen panel: kullanılmamış jokerler, bir sonraki
/// canın geri sayımı ve "Ana menü". Beklerken can dolarsa kendiliğinden
/// kapanır (`lifeRestored`).
class OutOfLivesSheet extends StatefulWidget {
  const OutOfLivesSheet({
    super.key,
    required this.level,
    required this.character,
    required this.sessions,
    required this.videoAvailable,
  });

  final Level level;
  final CharacterDef character;
  final SessionRepository sessions;
  final bool videoAvailable;

  static Future<OutOfLivesAction> show(
    BuildContext context, {
    required Level level,
    required CharacterDef character,
    required SessionRepository sessions,
    required bool videoAvailable,
  }) async =>
      await showModalBottomSheet<OutOfLivesAction>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: AppColors.panel,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => PopScope(
          canPop: false,
          child: OutOfLivesSheet(
            level: level,
            character: character,
            sessions: sessions,
            videoAvailable: videoAvailable,
          ),
        ),
      ) ??
      OutOfLivesAction.mainMenu;

  @override
  State<OutOfLivesSheet> createState() => _OutOfLivesSheetState();
}

class _OutOfLivesSheetState extends State<OutOfLivesSheet> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.sessions.sessionFor(widget.level).lives > 0) {
        _timer.cancel();
        Navigator.pop(context, OutOfLivesAction.lifeRestored);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final used = widget.sessions.sessionFor(widget.level).usedJokers;
    final next = widget.sessions.nextLifeIn(widget.level);
    final options = [
      if (!used.contains(JokerType.life))
        (JokerType.life, l.useLifeJoker, OutOfLivesAction.useLife),
      if (!used.contains(JokerType.skip))
        (JokerType.skip, l.skipLevelAction, OutOfLivesAction.skip),
      if (widget.videoAvailable && !used.contains(JokerType.video))
        (JokerType.video, l.watchVideoAction, OutOfLivesAction.video),
    ];
    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Çarpma pozunun yumuşak hali: sersemleme dönmeden durur.
                SizedBox.square(
                  dimension: 96,
                  child: CharacterView(
                    character: widget.character,
                    state: CharacterState.crash,
                    animate: false,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.outOfLivesTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.outOfLivesBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l.nextLife(l.countdown(next)),
                      style: const TextStyle(
                        color: AppColors.activeHighlight,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                for (final (type, label, action) in options) ...[
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: label,
                      icon: jokerIcon(type),
                      height: 60,
                      onPressed: () => Navigator.pop(context, action),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: l.mainMenu,
                    primary: false,
                    icon: Icons.home,
                    onPressed: () =>
                        Navigator.pop(context, OutOfLivesAction.mainMenu),
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
