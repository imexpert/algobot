import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../characters/character_def.dart';
import '../../characters/character_painter.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../engine/run_result.dart';
import '../../models/age_group.dart';
import '../../models/level.dart';
import 'app_button.dart';
import 'character_view.dart';

enum ResultAction { again, next }

/// Seviye sonu paneli: mutlu robot, sırayla beliren yıldızlar, özet.
class ResultSheet extends StatefulWidget {
  const ResultSheet({
    super.key,
    required this.level,
    required this.character,
    required this.result,
    required this.stars,
  });

  final Level level;
  final CharacterDef character;

  final RunResult result;
  final int stars;

  static Future<ResultAction?> show(
    BuildContext context, {
    required Level level,
    required CharacterDef character,
    required RunResult result,
    required int stars,
  }) => showModalBottomSheet<ResultAction>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: AppColors.panel,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ResultSheet(
      level: level,
      character: character,
      result: result,
      stars: stars,
    ),
  );

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet>
    with TickerProviderStateMixin {
  late final List<AnimationController> _starAnims = List.generate(
    3,
    (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    ),
  );

  @override
  void initState() {
    super.initState();
    _playStars();
  }

  Future<void> _playStars() async {
    final sound = context.read<SoundService>();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (var i = 0; i < widget.stars; i++) {
      if (!mounted) return;
      _starAnims[i].forward();
      sound.play(Sound.star);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    for (final a in _starAnims) {
      a.dispose();
    }
    super.dispose();
  }

  String? get _missingHint {
    final l = context.l10n;
    if (widget.stars >= 3) return null;
    if (widget.result.collectedCount < widget.level.collectibles.length) {
      return l.hintCollect(widget.character.id);
    }
    return l.hintShorter(widget.level.optimalLength);
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final result = widget.result;
    const secondary = TextStyle(color: AppColors.textSecondary, fontSize: 16);
    final hint = _missingHint;

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
                SizedBox.square(
                  dimension: 96,
                  child: CharacterView(
                    character: widget.character,
                    state: CharacterState.win,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: context.l10n.starsLabel(widget.stars),
                  excludeSemantics: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [for (var i = 0; i < 3; i++) _star(i)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.resultTitle(widget.stars),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.resultCommands(
                    result.programLength,
                    level.optimalLength,
                  ),
                  textAlign: TextAlign.center,
                  style: secondary,
                ),
                if (level.collectibles.isNotEmpty)
                  Text(
                    context.l10n.collectedCount(
                      widget.character.id,
                      result.collectedCount,
                      level.collectibles.length,
                    ),
                    style: secondary,
                  ),
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.activeHighlight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: context.l10n.again,
                        primary: false,
                        icon: Icons.replay,
                        onPressed: () =>
                            Navigator.pop(context, ResultAction.again),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: context.l10n.next,
                        icon: Icons.arrow_forward,
                        onPressed: () =>
                            Navigator.pop(context, ResultAction.next),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _star(int i) {
    // 5–7: okuyamayanlar için büyük yıldızlar.
    final size = widget.level.ageGroup == AgeGroup.ages5to7 ? 72.0 : 48.0;
    final empty = Icon(
      Icons.star_rounded,
      size: size,
      color: AppColors.starEmpty,
    );
    if (i >= widget.stars) return empty;
    return Stack(
      alignment: Alignment.center,
      children: [
        empty,
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _starAnims[i],
            curve: Curves.easeOutBack,
          ),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: AppColors.starEarned,
          ),
        ),
      ],
    );
  }
}
