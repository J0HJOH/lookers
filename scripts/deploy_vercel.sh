#!/usr/bin/env bash
# Builds the site and deploys frontend/build/web to Vercel from your computer.
# First time only: run `npx vercel login` and `npx vercel link` in the repo root (docs/SETUP.md, step 6).
# Usage: ./scripts/deploy_vercel.sh           (preview deployment)
#        ./scripts/deploy_vercel.sh --prod    (production)
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .vercel/project.json ]; then
  echo "Not linked to a Vercel project yet. Run:  npx vercel link   (see docs/SETUP.md step 6)" >&2
  exit 1
fi
if [ ! -f frontend/env.json ]; then
  echo "frontend/env.json is missing: this build would be PREVIEW mode (no Supabase). Create it first (docs/SETUP.md step 1)." >&2
  exit 1
fi

# Vercel CLI picks the target project from these two variables.
export VERCEL_ORG_ID="$(python3 -c "import json;print(json.load(open('.vercel/project.json'))['orgId'])")"
export VERCEL_PROJECT_ID="$(python3 -c "import json;print(json.load(open('.vercel/project.json'))['projectId'])")"

./scripts/build_web.sh
cd frontend/build/web
npx --yes vercel@latest deploy --yes "$@"
