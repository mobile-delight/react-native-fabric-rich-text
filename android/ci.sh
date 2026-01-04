#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Android CI Test Runner ==="
echo "Working directory: $PACKAGE_DIR"
echo ""

# ========== Standalone Tests ==========
echo "=== Running Standalone Tests ==="
echo "These tests run the core library code without React Native dependencies."
echo ""

cd "$SCRIPT_DIR"
./gradlew test --console=plain

echo ""
echo "=== Android Tests Complete ==="
