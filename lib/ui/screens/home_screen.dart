import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../characters/character_registry.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../state/settings_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/parent_gate_dialog.dart';
import '../widgets/character_view.dart';
import 'character_gallery_screen.dart';
import '../tutorial/tutorial_screen.dart';
import 'character_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _open(Widget page) {
    context.read<SoundService>().play(Sound.tap);
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: context.l10n.parent,
                        icon: const Icon(
                          Icons.supervisor_account,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => ParentGateDialog.show(context),
                      ),
                      const Spacer(),
                      if (kDebugMode)
                        IconButton(
                          tooltip: context.l10n.gallery,
                          icon: const Icon(
                            Icons.grid_view,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              _open(const CharacterGalleryScreen()),
                        ),
                      IconButton(
                        tooltip: settings.soundOn
                            ? context.l10n.soundOn
                            : context.l10n.soundOff,
                        icon: Icon(
                          settings.soundOn ? Icons.volume_up : Icons.volume_off,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: settings.toggleSound,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Marka logosu (tek harici görsel); genişliğin en fazla
                // %60'ı, en fazla 240dp.
                LayoutBuilder(
                  builder: (context, c) {
                    final width = (c.maxWidth * 0.6).clamp(0, 240).toDouble();
                    final dpr = MediaQuery.devicePixelRatioOf(context);
                    return Semantics(
                      image: true,
                      label: context.l10n.appTitle,
                      child: SizedBox(
                        width: width,
                        child: Image.asset(
                          'assets/images/algobot_logo.png',
                          excludeFromSemantics: true,
                          // Görüntü boyutunda çöz (kaynak 1536 px).
                          cacheWidth: (width * dpr).round().clamp(1, 1536),
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Flexible(
                  flex: 4,
                  child: ConstrainedBox(
                    // Logo eklendiği için karakter biraz küçüldü.
                    constraints: const BoxConstraints(
                      maxWidth: 160,
                      maxHeight: 160,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ExcludeSemantics(
                        child: CharacterView(
                          character: CharacterRegistry.byId(
                            settings.characterId,
                          ),
                          showDisc: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: context.l10n.play,
                      icon: Icons.play_arrow,
                      height: 64,
                      // İlk "Oyna"da önce yaş grubunun eğitimi açılır.
                      onPressed: () {
                        context.read<SoundService>().play(Sound.tap);
                        openPlay(context);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: context.l10n.characters,
                      primary: false,
                      icon: Icons.pets,
                      onPressed: () => _open(const CharacterSelectScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: context.l10n.howToPlay,
                      primary: false,
                      icon: Icons.school,
                      onPressed: () {
                        context.read<SoundService>().play(Sound.tap);
                        openTutorial(context, settings.ageGroup);
                      },
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
