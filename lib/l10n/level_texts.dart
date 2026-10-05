import '../models/level.dart';
import 'app_localizations.dart';

/// Seviye başlık ve ipuçlarının yerelleştirilmiş metinleri.
/// Yeni seviye: ARB dosyalarına `<textKey>Title` / `<textKey>Intro` ekleyip
/// buraya birer satır yazmak yeterli (testler eksik anahtarı yakalar).
extension LevelTexts on AppLocalizations {
  String levelTitle(Level level) => switch (level.textKey) {
    'level57n01' => level57n01Title,
    'level57n02' => level57n02Title,
    'level57n03' => level57n03Title,
    'level57n04' => level57n04Title,
    'level57n05' => level57n05Title,
    'level57n06' => level57n06Title,
    'level57n07' => level57n07Title,
    'level57n08' => level57n08Title,
    'level812n01' => level812n01Title,
    'level812n02' => level812n02Title,
    'level812n03' => level812n03Title,
    'level812n04' => level812n04Title,
    'level812n05' => level812n05Title,
    'level812n06' => level812n06Title,
    'level812n07' => level812n07Title,
    'level812n08' => level812n08Title,
    'level13n01' => level13n01Title,
    'level13n02' => level13n02Title,
    'level13n03' => level13n03Title,
    'level13n04' => level13n04Title,
    'level13n05' => level13n05Title,
    'level13n06' => level13n06Title,
    'level13n07' => level13n07Title,
    'level13n08' => level13n08Title,
    _ => level.textKey,
  };

  String levelIntro(Level level) => switch (level.textKey) {
    'level57n01' => level57n01Intro,
    'level57n02' => level57n02Intro,
    'level57n03' => level57n03Intro,
    'level57n04' => level57n04Intro,
    'level57n05' => level57n05Intro,
    'level57n06' => level57n06Intro,
    'level57n07' => level57n07Intro,
    'level57n08' => level57n08Intro,
    'level812n01' => level812n01Intro,
    'level812n02' => level812n02Intro,
    'level812n03' => level812n03Intro,
    'level812n04' => level812n04Intro,
    'level812n05' => level812n05Intro,
    'level812n06' => level812n06Intro,
    'level812n07' => level812n07Intro,
    'level812n08' => level812n08Intro,
    'level13n01' => level13n01Intro,
    'level13n02' => level13n02Intro,
    'level13n03' => level13n03Intro,
    'level13n04' => level13n04Intro,
    'level13n05' => level13n05Intro,
    'level13n06' => level13n06Intro,
    'level13n07' => level13n07Intro,
    'level13n08' => level13n08Intro,
    _ => '',
  };
}
