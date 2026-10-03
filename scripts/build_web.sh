#!/usr/bin/env bash
# Builds the Flutter web app into frontend/build/web for deployment.
# Usage: ./scripts/build_web.sh            (reads frontend/env.json if present)
set -euo pipefail
cd "$(dirname "$0")/../frontend"

FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.44.6/bin/flutter}"
[ -x "$FLUTTER" ] || FLUTTER=flutter

ARGS=()
if [ -f env.json ]; then
  ARGS+=(--dart-define-from-file=env.json)
else
  echo "Note: frontend/env.json not found, building in PREVIEW mode (no Supabase)." >&2
fi

"$FLUTTER" build web --release ${ARGS[@]+"${ARGS[@]}"}

# Hosting config for Vercel (Netlify equivalent below):
#  - single-page app: every path must serve index.html (needed for /shop, /product/..., /admin)
#  - security headers (a Content-Security-Policy is still an open decision, see AGENTS.md section 27)
#  - the app shell must never be cached stale, or visitors keep running an old build
cat > build/web/vercel.json <<'JSON'
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "git": { "deploymentEnabled": false },
  "rewrites": [{ "source": "/((?!.*\\.).*)", "destination": "/index.html" }],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()" },
        { "key": "Strict-Transport-Security", "value": "max-age=31536000; includeSubDomains" }
      ]
    },
    {
      "source": "/(index.html|flutter_bootstrap.js|flutter_service_worker.js|version.json|manifest.json)",
      "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
    }
  ]
}
JSON
printf '/*    /index.html   200\n' > build/web/_redirects   # Netlify equivalent
echo "Built frontend/build/web"
