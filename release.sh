
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

  [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]] ||
    fail "Invalid version: $VERSION"

  local file
  for file in \
    "tr-TR.txt" \
    "en-US.txt" \
    "promotional-tr-TR.txt" \
    "promotional-en-US.txt"; do

    [[ -s "$NOTES_DIR/$file" ]] ||
      fail "Missing or empty release file: $NOTES_DIR/$file"
  done

  (cd "$ANDROID_DIR" && bundle exec fastlane android check_release)
  (cd "$IOS_DIR" && bundle exec fastlane ios check_release)

  log "Release metadata validation completed"
}

build_android() {
  log "Building Android AAB"

  (cd "$ANDROID_DIR" && bundle exec fastlane android build)

  [[ -f "$ANDROID_AAB" ]] || fail "Android AAB not found"
}

build_ios() {
  log "Building iOS IPA"

  (cd "$IOS_DIR" && bundle exec fastlane ios build)

  [[ -f "$IOS_IPA" ]] || fail "iOS IPA not found"
}

upload_android() {
  log "Uploading Android to Google Play Production"

  # Uses existing AAB without rebuilding.
  (cd "$ANDROID_DIR" && bundle exec fastlane android upload)
}

upload_ios() {
  log "Uploading iOS to App Store Connect"

  # Uses existing IPA without rebuilding.
  (cd "$IOS_DIR" && bundle exec fastlane ios upload)
}

main() {
  log "AlgoBot Unified Release"

  printf 'Shared version: %s\n' "$VERSION"

  check_requirements

  printf '\nRelease targets:\n'
  printf '  Android: Google Play Production\n'
  printf '  iOS: App Store Connect\n'

  if ! confirm "Build Android and iOS for version $VERSION?"; then
    log "Release cancelled"
    exit 0
  fi

  build_android
  build_ios

  log "Both platform builds completed"

  if confirm "Proceed to Android upload?"; then
    upload_android
  else
    log "Android upload skipped"
  fi

  if confirm "Proceed to iOS upload?"; then
    upload_ios
  else
    log "iOS upload skipped"
  fi

  log "AlgoBot release workflow finished"
  printf 'Check Google Play Console and App Store Connect for review status.\n'
}

main "$@"

