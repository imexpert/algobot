import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';

/// Mağaza değerlendirmesinin platform tarafı (testlerde sahtesi kullanılır).
abstract class ReviewPlatform {
  /// Sistemin uygulama içi değerlendirme penceresi kullanılabilir mi.
  Future<bool> isAvailable();

  /// Sistem penceresini ister. Sistem pencereyi göstermeyebilir ve bunu
  /// bildirmez (Apple/Google kotası).
  Future<void> requestReview();

  /// Mağaza sayfasını açar (App Store'da yorum yazma ekranı).
  Future<void> openStoreListing();
}

class InAppReviewPlatform implements ReviewPlatform {
  InAppReviewPlatform({this.appStoreId = ReviewService.appStoreId});

  final String appStoreId;
  final _review = InAppReview.instance;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();

  @override
  Future<void> openStoreListing() =>
      _review.openStoreListing(appStoreId: appStoreId);
}

/// "Uygulamayı değerlendir" kuralları. Her şey yalnızca cihazda saklanır.
///
/// Seviye sonunda ebeveyne yönelik soru ancak şu koşullarda çıkar:
/// - bir kilometre taşında (dünya bitti ya da 5/15/30. üç yıldız),
/// - kurulumdan en az [minAge] sonra,
/// - son sorudan en az [minGap] sonra,
/// - en fazla [maxPrompts] kez,
/// - ebeveyn daha önce değerlendirme ekranına ulaşmadıysa.
class ReviewService {
  ReviewService(
    this._prefs, {
    ReviewPlatform? platform,
    this._clock = const SystemClock(),
  }) : _platform = platform ?? InAppReviewPlatform() {
    if (_prefs.getInt(firstSeenKey) == null) {
      _prefs.setInt(firstSeenKey, _clock.now().millisecondsSinceEpoch);
    }
  }

  /// App Store kimliği ("AlgoBot: Kids Coding Game"). Android'de paket adı
  /// (com.fabsora.algobot) otomatik kullanılır.
  static const appStoreId = '6818866136';

  static const firstSeenKey = 'review_first_seen';
  static const lastPromptKey = 'review_last_prompt';
  static const promptCountKey = 'review_prompt_count';
  static const reviewedKey = 'review_done';

  static const minAge = Duration(days: 3);
  static const minGap = Duration(days: 14);
  static const maxPrompts = 3;

  /// Bu üç yıldızlı seviye sayılarına ulaşınca sorulabilir.
  static const starMilestones = [5, 15, 30];

  final SharedPreferences _prefs;
  final ReviewPlatform _platform;
  final Clock _clock;

  bool get reviewed => _prefs.getBool(reviewedKey) ?? false;
  int get promptCount => _prefs.getInt(promptCountKey) ?? 0;

  DateTime? _time(String key) {
    final ms = _prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Üç yıldızlı seviye sayısı [before]'dan [after]'a çıkarken bir eşik
  /// geçildi mi.
  static bool crossedStarMilestone(int before, int after) =>
      starMilestones.any((m) => before < m && after >= m);

  /// Seviye sonunda soru gösterilmeli mi ([milestone]: kilometre taşı).
  bool shouldPrompt({required bool milestone}) {
    if (!milestone || reviewed || promptCount >= maxPrompts) return false;
    final now = _clock.now();
    final firstSeen = _time(firstSeenKey) ?? now;
    if (now.difference(firstSeen) < minAge) return false;
    final last = _time(lastPromptKey);
    if (last != null && now.difference(last) < minGap) return false;
    return true;
  }

  /// Soru gösterildi (cevap ne olursa olsun sayılır).
  Future<void> markPrompted() async {
    await _prefs.setInt(promptCountKey, promptCount + 1);
    await _prefs.setInt(lastPromptKey, _clock.now().millisecondsSinceEpoch);
  }

  /// Seviye sonundaki soru: önce sistem penceresi, yoksa mağaza sayfası.
  Future<void> requestReview() async {
    await _markReviewed();
    try {
      if (await _platform.isAvailable()) {
        await _platform.requestReview();
      } else {
        await _platform.openStoreListing();
      }
    } catch (e) {
      debugPrint('Değerlendirme açılamadı: $e');
    }
  }

  /// Menüdeki buton: her zaman çalışsın diye doğrudan mağaza sayfası.
  /// (Sistem penceresi kotaya takılırsa hiçbir şey görünmeyebilir.)
  Future<void> openStore() async {
    await _markReviewed();
    try {
      await _platform.openStoreListing();
    } catch (e) {
      debugPrint('Mağaza sayfası açılamadı: $e');
    }
  }

  Future<void> _markReviewed() => _prefs.setBool(reviewedKey, true);
}
