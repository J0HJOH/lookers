# Lookers

An online clothing store for the Lookers brand: men's, women's and baby's clothing, hats, shoes and bags.
One Flutter codebase runs as a **website**, an **Android app** and an **iPhone app**, all sharing the same
Supabase backend. Soft "neumorphic" design in purple hues, with light and dark modes.

**Live website:** https://lookers-nine.vercel.app

## What it does

| | |
|---|---|
| **Shop** | Categories, search with live suggestions, sort, product pages with photo gallery, colour and size choice, ratings and customer reviews, and "more from this category" |
| **Accounts** | Sign in or sign up with Google from a popup (no separate login page). On phones it uses Google's own account picker, with no browser and no website |
| **Shared bag** | Signed in, your bag follows you across web, Android and iPhone **in real time** (Supabase Realtime over a WebSocket). Signed out, it stays on your device and merges into your account when you sign in |
| **Checkout** | Browse and fill the form as a guest; placing the order asks you to sign in. Pay on delivery works today; the card screen is display-only. Prices, stock and shipping are decided by the database, never the app |
| **Customer dashboard** | Order history and order details |
| **Admin dashboard** | Revenue, orders, low stock, product create/edit/hide/delete, order status |
| **Emails** | Order confirmation through Mailgun (sent by a Supabase Edge Function) |
| **Look and feel** | Purple neumorphism, light and dark mode (remembered), your logo as the app icon on every platform |

## Where things are

```
lookers/
├── frontend/              THE APP. One Flutter project for web, Android and iPhone
│   ├── lib/               All the app code (screens, logic, data access), shared by every platform
│   ├── android/           Android wrapper: manifest, icons, launch screen, sign-in deep link
│   ├── ios/               iPhone wrapper: Info.plist, icons, launch screen, sign-in URL schemes
│   ├── web/               Website wrapper: index.html, favicon, manifest
│   ├── assets/fonts/      Bundled fonts (Jost, Pinyon Script)
│   ├── test/              Automated tests (60)
│   ├── tool/              Generators: app icons, review screenshots
│   └── env.json           Your Supabase/Google settings (git-ignored, copy env.example.json)
├── supabase/              Database and server code
│   ├── migrations/        0001_init.sql (shop), 0002_cart_sync.sql (synced bag)
│   ├── seed.sql           Sample catalogue, generated from seed/catalog.ts
│   └── functions/         send-order-confirmation (Mailgun email)
├── scripts/               Helper scripts (see Commands)
├── docs/SETUP.md          Step-by-step setup for accounts, keys, deploy and mobile
├── AGENTS.md              Engineering rules for AI coding agents working on this project
└── .github/workflows/     CI: tests, Android build check, deploy to Vercel
```

## Quick start

You need Flutter 3.44.6 (installed through FVM at `~/fvm/versions/3.44.6`).

**Website, preview mode (no accounts needed):** shows a sample catalogue so you can see the design.

```bash
cd frontend
~/fvm/versions/3.44.6/bin/flutter pub get
~/fvm/versions/3.44.6/bin/flutter run -d chrome --web-port 3000
```

**With your real data (sign-in, checkout, admin, shared bag):** follow [docs/SETUP.md](docs/SETUP.md) to create the
Supabase project, Google sign-in and `frontend/env.json`, then pass that file when running:

```bash
cd frontend && ~/fvm/versions/3.44.6/bin/flutter run -d chrome --web-port 3000 --dart-define-from-file=env.json
```

**Phone app (Android emulator, iPhone simulator or a real phone):**

```bash
./scripts/run_mobile.sh                 # asks which device
./scripts/run_mobile.sh <device-id>     # see `flutter devices`
```

> Always run with `--dart-define-from-file=env.json` (the script does). Pressing Run in Xcode or Android Studio
> doesn't pass it, so the app starts in preview mode and sign-in says it has no Supabase settings. In VS Code use the
> "Lookers (phone or simulator, with Supabase)" launch entry.

## Commands

| Command | What it does |
|---|---|
| `./scripts/run_mobile.sh [device]` | Run the phone app with your settings |
| `flutter analyze` / `flutter test` | Static analysis / tests (run in `frontend/`) |
| `./scripts/build_web.sh` | Release build of the website into `frontend/build/web` |
| `python3 scripts/serve_web.py` | Serve that build locally on port 3000 |
| `./scripts/deploy_vercel.sh [--prod]` | Build and deploy the website to Vercel by hand |
| `flutter build apk --release --dart-define-from-file=env.json` | Android APK to share with testers (in `frontend/`) |
| `./scripts/make_icons.sh` | Regenerate every icon and launch image from the logo |
| `node scripts/generate-seed.ts` | Rebuild `supabase/seed.sql` and the preview catalogue from `seed/catalog.ts` |
| `node scripts/test_edge_function.mjs` | Test the confirmation-email function's logic |

## Platforms

| Platform | Status | Notes |
|---|---|---|
| **Website** | Live on Vercel | Deployed automatically when you push to `main` |
| **Android** | Builds, runs, release APK for testers | Needs the tester's Google account on the OAuth "test users" list; store release needs your own signing key |
| **iPhone** | Builds and runs in the simulator | Store release needs an Apple Developer account, signing, and Sign in with Apple (App Store rule) |

Phone setup details (Google sign-in client ids, signing keys, store steps) are in
[docs/SETUP.md](docs/SETUP.md), section 8.

## How it fits together

- **Flutter app** (`frontend/lib`) is organised by feature (catalog, cart, checkout, orders, auth, admin), each split
  into domain (rules), data (Supabase) and presentation (screens). Design values live in one theme folder.
- **Supabase** holds the data and enforces security with Row Level Security: shoppers can only see their own orders and
  bag; only admins can change products and order status. A database function places orders atomically.
- **Real-time bag:** the app listens on a Supabase Realtime channel for the signed-in shopper's bag and reloads it when
  it changes anywhere.
- **Secrets:** the app only contains public values (Supabase URL, publishable key, Google client ids). The Mailgun key
  lives in Supabase secrets, and there is no service-role key anywhere.

Full engineering rules, architecture and the list of known gaps are in [AGENTS.md](AGENTS.md).

## Still to do before real customers

- A verified Mailgun domain, so customer confirmation emails are delivered (the sandbox only reaches addresses you approved).
- Remove or replace the dummy reviews and sample products with real ones.
- Choose a card-payment provider (the card screen is display-only today).
- Google OAuth: add testers as test users, or publish the consent screen.
- Phone stores: release signing keys, Sign in with Apple, in-app account deletion, privacy policy.

## Documentation

- [docs/SETUP.md](docs/SETUP.md): every account, key and deployment step, with troubleshooting.
- [AGENTS.md](AGENTS.md): architecture, design system, security and testing rules.

Product photos are free images from [Pexels](https://www.pexels.com/license/). Fonts are SIL OFL (licences in
`frontend/assets/fonts`).
