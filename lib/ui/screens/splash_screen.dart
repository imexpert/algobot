import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../characters/character_painter.dart';
import '../../characters/character_registry.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../state/settings_controller.dart';
import '../widgets/character_view.dart';

/// Animasyonlu ve sesli açılış ekranı (~2,2 sn). Metin içermez: logo,
/// parıltılar ve maskot Bip. Başlangıç işleri ([ready]) paralel yürür;
/// geçiş hem animasyon hem yükleme bitince olur. Dokunmak animasyonu
/// atlar ama yükleme bitmeden geçmez (Bip bekleme pozunda kalır).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.ready, required this.next});

  final Future<Object?> ready;
  final Widget Function(SettingsController settings) next;

  static const logoAsset = 'assets/images/algobot_logo.png';

  /// Logonun son genişliği. Yerel açılış logosu bunun %90'ı (216 dp),
  /// animasyon oradan başladığı için geçiş kesintisizdir.
  static const logoWidth = 240.0;

  static const total = Duration(milliseconds: 2200);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: SplashScreen.total,
  );

  bool _ready = false;
  bool _skipped = false;
  bool _leaving = false;

  /// Animasyon bekleme noktasına (1600 ms) ulaştı mı.
  bool _atHold = false;

  /// Bekleme noktası (1600 ms): yükleme sürüyorsa animasyon burada durur.
  static const _hold = 1600 / 2200;

  static double _ms(double ms) => ms / 2200;

  @override
  void initState() {
    super.initState();
    // Sistem çubukları açılış süresince gizli.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    widget.ready.then(
      (_) {
        if (!mounted) return;
        setState(() => _ready = true);
        // Animasyon yüklemeyi bekliyorsa (ya da atlandıysa) şimdi geç.
        if (_skipped) {
          _leave(fade: false);
        } else if (_atHold) {
          _leave(fade: true);
        }
      },
      onError: (Object e) {
        debugPrint('Açılış yüklemesi başarısız: $e');
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    // Logo çözülmeden yerel açılışı kaldırma (boş kare görünmesin).
    // En fazla 500 ms beklenir; çözme takılırsa açılış yine de sürer.
    await precacheImage(
      const AssetImage(SplashScreen.logoAsset),
      context,
    ).timeout(const Duration(milliseconds: 500), onTimeout: () {});
    FlutterNativeSplash.remove();
    if (!mounted) return;
    context.read<SoundService>().play(Sound.splash);
    try {
      await _anim.animateTo(_hold).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || _skipped) return;
    _atHold = true;
    if (_ready) {
      _leave(fade: true);
    } else {
      setState(() {}); // Bip bekleme pozuna geçer.
    }
  }

  void _skip() {
    if (_skipped || _leaving) return;
    _skipped = true;
    context.read<SoundService>().stop(Sound.splash);
    _anim.stop();
    if (_ready) {
      _leave(fade: false);
    } else {
      // Yükleme sürüyor: Bip görünür ve bekler.
      setState(() => _anim.value = _hold);
    }
  }

  Future<void> _leave({required bool fade}) async {
    if (_leaving || !mounted) return;
    _leaving = true;
    if (fade && !_skipped) {
      try {
        await _anim.animateTo(1).orCancel;
      } on TickerCanceled {
        // Atlandı: hemen geç.
      }
    }
    if (!mounted) return;
    final settings = context.read<SettingsController>();
    unawaited(
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, _, _) => widget.next(settings),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        systemNavigationBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => _content(_anim.value),
          ),
        ),
      ),
    );
  }

  Widget _content(double v) {
    double phase(double fromMs, double toMs) =>
        ((v - _ms(fromMs)) / (_ms(toMs) - _ms(fromMs))).clamp(0.0, 1.0);

    // 0–600 ms: %90 → %105 → %100 yumuşak zıplama.
    final logoScale = _logoScale.transform(phase(0, 600));
    // 1600–2200 ms: tüm ekran solar.
    final fadeOut = 1 - Curves.easeIn.transform(phase(1600, 2200));
    // 900–1600 ms: Bip aşağıdan belirir.
    final bip = Curves.easeOutBack.transform(phase(900, 1300));
    final waiting = !_ready && v >= _hold - 0.001;

    return Opacity(
      opacity: fadeOut,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 400–1200 ms: logonun çevresinde parıltılar.
          CustomPaint(painter: _SparklePainter(progress: phase(400, 1200))),
          Center(
            child: Semantics(
              image: true,
              label: context.l10n.appTitle,
              child: Transform.scale(
                scale: logoScale,
                child: Image.asset(
                  SplashScreen.logoAsset,
                  width: SplashScreen.logoWidth,
                  excludeFromSemantics: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          if (bip > 0)
            Align(
              alignment: const Alignment(0, 0.62),
              child: Opacity(
                opacity: bip.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 40 * (1 - bip)),
                  child: SizedBox.square(
                    dimension: 140,
                    // Marka maskotu: seçili karakter ne olursa olsun Bip.
                    child: CharacterView(
                      character: CharacterRegistry.byId('bip'),
                      state: waiting ? CharacterState.idle : CharacterState.win,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static final _logoScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.9,
        end: 1.05,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.05,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 40,
    ),
  ]);
}

/// Logodan dışa yayılıp kaybolan renkli parıltılar.
class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress});

  final double progress;

  static const _colors = [
    Color(0xFF5DCAA5),
    Color(0xFFFAC775),
    Color(0xFF7F77DD),
    Color(0xFFD85A30),
  ];
  static const _count = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final t = Curves.easeOut.transform(progress);
    for (var i = 0; i < _count; i++) {
      final angle = i * 2 * pi / _count + 0.3;
      // Logo yatay olduğu için elips üzerinde yayılır.
      final r = 80 + 120 * t;
      final p = center + Offset(cos(angle) * r * 1.3, sin(angle) * r * 0.85);
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: 1 - progress);
      final s = 13 * (1 - 0.4 * t);
      // Dört köşeli küçük parıltı.
      final path = Path()
        ..moveTo(p.dx, p.dy - s)
        ..lineTo(p.dx + s * 0.35, p.dy)
        ..lineTo(p.dx, p.dy + s)
        ..lineTo(p.dx - s * 0.35, p.dy)
        ..close()
        ..moveTo(p.dx - s, p.dy)
        ..lineTo(p.dx, p.dy + s * 0.35)
        ..lineTo(p.dx + s, p.dy)
        ..lineTo(p.dx, p.dy - s * 0.35)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}
