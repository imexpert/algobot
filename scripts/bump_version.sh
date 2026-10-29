
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION_FILE="pubspec.yaml"

CURRENT=$(sed -nE 's/^version:[[:space:]]*//p' "$VERSION_FILE" | head -1)

if [[ ! "$CURRENT" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$ ]]; then
  echo "Invalid version: $CURRENT"
  exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"
BUILD="${BASH_REMATCH[4]}"

echo "Current version: $CURRENT"

# Accept release type from Fastlane or ask interactively
CHOICE="${1:-}"

if [[ -z "$CHOICE" ]]; then
  echo "Select release type:"
  echo "1) Patch"
  echo "2) Minor"
  echo "3) Major"

  read -r -p "Selection (1/2/3): " CHOICE
fi

case "$CHOICE" in
  1)
    PATCH=$((PATCH + 1))
    ;;
  2)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  3)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  *)
    echo "Invalid selection: $CHOICE"
    exit 1
    ;;
esac

BUILD=$((BUILD + 1))

NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD"

sed -i.bak "s/^version:.*/version: $NEW_VERSION/" "$VERSION_FILE"
rm -f "$VERSION_FILE.bak"

echo "New version: $NEW_VERSION"

