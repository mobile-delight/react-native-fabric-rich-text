#!/bin/bash
set -euo pipefail

SIMULATOR_NAME="iPhoneTest"
SCHEME="FabricHtmlTextTests"

# Navigate to the example app
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_IOS_DIR="$SCRIPT_DIR/../example/ios"

cd "$EXAMPLE_IOS_DIR"

# Get the latest available iOS runtime
get_latest_ios_runtime() {
    xcrun simctl list runtimes -j | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
ios_runtimes = [r for r in data['runtimes'] if r['platform'] == 'iOS' and r['isAvailable']]
if ios_runtimes:
    latest = sorted(ios_runtimes, key=lambda x: [int(p) for p in x['version'].split('.')], reverse=True)[0]
    print(latest['identifier'])
else:
    sys.exit(1)
"
}

# Get a compatible device type for the given runtime
get_compatible_device_type() {
    local runtime="$1"
    xcrun simctl list devicetypes -j | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
runtime = '$runtime'

# Extract major version from runtime (e.g., 'iOS-26-0' -> 26)
import re
match = re.search(r'iOS-(\d+)', runtime)
runtime_major = int(match.group(1)) if match else 18

# Modern device types that work with recent iOS versions
# Prefer iPhone models from the last few years
preferred_patterns = ['iPhone-16', 'iPhone-15', 'iPhone-14', 'iPhone-13', 'iPhone-12']

for pattern in preferred_patterns:
    for d in data['devicetypes']:
        if pattern in d['identifier']:
            print(d['identifier'])
            sys.exit(0)

# Fallback: any iPhone that's not too old
for d in reversed(data['devicetypes']):
    if 'iPhone' in d['name'] and 'SE' not in d['name']:
        # Skip very old models
        old_models = ['iPhone-4', 'iPhone-5', 'iPhone-6', 'iPhone-7', 'iPhone-8']
        if not any(old in d['identifier'] for old in old_models):
            print(d['identifier'])
            sys.exit(0)

# Last resort: any iPhone
for d in reversed(data['devicetypes']):
    if 'iPhone' in d['name']:
        print(d['identifier'])
        sys.exit(0)

sys.exit(1)
"
}

# Check if simulator exists and is available
simulator_exists() {
    xcrun simctl list devices -j | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
name = '$SIMULATOR_NAME'
for runtime, devices in data['devices'].items():
    for device in devices:
        if device['name'] == name and device.get('isAvailable', False):
            print(device['udid'])
            sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

echo "=== iOS CI Test Runner ==="
echo "Working directory: $(pwd)"

# Install CocoaPods dependencies
echo ""
echo "=== Installing CocoaPods Dependencies ==="
bundle install --quiet
bundle exec pod install

# Check if simulator already exists
if UDID=$(simulator_exists); then
    echo "Using existing simulator: $SIMULATOR_NAME ($UDID)"
else
    echo "Creating simulator: $SIMULATOR_NAME"

    RUNTIME=$(get_latest_ios_runtime)
    echo "  Runtime: $RUNTIME"

    DEVICE_TYPE=$(get_compatible_device_type "$RUNTIME")
    echo "  Device type: $DEVICE_TYPE"

    UDID=$(xcrun simctl create "$SIMULATOR_NAME" "$DEVICE_TYPE" "$RUNTIME")
    echo "  Created: $UDID"
fi

# Custom DerivedData path for predictable caching
# Configurable via environment variable for CI flexibility
DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-$EXAMPLE_IOS_DIR/DerivedData}"
mkdir -p "$DERIVED_DATA_PATH" || {
    echo "ERROR: Cannot create DerivedData directory at $DERIVED_DATA_PATH"
    exit 1
}

echo ""
echo "=== Building Dependencies (Stage 1) ==="
# Build pods scheme first - this compiles all React Native dependencies
# and is cached by irgaly/xcode-cache action in CI
if command -v xcbeautify &> /dev/null; then
    xcodebuild build \
        -workspace FabricHtmlTextExample.xcworkspace \
        -scheme "Pods-FabricHtmlTextExample" \
        -destination "platform=iOS Simulator,id=$UDID" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        2>&1 | xcbeautify --is-ci
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        echo "ERROR: Pod compilation failed in Stage 1. Check output above."
        exit 1
    fi
else
    echo "Note: Install xcbeautify for prettier output (brew install xcbeautify)"
    xcodebuild build \
        -workspace FabricHtmlTextExample.xcworkspace \
        -scheme "Pods-FabricHtmlTextExample" \
        -destination "platform=iOS Simulator,id=$UDID" \
        -derivedDataPath "$DERIVED_DATA_PATH"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Pod compilation failed in Stage 1."
        exit 1
    fi
fi

echo ""
echo "=== Running Tests (Stage 2) ==="
# Run tests - pods cached from Stage 1, only incremental compilation needed
if command -v xcbeautify &> /dev/null; then
    xcodebuild test \
        -workspace FabricHtmlTextExample.xcworkspace \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$UDID" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        2>&1 | xcbeautify --is-ci
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        echo "ERROR: Tests failed in Stage 2. Check output above."
        exit 1
    fi
else
    xcodebuild test \
        -workspace FabricHtmlTextExample.xcworkspace \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$UDID" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -resultBundlePath "$DERIVED_DATA_PATH/TestResults.xcresult"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Tests failed in Stage 2."
        exit 1
    fi
fi

echo ""
echo "=== Tests Complete ==="
