# AlgoBot — QA Raporu

Tarih: 24 Ekim 2026 · Kapsam: çalışma kopyasındaki güncel kod (Dünya 2 ve "Uygulamayı değerlendir" dahil, commit edilmemiş hâli) · Uygulama kodu **değiştirilmedi**; yalnızca test dosyaları eklendi.

## Düzeltmeler (25 Ekim 2026)

Raporda listelenen 12 bulgunun 11'i düzeltildi. QA-12 paket tarafında, uygulamadan düzeltilemiyor. Düzeltmelerden sonra:

- `flutter analyze` sorunsuz; **532/532 test geçiyor**.
- Entegrasyon testleri Android emülatöründe (İngilizce) ve iOS simülatöründe (Türkçe) ses açıkken iki aşamada geçti.
- Release AAB (54,6 MB) ve iOS release derlemesi başarılı.

| # | Durum | Ne değişti |
|---|---|---|
| QA-1, QA-2 | ✅ Düzeltildi | Atlama animasyonu sürerken şerit, palet ve Çalıştır kilitli (`isLocked` artık `_skipping`'i de kapsıyor) — [game_controller.dart](lib/state/game_controller.dart) |
| QA-3 | ✅ Düzeltildi | Can 0 iken Çalıştır programı oynatmıyor, "Canlar bitti" panelini hemen açıyor. |
| QA-4 | ✅ Düzeltildi | Geri sayım satırı dar kartta küçülerek sığıyor (`Flexible` + `FittedBox`) — [level_select_screen.dart](lib/ui/screens/level_select_screen.dart) |
| QA-5 | ✅ Düzeltildi | İlerleme kaydı `try/await/catch` ile; veritabanı hatası artık yakalanmamış hata üretmiyor — [progress_controller.dart](lib/state/progress_controller.dart) |
| QA-6 | ✅ Düzeltildi | Efekt oynatıcılarında konum güncelleyici kapatıldı (`positionUpdater = null`). Android'de ses açıkken bekleyen kare geri çağrısı **9 → 0** — [sound_service.dart](lib/audio/sound_service.dart) |
| QA-7 | ✅ Düzeltildi | Ses önbelleği açılışta beklenmiyor (arka planda sürüyor). Veritabanı zaman aşımı 6 → 20 sn; yedeğe yalnızca gerçek takılma ya da hata durumunda düşülüyor — [app_services.dart](lib/app_services.dart) |
| QA-8 | ✅ Düzeltildi | Sürüm `1.1.0+2` — [pubspec.yaml](pubspec.yaml) |
| QA-9 | ✅ İyileştirildi | Geniş yatay ekranda (≥900dp ve yatay) oyun ekranı iki sütunlu: tahta solda, şerit ve kontroller sağda. Dikey düzen değişmedi — [game_screen.dart](lib/ui/screens/game_screen.dart) |
| QA-10 | ✅ Düzeltildi | "Oynamak için internet gerekmez." / "No internet needed to play." |
| QA-11 | ✅ Düzeltildi | Yalnızca boş döngü varsa "Önce bir komut ekle" gösteriliyor; çalışmıyor ve can düşmüyor. |
| QA-12 | ⏸ Paket tarafında | `in_app_review` zaten en son sürümde (2.0.12). Uyarı derlemeyi engellemiyor; paketin yeni sürümleri takip edilmeli. |

`known_bugs_qa_test.dart` dosyası [test/qa/regression_qa_test.dart](test/qa/regression_qa_test.dart) olarak yeniden adlandırıldı ve QA-7, QA-9, QA-10, QA-11 testleri eklendi (toplam 10 test, hepsi yeşil).

---

## Özet (ilk tarama)

**Uygulama çalışıyor; kritik sorun yok. 1 yüksek önemli oyun hatası, 1 yüksek önemli yayın engeli, 5 orta ve 5 düşük önemli sorun var.**

Önemli notlar:

- Görevde "24 seviye" yazıyor, ama uygulamada artık **48 seviye** var (3 yaş grubu × 16; Dünya 1 ve Dünya 2). Testler 48 seviyenin hepsini kapsıyor.
- Uygulamada reklam entegrasyonu yok. Video jokeri stub (yer tutucu) servis kullanıyor ve release'de `available: false` sabit ([app_services.dart:45](lib/app_services.dart#L45)).

### Test edilen ortamlar

| Ortam | Durum |
|---|---|
| Android emülatörü Pixel 7, Android 15 (API 35), İngilizce | ✅ Entegrasyon testleri (2 aşama) geçti |
| iOS simülatörü iPhone 18 Pro, iOS 27.0, Türkçe | ✅ Entegrasyon testleri (2 aşama) geçti |
| Widget ve birim testleri (macOS, Flutter 3.47.6 / Dart 3.13.5) | ✅ 528 testten 522'si geçti; 6 kırmızı test bilinen hataları yeniden üretiyor |
| Fiziksel Android cihaz | ❌ Yok (profil modu ölçümü yapılamadı) |
| Fiziksel iPhone (kablosuz bağlı) | Kullanılmadı |

### Komut sonuçları

| Komut | Sonuç |
|---|---|
| `flutter --version` | Flutter 3.47.6 (stable), Dart 3.13.5, Xcode 27.1 |
| `flutter doctor -v` | Tek uyarı: bazı Android SDK lisansları kabul edilmemiş (`flutter doctor --android-licenses`). Derlemeyi engellemiyor. |
| `flutter clean` + `flutter pub get` | ✅ |
| `flutter analyze` | ✅ Sorun yok (0 uyarı, 0 hata) |
| `flutter test` (QA öncesi, mevcut testler) | ✅ 408 geçti, 0 kaldı, 0 atlandı |
| `flutter test` (QA testleri dahil) | 522 geçti, **6 kaldı** (hepsi `known_bugs_qa_test.dart`), 0 atlandı |
| `flutter build apk --debug` | ✅ |
| `flutter build apk --release` | ✅ 55,5 MB. Bu üç işlemci mimarisini birden içeren paket; Play'e yüklenen AAB cihaza göre bölünür. Uyarı: `in_app_review` eski Kotlin Gradle Plugin yöntemini kullanıyor. |
| `flutter build ios --debug --no-codesign` | ✅ |
| `dart pub outdated` | Güvenlik riski yok. Küçük güncellemeler var: `sqflite` 2.4.5, `shared_preferences_android` 2.5.3, `sqflite_android` 2.4.5. `cupertino_icons` 2.0.0 büyük sürüm (kullanılmıyor gibi). |

## Bulgular

| # | Önem | Bölüm | Sorun | Yeniden üretme adımları | Olası sebep (dosya:satır) | Önerilen düzeltme |
|---|---|---|---|---|---|---|
| QA-1 | **Yüksek** | Jokerler / oyun akışı | Tur Atla animasyonu sırasında "Çalıştır"a basılırsa atlama yarıda kalıyor. Ekranda "Atlandı" yazısı kalıcı olarak duruyor, sonraki seviyeye geçilmiyor, tüm jokerler pasif kalıyor ve çalışan program başarısız olursa yeni sıfırlanmış oturumdan bir can düşüyor. | 1. Herhangi bir seviyeyi açın (ör. 8–12 Seviye 3) ve şeride bir kart ekleyin. 2. Tur Atla → onaylayın. 3. "Atlandı" yazısı görünürken (~1,5 sn) "Çalıştır"a basın. 4. Seviye 4 açılmıyor, ekran takılı kalıyor. Test: `QA-1`. | [game_controller.dart:584](lib/state/game_controller.dart#L584): atlama sırasında aşama `editing` yapılıyor, bu yüzden `isLocked` ([:125](lib/state/game_controller.dart#L125)) false oluyor. `run()` ([:630](lib/state/game_controller.dart#L630)) `_skipping`'e bakmıyor; `_begin` içindeki `_cancelPlayback` atlama animasyonunu iptal ediyor, `onSkipped` hiç çağrılmıyor ve `_skipping` true kalıyor. | `isLocked` içine `_skipping`'i ekleyin (`_phase != editing \|\| _skipping`). Böylece Çalıştır, palet, şerit ve Temizle atlama boyunca kilitlenir. |
| QA-2 | Düşük | Kalıcılık | Aynı kök neden: atlama animasyonu sırasında palete dokunmak kartı ekliyor. 300 ms sonra bu program, yeni silinen (atlanan) seviyenin oturumuna yazılıyor. | Atlamayı onaylayın, animasyon sırasında bir palet kartına dokunun. Seviyeye geri dönünce o kart şeritte duruyor. Test: `QA-2`. | [game_controller.dart:385](lib/state/game_controller.dart#L385) `addCommand` yalnızca `isLocked`'a bakıyor. | QA-1 düzeltmesi bunu da çözer. |
| QA-3 | Düşük | Canlar | Üçüncü başarısızlıktan sonra "Canlar bitti" paneli 900 ms gecikmeyle açılıyor. Bu arada "Tekrar dene" + "Çalıştır"a basılırsa program 0 canla çalışıyor. Panel çalışma sırasında açılıyor; bu anda Can jokeri reddediliyor ve panel bir kez daha açılıyor. | 1. Çarpan bir programla 3 kez başarısız olun. 3. çarpmada başarısız paneli görünür görünmez "Tekrar dene"ye, hemen ardından "Çalıştır"a basın. 2. Program oynuyor ("Durdur" görünüyor). Test: `QA-3`. | [game_controller.dart:654](lib/state/game_controller.dart#L654) `_begin` can kontrolü yapmıyor. Panel `_after(900, …)` ile geciktiriliyor. | `_begin`'de `outOfLives` ise çalıştırmayın ve paneli hemen açın (`onOutOfLives`). İsterseniz başarısız panelindeki "Tekrar dene" de 0 canda doğrudan paneli açabilir. |
| QA-4 | Orta | Taşma | Seviye seçiminde canı bitmiş seviyenin kartı, 360dp genişlik ve 1.3x yazı boyutunda 17 piksel sağa taşıyor (iki dilde de). Kırık kalp ve geri sayım sığmıyor. | 1. Telefonu en küçük ekran ve en büyük yazı (1.3x) ayarına alın. 2. Bir seviyede 3 can kaybedin. 3. Seviye seçimine dönün: kartta sarı-siyah taşma şeridi (debug) ya da kesik geri sayım görünüyor. Test: `QA-4 (tr)`, `QA-4 (en)`. | [level_select_screen.dart:332](lib/ui/screens/level_select_screen.dart#L332): geri sayım satırı esnek değil. Kart içeriği 134dp, satır 151dp istiyor. | Satırı `Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Row(...)))` içine alın. Kalp ikonu küçültülebilir ya da yalnızca geri sayım gösterilebilir. |
| QA-5 | Orta | Veritabanı sağlamlığı | İlerleme kaydı başarısız olursa (disk dolu, veritabanı kapalı vb.) hata yakalayıcının kendisi ikinci bir **yakalanmamış** hata üretiyor (`Invalid argument(s) (onError): The error handler of Future.catchError must return a value of the future's type`). Oyun çökmüyor, ama "veritabanı hatası sessizce yutulur" sözü tutulmuyor ve hata raporlayıcılar bunu çökme sayar. | Veritabanını kapatıp bir seviyeyi kazanın (testte benzetildi). Test: `QA-5`. Ayrıca saf Dart ile yeniden üretildi. | [progress_controller.dart:104](lib/state/progress_controller.dart#L104): `save()` aslında `Future<int>` (sqflite `insert`). `catchError` işleyicisi `null` döndüğü için Dart çalışma anında ArgumentError atıyor. | `SessionRepository._guard` gibi `try { await … } catch` kullanın, ya da `.then((_) {}, onError: (Object e) => debugPrint(...))`. |
| QA-6 | Orta (yalnızca Android) | Performans / pil | Ses açıkken her efekt ilk çalındıktan sonra ses eklentisi o oynatıcı için **her karede** konum sorgusu yapmaya ve yeni kare istemeye devam ediyor; uygulama boştayken bile. Android'de bir tur oynadıktan sonra 9 kare geri çağrısı askıda kalıyor (ses kapalı: 0; iOS'ta ses açık: 0). Bu, ekran dursa bile sürekli çizim ve sürekli platform kanalı çağrısı demek (pil ve ısınma). | Android'de ses açıkken bir seviye oynayın, seviye seçiminde bekleyin. Entegrasyon testinde `SOUND=true` ile: "boşta 3 sn: … 9 bekleyen kare geri çağrısı" ve test bitişinde "An animation is still running…" (yığın: `audioplayers FramePositionUpdater._tick`). | [sound_service.dart:66](lib/audio/sound_service.dart#L66): oynatıcılar `PlayerMode.lowLatency` ile çalıyor. Android'de bu mod (SoundPool) "çalma bitti" olayı göndermiyor; audioplayers'ın `FramePositionUpdater`'ı da yalnızca bu olayla duruyor. | Oynatıcıyı oluştururken `p.positionUpdater = null;` (efektler için konum gerekmiyor). Alternatif: `AudioPool` ya da `TimerPositionUpdater`. Düzeltmeden sonra entegrasyon testini `--dart-define=SOUND=true` ile çalıştırıp 0 geri çağrı kaldığını doğrulayın. |
| QA-7 | Orta (tasarım riski) | Açılış / veri kaybı | Açılış işleri (veritabanı + **ses önbelleği** + yüklemeler) 6 sn'yi aşarsa uygulama oturumun tamamını **bellek içi** veritabanıyla sürdürüyor. O oturumda kazanılan yıldızlar, canlar ve programlar uygulama kapanınca kayboluyor; kullanıcıya bir şey söylenmiyor. Yavaş ve eski cihazlarda ilk açılışta tetiklenebilir. | Kod incelemesiyle bulundu; cihazda yeniden üretilemedi (emülatörde yükleme 6 sn'nin çok altında). | [app_services.dart:64](lib/app_services.dart#L64): tüm `load` için tek zaman aşımı var ve `sound.preload()` ([:52](lib/app_services.dart#L52)) de bunun içinde. | Ses önbelleğini zaman aşımının dışına çıkarın (arka planda devam etsin). Zaman aşımında bellek içine geçmek yerine gerçek veritabanını beklemeye devam edin; ya da yalnızca açılış gerçekten hata verirse bellek içine düşün. |
| QA-8 | **Yüksek** (yayın süreci) | Yapılandırma | Sürüm hâlâ `1.0.0+1` (Android versionCode 1). Bu sürüm iki mağazada da yayında; aynı yapı numarasıyla güncelleme Google Play ve App Store Connect tarafından reddedilir. | `pubspec.yaml` ve `aapt dump badging app-release.apk` çıktısı: `versionCode='1' versionName='1.0.0'`. | [pubspec.yaml:19](pubspec.yaml#L19) | Bir sonraki yükleme için örneğin `version: 1.1.0+2`. |
| QA-9 | Düşük | Ekran döndürme | targetSdk 36 (Android 16) ile 600dp üstü ekranlarda (tablet, katlanabilir) uygulamanın dikey kilidi işletim sistemi tarafından yok sayılıyor; uygulama yatay açılabilir. Yatay tablet testinde (1280×800, 48 seviye, iki dil) taşma bulunmadı, ama görünüm yatay için tasarlanmadı. | Android 16 tablette uygulamayı açıp cihazı yatay çevirin. | `targetSdkVersion=36` (Flutter varsayılanı). Kilit yalnızca `SystemChrome` ile yapılıyor ([main.dart](lib/main.dart)). | Gerçek tablette görsel kontrol yapın. Yatay görünüm yeterli değilse yatay için düzeni iyileştirin (Android 16'da kilitle engellemek artık mümkün değil). |
| QA-10 | Düşük | Metin | Ebeveyn panelindeki "Hakkında" metni "İnternet bağlantısı gerekmez" diyor; hemen üstündeki "Uygulamayı değerlendir" ise mağazayı açıyor ve internet istiyor. | Ebeveyn paneli → ayarlar. | [app_tr.arb:104](lib/l10n/app_tr.arb#L104) ve EN karşılığı | Örneğin "Oynamak için internet gerekmez." |
| QA-11 | Düşük | Döngüler (Dünya 2) | Şeritte yalnızca içi boş bir döngü varsa "Çalıştır" hiçbir adım oynatmadan başarısız sayılıyor ve bir can düşüyor. Boş program uyarısı çıkmıyor. | 8–12 Dünya 2: Tekrarla kartını ekleyin, içine kart koymadan Çalıştır'a basın. | [game_controller.dart:654](lib/state/game_controller.dart#L654) `_begin` yalnızca `_program.isEmpty`'ye bakıyor. | `expandProgram(...)` boşsa `emptyProgram` mesajını gösterip çalıştırmayın. |
| QA-12 | Düşük | Bağımlılık | `in_app_review` eski Kotlin Gradle Plugin yöntemini kullanıyor. Flutter release derlemesinde uyarı veriyor; ileriki Flutter sürümlerinde derlemeyi bozabilir. | `flutter build apk --release` çıktısı | Paket tarafı | Paketin yeni sürümlerini takip edin; gerekirse `flutter pub upgrade in_app_review`. |

### Doğrulanan, sorun bulunmayan alanlar

- **Kimlik:**
  - Paket adı `algobot`. Kodda `kod_robotu`, `Kod Robotu`, `Code Robot` ya da `com.example` kalıntısı yok (yalnızca bunu denetleyen testte geçiyor).
  - `applicationId`, `namespace` ve `MainActivity` yolu `com.fabsora.algobot`.
  - iOS `PRODUCT_BUNDLE_IDENTIFIER` üç yapılandırmada da `com.fabsora.algobot`.
  - Görünen ad iki dilde de AlgoBot (`strings.xml`, `values-tr/strings.xml`, `en.lproj` ve `tr.lproj` `InfoPlist.strings`).
- **İkonlar:**
  - Android'de 5 yoğunlukta ikon ve uyarlanabilir ikon (arka plan `#26215C`) var.
  - iOS `AppIcon` 21 dosyanın hepsinde alfa kanalı yok.
- **Açılış ekranı:** Android 12+ (`values-v31`, `android12splash`, gece varyantları) ve eski sürümler yapılandırılmış.
- **Asset'ler:** Kodda kullanılan tüm yollar var ve `pubspec.yaml`'da tanımlı. `assets/media/logo/algobot.png` ve ikon kaynakları pakete girmiyor (yalnızca araçlar kullanıyor).
- **Ekran yönü:** iOS'ta yalnızca dikey ve `UIRequiresFullScreen` açık. Android release manifestinde **INTERNET izni yok** (çocuk uygulaması için olumlu).
- **Simülatör:**
  - Göreli komutlar 4 yönün hepsinde ve mutlak komutlar her başlangıç yönünde doğru.
  - Çarpma, hedef sonrası durma ve tek seferlik toplama doğru.
  - Buz (kayma, kayarken toplama, kayarak portala girme) doğru.
  - Portal (yön korunur, zincirleme ışınlanma yok), anahtar ve kapı doğru.
- **Seviyeler (48):**
  - Haritalar geçerli; BFS ve döngülü çözücü sonuçları `optimalLength` ile eşleşiyor.
  - Referans çözümler 3 yıldız alıyor ve şeride sığıyor.
  - 8–12 ve 13+'da en kısa çözüm tam komut kümesiyle hesaplanıyor.
  - Başlık ve ipucu anahtarları iki ARB'de de var ve boş değil.
- **Canlar ve jokerler:**
  - Başlangıç canı her yaşta 3; 10 dakikada 1 can doluyor, en fazla 3.
  - Saat geri alınınca can verilmiyor.
  - Can jokeri 4'e çıkarabiliyor; eski kayıtlar doğru düzeltiliyor.
  - Çift dokunma tek can veriyor; joker kullanımı kalıcı.
  - Durdur, Temizle ve başarılı bitiş can düşürmüyor.
  - Tur Atla ve video kuralları doğru.
- **Veritabanı:**
  - Tablolar oluşuyor; okuma ve yazma çalışıyor.
  - Göç bir kez çalışıyor ve veri çoğaltmıyor. Göç yarıda kalırsa eski yıldızlar silinmiyor, sonraki açılışta yeniden deneniyor.
  - Bozuk dosya ve kapalı veritabanında oturum yazmaları çökmüyor (ilerleme yazması için QA-5'e bakın).
- **Akışlar:**
  - İlk açılış (yaş → arkadaş → seviye seçimi) çalışıyor; geri tuşu açılış ekranına dönmüyor.
  - Sonraki açılış doğrudan ana menüye gidiyor.
  - Üç yaş grubunda Seviye 1 baştan sona oynanıyor (cihazda).
  - Kalıcılık, uygulama yeniden başlatılarak cihazda doğrulandı: can, program ve yıldızlar korunuyor.
  - Kilitli seviye açılmıyor; canlar bitince "Ana menü"den oyuna geri dönülemiyor.
  - Ebeveyn kapısı doğru çalışıyor: yanlış cevap reddediliyor, yaş değişimi diğer yaşın ilerlemesini silmiyor, Vazgeç bir şey silmiyor, ses ayarı kalıcı.
  - Dil seçimi doğru: tr → Türkçe; en, de, ar → İngilizce. Hiçbir ekranda ARB anahtarı görünmüyor.
  - Ses kapalıyken hiç ses çalmıyor.
  - Hızlı mod adımları yarı sürede oynatıyor.
  - "Çalıştır" ve "Devam"a çift dokunma tek işlem yapıyor.
  - Çalışırken arka plana alıp dönmek ya da geri tuşuna basmak çökme yapmıyor.
- **Taşma:**
  - QA-4 dışında tüm ekran ve panellerde iki dilde, 360×640 ve 800×1280'de, 1.0x ve 1.3x yazıda taşma yok.
  - Yatay 1280×800'de de taşma yok.
- **Erişilebilirlik:**
  - Ana menü, seviye seçimi, oyun ekranı (3 yaş), ebeveyn paneli ve karakter seçimi iki dilde kılavuzları geçiyor: Android 48dp, iOS 44pt, etiketli dokunma hedefleri ve metin kontrastı.
  - Logo, kartlar ve jokerlerin anlamsal etiketi var.
  - "Komutlar" yalnızca ekran okuyucu etiketi (`paletteSemanticsLabel`) olarak var; ekranda görünmüyor.

## Test edilemeyenler

- **Profil modu ve kare düşmesi:**
  - Fiziksel Android cihaz yok; emülatörde profil modu desteklenmiyor. Uzun programlarda (16+ kart) akıcılık ölçülemedi.
  - QA-6'nın gerçek pil ve kare etkisi de ölçülemedi: test ortamı canlı kare üretmiyor ve `gfxinfo` Flutter yüzeyini saymıyor. Kanıt olarak askıda kalan kare geri çağrıları gösterildi.
- **Android'de Türkçe cihaz dili:** Emülatör Play Store imajı, dil komutla değiştirilemiyor (root yok). Türkçe akış iOS simülatöründe ve widget testlerinde doğrulandı.
- **Gerçek mağaza değerlendirme penceresi:** Simülatör ve geliştirme sürümünde görünmüyor. Mantığı sahte platformla test edildi; TestFlight veya Play iç test kanalında kontrol edilmeli.
- **Gerçek tablette yatay görünüm (QA-9):** Yalnızca widget testinde 1280×800 ile denendi.
- **Reklam:** Reklam SDK'sı yok. Yalnızca stub'ın release'de kapalı olduğu (`available: false`) doğrulandı.
- **QA-7'nin cihazda yeniden üretilmesi:** Yükleme süresi emülatörde 6 sn'nin çok altında kaldı.

## Eklenen testler (projede kalıyor)

| Dosya | Test sayısı | İçerik |
|---|---|---|
| [test/qa/qa_harness.dart](test/qa/qa_harness.dart) | — | Ortak kurulum: gerçek uygulama, bellek içi veritabanı, sahte saat, ses, video ve mağaza değerlendirmesi |
| [test/qa/logic_qa_test.dart](test/qa/logic_qa_test.dart) | 52 | Simülatör kenar durumları, 48 seviye kontrolü, yıldız/can/joker kuralları, ilerleme, veritabanı sağlamlığı, karakter eşikleri |
| [test/qa/flows_qa_test.dart](test/qa/flows_qa_test.dart) | 21 | Çift dokunma, Durdur, Temizle, Kaybet, Hızlı mod, canlar bitince, kilitler, ebeveyn kapısı, ses, dil, arka plana alma |
| [test/qa/screens_qa_test.dart](test/qa/screens_qa_test.dart) | 41 | Tüm ekran ve panellerde taşma + anahtar sızıntısı (2 dil × 2 boyut × 2 yazı ölçeği), yatay tablet (48 seviye), erişilebilirlik kılavuzları |
| [test/qa/regression_qa_test.dart](test/qa/regression_qa_test.dart) | 10 | Gerileme testleri: QA-1, QA-2, QA-3, QA-4 (tr/en), QA-5, QA-7, QA-9, QA-10, QA-11 (ilk taramada `known_bugs_qa_test.dart` adıyla 6 test, kırmızıydı) |
| [integration_test/qa_flows_test.dart](integration_test/qa_flows_test.dart) | 1 (2 aşama) | Cihazda temiz kurulum → karşılama → oyna/kazan (3 yaş) → can kaybı ve kart → ebeveyn paneli; 2. aşamada yeniden açılışta kalıcılık. İsteğe bağlı `--dart-define=SOUND=true` QA-6'yı gösterir. |

Toplam **125 yeni test** (düzeltmelerle eklenen 4 dahil). Projedeki toplam test sayısı 532.

Çalıştırma:

```sh
flutter test                       # tümü
flutter test test/qa               # yalnızca QA
flutter drive --driver test_driver/integration_test.dart \
  --target integration_test/qa_flows_test.dart -d <cihaz> \
  --dart-define=PHASE=1 --keep-app-running
# ardından aynı komut --dart-define=PHASE=2 ile
```

Not: Aşama 1, cihazdaki uygulamanın ayarlarını ve veritabanını temizler (temiz kurulum benzetimi).

## Sonraki adım önerisi

1. **QA-8 sürüm numarası:** Mağazaya yüklemeden önce şart, tek satır.
2. **QA-1 (+QA-2) atlama sırasında kilit:** Kullanıcının karşılaşabileceği en görünür hata; düzeltmesi küçük (`isLocked`).
3. **QA-6 Android ses eklentisi:** Pil ve performans; tek satır (`positionUpdater = null`).
4. **QA-5 ilerleme hata yakalayıcı** ve **QA-4 geri sayım taşması:** Küçük, düşük riskli düzeltmeler.
5. **QA-7 açılış zaman aşımı:** Biraz daha tasarım gerektiriyor; sessiz veri kaybını önler.
6. **QA-3, QA-11, QA-10:** Düşük öncelikli davranış ve metin iyileştirmeleri.
7. **QA-9 ve QA-12:** Gerçek bir Android 16 tablette yatay görünüm kontrolü; `in_app_review` güncellemesini takip.

Her düzeltmeden sonra `flutter test` çalıştırılmalı. `known_bugs_qa_test.dart` içindeki ilgili test yeşile dönmeli.
