import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Aydınlatılan bölgenin çerçeve rengi.
const spotlightFrame = Color(0xFFFAC775);

/// Ekranı %60 karartıp hedef bölgeleri yuvarlak köşeli açıklıklarla aydınlık
/// bırakan katman. Açıklıkların dışı dokunmaya kapalıdır; açıklıklara
/// dokunuş alttaki bileşene geçer. [holes] her karede yeniden (genel ekran
/// koordinatlarında) hesaplanır; böylece ekran boyutu değişse de konumlar
/// doğru kalır.
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({
    super.key,
    required this.holes,
    this.dim = true,
    this.block = false,
  });

  final List<Rect> Function() holes;

  /// false: karartma yok ve dokunuşlar engellenmez (serbest adımlar).
  final bool dim;

  /// Karartma yokken de tüm dokunuşları yut (balona dokunarak ilerlenen
  /// adımlar). Balon bu katmanın üstündedir.
  final bool block;

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.dim) {
      return widget.block
          ? const AbsorbPointer(child: SizedBox.expand())
          : const SizedBox.expand();
    }
    return _Spotlight(holes: widget.holes, pulse: _pulse);
  }
}

class _Spotlight extends LeafRenderObjectWidget {
  const _Spotlight({required this.holes, required this.pulse});

  final List<Rect> Function() holes;
  final Animation<double> pulse;

  @override
  RenderSpotlight createRenderObject(BuildContext context) =>
      RenderSpotlight(holes: holes, pulse: pulse);

  @override
  void updateRenderObject(BuildContext context, RenderSpotlight render) {
    render
      ..holes = holes
      ..pulse = pulse;
  }
}

/// Karartma + açıklıklar. Dokunma testi açıklıkların içinde başarısız olur
/// (dokunuş alttaki bileşene geçer), dışında katman dokunuşu yutar.
class RenderSpotlight extends RenderBox {
  RenderSpotlight({required this._holes, required this._pulse});

  List<Rect> Function() _holes;
  set holes(List<Rect> Function() value) {
    _holes = value;
    markNeedsPaint();
  }

  Animation<double> _pulse;
  set pulse(Animation<double> value) {
    if (identical(value, _pulse)) return;
    if (attached) _pulse.removeListener(markNeedsPaint);
    _pulse = value;
    if (attached) _pulse.addListener(markNeedsPaint);
  }

  static const radius = 16.0;
  static const padding = 6.0;

  /// Açıklıklar, bu katmanın yerel koordinatlarında.
  List<RRect> localHoles() {
    if (!attached || !hasSize) return const [];
    return [
      for (final r in _holes())
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            globalToLocal(r.topLeft),
            globalToLocal(r.bottomRight),
          ).inflate(padding),
          const Radius.circular(radius),
        ),
    ];
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _pulse.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _pulse.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    for (final h in localHoles()) {
      if (h.contains(position)) return false; // alttaki bileşene geçer
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final holes = localHoles();
    final dimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(offset & size);
    for (final h in holes) {
      dimPath.addRRect(h.shift(offset));
    }
    canvas.drawPath(dimPath, Paint()..color = const Color(0x99000000));
    // Nabız atan çerçeve.
    final beat = 0.55 + 0.45 * (0.5 + 0.5 * sin(_pulse.value * 2 * pi));
    final frame = Paint()
      ..color = spotlightFrame.withValues(alpha: beat)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final h in holes) {
      canvas.drawRRect(h.shift(offset).inflate(1 + beat * 2), frame);
    }
  }
}
