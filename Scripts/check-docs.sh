#!/usr/bin/env bash
# Fails when a module has no DocC landing page, or when doc comments
# mention internal commit numbers.
set -euo pipefail

cd "$(dirname "$0")/.."

status=0

for suffix in Core LocalAuth Keychain UIKit TestSupport; do
    name="BiometricSession${suffix}"
    page="Sources/${name}/${name}.docc/${name}.md"
    if [ ! -f "$page" ]; then
        echo "Missing landing page: $page"
        status=1
        continue
    fi
    if ! grep -q "^# \`\`${name}\`\`" "$page"; then
        echo "Landing page heading must be: # \`\`${name}\`\` ($page)"
        status=1
    fi
done

hits=$(grep -rnE '^[[:space:]]*///.*[Cc]ommit [0-9]' Sources || true)
if [ -n "$hits" ]; then
    echo "Doc comments mention internal commit numbers:"
    echo "$hits"
    status=1
fi

exit "$status"
