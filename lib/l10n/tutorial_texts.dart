import 'app_localizations.dart';

/// Eğitim balonlarının yerelleştirilmiş metinleri.
/// Yeni adım: ARB dosyalarına metni ekleyip buraya bir satır yazmak yeterli
/// (testler eksik anahtarı yakalar).
extension TutorialTexts on AppLocalizations {
  /// [characterId]: toplanabilir adı için seçili karakter.
  /// [video]: o cihazda video jokeri kullanılabiliyor mu.
  String tutorialText(
    String key, {
    String characterId = 'bip',
    bool video = false,
  }) => switch (key) {
    'tutRel01' => tutRel01,
    'tutRel02' => tutRel02,
    'tutRel03' => tutRel03,
    'tutRel04' => tutRel04,
    'tutRel05' => tutRel05,
    'tutRel06' => tutRel06,
    'tutRel07' => tutRel07,
    'tutRel08' => tutRel08,
    'tutRel09' => tutRel09,
    'tutRel10' => tutRel10,
    'tutRel11' => tutRel11,
    'tutRel12' => tutRel12,
    'tutRel13' => tutRel13,
    'tutRel14' => tutRel14,
    'tutRel15' => tutRel15,
    'tutRel16' => tutRel16,
    'tutRel17' => tutRel17(characterId),
    'tutRel18' => tutRel18,
    'tutRel19' => tutRel19,
    'tutRel20' => tutRel20,
    'tutRel21' => video ? tutRel21Video : tutRel21,
    'tutRel22' => tutRel22,
    'tutAbs01' => tutAbs01,
    'tutAbs02' => tutAbs02,
    'tutAbs03' => tutAbs03,
    'tutAbs04' => tutAbs04,
    'tutAbs05' => tutAbs05,
    'tutAbs06' => tutAbs06,
    'tutAbs07' => tutAbs07,
    'tutAbs08' => tutAbs08,
    'tutAbs09' => tutAbs09,
    'tutAbs10' => tutAbs10,
    'tutAbs11' => tutAbs11,
    'tutMechIce' => tutMechIce,
    'tutMechDoor' => tutMechDoor,
    'tutMechPortal' => tutMechPortal,
    'tutMechWatch' => tutMechWatch,
    _ => '',
  };
}
