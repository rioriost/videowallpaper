#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-VideoWallpaper}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/DerivedData}"
BUILD_PRODUCTS="$DERIVED_DATA/Build/Products/$CONFIGURATION"
APP_PATH="${APP_PATH:-$BUILD_PRODUCTS/$APP_NAME.app}"

TAG="${1:-${TAG:-}}"
if [[ -z "$TAG" ]]; then
  TAG="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/VideoWallpaper/Info.plist" 2>/dev/null || true)"
fi
if [[ -z "$TAG" ]]; then
  echo "ERROR: No release tag found. Pass a tag as an argument or set TAG env."
  exit 1
fi

ZIP_NAME="${ZIP_NAME:-$APP_NAME-$TAG.zip}"
ZIP_PATH="${ZIP_PATH:-$ROOT_DIR/build/$ZIP_NAME}"

NOTARY_PROFILE="${NOTARY_PROFILE:-${AC_PROFILE:-}}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $cmd"
    exit 1
  fi
}

require_cmd xcrun
require_cmd ditto

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: App not found at $APP_PATH"
  echo "Build first or set APP_PATH / DERIVED_DATA / CONFIGURATION."
  exit 1
fi

sign_if_needed() {
  local sign_identity="${SIGN_IDENTITY:-}"
  if [[ -z "$sign_identity" ]]; then
    echo "==> Skipping signing (SIGN_IDENTITY not set)"
    return 0
  fi

  echo "==> Codesigning with identity: $sign_identity"
  codesign --force --deep --options runtime --timestamp \
    --sign "$sign_identity" "$APP_PATH"

  echo "==> Verifying code signature"
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"
}

create_zip() {
  echo "==> Creating zip: $ZIP_PATH"
  mkdir -p "$(dirname "$ZIP_PATH")"
  rm -f "$ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
}

ensure_notary_credentials() {
  if [[ -n "$NOTARY_PROFILE" ]]; then
    echo "==> Using notarytool profile: $NOTARY_PROFILE"
    return 0
  fi

  if [[ -n "$APPLE_ID" && -n "$TEAM_ID" && -n "$APP_PASSWORD" ]]; then
    NOTARY_PROFILE="AC_PROFILE"
    echo "==> Storing notarytool credentials in keychain profile: $NOTARY_PROFILE"
    xcrun notarytool store-credentials "$NOTARY_PROFILE" \
      --apple-id "$APPLE_ID" \
      --team-id "$TEAM_ID" \
      --password "$APP_PASSWORD"
    return 0
  fi

  echo "ERROR: Notary credentials not configured."
  echo "Set NOTARY_PROFILE to an existing keychain profile, or set:"
  echo "  APPLE_ID, TEAM_ID, APP_PASSWORD"
  exit 1
}

submit_notarization() {
  echo "==> Submitting to Apple notarization"
  xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
}

staple_app() {
  echo "==> Stapling notarization ticket"
  xcrun stapler staple "$APP_PATH"
}

assess_app() {
  echo "==> Assessing app with Gatekeeper"
  spctl --assess --type exec --verbose=4 "$APP_PATH"
}

echo "==> Notarization flow for $APP_NAME ($TAG)"

sign_if_needed
create_zip
ensure_notary_credentials
submit_notarization
staple_app
assess_app
create_zip

echo "==> Notarization complete"
echo "App: $APP_PATH"
echo "Zip: $ZIP_PATH"
echo "Tag: $TAG"
