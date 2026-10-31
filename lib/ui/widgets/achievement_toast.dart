import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../games/achievement_definitions.dart';
import '../../l10n/l10n.dart';
import 'achievement_badge.dart';

/// Başarım kazanıldığında üstten kayan kısa bildirim (rozet + ad).
///
/// Kök overlay'e eklenir: ekran değişse (sonraki seviye, eğitimden dönüş)
/// bildirim sürer. Birden fazla başarım sırayla gösterilir; her biri
/// [duration] kadar. Dokunmayı engellemez.
abstract final class AchievementToast {
  static const duration = Duration(milliseconds: 2500);

  static void show(BuildContext context, List<AchievementDef> defs) {
    if (defs.isEmpty) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastHost(defs: defs, onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.defs, required this.onDone});

  final List<AchievementDef> defs;
  final VoidCallback onDone;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  // Zamanlayıcı yerine animasyon: ekran kapanınca güvenle durur.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AchievementToast.duration,
  )..addStatusListener(_onStatus);

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_index + 1 < widget.defs.length) {
      setState(() => _index++);
      _c.forward(from: 0);
    } else {
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// İlk ve son 300 ms kayma; arada sabit.
  double _offset(double t) {
    const edge = 0.12;
    if (t < edge) return 1 - Curves.easeOut.transform(t / edge);
    if (t > 1 - edge) return Curves.easeIn.transform((t - (1 - edge)) / edge);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.defs[_index];
    final l = context.l10n;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) => FractionalTranslation(
              translation: Offset(0, -1.3 * _offset(_c.value)),
              child: child,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Material(
                    key: const ValueKey('achievement-toast'),
                    color: AppColors.panel,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                        color: AppColors.activeHighlight,
                        width: 2,
                      ),
                    ),
                    child: Semantics(
                      liveRegion: true,
                      label:
                          '${l.achievementUnlocked} ${l.achievementName(def.key)}',
                      excludeSemantics: true,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AchievementBadge(def: def, size: 48),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.achievementUnlocked,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.activeHighlight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    l.achievementName(def.key),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
