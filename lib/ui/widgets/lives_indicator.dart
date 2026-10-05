import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../l10n/l10n.dart';

/// Kalan can: dolu/boş kalpler. Can düşünce son dolu kalp
/// küçülüp kırılır; son canda kalp hafifçe nabız atar.
class LivesIndicator extends StatefulWidget {
  const LivesIndicator({
    super.key,
    required this.left,
    required this.max,
    required this.lostCount,
    this.alignment = Alignment.centerLeft,
  });

  final int left;
  final int max;

  /// Her can kaybında artar; kırılma animasyonunu tetikler.
  final int lostCount;

  final AlignmentGeometry alignment;

  static const filledColor = Color(0xFFE24B4A);

  @override
  State<LivesIndicator> createState() => _LivesIndicatorState();
}

class _LivesIndicatorState extends State<LivesIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _break = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(LivesIndicator old) {
    super.didUpdateWidget(old);
    if (widget.lostCount > old.lostCount) _break.forward(from: 0);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.left == 1) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _break.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = max(widget.max, widget.left);
    return Semantics(
      label: context.l10n.livesLabel(widget.left),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_break, _pulse]),
        // Dar üst çubukta (uzun dil + yazı büyütme) sığmazsa küçülür.
        builder: (context, _) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: widget.alignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (var i = 0; i < count; i++) _heart(i)],
          ),
        ),
      ),
    );
  }

  Widget _heart(int i) {
    const size = 16.0;
    final filled = i < widget.left;
    // Az önce kırılan kalp: sağındaki ilk boş kalp.
    final breaking = !filled && i == widget.left && _break.isAnimating;
    Widget icon;
    if (breaking) {
      final t = _break.value;
      icon = Transform.scale(
        scale: 1 - 0.4 * sin(pi * t),
        child: Icon(
          t < 0.7 ? Icons.heart_broken : Icons.favorite_border,
          size: size,
          color: Color.lerp(LivesIndicator.filledColor, AppColors.starEmpty, t),
        ),
      );
    } else if (filled) {
      final last = widget.left == 1;
      icon = Transform.scale(
        scale: last ? 1 + 0.15 * _pulse.value : 1,
        child: const Icon(
          Icons.favorite,
          size: size,
          color: LivesIndicator.filledColor,
        ),
      );
    } else {
      icon = const Icon(
        Icons.favorite_border,
        size: size,
        color: AppColors.starEmpty,
      );
    }
    return Padding(padding: const EdgeInsets.only(right: 2), child: icon);
  }
}
