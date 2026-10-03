# Lookers

An e-commerce site for the Lookers clothing brand: men's, women's and baby's clothing, hats, shoes and bags.
Luxury-editorial design, Google sign-in, a customer dashboard, checkout and an admin dashboard.

| Part | Technology |
|---|---|
| Frontend | **Flutter** (web) in `frontend/` |
| Database + login | **Supabase** (Postgres with Row Level Security, Google auth) in `supabase/` |
| Confirmation emails | **Mailgun**, sent by a Supabase Edge Function |

## Quick start (preview mode, no accounts needed)

```bash
cd frontend
~/fvm/versions/3.44.6/bin/flutter pub get
~/fvm/versions/3.44.6/bin/flutter run -d chrome --web-port 3000
```

Without Supabase settings the app shows a sample catalogue so you can see the design. To enable sign-in,
checkout, orders and the admin dashboard, follow **[docs/SETUP.md](docs/SETUP.md)**: Supabase, Google Cloud
Console, Mailgun and deployment are steps you do yourself.

## Commands

| Command | What it does |
|---|---|
| `flutter run -d chrome --web-port 3000 --dart-define-from-file=env.json` | Run with your Supabase settings (from `frontend/`) |
| `flutter analyze` / `flutter test` | Static analysis / tests (from `frontend/`) |
| `node scripts/test_edge_function.mjs` | Test the confirmation-email function's logic (no accounts needed) |
| `./scripts/build_web.sh` | Release build into `frontend/build/web` |
| `./scripts/deploy_vercel.sh [--prod]` | Build and deploy to Vercel (first set up in docs/SETUP.md step 6) |
| `python3 scripts/serve_web.py` | Serve that build locally on port 3000 |
| `node scripts/generate-seed.ts` | Regenerate `supabase/seed.sql` and the preview catalogue from `seed/catalog.ts` |

## Pages

| Path | Who | What |
|---|---|---|
| `/`, `/shop`, `/product/:slug`, `/cart` | Everyone | Storefront: category filter, search, sort |
| `/login` | Everyone | "Continue with Google" |
| `/checkout` | Signed in | Address form, pay on delivery |
| `/account` | Signed in | Order history |
| `/admin` | Admin only | Overview, products, orders |

## Project docs

- [AGENTS.md](AGENTS.md): engineering contract for AI coding agents (architecture, design system, security
  rules, definition of done, open decisions).
- [docs/SETUP.md](docs/SETUP.md): owner setup directives.
- `archive/nextjs/`: the earlier Next.js version of the frontend, kept for reference. Safe to delete.

Product photos are free images from [Pexels](https://www.pexels.com/license/). Fonts are SIL OFL
(licences in `frontend/assets/fonts`).
