import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show inMemoryDatabasePath;

import 'audio/sound_service.dart';
import 'data/db/app_database.dart';
import 'data/levels.dart';
import 'data/progress_repository.dart';
import 'data/session_repository.dart';
import 'review/review_service.dart';
import 'rewards/rewarded_video_service.dart';
import 'rewards/stub_rewarded_video_service.dart';
import 'state/progress_controller.dart';

/// Açılış sırasında arka planda hazırlanan servisler.
class AppServices {
  const AppServices({
    required this.progress,
    required this.sessions,
    required this.video,
    required this.review,
  });

  final ProgressController progress;
  final SessionRepository sessions;
  final RewardedVideoService video;
  final ReviewService review;
}

/// Açılış animasyonuyla paralel yürüyen başlangıç işleri: veritabanı ve
/// göçler, ilerleme ve oturumların yüklenmesi.
///
/// Seslerin önbelleğe alınması beklenmez (önbellek yalnızca hızlandırır;
/// yavaş bir cihazda açılışı uzatıp veritabanını yedeğe düşürmesin).
/// Veritabanı açılamazsa ya da [timeout] süresinde yüklenemezse hata
/// kaydedilir ve bu oturum bellek içi veritabanıyla sürer. Bu durumda ilerleme
/// diske yazılmaz; bu yüzden süre yalnızca takılmaya karşı bir güvencedir ve
/// cömert tutulur.
Future<AppServices> loadAppServices(
  SharedPreferences prefs,
  SoundService sound, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  unawaited(sound.preload());
  Future<AppServices> load(Future<AppDatabase> Function() openDb) async {
    final database = await openDb();
    final repository = ProgressRepository(database);
    // Eski sürümlerin yıldızları bir kez SQLite'a aktarılır.
    await repository.migrateFromPrefs(prefs);
    final progress = ProgressController(repository, allLevelSets);
    final sessions = SessionRepository(database);
    // Video jokeri şimdilik kapalı: joker çubuğunda pasif görünür, canlar
    // bitti panelinde gösterilmez. Açmak için `available: true` (ya da
    // gerçek reklam SDK'sı entegre edilince yalnızca bu satır değişir).
    final video = StubRewardedVideoService(available: false);
    await Future.wait([progress.load(), sessions.load(), video.preload()]);
    return AppServices(
      progress: progress,
      sessions: sessions,
      video: video,
      review: ReviewService(prefs),
    );
  }

  try {
    return await load(_openDatabase).timeout(timeout);
  } catch (e) {
    debugPrint('Başlangıç yüklemesi tamamlanamadı, yedekle devam: $e');
    return load(() => AppDatabase.open(path: inMemoryDatabasePath));
  }
}

/// Veritabanı açılamazsa oyun çökmez: bu oturum için bellek içi veritabanı.
Future<AppDatabase> _openDatabase() async {
  try {
    return await AppDatabase.open();
  } catch (e) {
    debugPrint('Veritabanı açılamadı, bellek içi devam: $e');
    return AppDatabase.open(path: inMemoryDatabasePath);
  }
}
