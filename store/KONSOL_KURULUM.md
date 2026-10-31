# AlgoBot: Google Play Games ve Game Center kurulumu

Bu rehber, Güncelleme 7'deki başarımların ve skor tablosunun Play Console ile App Store Connect'te nasıl oluşturulacağını anlatır. Kod tarafı hazır. Eksik olan yalnızca konsollarda oluşturulacak kayıtlar ve onlardan alınacak kimlikler.

**Hazır dosyalar:**

| Dosya | İçerik |
|---|---|
| `store/achievements.csv` | 17 başarımın listesi: TR/EN ad ve açıklama, tür, adım sayısı, puan (toplam 760), sıra, önerilen iOS kimliği |
| `store/badges/*.png` | 512×512 rozetler (Play Games ve Game Center) |
| `store/badges_1024/*.png` | 1024×1024 rozetler (Game Center) |
| `store/badges/leaderboard_total_stars.png` | Skor tablosu simgesi (1024 sürümü `badges_1024/` içinde) |

Metinleri değiştirirseniz, önce `lib/l10n/app_tr.arb` ve `app_en.arb` dosyalarında değiştirin. Ardından CSV'yi ve rozetleri yeniden üretin:

```
flutter test tool/export_achievements_csv.dart
flutter test tool/export_badges.dart
```

> Kimlikler doldurulmadan da uygulama yayınlanabilir. Yer tutucu duran başarım ve skorlar platforma gönderilmez, yalnızca uygulama içinde görünür. Gönderilmeyen kayıtlar bekletilir ve kimlikler eklendikten sonraki ilk sürümde otomatik gönderilir.

---

## 1. Google Play Console (Play Games Services v2)

### 1.1 Play Games Services projesini oluşturma

1. Play Console'da **AlgoBot**'u açın. **Büyüme** (Grow) bölümünde **Play Games Services → Kurulum ve yönetim → Yapılandırma**'ya gidin.
   - Bu menü yalnızca uygulama türü **Oyun** olan uygulamalarda görünür. AlgoBot "Uygulama" olarak sınıflandırılmışsa önce **Ana mağaza girişi → Uygulama kategorisi** ayarını kontrol edin.
2. "Oyununuz zaten Google API'leri kullanıyor mu?" sorusuna **Hayır** deyin. Oyun adını **AlgoBot** yazıp oluşturun.
3. Açılan sayfadaki **Proje kimliği**ni (yalnızca rakamlardan oluşan uzun sayı) kopyalayın. Bu kimlik 1.6. adımda kullanılacak.

### 1.2 OAuth izin ekranı ve kimlik bilgileri (SHA-1)

Play Games, uygulamanın imza sertifikasını tanımak için **SHA-1 parmak izi** ister. Her imza anahtarı için ayrı bir Android kimlik bilgisi gerekir.

1. **Yapılandırma → Kimlik bilgileri → Kimlik bilgisi ekle → Android** seçin.
2. Google Cloud'da **OAuth izin ekranı** isteniyorsa bağlantıdan açın:
   - Tür: Harici (External).
   - Uygulama adı: AlgoBot.
   - Destek e-postası: kendi adresiniz.
   - Kaydedip yayınlayın. Ek kapsam (scope) eklemeyin.
3. Android kimlik bilgisini oluşturun:
   - Paket adı: `com.fabsora.algobot`.
   - Google Cloud'da bir **OAuth istemcisi (Android)** oluşturun: aynı paket adı ve aşağıdaki SHA-1 ile.
   - Play Console'a dönüp bu istemciyi seçin.
4. SHA-1 değerlerinin nereden alınacağı:

| Anahtar | Nerede | Neden gerekli |
|---|---|---|
| **Play uygulama imzalama anahtarı** | Play Console → **Test ve yayınlama → Kurulum → Uygulama bütünlüğü (App integrity) → Uygulama imzalama** → "Uygulama imzalama anahtarı sertifikası" → SHA-1 | Mağazadan indirilen sürüm bu anahtarla imzalanır. **Zorunlu.** |
| **Yükleme anahtarı** | Aynı sayfada "Yükleme anahtarı sertifikası" → SHA-1. Ya da yerelde `keytool -list -v -keystore <keystore dosyası> -alias <alias>` | Kendi derlediğiniz release sürümü (`./release.sh` öncesi denemeler) |
| **Debug anahtarı** (isteğe bağlı) | `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android` | `flutter run` ile emülatörde ve cihazda deneme |

Keystore şifreleri `android/key.properties` dosyasındadır. Bu dosyayı kimseyle paylaşmayın ve git'e eklemeyin. Her SHA-1 için 3. adımı tekrarlayın: ayrı OAuth istemcisi, ayrı kimlik bilgisi.

### 1.3 Başarımları oluşturma

**Play Games Services → Başarımlar → Başarım oluştur.** `store/achievements.csv` dosyasındaki her satır için:

| Alan | CSV sütunu / değer |
|---|---|
| Ad | `ad_en` (varsayılan dil İngilizceyse). Çeviri olarak `ad_tr` ekleyin. |
| Açıklama | `aciklama_en` / `aciklama_tr` |
| Simge | `store/badges/<anahtar>.png` (512×512) |
| Artımlı başarım | `tur` = **artan** ise açın. **Adım sayısı** = `hedef_adim` |
| Başlangıç durumu | **Gösterilen** (Revealed). Hiçbiri gizli değil. |
| Puan | `puan` |
| Liste sırası | `sira` |

Kaydettikten sonra her başarımın **kimliğini** (`CgkI...` ile başlar) kopyalayın.

Kolaylık için başarımlar listesindeki **Kaynakları al** (Get resources) düğmesi tüm kimlikleri tek bir XML olarak verir. Oradan kopyalayabilirsiniz.

### 1.4 Skor tablosunu oluşturma

**Play Games Services → Skor tabloları → Skor tablosu oluştur:**

- Ad: **Total Stars**, Türkçe çeviri: **Toplam Yıldız**.
- Skor biçimi: Sayısal, 0 ondalık.
- Sıralama: **Büyük skor daha iyi**.
- Simge: `store/badges/leaderboard_total_stars.png`.
- Sınırlar: en düşük **0**, en yüksek **144** (hileli skorları engeller).

Kimliği (`CgkI...`) kopyalayın.

### 1.5 Test kullanıcıları

**Play Games Services → Test kullanıcıları** bölümüne denemede kullanacağınız Google hesaplarını ekleyin. Yapılandırma yayınlanana kadar yalnızca bu hesaplar oturum açabilir.

### 1.6 Kimlikleri koda yazma

| Ne | Dosya ve satır |
|---|---|
| Proje kimliği (rakamlar) | `android/app/src/main/res/values/games-ids.xml` satır 10: `REPLACE_WITH_PLAY_GAMES_PROJECT_ID` |
| Başarım kimlikleri | `lib/games/game_ids.dart`: her başarımın `android:` satırı (`REPLACE_ANDROID_...`) |
| Skor tablosu kimliği | `lib/games/game_ids.dart` satır 90: `REPLACE_ANDROID_LB_TOTAL_STARS` |

### 1.7 Yapılandırmayı yayınlama

**Play Games Services → Yayınlama** bölümüne gidin. Eksik varsa Play Console listeler; çoğu zaman eksik bir simge ya da çevirisi olmayan bir metin olur. Eksikleri giderip yapılandırmayı **yayınlayın**. Yayından sonra herkes oturum açabilir.

---

## 2. App Store Connect (Game Center)

### 2.1 Game Center'ı etkinleştirme

1. **Apple Developer → Certificates, Identifiers & Profiles → Identifiers → com.fabsora.algobot** sayfasında **Game Center**'ın işaretli olduğunu kontrol edin. Varsayılan olarak açıktır.
2. App Store Connect'te AlgoBot'u açın ve sol menüden **Game Center**'a girin. Apple bu menünün yerini zaman zaman değiştiriyor; bulamazsanız uygulama sayfasındaki "Hizmetler" ya da "Özellikler" bölümlerine bakın.
3. Etkinleştirirken **"Tek oyun"** seçin. Oyun grubu (Game Center group) gerekmez.

### 2.2 Başarımları oluşturma

Game Center → Başarımlar → **+**. CSV'deki her satır için:

| Alan | Değer |
|---|---|
| Referans adı | `anahtar` (ör. `first_level`) |
| Başarım kimliği | `ios_kimlik_onerilen` (ör. `com.fabsora.algobot.ach.first_level`) |
| Puan | `puan` |
| Gizli | Hayır |
| Birden fazla kez kazanılabilir | Hayır |
| Yerelleştirme: İngilizce ve Türkçe | Başlık: `ad_en` / `ad_tr`. Kazanmadan önceki açıklama: `aciklama_en` / `aciklama_tr`. Kazandıktan sonraki açıklama: aynı metin. Görsel: `store/badges_1024/<anahtar>.png` |

Game Center'da "artan" diye ayrı bir tür yoktur. Uygulama ilerlemeyi yüzde olarak gönderir; örneğin 9/12 yıldız %75 olarak gider.

### 2.3 Skor tablosunu oluşturma

Game Center → Skor tabloları → **+ → Klasik skor tablosu:**

- Referans adı: `total_stars`.
- Kimlik: `com.fabsora.algobot.lb.total_stars`.
- Skor biçimi: **Tamsayı**.
- Skor gönderim türü: **En iyi skor**.
- Sıralama: **Yüksekten düşüğe**.
- Skor aralığı: **0–144**.
- Yerelleştirme:
  - Ad: **Total Stars** / **Toplam Yıldız**.
  - Görsel: `store/badges_1024/leaderboard_total_stars.png`.

### 2.4 Sürüme ekleme (önemli)

İlk kez Game Center içeren sürümü incelemeye göndermeden önce şunları yapın:

1. **Dağıtım → sürüm sayfası → Game Center** bölümünü açın.
2. Oluşturduğunuz **başarımları ve skor tablosunu sürüme ekleyin**.

Eklenmeyen kayıtlar canlı sürümde çalışmaz.

### 2.5 Kimlikleri koda yazma

| Ne | Dosya ve satır |
|---|---|
| Başarım kimlikleri | `lib/games/game_ids.dart`: her başarımın `ios:` satırı (`REPLACE_IOS_...`). Önerilen biçim: `com.fabsora.algobot.ach.<anahtar>` |
| Skor tablosu kimliği | `lib/games/game_ids.dart` satır 91: `REPLACE_IOS_LB_TOTAL_STARS` → `com.fabsora.algobot.lb.total_stars` |

### 2.6 Xcode'da doğrulama

1. `open ios/Runner.xcworkspace` ile projeyi açın.
2. **Runner** hedefinde **Signing & Capabilities** sekmesine gidin.
3. Şunları kontrol edin:
   - **Game Center** yeteneği listede görünüyor.
   - Team: **2VFY4PNMAG**.
   - "Automatically manage signing" açık ve hata yok.

Entitlements dosyası: `ios/Runner/Runner.entitlements` (`com.apple.developer.game-center = true`).

Test için cihazda **Ayarlar → Game Center** ile oturum açın; geliştirme ve TestFlight derlemeleri Game Center'ın test ortamını kullanır. Uygulama Game Center giriş ekranını **yalnızca bir kez** otomatik dener. Ekran kapatılırsa bir daha otomatik denemez. Yeniden denemek için **ebeveyn paneli → Oyun hesabı → "Game Center'a bağlan"** butonunu kullanın. iOS ekranı yine göstermezse **Ayarlar → Game Center**'dan giriş yapıp uygulamayı yeniden açın.

---

## 3. Gizlilik ve mağaza hatırlatmaları

- [ ] **Gizlilik politikası:** isteğe bağlı Google Play Games Services (Android) ve Game Center (iOS) kullanımını ekleyin. Şunları belirtin:
  - Başarım ve toplam yıldız skoru oyuncunun Google/Apple hesabına gönderilir.
  - Uygulama oyuncunun adını, avatarını ya da oyuncu kimliğini göstermez ve saklamaz.
  - Platform hesabı olmadan oyun tamamen oynanabilir.
- [ ] **Play Console → Uygulama içeriği → Veri güvenliği** formunu Play Games Services'e göre güncelleyin. Google'ın Play Games Services için yayımladığı veri güvenliği açıklamalarını esas alın; oyuncu kimliği, başarımlar ve skorlar Google'a gönderilir.
- [ ] **Families (Aileler) politikası:** AlgoBot'un hedef kitlesinde çocuklar var. Yayından önce Play Games Services'in bu uygulamada Families politikası kapsamında kullanılabildiğini Play Console'da doğrulayın. Kontrol edilecek yerler:
  - Uygulama içeriği → Hedef kitle ve içerik.
  - Politika durumu ve uyarılar.
  
  Sorun çıkarsa servisi kodda tek satırla kapatın (bölüm 4). Uygulama içi başarımlar çalışmaya devam eder.
- [ ] **App Store gizlilik etiketi:** Game Center verilerini Apple toplar. Uygulamanın kendisi veri toplamaz. Yine de "App Privacy" yanıtlarını gözden geçirin.
- [ ] **Şifreleme sorusu:** değişmedi. Game Center işletim sisteminin bir parçası olduğu için cevap yine **"None of the algorithms mentioned above"**.
- [ ] **Çocuk güvenliği:** platformun kendi başarım ve skor ekranları, yani diğer oyuncuların takma adları, uygulamada yalnızca ebeveyn kapısından sonra açılır. Oturum açma hiçbir ekranda zorlanmaz.

---

## 4. Servisi açma ve kapatma

`lib/games/game_config.dart`:

```dart
const bool kGamePlatformEnabled = true; // ikisini birden kapatır
const bool kPlayGamesEnabled = true;    // yalnızca Android
const bool kGameCenterEnabled = true;   // yalnızca iOS
```

`false` yapıp yeni sürüm yayınladığınızda hiçbir platform çağrısı yapılmaz ve platform butonları gizlenir. Uygulama içi başarımlar ekranı çalışmaya devam eder.

Android'de Play Games kütüphanesi uygulamada kalır. Servisi tamamen çıkarmak için ayrıca şunlar gerekir:

- `pubspec.yaml` dosyasından `games_services` paketini kaldırmak.
- `AndroidManifest.xml` dosyasındaki `com.google.android.gms.games.APP_ID` satırını silmek.
