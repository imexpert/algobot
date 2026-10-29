
#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

ANDROID_DIR="$ROOT_DIR/android"
IOS_DIR="$ROOT_DIR/ios"

VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1)"
NOTES_DIR="$ROOT_DIR/release-notes/$VERSION"

ANDROID_AAB="$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab"
IOS_IPA="$ROOT_DIR/build/ios/ipa/AlgoBot.ipa"

log() {
  printf '\n=== %s ===\n' "$1"
}

fail() {
  printf '\nERROR: %s\n' "$1" >&2
  exit 1
}

confirm() {
  local answer
  read -r -p "$1 [y/N]: " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

check_requirements() {
  log "Checking AlgoBot release requirements"

  command -v flutter >/dev/null || fail "Flutter not found"
  command -v bundle >/dev/null || fail "Bundler not found"
  command -v ruby >/dev/null || fail "Ruby not found"

  [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]] ||
    fail "Invalid version: $VERSION"

  local file

  for file in \
    "tr-TR.txt" \
    "en-US.txt" \
    "promotional-tr-TR.txt" \
    "promotional-en-US.txt"
  do
    [[ -s "$NOTES_DIR/$file" ]] ||
      fail "Missing or empty release file: $NOTES_DIR/$file"
  done

  [[ -f "$ROOT_DIR/scripts/check_android_store.rb" ]] ||
    fail "Android store check script not found"

  [[ -f "$ROOT_DIR/scripts/check_ios_store.rb" ]] ||
    fail "iOS store check script not found"

  (cd "$ANDROID_DIR" && bundle exec fastlane android check_release)
  (cd "$IOS_DIR" && bundle exec fastlane ios check_release)

  log "Release metadata validation completed"
}

read_store_status() {
  local platform="$1"
  local script="$ROOT_DIR/scripts/check_${platform}_store.rb"
  local result
  local status

  if ! result="$(ruby "$script")"; then
    fail "$platform store query failed. Release blocked."
  fi

  status="$(
    printf '%s' "$result" |
      ruby -rjson -e '
        data = JSON.parse(STDIN.read)
        expected_platform = ARGV.fetch(0)
        expected_version = ARGV.fetch(1)

        unless data["platform"] == expected_platform &&
               data["version"] == expected_version &&
               %w[EXISTS AVAILABLE].include?(data["status"])
          abort "Invalid store status response"
        end

        puts data["status"]
      ' "$platform" "$VERSION"
  )" || fail "$platform store status could not be validated"

  printf '%s' "$status"
}

build_android() {
  log "Building Android AAB"

  (cd "$ANDROID_DIR" && bundle exec fastlane android build)

  [[ -f "$ANDROID_AAB" ]] ||
    fail "Android AAB not found"
}

build_ios() {
  log "Building iOS IPA"

  (cd "$IOS_DIR" && bundle exec fastlane ios build)

  [[ -f "$IOS_IPA" ]] ||
    fail "iOS IPA not found"
}

upload_android() {
  log "Uploading Android to Google Play Production"
  (cd "$ANDROID_DIR" && bundle exec fastlane android upload)
}

upload_ios() {
  log "Uploading iOS to App Store Connect"
  (cd "$IOS_DIR" && bundle exec fastlane ios upload)
}

usage() {
  cat <<'USAGE'
Usage: ./release.sh [--check]

  (no option)  Validate, query stores, then build and upload after
               per-platform confirmation.
  --check      Dry run: validate requirements, release notes and store
               status only. Never bumps, builds or uploads.
USAGE
}

main() {
  local check_only=false

  case "${1:-}" in
    "") ;;
    --check|--dry-run) check_only=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage; fail "Unknown option: $1" ;;
  esac

  log "AlgoBot Unified Release"
  printf 'Shared version: %s\n' "$VERSION"
  if [[ "$check_only" == true ]]; then
    printf 'Mode: CHECK ONLY (no build, no upload)\n'
  fi

  check_requirements

  log "Checking existing store versions"

  local android_status
  local ios_status

  android_status="$(read_store_status android)"
  ios_status="$(read_store_status ios)"

  printf '\nStore status:\n'
  printf '  Android: %s\n' "$android_status"
  printf '  iOS:     %s\n' "$ios_status"

  if [[ "$android_status" == "EXISTS" &&
        "$ios_status" == "EXISTS" ]]; then
    log "Version already exists on both stores"
    printf 'No builds or uploads are necessary.\n'
    exit 0
  fi

  if [[ "$check_only" == true ]]; then
    printf '\nWould release:\n'
    [[ "$android_status" == "AVAILABLE" ]] &&
      printf '  Android: build + upload to Google Play Production\n'
    [[ "$ios_status" == "AVAILABLE" ]] &&
      printf '  iOS: build + upload to App Store Connect\n'
    log "Check completed — nothing was built or uploaded"
    exit 0
  fi

  printf '\nRelease targets:\n'
  printf '  Android: Google Play Production\n'
  printf '  iOS: App Store Connect\n'

  if [[ "$android_status" == "EXISTS" ]]; then
    log "Android already exists on Google Play — skipping"
  else
    if confirm "Build and upload Android version $VERSION?"; then
      build_android
      upload_android
    else
      log "Android release skipped"
    fi
  fi

  if [[ "$ios_status" == "EXISTS" ]]; then
    log "iOS already exists on App Store Connect — skipping"
  else
    if confirm "Build and upload iOS version $VERSION?"; then
      build_ios
      upload_ios
    else
      log "iOS release skipped"
    fi
  fi

  log "AlgoBot release workflow finished"
  printf 'Check Google Play Console and App Store Connect for review status.\n'
}

main "$@"

