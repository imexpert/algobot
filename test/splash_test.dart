import 'dart:async';

import 'package:algobot/app.dart';
import 'package:algobot/app_services.dart';
import 'package:algobot/audio/sound_service.dart';
import 'package:algobot/characters/character_painter.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/data/progress_repository.dart';
import 'package:algobot/data/session_repository.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/rewards/stub_rewarded_video_service.dart';
import 'package:algobot/state/progress_controller.dart';
import 'package:algobot/state/settings_controller.dart';
import 'package:algobot/ui/screens/home_screen.dart';
import 'package:algobot/ui/screens/onboarding_screen.dart';
import 'package:algobot/ui/screens/splash_screen.dart';
import 'package:algobot/ui/widgets/character_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

/// Gerçekten çalmadan çalınan sesleri kaydeden sahte ses servisi.
class FakeSoundService extends SoundService {
  FakeSoundService(super.settings);

  final played = <Sound>[];
  final stopped = <Sound>[];

  @override
  Future<void> playNow(Sound sound) async => played.add(sound);

  @override
  Future<void> stop(Sound sound) async => stopped.add(sound);

  @override
  Future<void> preload() async {}
}

class _Splash {
  _Splash(this.loading, this.sound, this.services);
  final Completer<AppServices> loading;
  final FakeSoundService sound;
  final AppServices services;
}

final en = lookupAppLocalizations(const Locale('en'));

Future<_Splash> _boot(
  WidgetTester tester, {
  String? age = 'ages8to12',
  bool soundOn = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'sound_on': soundOn,
    'age_group': ?age,
    ProgressRepository.migratedKey: true,
  });
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(prefs);
  final sound = FakeSoundService(settings);
  final db = (await tester.runAsync(() => openTestDatabase(noIsolate: true)))!;
  final progress = ProgressController(ProgressRepository(db), allLevelSets);
  final sessions = SessionRepository(db, clock: FakeClock());
  final services = AppServices(
    progress: progress,
    sessions: sessions,
    video: StubRewardedVideoService(available: false),
  );
  final loading = Completer<AppServices>();
  tester.view.physicalSize = const Size(360, 640) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AlgoBotApp(
      settings: settings,
      sound: sound,
      services: loading.future,
      locale: const Locale('en'),
    ),
  );
  return _Splash(loading, sound, services);
}

Future<void> _pumpMs(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('Açılış ilk ekran; yükleme ve animasyon bitince ilk açılışta '
      'karşılama akışı, geri tuşu açılışa dönmez', (tester) async {
    final s = await _boot(tester, age: null);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Text), findsNothing, reason: 'Açılışta metin yok');

    s.loading.complete(s.services);
    await _pumpMs(tester, 1000);
    expect(
      find.byType(SplashScreen),
      findsOneWidget,
      reason: 'Animasyon sürüyor',
    );
    await _pumpMs(tester, 2500);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(nav.canPop(), isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Sonraki açılışlarda ana ekran; logo "AlgoBot" etiketli', (
    tester,
  ) async {
    final s = await _boot(tester);
    s.loading.complete(s.services);
    await _pumpMs(tester, 3000);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.bySemanticsLabel('AlgoBot'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Yükleme uzarsa Bip bekleme pozunda kalır, bitince geçilir', (
    tester,
  ) async {
    final s = await _boot(tester);
    await _pumpMs(tester, 3500);
    expect(find.byType(SplashScreen), findsOneWidget);
    final bip = tester.widget<CharacterView>(find.byType(CharacterView));
    expect(bip.character.id, 'bip');
    expect(bip.state, CharacterState.idle);
    s.loading.complete(s.services);
    await _pumpMs(tester, 1200);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Dokunmak animasyonu atlar ve sesi keser, ama yükleme bitmeden '
      'geçilmez', (tester) async {
    final s = await _boot(tester);
    await _pumpMs(tester, 300);
    await tester.tap(find.byType(SplashScreen));
    await _pumpMs(tester, 1000);
    expect(s.sound.stopped, contains(Sound.splash));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(
      tester.widget<CharacterView>(find.byType(CharacterView)).state,
      CharacterState.idle,
    );

    s.loading.complete(s.services);
    await _pumpMs(tester, 600);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Yükleme bittiyse dokunmak hemen geçirir', (tester) async {
    final s = await _boot(tester);
    s.loading.complete(s.services);
    await _pumpMs(tester, 300);
    await tester.tap(find.byType(SplashScreen));
    await _pumpMs(tester, 400);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Açılış sesi animasyonla çalar; ses kapalıyken çalmaz', (
    tester,
  ) async {
    var s = await _boot(tester);
    await _pumpMs(tester, 600);
    expect(s.sound.played, [Sound.splash]);
    s.loading.complete(s.services);
    await _pumpMs(tester, 3000);
    await tester.pumpWidget(const SizedBox());

    s = await _boot(tester, soundOn: false);
    await _pumpMs(tester, 600);
    expect(s.sound.played, isEmpty);
    s.loading.complete(s.services);
    await _pumpMs(tester, 3000);
    await tester.pumpWidget(const SizedBox());
  });

  test('Uygulama adı her iki dilde AlgoBot', () {
    expect(en.appTitle, 'AlgoBot');
    expect(lookupAppLocalizations(const Locale('tr')).appTitle, 'AlgoBot');
  });
}
