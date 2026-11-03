#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p test-results
log="test-results/$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee "$log") 2>&1
xcrun swift test --disable-xctest
xcrun swift build --product GentleNight
python3 scripts/test-cli.py
if [[ "${1:-}" == "--with-display" || "${1:-}" == "--full-screen" ]]; then
    python3 scripts/test-audio.py
    .build/debug/GentleNight --self-test
    .build/debug/GentleNight --smoke-test
else
    printf 'GPU and small-window checks skipped; use --with-display on a logged-in Mac.\n'
fi
bash scripts/build-app.sh
codesign --verify --strict "dist/Gentle Night.app"
if [[ "${1:-}" == "--full-screen" ]]; then
    python3 scripts/test-live.py
fi
printf 'PASS: requested automated checks complete. Receipt: %s\n' "$log"
