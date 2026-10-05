// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'AlgoBot';

  @override
  String get play => 'Oyna';

  @override
  String get soundOn => 'Ses açık';

  @override
  String get soundOff => 'Ses kapalı';

  @override
  String get parent => 'Ebeveyn';

  @override
  String get characters => 'Karakterler';

  @override
  String get gallery => 'Karakter galerisi';

  @override
  String get back => 'Geri';

  @override
  String ageRange(String age) {
    String _temp0 = intl.Intl.selectLogic(age, {
      'ages5to7': '5–7 yaş',
      'ages8to12': '8–12 yaş',
      'other': '13+ yaş',
    });
    return '$_temp0';
  }

  @override
  String ageShort(String age) {
    String _temp0 = intl.Intl.selectLogic(age, {
      'ages5to7': '5–7',
      'ages8to12': '8–12',
      'other': '13+',
    });
    return '$_temp0';
  }

  @override
  String worldTitle(String ageRange) {
    return 'Dünya 1 · Fabrika · $ageRange';
  }

  @override
  String totalStars(int earned, int total) {
    return 'Yıldızların: $earned / $total';
  }

  @override
  String get nextWorldTeaser => 'Dünya 2 yakında: Döngüler!';

  @override
  String levelCardLabel(int id, String title, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars yıldız',
      zero: 'yıldız yok',
    );
    return 'Seviye $id, $title, $_temp0';
  }

  @override
  String levelCardLockedLabel(int id, String title) {
    return 'Seviye $id, $title, kilitli';
  }

  @override
  String levelCardSkippedLabel(int id, String title) {
    return 'Seviye $id, $title, atlandı';
  }

  @override
  String levelCardNoLivesLabel(int id, String title, String time) {
    return 'Seviye $id, $title, can yok. Yeni can: $time';
  }

  @override
  String levelHeader(int id) {
    return 'Dünya 1 · Seviye $id';
  }

  @override
  String get program => 'Programın';

  @override
  String get paletteSemanticsLabel => 'Komutlar';

  @override
  String slotCounter(int used, int max) {
    return '$used / $max';
  }

  @override
  String get clear => 'Temizle';

  @override
  String get run => 'Çalıştır';

  @override
  String get stop => 'Durdur';

  @override
  String get fast => 'Hızlı';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get emptyProgram => 'Önce bir komut ekle';

  @override
  String get stripFull => 'Kart yerin doldu';

  @override
  String stepInfo(int step, int total, String command) {
    return 'Adım $step / $total · $command';
  }

  @override
  String get crashMessage =>
      'Bum! Duvara çarptın. Programını düzeltip tekrar dene.';

  @override
  String get stoppedShortMessage => 'Program bitti ama hedefe ulaşamadın.';

  @override
  String get tapToClose => 'Kapatmak için dokun';

  @override
  String get board => 'Oyun tahtası';

  @override
  String get cmdForward => 'İleri';

  @override
  String get cmdRight => 'Sağa';

  @override
  String get cmdLeft => 'Sola';

  @override
  String get cmdTurnRight => 'Sağa dön';

  @override
  String get cmdTurnLeft => 'Sola dön';

  @override
  String get cmdUp => 'Yukarı';

  @override
  String get cmdDown => 'Aşağı';

  @override
  String get cmdMoveLeft => 'Sol';

  @override
  String get cmdMoveRight => 'Sağ';

  @override
  String paletteCardLabel(String command) {
    return '$command kartı';
  }

  @override
  String stripCardLabel(String command) {
    return 'Programdan sil: $command';
  }

  @override
  String emptySlotLabel(int n) {
    return '$n. boş yuva';
  }

  @override
  String livesLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n can kaldı',
      zero: 'Can kalmadı',
    );
    return '$_temp0';
  }

  @override
  String get lastLife => 'Son can!';

  @override
  String get outOfLivesTitle => 'Canların bitti';

  @override
  String get outOfLivesBody => 'Sorun değil! Biraz dinlen, sonra tekrar dene.';

  @override
  String nextLife(String time) {
    return 'Yeni can: $time';
  }

  @override
  String get mainMenu => 'Ana menü';

  @override
  String get useLifeJoker => 'Can jokerini kullan (+1)';

  @override
  String get skipLevelAction => 'Seviyeyi atla';

  @override
  String get watchVideoAction => 'Video izle ve geç';

  @override
  String get jokerSkip => 'Atla';

  @override
  String get jokerLife => 'Can';

  @override
  String get jokerVideo => 'Video';

  @override
  String jokerUsedLabel(String name) {
    return '$name, kullanıldı';
  }

  @override
  String get skipConfirm =>
      'Bu seviyeyi atlamak istiyor musun? Atlanan seviyeden yıldız kazanamazsın.';

  @override
  String get skipConfirmYes => 'Atla';

  @override
  String get skippedLabel => 'Atlandı';

  @override
  String get videoFailed => 'Video şu an yüklenemedi.';

  @override
  String get videoPlaceholder => 'Video burada gösterilecek';

  @override
  String get resultOneStar => 'Başardın!';

  @override
  String get resultTwoStars => 'Çok iyi!';

  @override
  String get resultThreeStars => 'Kusursuz!';

  @override
  String resultCommands(int used, int optimal) {
    return 'Kullandığın komut: $used · En kısa çözüm: $optimal';
  }

  @override
  String collectedCount(String character, int got, int total) {
    String _temp0 = intl.Intl.selectLogic(character, {
      'bip': 'Piller',
      'pati': 'Balıklar',
      'vizviz': 'Bal damlaları',
      'buzi': 'Buz kristalleri',
      'tosbi': 'Çilekler',
      'hop': 'Havuçlar',
      'zorp': 'Yıldızlar',
      'kivilcim': 'Altın paralar',
      'other': '?',
    });
    return '$_temp0: $got / $total';
  }

  @override
  String hintCollect(String character) {
    String _temp0 = intl.Intl.selectLogic(character, {
      'bip': 'pilleri',
      'pati': 'balıkları',
      'vizviz': 'bal damlalarını',
      'buzi': 'buz kristallerini',
      'tosbi': 'çilekleri',
      'hop': 'havuçları',
      'zorp': 'yıldızları',
      'kivilcim': 'altın paraları',
      'other': '?',
    });
    return 'Tüm $_temp0 toplarsan 2. yıldızı alırsın.';
  }

  @override
  String hintShorter(int optimal) {
    return '$optimal komutla çözebilir misin?';
  }

  @override
  String get again => 'Tekrar';

  @override
  String get next => 'Devam';

  @override
  String starsLabel(int stars) {
    return '3 üzerinden $stars yıldız';
  }

  @override
  String characterName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bip': 'Bip',
      'pati': 'Pati',
      'vizviz': 'Vızvız',
      'buzi': 'Buzi',
      'tosbi': 'Tosbi',
      'hop': 'Hop',
      'zorp': 'Zorp',
      'kivilcim': 'Kıvılcım',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String collectibleOf(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bip': 'pil',
      'pati': 'balık',
      'vizviz': 'bal damlası',
      'buzi': 'buz kristali',
      'tosbi': 'çilek',
      'hop': 'havuç',
      'zorp': 'yıldız',
      'kivilcim': 'altın para',
      'other': '?',
    });
    return 'Topladığı: $_temp0';
  }

  @override
  String get select => 'Seç';

  @override
  String get selectedLabel => 'Seçili';

  @override
  String unlockAt(int stars) {
    return '$stars yıldızda açılır';
  }

  @override
  String unlockProgress(int have, int need) {
    return '$have / $need';
  }

  @override
  String newFriend(String name) {
    return 'Yeni arkadaş: $name!';
  }

  @override
  String get tryNow => 'Şimdi dene';

  @override
  String get later => 'Sonra';

  @override
  String characterCardLocked(String name) {
    return '$name, kilitli';
  }

  @override
  String characterCardSelected(String name) {
    return '$name, seçili';
  }

  @override
  String get welcomeAge => 'Merhaba! Kaç yaşındasın?';

  @override
  String get pickFriend => 'Bir arkadaş seç!';

  @override
  String get start => 'Başla';

  @override
  String get parentGateTitle => 'Ebeveyn alanı';

  @override
  String parentQuestion(int a, int b) {
    return '$a + $b kaç?';
  }

  @override
  String get wrongAnswer => 'Yanlış cevap, tekrar dene.';

  @override
  String get ok => 'Tamam';

  @override
  String get delete => 'Sil';

  @override
  String get close => 'Kapat';

  @override
  String get settings => 'Ayarlar';

  @override
  String get sound => 'Ses';

  @override
  String get ageRangeTitle => 'Yaş aralığı';

  @override
  String get resetProgress => 'İlerlemeyi sıfırla';

  @override
  String get resetConfirmTitle => 'Emin misiniz?';

  @override
  String get resetConfirmBody =>
      'Tüm yıldızlar silinecek ve seviyeler yeniden kilitlenecek.';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get reset => 'Sıfırla';

  @override
  String get resetDone => 'İlerleme sıfırlandı.';

  @override
  String get about =>
      'AlgoBot, çocuklara programcı gibi düşünmeyi öğreten bir bulmaca oyunudur. Veri toplanmaz. İnternet bağlantısı gerekmez. Karakterler yalnızca oynayarak açılır; satın alma yoktur.';

  @override
  String get level57n01Title => 'Merhaba!';

  @override
  String get level57n01Intro => 'Ok kartına dokun, sonra yeşil düğmeye bas!';

  @override
  String get level57n02Title => 'Aşağı in';

  @override
  String get level57n02Intro => 'Bu sefer aşağı gitmen lazım.';

  @override
  String get level57n03Title => 'Köşe';

  @override
  String get level57n03Intro => 'Önce sağa, sonra aşağı!';

  @override
  String get level57n04Title => 'Yukarı çık';

  @override
  String get level57n04Intro => 'Duvarın etrafından dolaş.';

  @override
  String get level57n05Title => 'Hazine';

  @override
  String get level57n05Intro => 'Hazineyi de alabilir misin?';

  @override
  String get level57n06Title => 'Yılan yolu';

  @override
  String get level57n06Intro => 'Yolu parmağınla takip et.';

  @override
  String get level57n07Title => 'İki hazine';

  @override
  String get level57n07Intro => 'Hedefe en son git!';

  @override
  String get level57n08Title => 'Büyük fabrika';

  @override
  String get level57n08Intro =>
      'Hazine biraz uzakta. Önce ona git, sonra geri dön.';

  @override
  String get level812n01Title => 'İlk adım';

  @override
  String get level812n01Intro =>
      'İleri kartını aşağıdaki şeride sürükle ve Çalıştır\'a bas.';

  @override
  String get level812n02Title => 'Sağa dönüş';

  @override
  String get level812n02Intro => 'Dönüş kartı yerinde döndürür, ilerletmez.';

  @override
  String get level812n03Title => 'Sola dönüş';

  @override
  String get level812n03Intro => 'Sağ ve sol, baktığın yöne göredir.';

  @override
  String get level812n04Title => 'Zikzak';

  @override
  String get level812n04Intro => 'Gideceğin yolu önce parmağınla takip et.';

  @override
  String get level812n05Title => 'Hazine mi, kestirme mi?';

  @override
  String get level812n05Intro =>
      'Hedefe gitmenin birden fazla yolu var. Hepsini toplayabilir misin?';

  @override
  String get level812n06Title => 'Ters yön';

  @override
  String get level812n06Intro => 'Hangi yöne bakıyorsun? Önce dön.';

  @override
  String get level812n07Title => 'Sınırlı kart';

  @override
  String get level812n07Intro =>
      'Sadece 10 kart yerin var. Her kartı iyi düşün.';

  @override
  String get level812n08Title => 'Fabrika çıkışı';

  @override
  String get level812n08Intro =>
      'Uzun bir yol! Aynı hareketleri tekrarladığını fark ettin mi?';

  @override
  String get level13n01Title => 'Büyük labirent';

  @override
  String get level13n01Intro => 'Harita büyüdü. Çıkmaz sokaklara dikkat!';

  @override
  String get level13n02Title => 'Yol ayrımı';

  @override
  String get level13n02Intro =>
      'En yakındakini hemen almak her zaman en kısa yol değildir.';

  @override
  String get level13n03Title => 'Kilitli kapı';

  @override
  String get level13n03Intro => 'Kapılar anahtarsız açılmaz. Anahtar nerede?';

  @override
  String get level13n04Title => 'Anahtar avı';

  @override
  String get level13n04Intro => 'Bazen geri dönmek gerekir. Önce anahtarı bul.';

  @override
  String get level13n05Title => 'Kaygan zemin';

  @override
  String get level13n05Intro =>
      'Buzda durmak zordur: önüne engel çıkana kadar kayarsın.';

  @override
  String get level13n06Title => 'Buz pateni';

  @override
  String get level13n06Intro =>
      'Buz hızlıdır ama her şeyi toplamana izin verir mi?';

  @override
  String get level13n07Title => 'Işınlan!';

  @override
  String get level13n07Intro =>
      'Portala giren, öbür portaldan aynı yöne bakarak çıkar.';

  @override
  String get level13n08Title => 'Final';

  @override
  String get level13n08Intro =>
      'Anahtar, buz ve portal bir arada. Kartın tam yetecek kadar!';
}
