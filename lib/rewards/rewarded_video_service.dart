import 'package:flutter/widgets.dart';

enum RewardedVideoResult { completed, dismissed, failed }

/// Ödüllü video ("Video ile Geç" jokeri).
///
/// NOT (gerçek entegrasyon için): Google Play "Families" politikasına uygun,
/// sertifikalı bir reklam SDK'sı kullanılmalı; kişiselleştirilmemiş reklam
/// ve çocuklara yönelik içerik ayarları açılmalı
/// (`tagForChildDirectedTreatment`, maksimum içerik derecesi G); video
/// sırasında dışarı link açılmamalı. Apple Kids kategorisinde üçüncü taraf
/// reklamlar ek kısıtlamalara tabidir. Gerçek uygulama, `main.dart`'taki
/// sağlayıcıda tek satırla bu arayüzün yerine geçer.
abstract class RewardedVideoService {
  /// false ise Video jokeri hiç gösterilmez.
  bool get isAvailable;

  Future<void> preload();

  /// Videoyu gösterir. Yalnızca `completed` jokeri harcatır.
  Future<RewardedVideoResult> show(BuildContext context);
}
