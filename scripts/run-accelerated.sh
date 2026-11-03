#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/build-app.sh
printf 'Accelerated session: fade starts at 3s idle; black at 12s. Audio hold is bypassed for this session.\nMove the mouse or type to restore. Auto-exits after 45s. Quit any existing Gentle Night first.\n'
exec "dist/Gentle Night.app/Contents/MacOS/GentleNight" --accelerated
