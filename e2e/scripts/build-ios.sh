#!/bin/bash
set -euo pipefail

# Build iOS app for E2E testing (Debug with bundled JS - no Metro server required)
# Usage: ./scripts/build-ios.sh
#
# Uses FORCE_BUNDLING=1 to bundle JS into the Debug build, making it
# self-contained and suitable for CI environments without a Metro server.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_DIR="$(dirname "$SCRIPT_DIR")"
EXAMPLE_DIR="$(cd "$E2E_DIR/../example" && pwd)"

echo "📱 Building iOS app for E2E testing"
echo "   Project: $EXAMPLE_DIR"
echo "   Mode: Debug with bundled JS (no Metro required)"
echo ""

cd "$EXAMPLE_DIR"

# Build Debug with FORCE_BUNDLING to include JS bundle in app
yarn build:ios:e2e

APP_PATH="$EXAMPLE_DIR/ios/build/Build/Products/Debug-iphonesimulator/FabricHtmlTextExample.app"

if [ -d "$APP_PATH" ] && [ -f "$APP_PATH/main.jsbundle" ]; then
  echo ""
  echo "✅ Build succeeded"
  echo "   App: $APP_PATH"
  echo "   JS Bundle: $(ls -lh "$APP_PATH/main.jsbundle" | awk '{print $5}')"
else
  echo ""
  echo "❌ Build failed - app or JS bundle not found"
  echo "   Expected: $APP_PATH"
  exit 1
fi
