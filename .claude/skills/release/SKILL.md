---
name: release
description: AlgoBot sürüm yayınlama asistanı. Sürüm artırma, TR/EN sürüm notları, mağaza kontrolleri ve Google Play / App Store Connect yüklemesini adım adım ve onayla yönetir. Kullanım /release, /release check (yalnızca kontrol), /release notes (yalnızca sürüm notları).
argument-hint: "[check | notes]"
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(./release.sh --check), Bash(ruby scripts/check_build_number.rb:*), Bash(ruby scripts/check_android_store.rb), Bash(ruby scripts/check_ios_store.rb)
---

# AlgoBot sürüm yayınlama

Mod: `$ARGUMENTS` (boş = tam yayın, `check` = yalnızca kontrol, `notes` = yalnızca sürüm notları).

Kullanıcı Türkçe konuşur. **Her mesajda en fazla bir komut ya da tek bir işlem** öner, sonucunu bekle, sonra devam et. Her komut için ne yaptığını açıkça etiketle:

- 🔍 **Yalnızca okur**: dosya ya da mağaza değiştirmez.
- ✏️ **Dosya değiştirir**: yerel dosyalar (pubspec, sürüm notları).
- 🚀 **Mağazaya yükler**: Google Play / App Store Connect.

## Değişmez kurallar

1. Kullanıcı onayı olmadan sürüm numarasını değiştirme, mağazaya yükleme yapma, Production yayını başlatma.
2. Mevcut bir sürümü tekrar yükleme. `EXISTS` olan platform her zaman atlanır.
3. Mağaza sorgusu `ERROR` verirse ya da JSON okunamazsa **dur**. Bunu asla `AVAILABLE` sayma.
4. Gizli bilgileri gösterme ya da okuma: `ios/fastlane/.env`, `android/key.properties`, `~/.config/fastlane/**`, `*.p8`, `*.json` anahtarlar, keystore. Yalnızca var olup olmadıklarını kontrol edebilirsin.
5. Çalışan Fastlane altyapısını değiştirme; mevcut betikleri kullan.
6. Hata olursa hangi aşamada durduğunu açıkça söyle. Bir platform başarılıysa onu yeniden yükleme.
7. Kullanıcı açıkça istemedikçe git commit ya da push yapma.
8. Sürüm notlarında doğrulanmamış değişiklik yazma: git geçmişi ve koddan doğrula, kullanıcıya sor.
9. Kuru çalıştırma (`check`) modunda hiçbir sürüm artırma, derleme ya da yükleme yapma.

## Altyapı (kısa başvuru)

| Parça | Ne yapar |
|---|---|
| `pubspec.yaml` `version:` | İki platformun ortak sürümü (`X.Y.Z+BUILD`) |
| `bash scripts/bump_version.sh <1\|2\|3> [BUILD]` ✏️ | 1 Patch, 2 Minor, 3 Major. İsteğe bağlı BUILD, mevcut build'den büyük olmalı |
| `ruby scripts/check_build_number.rb [BUILD]` 🔍 | İki mağazadaki en yüksek build'i okur. JSON: `OK` / `TOO_LOW` (`next_build` önerir) / `ERROR`. Çıkış kodu 0 / 2 / 1 |
| `ruby scripts/check_android_store.rb`, `ruby scripts/check_ios_store.rb` 🔍 | Bu tam sürüm mağazada var mı: `EXISTS` / `AVAILABLE` / `ERROR` |
| `./release.sh --check` 🔍 | Araçlar, sürüm notları (Fastlane `check_release`) ve iki mağaza durumu. Derleme ya da yükleme yok |
| `./release.sh` 🚀 | Kontroller, sonra her platform için `[y/N]` onayı; derler ve yükler. Fastlane yükleme öncesi bir kez daha onay ister |
| `release-notes/<VERSION>/` | `tr-TR.txt`, `en-US.txt` (≤ 500 karakter, Android sınırı; iOS 4000), `promotional-tr-TR.txt`, `promotional-en-US.txt` (≤ 170, App Store) |

- **Android:** AAB → Google Play **Production**, `release_status: completed`. Google incelemesinden sonra **kullanıcılara canlı çıkar**.
- **iOS:** IPA → App Store Connect, `submit_for_review: false`, `automatic_release: false`. İncelemeye gönderme ayrı ve elle yapılır.
- `./release.sh` etkileşimli onaylar ister (`read`, Fastlane `UI.confirm`). Bu onaylar Claude'un kabuğunda verilemez, Fastlane etkileşimsiz modda soruyu reddeder. Bu yüzden **🚀 adımını kullanıcı kendi terminalinde çalıştırır**; sen yalnızca komutu verir, çıktıyı yorumlarsın.

## Aşama A — Ön kontrol 🔍

1. Proje kökünde olduğunu doğrula (`pubspec.yaml` içinde `name: algobot`).
2. `git status --short` çalıştır. Commit edilmemiş değişiklik varsa kullanıcıya göster ve sor: yayına girmeli mi, önce commit mi edilmeli? Commit'i kendin yapma.
3. Mevcut sürümü `pubspec.yaml`'dan oku.
4. Son yayından bu yana değişiklikler: sürüm satırını en son değiştiren commit'i bul (`git log --oneline -S"version: <MEVCUT>" -- pubspec.yaml`), sonra `git log --oneline <o commit>..HEAD` ve gerekirse `git diff --stat <o commit>..HEAD -- lib`.
5. Gizli dosyaları **içeriğini okumadan** kontrol et: `test -f ios/fastlane/.env`, `test -f android/key.properties`. Eksikse dur.

`check` modunda: Aşama A'dan sonra doğrudan Aşama D'ye geç (`./release.sh --check` ve `ruby scripts/check_build_number.rb`), raporla ve bitir.

## Aşama B — Sürüm seçimi ✏️ (onayla)

1. `ruby scripts/check_build_number.rb <mevcut build + 1>` 🔍 ile önerilen build'i doğrula. `TOO_LOW` ise `next_build` kullan, `ERROR` ise dur.
2. Patch / Minor / Major seçeneklerini mevcut ve önerilen sürümle birlikte göster (AskUserQuestion), örneğin `1.1.4+6` → Patch `1.1.5+7`. Değişikliklere göre bir öneri yap: yalnızca hata düzeltmesiyse Patch, yeni özellikse Minor.
3. Onaydan sonra tek komut: `bash scripts/bump_version.sh <1|2|3> <BUILD>` ✏️. Sonra `pubspec.yaml`'ı oku ve doğrula.

## Aşama C — Sürüm notları ✏️ (onayla)

1. Aşama A'daki değişikliklerden yalnızca **kullanıcıya görünen** ve **doğrulanmış** olanları listele. Kullanıcıya eksik ya da yanlış bir şey olup olmadığını sor.
2. Dört dosyanın taslağını göster (her birinin karakter sayısıyla):
   - `tr-TR.txt` ve `en-US.txt`: kısa, sade, çocuk uygulaması için ebeveyne yönelik; **≤ 500 karakter**.
   - `promotional-tr-TR.txt` ve `promotional-en-US.txt`: önceki sürüm klasöründeki metni oku; değişiklik gerekmiyorsa aynen kopyala; **≤ 170 karakter**.
3. Onaydan sonra `release-notes/<YENİ_SÜRÜM>/` klasörüne UTF-8 olarak yaz. Boş dosya bırakma. Karakter sayısını `ruby -e 'puts File.read(ARGV[0], encoding: "UTF-8").strip.length' <dosya>` ile doğrula.

`notes` modunda: sürümü artırma. Mevcut `pubspec.yaml` sürümü için Aşama C'yi yap ve bitir. Klasör zaten doluysa üzerine yazmadan önce sor.

## Aşama D — Yayın öncesi kontrol 🔍

1. `git status --short` ile değişiklikleri (pubspec ve sürüm notları) göster.
2. `./release.sh --check` çalıştır. Çıktıdan Android ve iOS durumlarını oku.
   - Herhangi bir `ERROR` ya da betik hatası: **dur**, hangi platform ve hangi mesaj olduğunu söyle.
   - İkisi de `EXISTS`: yüklenecek bir şey yok. Bildir ve bitir.
3. `ruby scripts/check_build_number.rb` 🔍 → `OK` olmalı. `TOO_LOW` ise dur ve yeni build numarası öner (Aşama B'ye dön).
4. Hangi platformların derlenip yükleneceğini tablo hâlinde göster.

## Aşama E — Yayınlama 🚀 (kullanıcı çalıştırır)

1. Uyar: Android doğrudan **Production**'a gider ve incelemeden sonra kullanıcılara çıkar. iOS yalnızca App Store Connect'e yüklenir.
2. Açık onay al (AskUserQuestion: "Yayına başla" / "Vazgeç").
3. Kullanıcıya **tek komut** ver ve kendi terminalinde çalıştırmasını iste:
   ```
   ./release.sh
   ```
   Betik her platform için `[y/N]` sorar; Fastlane yüklemeden önce bir kez daha sorar. Yalnızca yayınlamak istedikleri platform için `y` yazsınlar.
4. Kullanıcıdan çıktının son kısmını yapıştırmasını iste. Android ve iOS sonuçlarını ayrı ayrı değerlendir.
   - Bir platform başarısızsa: hata mesajını açıkla. Derleme bittiyse yeniden derlemeden yalnızca yüklemeyi tekrarlamak için tek komut öner (`cd android && bundle exec fastlane android retry_release` ya da `cd ios && bundle exec fastlane ios retry_release`). Başarılı platformu tekrar yükleme; tekrar `./release.sh` çalıştırılırsa o platform zaten `EXISTS` olarak atlanır.

## Aşama F — Sonuç raporu

Türkçe, kısa bir tablo:

| | Derleme | Yükleme |
|---|---|---|
| Android | ✅ / ❌ / atlandı | ✅ / ❌ / atlandı |
| iOS | … | … |

Ardından:
- Yayınlanan sürüm numarası; atlanan platformlar ve nedenleri; hata varsa nedeni ve durulan aşama.
- **Google Play Console:** Production sürümünün inceleme durumunu "Yayın genel bakışı"ndan izle. Gerekirse kademeli yayını yönet.
- **App Store Connect:** derlemenin işlenmesini bekle (10–30 dk), sürüme derlemeyi seç, gerekirse Export Compliance'ı yanıtla, "İncelemeye Gönder"e bas. Otomatik yayın kapalı; onaydan sonra elle yayınla.
- **Git:** `git status --short` çıktısı. `pubspec.yaml` ve `release-notes/<SÜRÜM>/` commit edilmedi; commit'i kullanıcı ister ya da kendisi yapar.
