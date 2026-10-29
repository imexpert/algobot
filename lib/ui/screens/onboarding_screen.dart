import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../characters/character_registry.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../models/age_group.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/character_card.dart';
import '../widgets/character_view.dart';
import 'home_screen.dart';
import '../tutorial/tutorial_screen.dart';

/// İlk açılış: 1) yaş aralığı, 2) arkadaş seçimi, 3) seviye seçimi.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _pickingFriend = false;

  static const _ageArt = {
    AgeGroup.ages5to7: 'hop',
    AgeGroup.ages8to12: 'bip',
    AgeGroup.ages13plus: 'zorp',
  };

  Future<void> _pickAge(AgeGroup age) async {
    context.read<SoundService>().play(Sound.tap);
    await context.read<SettingsController>().setAgeGroup(age);
    if (!mounted) return;
    setState(() => _pickingFriend = true);
  }

  /// Ana menü altta kalır; üstüne ilk "Oyna" açılır (eğitim görülmediyse
  /// önce eğitim, bitince seviye seçimi).
  void _finish() {
    context.read<SoundService>().play(Sound.tap);
    final nav = Navigator.of(context);
    nav.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
    openPlay(nav.context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _pickingFriend ? _friendStep() : _ageStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _ageStep() {
    return Column(
      children: [
        _title(context.l10n.welcomeAge),
        for (final age in AgeGroup.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                button: true,
                label: context.l10n.ageRangeOf(age),
                excludeSemantics: true,
                onTap: () => _pickAge(age),
                child: Material(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _pickAge(age),
                    child: Row(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CharacterView(
                              character: CharacterRegistry.byId(_ageArt[age]!),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              context.l10n.ageShortOf(age),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _friendStep() {
    final settings = context.watch<SettingsController>();
    final stars = context.watch<ProgressController>().totalStarsAll;
    final friends = CharacterRegistry.unlocked(stars);
    return Column(
      children: [
        _title(context.l10n.pickFriend),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: friends.length,
            itemBuilder: (context, i) => CharacterCard(
              character: friends[i],
              totalStars: stars,
              selected: settings.characterId == friends[i].id,
              onTap: () {
                context.read<SoundService>().play(Sound.tap);
                settings.setCharacter(friends[i].id);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: context.l10n.start,
            icon: Icons.play_arrow,
            height: 64,
            onPressed: _finish,
          ),
        ),
      ],
    );
  }
}
