import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../characters/character_def.dart';
import '../../characters/character_painter.dart';
import '../../characters/character_registry.dart';
import '../../characters/collectibles/collectible_painter.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../models/direction.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/character_card.dart';
import '../widgets/character_view.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  late CharacterDef _focused = CharacterRegistry.byId(
    context.read<SettingsController>().characterId,
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final stars = context.watch<ProgressController>().totalStarsAll;
    final unlocked = _focused.isUnlocked(stars);
    final isSelected = settings.characterId == _focused.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
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
                          context.l10n.characters,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Büyük önizleme alanı.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // İçerik uzarsa (yazı büyütme, kilit metni) alan da uzar.
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: unlocked
                                ? CharacterShowcase(
                                    key: ValueKey(_focused.id),
                                    character: _focused,
                                  )
                                : CharacterView(
                                    character: _focused,
                                    silhouette: true,
                                    animate: false,
                                  ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.characterName(_focused.id),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox.square(
                                  dimension: 44,
                                  child: CustomPaint(
                                    painter: _CollectiblePainter(
                                      _focused.collectible,
                                    ),
                                  ),
                                ),
                                Text(
                                  context.l10n.collectibleOf(_focused.id),
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (unlocked)
                                  AppButton(
                                    label: isSelected
                                        ? context.l10n.selectedLabel
                                        : context.l10n.select,
                                    height: 48,
                                    icon: isSelected ? Icons.check : null,
                                    onPressed: isSelected
                                        ? null
                                        : () {
                                            context.read<SoundService>().play(
                                              Sound.star,
                                            );
                                            settings.setCharacter(_focused.id);
                                          },
                                  )
                                else
                                  Text(
                                    context.l10n.unlockAt(_focused.unlockStars),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
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
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final columns = c.maxWidth >= 600 ? 4 : 2;
                      final scale =
                          MediaQuery.textScalerOf(context).scale(16) / 16;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 150 + 40 * scale,
                        ),
                        itemCount: CharacterRegistry.all.length,
                        itemBuilder: (context, i) {
                          final def = CharacterRegistry.all[i];
                          return CharacterCard(
                            character: def,
                            totalStars: stars,
                            selected: settings.characterId == def.id,
                            focused: _focused.id == def.id,
                            onTap: () {
                              context.read<SoundService>().play(Sound.tap);
                              setState(() => _focused = def);
                            },
                          );
                        },
                      );
                    },
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

/// Karakter tanıtımı: dört yöne sırayla döner, sonra bir kez kazanır.
class CharacterShowcase extends StatefulWidget {
  const CharacterShowcase({super.key, required this.character});

  final CharacterDef character;

  @override
  State<CharacterShowcase> createState() => _CharacterShowcaseState();
}

class _CharacterShowcaseState extends State<CharacterShowcase> {
  static const _order = [
    Direction.south,
    Direction.east,
    Direction.north,
    Direction.west,
  ];
  int _step = 0;
  late final Timer _timer = Timer.periodic(
    const Duration(milliseconds: 800),
    (_) => setState(() => _step = (_step + 1) % 7),
  );

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 0–3: dört yön, 4–5: kazanma, 6: bekleme.
    final facing = _step < 4 ? _order[_step] : Direction.south;
    final state = switch (_step) {
      4 || 5 => CharacterState.win,
      _ => CharacterState.idle,
    };
    return CharacterView(
      character: widget.character,
      facing: facing,
      state: state,
      showDisc: true,
    );
  }
}

class _CollectiblePainter extends CustomPainter {
  _CollectiblePainter(this.kind);
  final CollectibleKind kind;

  @override
  void paint(Canvas canvas, Size size) => paintCollectible(
    canvas,
    kind,
    size.center(Offset.zero),
    size.shortestSide,
  );

  @override
  bool shouldRepaint(_CollectiblePainter old) => old.kind != kind;
}
