#!/usr/bin/env bash
# Runs the phone app WITH your Supabase settings (frontend/env.json), so Google sign-in, the real catalogue,
# checkout and the synced bag work. Pressing "Run" in Xcode / Android Studio does NOT pass these settings
# and gives a preview-mode app, so use this (or the IDE setup in docs/SETUP.md).
# Usage: ./scripts/run_mobile.sh              (asks Flutter which device)
#        ./scripts/run_mobile.sh <device-id>  (see: flutter devices)
set -euo pipefail
cd "$(dirname "$0")/../frontend"
FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.44.6/bin/flutter}"
[ -x "$FLUTTER" ] || FLUTTER=flutter
[ -f env.json ] || { echo "frontend/env.json is missing: copy env.example.json to env.json and fill it in (docs/SETUP.md step 1)." >&2; exit 1; }
if [ $# -ge 1 ]; then
  exec "$FLUTTER" run -d "$1" --dart-define-from-file=env.json
fi
exec "$FLUTTER" run --dart-define-from-file=env.json
