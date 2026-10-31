// QA testleri için ortak kurulum: gerçek AlgoBotApp, bellek içi veritabanı,
// sahte saat, sahte ses ve sahte mağaza değerlendirmesi.
import 'package:algobot/games/achievement_sync.dart';
import 'package:algobot/games/game_platform_service.dart';
import 'package:algobot/games/noop_game_platform.dart';
import 'package:algobot/app.dart';
import 'package:algobot/app_services.dart';
import 'package:algobot/audio/sound_service.dart';
import 'package:algobot/data/db/app_database.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/data/progress_repository.dart';
import 'package:algobot/data/session_repository.dart';
import 'package:algobot/engine/run_result.dart';
import 'package:algobot/engine/simulator.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_config.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/level.dart';
import 'package:algobot/review/review_service.dart';
import 'package:algobot/rewards/rewarded_video_service.dart';
import 'package:algobot/rewards/stub_rewarded_video_service.dart';
import 'package:algobot/state/progress_controller.dart';
import 'package:algobot/state/settings_controller.dart';
import 'package:algobot/ui/screens/game_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_review.dart';
import '../helpers/test_db.dart';
import '../helpers/tutorial_prefs.dart';

final en = lookupAppLocalizations(const Locale('en'));
final tr = lookupAppLocalizations(const Locale('tr'));

/// Çalınan sesleri kaydeden sahte ses servisi (gerçek ses çalmaz).
class QaSound extends SoundService {
  QaSound(super.settings);
  final played = <Sound>[];

  @override
  Future<void> playNow(Sound sound) async => played.add(sound);

  @override
  Future<void> stop(Sound sound) async {}

  @override
  Future<void> preload() async {}
}

/// Sonucu ayarlanabilen sahte video servisi.
class QaVideo implements RewardedVideoService {
  QaVideo(this.result);
  RewardedVideoResult result;
  int shown = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<void> preload() async {}

  @override
  Future<RewardedVideoResult> show(BuildContext context) async {
    shown++;
    return result;
  }
}

class QaApp {
  QaApp(
    this.settings,
    this.progress,
    this.sessions,
    this.db,
    this.clock,
    this.sound,
    this.review,
    this.achievements,
  );
  final SettingsController settings;
  final ProgressController progress;
  final SessionRepository sessions;
  final AppDatabase db;
  final FakeClock clock;
  final QaSound sound;
  final FakeReviewPlatform review;
  final AchievementSync achievements;
}

Future<QaApp> qaSetUp(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double textScale = 1.0,
  AgeGroup? age = AgeGroup.ages8to12,
  Locale? locale = const Locale('en'),
  Map<String, Object> prefs = const {},
  Map<(AgeGroup, int), int> stars = const {},
  RewardedVideoService? video,
  bool soundOn = false,
  bool showSplash = false,
  FakeClock? clock,
  AppDatabase? database,
  bool seenTutorial = true,
  GamePlatformService? gamePlatform,
}) async {
  SharedPreferences.setMockInitialValues({
    'sound_on': soundOn,
    'age_group': ?age?.name,
    ProgressRepository.migratedKey: true,
    if (seenTutorial) ...seenTutorialPrefs,
    ...prefs,
  });
  final sp = await SharedPreferences.getInstance();
  final settings = SettingsController(sp);
  final c = clock ?? FakeClock();
  final db =
      database ??
      (await tester.runAsync(() => openTestDatabase(noIsolate: true)))!;
  final repo = ProgressRepository(db, clock: c);
  final progress = ProgressController(repo, allLevelSets);
  final sessions = SessionRepository(db, clock: c);
  await tester.runAsync(() async {
    for (final e in stars.entries) {
      await repo.save(
        e.key.$1,
        e.key.$2,
        LevelProgress(bestStars: e.value, completed: e.value > 0),
      );
    }
    await Future.wait([progress.load(), sessions.load()]);
  });
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final sound = QaSound(settings);
  final achievements = AchievementSync(
    database: db,
    platform: gamePlatform ?? const NoopGamePlatform(),
    prefs: sp,
  );
  final review = FakeReviewPlatform();
  await tester.pumpWidget(
    AlgoBotApp(
      settings: settings,
      sound: sound,
      services: SynchronousFuture(
        AppServices(
          progress: progress,
          sessions: sessions,
          video: video ?? StubRewardedVideoService(available: false),
          review: ReviewService(sp, platform: review, clock: c),
          achievements: achievements,
        ),
      ),
      showSplash: showSplash,
      locale: locale,
    ),
  );
  await tester.pump();
  return QaApp(
    settings,
    progress,
    sessions,
    db,
    c,
    sound,
    review,
    achievements,
  );
}

/// Sonsuz animasyonlar olduğu için pumpAndSettle kullanılamaz.
Future<void> settle(WidgetTester tester, [int ms = 1500]) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> flushDb(WidgetTester tester) => tester.runAsync(
  () => Future<void>.delayed(const Duration(milliseconds: 50)),
);

Future<void> push(WidgetTester tester, Widget page) async {
  final ctx = tester.element(find.byType(Navigator).first);
  Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => page));
  await settle(tester, 800);
}

Future<void> openLevel(WidgetTester tester, Level level) async {
  await push(tester, GameScreen(level: level));
  final intro = find.text(en.levelIntro(level));
  if (intro.evaluate().isNotEmpty) {
    await tester.tap(intro.first, warnIfMissed: false);
    await tester.pump();
  }
}

Future<void> tapIt(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Finder card(AppLocalizations l, Command c) =>
    find.bySemanticsLabel(l.paletteCardLabel(l.commandShort(c)));

Future<void> addAll(
  WidgetTester tester,
  List<Command> commands, [
  AppLocalizations? l,
]) async {
  for (final c in commands) {
    await tapIt(tester, card(l ?? en, c));
    await tester.pump();
  }
  await settle(tester, 400);
}

int runtime(Level level) => level.maxSlots * 1200 + 1500;

Level lvl(AgeGroup age, int id) => levelsFor(age).firstWhere((l) => l.id == id);

Finder lives(int n, [AppLocalizations? l]) =>
    find.bySemanticsLabel((l ?? en).livesLabel(n));

/// Ebeveyn kapısındaki toplama sorusunu doğru ya da yanlış cevaplar.
Future<void> answerGate(
  WidgetTester tester,
  AppLocalizations l, {
  bool correct = true,
}) async {
  final pattern = RegExp(r'(\d+) \+ (\d+)');
  final q = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere(pattern.hasMatch);
  final m = pattern.firstMatch(q)!;
  var answer = int.parse(m[1]!) + int.parse(m[2]!);
  if (!correct) answer += 1;
  for (final d in '$answer'.split('')) {
    await tester.tap(find.text(d).last);
    await tester.pump();
  }
  await tester.tap(find.text(l.ok));
  await settle(tester, 500);
}

/// Başarısız biten (tercihen duvara çarpan) en kısa program.
List<Command> crashProgram(Level level) {
  final palette = level.paletteCommands;
  List<Command>? fallback;
  Iterable<List<Command>> all(int n) sync* {
    if (n == 0) {
      yield const [];
      return;
    }
    for (final head in all(n - 1)) {
      for (final c in palette) {
        yield [...head, c];
      }
    }
  }

  for (var n = 1; n <= 3; n++) {
    for (final p in all(n)) {
      final outcome = Simulator.run(level, p).outcome;
      if (outcome == RunOutcome.crashed) return p;
      if (outcome == RunOutcome.stoppedShort) fallback ??= p;
    }
  }
  if (fallback != null) return fallback;
  throw StateError('Başarısız program bulunamadı: ${level.textKey}');
}
