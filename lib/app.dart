import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_services.dart';
import 'audio/sound_service.dart';
import 'core/colors.dart';
import 'games/achievement_sync.dart';
import 'l10n/l10n.dart';
import 'review/review_service.dart';
import 'rewards/rewarded_video_service.dart';
import 'state/settings_controller.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/splash_screen.dart';

class AlgoBotApp extends StatefulWidget {
  const AlgoBotApp({
    super.key,
    required this.settings,
    required this.sound,
    required this.services,
    this.showSplash = true,
    this.locale,
  });

  final SettingsController settings;
  final SoundService sound;

  /// Arka planda hazırlanan servisler; açılış ekranı bunu bekler.
  final Future<AppServices> services;

  /// Testlerde açılış ekranı atlanabilir.
  final bool showSplash;

  /// Testler için dili zorlar; normalde telefonun dili kullanılır.
  final Locale? locale;

  @override
  State<AlgoBotApp> createState() => _AlgoBotAppState();
}

class _AlgoBotAppState extends State<AlgoBotApp> {
  AppServices? _services;

  /// Uygulama öne gelince oyun platformu oturumu sessizce yeniden kontrol
  /// edilir (oturum sonradan açıldıysa bekleyen başarımlar gönderilir).
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () {
      final sync = _services?.achievements;
      if (sync != null && sync.started) sync.signInAndSync();
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    widget.services.then((s) {
      if (mounted) setState(() => _services = s);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    final settings = widget.settings;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider.value(value: widget.sound),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        locale: widget.locale,
        supportedLocales: supportedAppLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Telefon Türkçe ise Türkçe, diğer tüm dillerde İngilizce. Telefonun
        // dili değişince uygulama yeniden başlatılmadan güncellenir.
        localeResolutionCallback: (device, _) => resolveAppLocale(device),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryButton,
            onPrimary: AppColors.primaryButtonText,
            secondary: AppColors.secondaryButton,
            onSecondary: AppColors.secondaryButtonText,
            surface: AppColors.panel,
            onSurface: AppColors.textPrimary,
          ),
          splashFactory: InkRipple.splashFactory,
        ),
        // Sistem yazı büyütmesi 1.3x ile sınırlanır; düzen buna göre test edildi.
        // Yükleme bitince ilerleme, oturum ve video servisleri Navigator'ın
        // üstüne eklenir (Navigator GlobalKey taşır; açılış ekranı korunur).
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: services == null
              ? child!
              : MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: services.progress),
                    ChangeNotifierProvider.value(value: services.sessions),
                    Provider<RewardedVideoService>.value(value: services.video),
                    Provider<ReviewService>.value(value: services.review),
                    ChangeNotifierProvider<AchievementSync>.value(
                      value: services.achievements,
                    ),
                  ],
                  child: child,
                ),
        ),
        home: widget.showSplash
            ? SplashScreen(ready: widget.services, next: firstScreen)
            : firstScreen(settings),
      ),
    );
  }
}

/// Açılıştan sonraki ilk ekran: yaş seçilmemişse karşılama akışı.
Widget firstScreen(SettingsController settings) =>
    settings.ageGroupOrNull == null
    ? const OnboardingScreen()
    : const HomeScreen();
