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
  String totalStars(int earned, int total) {
    return 'Yıldızların: $earned / $total';
  }

  @override
  String get nextWorldTeaser => 'Yeni dünyalar yakında!';

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
  String levelHeader(int world, int number) {
    return 'Dünya $world · Seviye $number';
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
  String get cardHelpForward => 'Baktığın yöne 1 kare git';

  @override
  String get cardHelpTurnRight => 'Olduğun yerde sağa dön';

  @override
  String get cardHelpTurnLeft => 'Olduğun yerde sola dön';

  @override
  String get cardHelpUp => 'Yukarı 1 kare git';

  @override
  String get cardHelpDown => 'Aşağı 1 kare git';

  @override
  String get cardHelpMoveLeft => 'Sola 1 kare git';

  @override
  String get cardHelpMoveRight => 'Sağa 1 kare git';

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
  String about(String privacy) {
    return 'AlgoBot, çocuklara programcı gibi düşünmeyi öğreten bir bulmaca oyunudur. $privacy Oynamak için internet gerekmez. Karakterler yalnızca oynayarak açılır; satın alma yoktur.';
  }

  @override
  String get rateApp => 'Uygulamayı değerlendir';

  @override
  String get reviewPromptTitle => 'Harika gidiyorsun! 💛';

  @override
  String get reviewPromptBody =>
      'AlgoBot\'u sevdin mi? Bunu bir yetişkine göster. Uygulamayı mağazada değerlendirebilir.';

  @override
  String get reviewPromptParent => 'Ebeveyn';

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

  @override
  String get level57w2n01Title => 'Uzun yol';

  @override
  String get level57w2n01Intro =>
      'Aynı oku tekrar tekrar koyma: Tekrarla ile ×5 yap!';

  @override
  String get level57w2n02Title => 'Derin kuyu';

  @override
  String get level57w2n02Intro => 'Aşağı ok, ama kaç kez?';

  @override
  String get level57w2n03Title => 'Uzun köşe';

  @override
  String get level57w2n03Intro =>
      'Önce sağa, sonra aşağı. İkisini de tekrarla!';

  @override
  String get level57w2n04Title => 'Gizli hazine';

  @override
  String get level57w2n04Intro => 'Hazine yolun dışında. Önce ona git.';

  @override
  String get level57w2n05Title => 'Zikzak';

  @override
  String get level57w2n05Intro => 'Her basamakta iki adım.';

  @override
  String get level57w2n06Title => 'Büyük kare';

  @override
  String get level57w2n06Intro => 'İki hazine, iki ayrı köşede.';

  @override
  String get level57w2n07Title => 'Yılan';

  @override
  String get level57w2n07Intro => 'Uzun bir yol, ama az kart yeter.';

  @override
  String get level57w2n08Title => 'Montaj hattı';

  @override
  String get level57w2n08Intro => 'Hazineleri topla, kartları tekrarla!';

  @override
  String get level812w2n01Title => 'İlk döngü';

  @override
  String get level812w2n01Intro =>
      'Tekrarla kartı, içindeki kartları birçok kez çalıştırır.';

  @override
  String get level812w2n02Title => 'Uzun dönemeç';

  @override
  String get level812w2n02Intro => 'Her uzun düzlük için bir döngü kullan.';

  @override
  String get level812w2n03Title => 'Merdiven';

  @override
  String get level812w2n03Intro =>
      'Her basamak aynı hareketler. Bir kez yaz, tekrarla!';

  @override
  String get level812w2n04Title => 'Kare tur';

  @override
  String get level812w2n04Intro =>
      'Hedef çok yakın, ama toplanacaklar köşelerde.';

  @override
  String get level812w2n05Title => 'İki döngü';

  @override
  String get level812w2n05Intro => 'Bir programda birden çok döngü olabilir.';

  @override
  String get level812w2n06Title => 'Hazineli merdiven';

  @override
  String get level812w2n06Intro =>
      'Basamaklarda hazine var; döngü hepsini toplar.';

  @override
  String get level812w2n07Title => 'Büyük tur';

  @override
  String get level812w2n07Intro => 'Önce düşün: hangi kısım tekrar ediyor?';

  @override
  String get level812w2n08Title => 'Hattın sonu';

  @override
  String get level812w2n08Intro => 'Döngüleri ve tek kartları birlikte kullan.';

  @override
  String get level13w2n01Title => 'Sonsuz merdiven';

  @override
  String get level13w2n01Intro => 'Uzun merdiven, kısa program.';

  @override
  String get level13w2n02Title => 'Işınlı koridor';

  @override
  String get level13w2n02Intro => 'Döngü portaldan geçince de devam eder.';

  @override
  String get level13w2n03Title => 'Buz merdiveni';

  @override
  String get level13w2n03Intro => 'Buzda kaysan da döngü aynı kalır.';

  @override
  String get level13w2n04Title => 'Kilitli kare';

  @override
  String get level13w2n04Intro => 'Anahtar karenin bir köşesinde.';

  @override
  String get level13w2n05Title => 'Anahtarlı merdiven';

  @override
  String get level13w2n05Intro => 'Her bölüm için ayrı bir döngü düşün.';

  @override
  String get level13w2n06Title => 'Çifte tur';

  @override
  String get level13w2n06Intro =>
      'Hazineler yolun dışında; en kısa yol işe yaramaz.';

  @override
  String get level13w2n07Title => 'Tarak';

  @override
  String get level13w2n07Intro =>
      'Her dişte bir hazine. Tekrar eden deseni bul.';

  @override
  String get level13w2n08Title => 'Büyük final';

  @override
  String get level13w2n08Intro =>
      'Buz, portal, anahtar ve döngüler. Kartın tam yetecek kadar!';

  @override
  String levelSelectTitle(String ageRange) {
    return 'Seviyeler · $ageRange';
  }

  @override
  String worldSection(int world, String name) {
    return 'Dünya $world · $name';
  }

  @override
  String get world1Name => 'Fabrika';

  @override
  String get world2Name => 'Montaj Hattı';

  @override
  String get cmdRepeat => 'Tekrarla';

  @override
  String get loopEndShort => 'Son';

  @override
  String loopCardLabel(int count) {
    return '$count kez tekrarla';
  }

  @override
  String get loopEndCardLabel => 'Döngü sonu';

  @override
  String get loopEndOpenLabel =>
      'Döngü sonu, yeni kartlar içine giriyor. Kapatmak için dokun.';

  @override
  String multiplierCardLabel(String command, int times) {
    return '$command ×$times. Silmek için dokun.';
  }

  @override
  String get loopCountTitle => 'Kaç kez tekrarlansın?';

  @override
  String get removeLoop => 'Döngüyü kaldır';

  @override
  String stepInfoRound(
    int step,
    int total,
    String command,
    int round,
    int rounds,
  ) {
    return 'Adım $step / $total · $command · tur $round/$rounds';
  }

  @override
  String get noCardToRepeat => 'Önce bir ok kartı ekle';

  @override
  String get maxRepeat => 'En fazla ×5';

  @override
  String get howToPlay => 'Nasıl oynanır?';

  @override
  String get tutTitle => 'Eğitim';

  @override
  String get tutSkip => 'Atla';

  @override
  String get tutSkipConfirm =>
      'Eğitimi atlamak istiyor musun? İstediğin zaman ana ekrandan tekrar izleyebilirsin.';

  @override
  String get tutHelpConfirm =>
      'Eğitimi başlatmak ister misin? Bu seviyedeki programın kaybolmaz.';

  @override
  String get tutHelpStart => 'Eğitimi başlat';

  @override
  String get tutHelpMechanic => 'Bu seviyenin tanıtımı';

  @override
  String get tutNext => 'Devam ›';

  @override
  String get tutStart => 'Başla';

  @override
  String get tutGotIt => 'Anladım';

  @override
  String get tutProgressLabel => 'Eğitim ilerlemesi';

  @override
  String tutWrongCard(String card) {
    return 'Bu sefer $card kartına dokun.';
  }

  @override
  String get tutTryAgain => 'Az kaldı! Tekrar dene.';

  @override
  String get tutForgot => 'Hedefe ulaştın ama bir şeyi unuttun!';

  @override
  String get tutRemoveWrong => 'Yanlış kartı silmek için ona dokun.';

  @override
  String get tutRel01 =>
      'Merhaba! Bu senin karakterin. Onu hedefe götüreceğiz.';

  @override
  String get tutRel02 => 'Burası hedef.';

  @override
  String get tutRel03 =>
      'Bu sarı ok karakterin baktığı yön. İleri dersen bu kareye gider.';

  @override
  String get tutRel04 => 'İleri kartına dokun.';

  @override
  String get tutRel05 =>
      'Kart programına eklendi! Karakter bu kartları sırayla yapacak.';

  @override
  String get tutRel06 => 'Hedefe 2 kare var. Bir İleri daha ekle.';

  @override
  String get tutRel07 => 'Şimdi Çalıştır\'a bas ve izle!';

  @override
  String get tutRel08 => 'Harika! İlk programını yazdın.';

  @override
  String get tutRel09 => 'Bu sefer hedef aşağıda. Karakter sağa bakıyor.';

  @override
  String get tutRel10 => 'Önce bir kare ilerle.';

  @override
  String get tutRel11 =>
      'Şimdi Sağa kartına dokun. Sağa kartı karakteri yürütmez, sadece olduğu yerde çevirir.';

  @override
  String get tutRel12 =>
      'Döndükten sonra ok aşağıyı gösterecek. Bir İleri daha ekle.';

  @override
  String get tutRel13 => 'Çalıştır\'a bas. Dönerken oku izle!';

  @override
  String get tutRel14 =>
      'Sağ ve sol, karakterin kendi baktığı yöne göredir. Emin değilsen karta basılı tut, ne yaptığını söyler.';

  @override
  String get tutRel15 =>
      'Yanlış kart eklersen şeritteki karta dokunarak silebilirsin. Şimdi bir kartı sil.';

  @override
  String get tutRel16 => 'Sıra sende! Bu yolu kendin çöz.';

  @override
  String tutRel17(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bip': 'pil',
      'pati': 'balık',
      'vizviz': 'bal damlası',
      'buzi': 'buz kristali',
      'tosbi': 'çilek',
      'hop': 'havuç',
      'zorp': 'yıldız',
      'kivilcim': 'altın para',
      'other': 'hazine',
    });
    return 'Bu bir $_temp0. Toplarsan daha çok yıldız kazanırsın.';
  }

  @override
  String get tutRel18 =>
      '1 yıldız: hedefe ulaş. 2 yıldız: hepsini topla. 3 yıldız: en az kartla çöz.';

  @override
  String get tutRel19 => 'Hem topla hem hedefe ulaş!';

  @override
  String get tutRel20 =>
      'Oyunda 3 canın var. Program hedefe ulaşamazsa 1 can gider. Canlar zamanla geri gelir.';

  @override
  String get tutRel21 =>
      'Takılırsan jokerler sana yardım eder: seviyeyi atla, can al.';

  @override
  String get tutRel21Video =>
      'Takılırsan jokerler sana yardım eder: seviyeyi atla, can al ya da video izle.';

  @override
  String get tutRel22 => 'Hazırsın! Hadi ilk seviyeye geçelim.';

  @override
  String get tutAbs01 => 'Bu senin arkadaşın!';

  @override
  String get tutAbs02 => 'Onu buraya götürelim.';

  @override
  String get tutAbs03 => 'Sağ okuna dokun.';

  @override
  String get tutAbs04 => 'Bir kere daha!';

  @override
  String get tutAbs05 => 'Yeşil düğmeye bas!';

  @override
  String get tutAbs06 => 'Süper!';

  @override
  String get tutAbs07 => 'Şimdi sağa, sonra aşağı.';

  @override
  String get tutAbs08 => 'Yanlış kartı silmek için ona dokun.';

  @override
  String get tutAbs09 => 'Hazineyi de al!';

  @override
  String get tutAbs10 => '3 kalbin var. Hata yapınca bir kalp gider.';

  @override
  String get tutAbs11 => 'Hazırsın!';

  @override
  String get tutMechIce => 'Buzda durana kadar kayarsın.';

  @override
  String get tutMechDoor => 'Anahtarı alınca kapı açılır.';

  @override
  String get tutMechPortal =>
      'Bir portala girersen diğerinden çıkarsın, yönün değişmez.';

  @override
  String get tutMechWatch => 'İzle! Hazır olunca Anladım\'a bas.';

  @override
  String get achievements => 'Başarımlar';

  @override
  String achievementName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'tutorial_done': 'Öğrenmeye Hazır',
      'first_level': 'İlk Adım',
      'first_perfect': 'Kusursuz',
      'last_life': 'Pes Etmek Yok',
      'world_5_7': 'Küçük Mühendis',
      'world_8_12': 'Fabrika Ustası',
      'world_13_plus': 'Usta Programcı',
      'stars_12': 'Yıldız Toplayıcı',
      'stars_36': 'Yıldız Avcısı',
      'stars_72': 'Süper Yıldız',
      'stars_144': 'Galaksi',
      'perfect_world': 'Sıfır Hata',
      'friends_4': 'Yeni Arkadaşlar',
      'friends_8': 'Tam Takım',
      'ice_master': 'Buz Patencisi',
      'key_master': 'Anahtar Ustası',
      'portal_master': 'Işınlan!',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String achievementDesc(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'tutorial_done': 'Bir eğitimi baştan sona tamamla.',
      'first_level': 'İlk seviyeni çöz.',
      'first_perfect': 'Bir seviyede 3 yıldız kazan.',
      'last_life': 'Son canınla bir seviyeyi çöz.',
      'world_5_7': '5–7 yaş setindeki 16 seviyenin hepsini çöz.',
      'world_8_12': '8–12 yaş setindeki 16 seviyenin hepsini çöz.',
      'world_13_plus': '13+ yaş setindeki 16 seviyenin hepsini çöz.',
      'stars_12': 'Toplam 12 yıldız topla.',
      'stars_36': 'Toplam 36 yıldız topla.',
      'stars_72': 'Toplam 72 yıldız topla.',
      'stars_144': '144 yıldızın hepsini topla.',
      'perfect_world': 'Bir dünyanın 8 seviyesinin hepsinde 3 yıldız kazan.',
      'friends_4': '4 karakterin kilidini aç.',
      'friends_8': '8 karakterin hepsinin kilidini aç.',
      'ice_master': '13+ setinde buzun ilk göründüğü seviyeyi çöz.',
      'key_master':
          '13+ setinde anahtar ve kapının ilk göründüğü seviyeyi çöz.',
      'portal_master': '13+ setinde portalların ilk göründüğü seviyeyi çöz.',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String achievementsSummary(int unlocked, int total) {
    return '$unlocked / $total başarım';
  }

  @override
  String get achievementUnlocked => 'Yeni başarım!';

  @override
  String get achievementLocked => 'Kilitli';

  @override
  String achievementProgress(int progress, int target) {
    return '$progress / $target';
  }

  @override
  String get achievementsParentArea => 'Yalnızca ebeveynler için';

  @override
  String viewOnGamePlatform(String service) {
    String _temp0 = intl.Intl.selectLogic(service, {
      'playGames': 'Google Play Games\'te gör',
      'other': 'Game Center\'da gör',
    });
    return '$_temp0';
  }

  @override
  String get openLeaderboard => 'Skor tablosu: Toplam Yıldız';

  @override
  String get leaderboardName => 'Toplam Yıldız';

  @override
  String aboutPrivacy(String service) {
    String _temp0 = intl.Intl.selectLogic(service, {
      'playGames':
          'Oyun içi veri toplanmaz. Başarımlar için isteğe bağlı olarak Google Play Games kullanılır.',
      'gameCenter':
          'Oyun içi veri toplanmaz. Başarımlar için isteğe bağlı olarak Game Center kullanılır.',
      'other': 'Veri toplanmaz.',
    });
    return '$_temp0';
  }

  @override
  String get resetAchievementsKept => 'Kazanılan başarımlar silinmez.';

  @override
  String get gameAccount => 'Oyun hesabı';

  @override
  String connectGamePlatform(String service) {
    String _temp0 = intl.Intl.selectLogic(service, {
      'playGames': 'Play Games\'e bağlan',
      'other': 'Game Center\'a bağlan',
    });
    return '$_temp0';
  }

  @override
  String connectedGamePlatform(String service) {
    String _temp0 = intl.Intl.selectLogic(service, {
      'playGames': 'Play Games\'e bağlı',
      'other': 'Game Center\'a bağlı',
    });
    return '$_temp0';
  }

  @override
  String get connectFailed =>
      'Bağlanılamadı, daha sonra tekrar deneyebilirsin.';

  @override
  String get gameCenterSettingsHint =>
      'Ayarlar > Game Center\'dan giriş yapıp uygulamayı yeniden açın.';
}
