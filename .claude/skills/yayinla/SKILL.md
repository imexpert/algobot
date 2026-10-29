---
name: yayinla
description: /release komutunun Türkçe kısayolu. /yayinla (tam yayın), /yayinla kontrol (yalnızca kontrol), /yayinla notlar (yalnızca sürüm notları).
argument-hint: "[kontrol | notlar]"
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(./release.sh --check), Bash(ruby scripts/check_build_number.rb:*), Bash(ruby scripts/check_android_store.rb), Bash(ruby scripts/check_ios_store.rb)
---

# /yayinla — /release kısayolu

Bu komut, `/release` ile birebir aynı süreci çalıştırır. Önce `.claude/skills/release/SKILL.md` dosyasını oku, ardından oradaki talimatların ve kuralların **tamamını** uygula. Burada ayrı bir süreç tanımlanmaz.

Argümanı şu moda çevir:

| `/yayinla` argümanı | `/release` modu |
|---|---|
| (boş) | tam yayın |
| `kontrol` (ya da `check`) | `check` — yalnızca kontrol |
| `notlar` (ya da `notes`) | `notes` — yalnızca sürüm notları |

Verilen argüman: `$ARGUMENTS`. Tanınmayan bir argüman gelirse işlem yapmadan bu üç seçeneği göster.
