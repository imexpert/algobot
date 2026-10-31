import 'package:algobot/data/db/app_database.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/data/progress_repository.dart';
import 'package:algobot/games/achievement_definitions.dart';
import 'package:algobot/games/achievement_evaluator.dart';
import 'package:algobot/games/achievement_sync.dart';
import 'package:algobot/games/game_config.dart';
import 'package:algobot/games/noop_game_platform.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/level.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_game_platform.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late FakeGamePlatform platform;
  late Map<LevelKey, LevelProgress> progress;

  AchievementFacts facts({bool tutorial = false, bool lastLife = false}) =>
      AchievementFacts(
        sets: allLevelSets,
        progressOf: (l) =>
            progress[(l.ageGroup, l.id)] ?? const LevelProgress(),
        tutorialCompleted: tutorial,
        solvedOnLastLife: lastLife,
      );

  void solve(Level l, int stars) => progress[(l.ageGroup, l.id)] =
      LevelProgress(bestStars: stars, completed: true);

  final first = levelsFor(AgeGroup.ages8to12).first;

  Future<AchievementSync> makeSync() async {
    final s = AchievementSync(database: db, platform: platform, prefs: prefs);
    await s.load();
    return s;
  }

  Future<List<Map<String, Object?>>> rows() =>
      db.db.query('achievement_state', orderBy: 'achievement_key');

  setUp(() async {
    db = await openTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    platform = FakeGamePlatform();
    progress = {};
  });
  tearDown(() => db.close());

  test('oturum yokken kayıt yerelde reported = 0 kalıyor', () async {
    final sync = await makeSync();
    solve(first, 1);
    final newly = sync.update(facts());
    await sync.idle;
    expect(newly.map((d) => d.key), [Achievements.firstLevel]);
    expect(platform.sends, isEmpty);
    final r = await rows();
    final firstLevel = r.firstWhere(
      (m) => m['achievement_key'] == Achievements.firstLevel,
    );
    expect(firstLevel['unlocked'], 1);
    expect(firstLevel['reported'], 0);
    expect(firstLevel['unlocked_at'], isNotNull);
    expect(sync.stateOf(Achievements.firstLevel).unlocked, true);
    expect(sync.pendingKeys, contains(Achievements.firstLevel));
  });

  test('oturum açılınca bekleyenler gönderiliyor', () async {
    final sync = await makeSync();
    solve(first, 3);
    sync.update(facts());
    await sync.idle;
    expect(platform.sends, isEmpty);

    platform.signInSucceeds = true;
    await sync.signInAndSync();
    await sync.idle;
    expect(
      platform.sends,
      containsAll([
        'unlock:${Achievements.firstLevel}',
        'unlock:${Achievements.firstPerfect}',
        'progress:${Achievements.stars12}:3/12',
        'progress:${Achievements.friends4}:3/4',
      ]),
    );
    expect(sync.pendingKeys, isEmpty);
    expect((await rows()).every((m) => m['reported'] == 1), true);

    // Yeni bir sync (uygulama yeniden açıldı): gönderilmiş olanlar tekrar
    // gönderilmez.
    platform.calls.clear();
    final again = await makeSync();
    await again.signInAndSync();
    await again.idle;
    expect(platform.sends, isEmpty);
  });

  test('gönderim hatasında kayıt bekler ve sonra yeniden denenir', () async {
    platform
      ..signInSucceeds = true
      ..failSends = true;
    final sync = await makeSync();
    await sync.signInAndSync();
    solve(first, 1);
    sync.update(facts());
    await sync.idle;
    expect(platform.sends, contains('unlock:${Achievements.firstLevel}'));
    expect(sync.pendingKeys, contains(Achievements.firstLevel));
    expect(
      (await rows()).firstWhere(
        (m) => m['achievement_key'] == Achievements.firstLevel,
      )['reported'],
      0,
    );

    platform
      ..failSends = false
      ..calls.clear();
    await sync.signInAndSync();
    expect(platform.sends, contains('unlock:${Achievements.firstLevel}'));
    expect(sync.pendingKeys, isEmpty);
  });

  test('aynı başarım iki kez gönderilse de sorun çıkmıyor', () async {
    platform.signInSucceeds = true;
    final sync = await makeSync();
    await sync.signInAndSync();
    solve(first, 1);
    sync.update(facts());
    await sync.idle;
    // Aynı ilerlemeyle tekrar: değişiklik yok, yeni kayıt ya da gönderim yok.
    platform.calls.clear();
    final newly = sync.update(facts());
    await sync.idle;
    expect(newly, isEmpty);
    expect(platform.sends, isEmpty);
    // Kayıt elle bekleyene çekilirse tekrar gönderilir; yine tutarlı.
    await db.db.update('achievement_state', {'reported': 0});
    await sync.load();
    await sync.flush();
    await sync.idle;
    expect(platform.sends, contains('unlock:${Achievements.firstLevel}'));
    expect(sync.pendingKeys, isEmpty);
    expect(sync.unlockedCount, 1);
  });

  test('son can olayı kalıcı: sonraki hesaplamada kapanmaz', () async {
    final sync = await makeSync();
    solve(first, 1);
    final newly = sync.update(facts(lastLife: true));
    expect(newly.map((d) => d.key), contains(Achievements.lastLife));
    sync.update(facts());
    expect(sync.stateOf(Achievements.lastLife).unlocked, true);
  });

  test('başarımlar geri gitmez (ilerleme sıfırlansa bile)', () async {
    final sync = await makeSync();
    for (final l in levelsFor(AgeGroup.ages8to12).take(4)) {
      solve(l, 3);
    }
    sync.update(facts());
    expect(sync.stateOf(Achievements.stars12).unlocked, true);
    expect(sync.stateOf(Achievements.stars36).progress, 12);
    progress.clear();
    sync.update(facts());
    expect(sync.stateOf(Achievements.stars12).unlocked, true);
    expect(sync.stateOf(Achievements.stars36).progress, 12);
  });

  test(
    'mevcut oyuncu: ilk açılışta önceki ilerlemeden hepsi kaydedilir',
    () async {
      for (final l in levelsFor(AgeGroup.ages5to7)) {
        solve(l, 3);
      }
      platform.signInSucceeds = true;
      final sync = await makeSync();
      await sync.start(facts(tutorial: true), 48);
      await sync.idle;
      for (final key in [
        Achievements.tutorialDone,
        Achievements.firstLevel,
        Achievements.firstPerfect,
        Achievements.world5to7,
        Achievements.stars12,
        Achievements.stars36,
        Achievements.perfectWorld,
        Achievements.friends4,
        Achievements.friends8,
      ]) {
        expect(sync.stateOf(key).unlocked, true, reason: key);
      }
      expect(sync.stateOf(Achievements.stars72).progress, 48);
      expect(platform.sends, contains('score:total_stars:48'));
      expect(
        platform.sends,
        contains('progress:${Achievements.stars72}:48/72'),
      );
      expect(sync.pendingKeys, isEmpty);
    },
  );

  group('Skor', () {
    test('toplam yıldız değişince gönderiliyor', () async {
      platform.signInSucceeds = true;
      final sync = await makeSync();
      await sync.signInAndSync();
      await sync.submitTotalStars(5);
      await sync.idle;
      expect(platform.sends, ['score:total_stars:5']);
      // Aynı değer tekrar gönderilmez.
      await sync.submitTotalStars(5);
      await sync.idle;
      expect(platform.sends, ['score:total_stars:5']);
      await sync.submitTotalStars(8);
      await sync.idle;
      expect(platform.sends, ['score:total_stars:5', 'score:total_stars:8']);
      expect(sync.pendingTotalStars, isNull);
    });

    test('çevrimdışıyken bekletilip en son değer sonra gönderiliyor', () async {
      final sync = await makeSync();
      await sync.submitTotalStars(3);
      await sync.submitTotalStars(7);
      await sync.idle;
      expect(platform.sends, isEmpty);
      expect(prefs.getInt(AchievementSync.pendingStarsKey), 7);

      platform.signInSucceeds = true;
      await sync.signInAndSync();
      expect(platform.sends, ['score:total_stars:7']);
      expect(prefs.getInt(AchievementSync.pendingStarsKey), isNull);
      expect(prefs.getInt(AchievementSync.reportedStarsKey), 7);
    });

    test('gönderim başarısızsa bekleyen değer korunur', () async {
      platform
        ..signInSucceeds = true
        ..failSends = true;
      final sync = await makeSync();
      await sync.signInAndSync();
      await sync.submitTotalStars(4);
      await sync.idle;
      expect(prefs.getInt(AchievementSync.pendingStarsKey), 4);
    });
  });

  test('platform kapalıyken (noop) hiçbir gönderim denenmez', () async {
    final sync = AchievementSync(
      database: db,
      platform: const NoopGamePlatform(),
      prefs: prefs,
    );
    await sync.load();
    solve(first, 3);
    await sync.start(facts(), 3);
    await sync.idle;
    expect(sync.platformKind, GamePlatformKind.none);
    expect(sync.isSignedIn, false);
    // Yerel başarımlar yine çalışır.
    expect(sync.stateOf(Achievements.firstPerfect).unlocked, true);
  });
}
