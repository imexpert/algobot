import 'package:flutter/material.dart';

import '../../characters/character_painter.dart';
import '../../characters/character_registry.dart';
import '../../characters/collectibles/collectible_painter.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../models/intro_glyph.dart';
import '../widgets/app_button.dart';
import '../widgets/character_view.dart';
import '../widgets/hint_bubble.dart';

/// Balon metni ve kuyruk rengi.
const coachText = Color(0xFF26215C);

/// Eğitim rehberi Bip ve konuşma balonu. Seçili karakter ne olursa olsun
/// rehber Bip'tir.
class CoachBubble extends StatelessWidget {
  const CoachBubble({
    super.key,
    required this.text,
    this.glyphs = const [],
    this.collectible = CollectibleKind.battery,
    this.large = false,
    this.stars = false,
    this.onNext,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final List<IntroGlyph> glyphs;
  final CollectibleKind collectible;

  /// 5–7: 18sp metin.
  final bool large;

  /// 1-2-3 yıldız görseli.
  final bool stars;

  /// Balona dokunarak ilerlenen adım: sağ altta "Devam ›".
  final VoidCallback? onNext;

  /// Son adım: "Başla" / "Anladım" düğmesi.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (glyphs.isNotEmpty) ...[
            GlyphRow(glyphs: glyphs, collectible: collectible),
            const SizedBox(height: 6),
          ],
          if (stars) ...[const _StarsRow(), const SizedBox(height: 6)],
          Semantics(
            liveRegion: true,
            child: Text(
              text,
              style: TextStyle(
                color: coachText,
                fontSize: large ? 18 : 16,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          if (onNext != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.tutNext,
                  style: TextStyle(
                    color: coachText.withValues(alpha: 0.65),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: actionLabel!,
              icon: Icons.play_arrow,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox.square(
          dimension: 56,
          child: ExcludeSemantics(
            child: CharacterView(character: _bip, state: CharacterState.idle),
          ),
        ),
        CustomPaint(size: const Size(10, 18), painter: _TailPainter()),
        Flexible(child: bubble),
      ],
    );
    if (onNext == null) return content;
    return Semantics(
      button: true,
      onTap: onNext,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onNext,
        child: content,
      ),
    );
  }

  static final _bip = CharacterRegistry.byId('bip');
}

/// Bip'e doğru bakan kuyruk.
class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height * 0.75)
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

/// 1 yıldız · 2 yıldız · 3 yıldız.
class _StarsRow extends StatelessWidget {
  const _StarsRow();

  @override
  Widget build(BuildContext context) {
    Widget group(int n) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            Icons.star_rounded,
            size: 20,
            color: i < n ? AppColors.starEarned : AppColors.starEmpty,
          ),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        children: [group(1), group(2), group(3)],
      ),
    );
  }
}
