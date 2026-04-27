#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "==> swift build"
swift build

echo "==> swift test"
swift test

echo "==> lint: no unguarded .spring( calls"
if grep -rn "\.spring(" Sources/ | grep -v "reduceMotion" | grep -v "//"; then
    echo "ERROR: Found .spring() calls not guarded by reduceMotion. Wrap them."
    exit 1
fi

echo "All checks passed."
