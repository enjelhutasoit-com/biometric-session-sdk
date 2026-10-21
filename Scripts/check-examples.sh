#!/usr/bin/env bash
# Keeps the demo out of the library and keeps fakes out of the demo app.
set -euo pipefail

cd "$(dirname "$0")/.."

demo="Examples/BiometricSessionDemo"
status=0

for file in \
    "$demo/README.md" \
    "$demo/BiometricSessionDemo/BiometricSessionDemoApp.swift" \
    "$demo/BiometricSessionDemo/DemoModel.swift" \
    "$demo/BiometricSessionDemo/DemoView.swift" \
    "$demo/BiometricSessionDemoTests/DemoModelTests.swift"; do
    if [ ! -f "$file" ]; then
        echo "Missing: $file"
        status=1
    fi
done

if [ ! -d "$demo/BiometricSessionDemo.xcodeproj" ]; then
    echo "Missing: $demo/BiometricSessionDemo.xcodeproj"
    status=1
fi

if grep -q "Examples" Package.swift; then
    echo "Package.swift must not mention Examples."
    status=1
fi

if [ -d "$demo/BiometricSessionDemo" ]; then
    hits=$(grep -rn "BiometricSessionTestSupport" "$demo/BiometricSessionDemo" || true)
    if [ -n "$hits" ]; then
        echo "The demo app must not import TestSupport:"
        echo "$hits"
        status=1
    fi
fi

exit "$status"
