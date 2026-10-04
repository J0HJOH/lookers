#!/usr/bin/env bash
# Regenerates every app icon and launch image from the Logo widget (web, Android, iOS), then strips the
# alpha channel from the iOS icons (Apple rejects icons that have one). Run from anywhere.
set -euo pipefail
cd "$(dirname "$0")/../frontend"
FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.44.6/bin/flutter}"
[ -x "$FLUTTER" ] || FLUTTER=flutter
"$FLUTTER" test tool/generate_icons_test.dart
for f in ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png; do
  sips -s format jpeg "$f" --out /tmp/_lookers_icon.jpg >/dev/null
  sips -s format png /tmp/_lookers_icon.jpg --out "$f" >/dev/null
done
rm -f /tmp/_lookers_icon.jpg
echo "Icons regenerated (iOS icons flattened)."
