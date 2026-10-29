import 'package:algobot/review/review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_review.dart';
import 'helpers/test_db.dart';

void main() {
  late FakeClock clock;
  late FakeReviewPlatform platform;

  Future<ReviewService> make([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    return ReviewService(
      await SharedPreferences.getInstance(),
      platform: platform,
      clock: clock,
    );
  }

  setUp(() {
    clock = FakeClock();
    platform = FakeReviewPlatform();
  });

  test('Kilometre taşı eşikleri: 5, 15, 30 üç yıldız', () {
    expect(ReviewService.crossedStarMilestone(4, 5), isTrue);
    expect(ReviewService.crossedStarMilestone(5, 6), isFalse);
    expect(ReviewService.crossedStarMilestone(14, 15), isTrue);
    expect(ReviewService.crossedStarMilestone(29, 30), isTrue);
    expect(ReviewService.crossedStarMilestone(30, 31), isFalse);
    expect(ReviewService.crossedStarMilestone(3, 3), isFalse);
  });

  test(
    'Kurulumdan 3 gün geçmeden ve kilometre taşı olmadan sorulmaz',
    () async {
      final review = await make();
      expect(review.shouldPrompt(milestone: true), isFalse);
      clock.advance(const Duration(days: 2, hours: 23));
      expect(review.shouldPrompt(milestone: true), isFalse);
      clock.advance(const Duration(hours: 1));
      expect(review.shouldPrompt(milestone: true), isTrue);
      expect(review.shouldPrompt(milestone: false), isFalse);
    },
  );

  test(
    'Kurulum tarihi bir kez kaydedilir, sonraki açılışlarda korunur',
    () async {
      await make();
      final prefs = await SharedPreferences.getInstance();
      final first = prefs.getInt(ReviewService.firstSeenKey);
      clock.advance(const Duration(days: 5));
      final again = ReviewService(prefs, platform: platform, clock: clock);
      expect(prefs.getInt(ReviewService.firstSeenKey), first);
      expect(again.shouldPrompt(milestone: true), isTrue);
    },
  );

  test('En az 14 gün arayla, en fazla 3 kez', () async {
    final review = await make();
    clock.advance(const Duration(days: 3));
    for (var i = 0; i < ReviewService.maxPrompts; i++) {
      expect(review.shouldPrompt(milestone: true), isTrue, reason: 'soru $i');
      await review.markPrompted();
      expect(review.shouldPrompt(milestone: true), isFalse);
      clock.advance(const Duration(days: 13));
      expect(review.shouldPrompt(milestone: true), isFalse);
      clock.advance(const Duration(days: 1));
    }
    expect(review.promptCount, 3);
    expect(review.shouldPrompt(milestone: true), isFalse);
  });

  test('Seviye sonu: sistem penceresi; yoksa mağaza sayfası; sonra bir daha '
      'sorulmaz', () async {
    final review = await make();
    clock.advance(const Duration(days: 3));
    await review.requestReview();
    expect(platform.requested, 1);
    expect(platform.storeOpened, 0);
    expect(review.reviewed, isTrue);
    expect(review.shouldPrompt(milestone: true), isFalse);

    platform.available = false;
    await review.requestReview();
    expect(platform.requested, 1);
    expect(platform.storeOpened, 1);
  });

  test('Menü butonu doğrudan mağaza sayfasını açar', () async {
    final review = await make();
    await review.openStore();
    expect(platform.storeOpened, 1);
    expect(platform.requested, 0);
    expect(review.reviewed, isTrue);
  });

  test('App Store kimliği yayındaki uygulamaya ait', () {
    expect(ReviewService.appStoreId, '6818866136');
  });
}
