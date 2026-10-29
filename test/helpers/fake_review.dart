import 'package:algobot/review/review_service.dart';

/// Çağrıları sayan sahte mağaza değerlendirmesi.
class FakeReviewPlatform implements ReviewPlatform {
  FakeReviewPlatform({this.available = true});

  bool available;
  int requested = 0;
  int storeOpened = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requested++;

  @override
  Future<void> openStoreListing() async => storeOpened++;
}
