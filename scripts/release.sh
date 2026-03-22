#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-VideoWallpaper}"
SCHEME="${SCHEME:-VideoWallpaper}"
CONFIGURATION="${CONFIGURATION:-Release}"
TAG="${1:-${TAG:-}}"

if [[ -z "$TAG" ]]; then
  TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
fi

if [[ -z "$TAG" ]]; then
  echo "ERROR: No git tag found. Pass a tag as an argument or set TAG env."
  exit 1
fi

VERSION="${VERSION:-$TAG}"
BUILD_NUMBER="${BUILD_NUMBER:-${VERSION##*.}}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/DerivedData}"
BUILD_PRODUCTS="$DERIVED_DATA/Build/Products/$CONFIGURATION"
APP_PATH="$BUILD_PRODUCTS/$APP_NAME.app"
ZIP_NAME="${ZIP_NAME:-${APP_NAME}-${TAG}.zip}"
ZIP_PATH="${ZIP_PATH:-$ROOT_DIR/build/$ZIP_NAME}"
APP_REPO="${APP_REPO:-rioriost/videowallpaper}"
HOMEPAGE="${HOMEPAGE:-https://github.com/$APP_REPO}"
CASK_TAP_PATH="${CASK_TAP_PATH:-$ROOT_DIR/../homebrew-cask}"
CASK_NAME="${CASK_NAME:-videowallpaper}"
CASK_FILE="$CASK_TAP_PATH/Casks/${CASK_NAME}.rb"
CASK_REL="Casks/${CASK_NAME}.rb"
URL="https://github.com/${APP_REPO}/releases/download/${TAG}/${ZIP_NAME}"
NOTARIZE="${NOTARIZE:-1}"
PUBLISH="${PUBLISH:-1}"
GIT_BRANCH="${GIT_BRANCH:-main}"
NOTARY_PROFILE="${NOTARY_PROFILE:-${AC_PROFILE:-}}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-${APP_SPECIFIC_PASSWORD:-}}"

require_cmd() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $cmd"
    echo "Hint: $hint"
    exit 1
  fi
}

require_env() {
  local var_name="$1"
  local hint="$2"
  local value="${!var_name:-}"
  if [[ -z "$value" ]]; then
    echo "ERROR: Required environment variable is not set: $var_name"
    echo "Hint: $hint"
    exit 1
  fi
}

sync_info_plist_versions() {
  local plist="$ROOT_DIR/$APP_NAME/Info.plist"
  if [[ ! -f "$plist" ]]; then
    echo "ERROR: Info.plist not found: $plist"
    exit 1
  fi

  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$plist" \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$plist"

  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$plist" \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$plist"

  echo "==> Synced Info.plist versions: CFBundleShortVersionString=$VERSION CFBundleVersion=$BUILD_NUMBER"
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

build_app() {
  echo "==> Building $APP_NAME ($CONFIGURATION, arch arm64)"
  xcodebuild \
    -project "$ROOT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=macOS,arch=arm64" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

  if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: App not found at $APP_PATH"
    exit 1
  fi
}

sign_app() {
  require_env "SIGN_IDENTITY" "Set SIGN_IDENTITY to your Developer ID Application identity."

  echo "==> Codesigning app with identity: $SIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp \
    --sign "$SIGN_IDENTITY" "$APP_PATH"

  echo "==> Verifying codesign"
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"
}

create_zip() {
  echo "==> Creating zip: $ZIP_PATH"
  mkdir -p "$(dirname "$ZIP_PATH")"
  rm -f "$ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
}

notarize_zip() {
  echo "==> Submitting to Apple notarization"
  xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
}

staple_app() {
  echo "==> Stapling notarization ticket"
  xcrun stapler staple "$APP_PATH"

  echo "==> Verifying Gatekeeper assessment"
  spctl --assess --type execute --verbose=4 "$APP_PATH"
}

compute_sha256() {
  shasum -a 256 "$ZIP_PATH" | awk '{print $1}'
}

write_cask() {
  local sha256="$1"

  echo "==> Writing cask: $CASK_FILE"
  mkdir -p "$(dirname "$CASK_FILE")"
  cat > "$CASK_FILE" <<EOF
cask "$CASK_NAME" do
  version "$VERSION"
  sha256 "$sha256"

  url "$URL"
  name "$APP_NAME"
  desc "Play videos as your macOS wallpaper"
  homepage "$HOMEPAGE"

  app "$APP_NAME.app"

  zap trash: [
    "~/Library/Application Support/$APP_NAME",
    "~/Library/Preferences/*$APP_NAME*.plist",
    "~/Library/Saved Application State/*$APP_NAME*.savedState",
  ]
end
EOF
}

publish_release() {
  local sha256="$1"

  require_cmd "gh" "Install GitHub CLI: https://cli.github.com/ or set PUBLISH=0."
  if ! gh auth status -h github.com >/dev/null 2>&1; then
    echo "ERROR: gh CLI is not authenticated."
    echo "Run: gh auth login"
    exit 1
  fi

  git fetch --prune origin --tags
  if ! git ls-remote --tags origin "$TAG" | grep -q "refs/tags/$TAG$"; then
    echo "==> Tag $TAG not found on origin. Pushing $GIT_BRANCH and tag..."
    git push origin "$GIT_BRANCH"
    git push origin "$TAG"
    git fetch --prune origin --tags
    if ! git ls-remote --tags origin "$TAG" | grep -q "refs/tags/$TAG$"; then
      echo "ERROR: Tag $TAG still not found on origin after push."
      exit 1
    fi
  fi

  echo "==> Publishing GitHub release: $TAG"
  assets=("$ZIP_PATH")
  for extra in README.md README-jp.md LICENSE; do
    if [[ -f "$extra" ]]; then
      assets+=("$extra")
    fi
  done

  if gh release view "$TAG" --repo "$APP_REPO" >/dev/null 2>&1; then
    gh release upload "$TAG" "${assets[@]}" --clobber --repo "$APP_REPO"
  else
    if [[ -n "${RELEASE_NOTES:-}" ]]; then
      gh release create "$TAG" "${assets[@]}" --notes "$RELEASE_NOTES" --repo "$APP_REPO" --target "$(git rev-parse "$TAG")"
    else
      gh release create "$TAG" "${assets[@]}" --generate-notes --repo "$APP_REPO" --target "$(git rev-parse "$TAG")"
    fi
  fi

  echo "==> Updating Homebrew cask"
  if [[ ! -d "$CASK_TAP_PATH" ]]; then
    echo "ERROR: CASK_TAP_PATH does not exist: $CASK_TAP_PATH"
    echo "Hint: set CASK_TAP_PATH to the local clone of homebrew-cask."
    exit 1
  fi
  if [[ ! -d "$CASK_TAP_PATH/.git" ]]; then
    echo "ERROR: CASK_TAP_PATH is not a git repo: $CASK_TAP_PATH"
    echo "Hint: git clone https://github.com/rioriost/homebrew-cask"
    exit 1
  fi

  git -C "$CASK_TAP_PATH" add "$CASK_REL"
  if ! git -C "$CASK_TAP_PATH" diff --cached --quiet; then
    local tap_commit_message="${TAP_COMMIT_MESSAGE:-${CASK_NAME} ${VERSION}}"
    git -C "$CASK_TAP_PATH" commit -m "$tap_commit_message"
  fi
  if ! git -C "$CASK_TAP_PATH" push; then
    echo "Push rejected; pulling and rebasing before retry."
    git -C "$CASK_TAP_PATH" pull --rebase
    git -C "$CASK_TAP_PATH" push
  fi

  cat <<INFO

Release artifacts:
- Tag: $TAG
- Version: $VERSION
- Build: $BUILD_NUMBER
- Zip: $ZIP_PATH
- SHA256: $sha256
- Cask: $CASK_FILE
- Notarize: $NOTARIZE
- Publish: $PUBLISH

INFO
}

main() {
  require_cmd "git" "Install Xcode command line tools."
  require_cmd "xcodebuild" "Install Xcode."
  require_cmd "xcrun" "Install Xcode."
  require_cmd "codesign" "Install Xcode command line tools."
  require_cmd "ditto" "Available on macOS by default."
  require_cmd "shasum" "Available on macOS by default."
  require_cmd "/usr/libexec/PlistBuddy" "Available on macOS by default."
  require_cmd "spctl" "Available on macOS by default."

  sync_info_plist_versions
  build_app

  if [[ "$NOTARIZE" == "1" ]]; then
    ensure_notary_credentials
    sign_app
    create_zip
    notarize_zip
    staple_app
    create_zip
  else
    echo "==> Skipping notarization"
    if [[ -n "${SIGN_IDENTITY:-}" ]]; then
      sign_app
    fi
    create_zip
  fi

  local sha256
  sha256="$(compute_sha256)"
  write_cask "$sha256"

  if [[ "$PUBLISH" == "1" ]]; then
    publish_release "$sha256"
  else
    cat <<INFO

Release artifacts:
- Tag: $TAG
- Version: $VERSION
- Build: $BUILD_NUMBER
- Zip: $ZIP_PATH
- SHA256: $sha256
- Cask: $CASK_FILE
- Notarize: $NOTARIZE
- Publish: $PUBLISH

INFO
  fi
}

main "$@"
