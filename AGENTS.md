# AGENTS.md — Lookers

The engineering contract for any AI coding agent working on **Lookers**. Read all of it before
changing anything. Where this document describes a target the code does not meet yet, the gap is
listed in [§27](#27-current-state-vs-this-contract). Do not assume the target already exists.

> **🟡 HUMAN REVIEW** marks a decision an agent must not make alone. Explain the options and
> trade-offs, then wait for a human.
>
> **🔧 OWNER STEP** marks work only the owner can do (creating accounts, keys, dashboards).
> An agent never does these; it gives the owner clear directives (see `docs/SETUP.md`).

Carried over from the owner's Task App contract: Clean Architecture (domain / data / presentation),
feature folders, design tokens enforced by a test, `Failure` types instead of raw errors,
validation at every boundary, hand-written fakes in tests, Definition of Done, human-review gates.

---

## 1. Project Context

**What it is.** Lookers is an e-commerce website for a clothing brand of the same name, in a
neumorphic purple style with dark mode. The **frontend is Flutter: web, Android and iOS from one codebase**; the backend is **Supabase**. Logo: a
large cursive **L** with a **K** beneath it (`lib/core/ui/logo.dart`).

**Categories:** Men's Clothing, Women's Clothing, Baby's Clothing, Hats, Shoes, Bags & Accessories
(rows in the `categories` table; seed in `seed/catalog.ts`).

**Priorities (owner's order):** 1) Authentication, 2) the customer dashboard, 3) checkout,
4) the Supabase database, 5) the admin dashboard.

**Implemented today:**

- Storefront, structured like a mainstream fast-fashion site (layout pattern only; our own brand look):
  announcement strip, header with **search box and live suggestions**, category rail, home, shop (category
  filter, search, sort, star ratings on cards), bag, policy pages, 404.
- **Product page:** photo gallery with thumbnails, **colour swatches and size chips** (both required),
  price, rating summary (jumps to reviews), accordions (description, details, shipping & returns),
  **customer reviews** (rating bars + list; each review shows who bought what, with the colour and size they
  chose), and **"More from <category>"** items beneath.
- **Reviews are dummy data** (2-3 per product, made-up customers, `is_dummy = true`). 🟡 They must be
  replaced or removed before launch: showing invented reviews as real is misleading and illegal in many places.
- **Guest checkout flow:** anyone can browse, fill the bag and fill in the checkout form. **Placing the
  order requires an account:** a signed-out shopper sees "Sign in to place order"; the form is saved on their
  device, they sign in or sign up with Google (account created automatically), return to `/checkout` with
  bag and details intact, then place the order. Only `/checkout/success`, `/account` and `/admin` are guarded.
- **Payment screen (UI only):** "Pay on delivery" (works) and "Credit or debit card" (**Coming soon**:
  disabled placeholder fields, ordering disabled while selected). Nothing typed there is read, stored or sent.
- **Auth:** Google sign-in via Supabase Auth (`/login`, `/auth/callback`), sign-out, route guards.
- **Customer dashboard** (`/account`, `/account/orders/:id`): order history and details.
- **Checkout** (`/checkout`, `/checkout/success`): contact + address form, validation, atomic order
  placement through the `place_order` SQL function (prices, stock, shipping decided in the
  database), **pay on delivery**.
- **Confirmation email** through Mailgun, sent by the `send-order-confirmation` Supabase Edge
  Function (best effort, never blocks an order, one-shot per order).
- **Admin dashboard** (`/admin`): overview (revenue, orders, pending, customers, low stock),
  products (create, edit, hide, delete), orders (view, change status).
- **Database:** Postgres with Row Level Security (`supabase/migrations/0001_init.sql`).

**Not implemented (do not write code or docs that assume otherwise):** online card payment, wishlist,
writing reviews (customers can't post yet), per-colour photos and per-variant stock, discount codes, image upload (admins paste image URLs), multiple images per product,
category management UI, restock on cancel, refunds/returns flow, shipping tracking, multi-currency,
i18n, analytics, AI features, store-published mobile releases (builds work; signing and store listings are owner steps), push notifications, in-app account deletion, SEO for crawlers (see §27).

**Preview mode.** Built without Supabase settings, the app serves the bundled sample catalogue so the
design can be viewed. Sign-in, checkout, account and admin show "not connected" states. Keep this working.

**Technologies**

| Part | Technology |
|---|---|
| Frontend | **Flutter 3.44.6** (FVM, Dart `^3.12`): **web, Android and iOS** (`frontend/android`, `frontend/ios`; app id / bundle id `com.lookers.lookers`). Packages: `supabase_flutter`, `go_router`, `shared_preferences`, `intl`. Lints: `flutter_lints` + `analysis_options.yaml`. Tests: `flutter_test` + hand-written fakes |
| Database + Auth | **Supabase** (Postgres, RLS, Auth with Google) |
| Server code | One **Supabase Edge Function** (Deno/TypeScript): `supabase/functions/send-order-confirmation` |
| Email | **Mailgun** HTTP API, called only from the Edge Function |
| Fonts | Jost and Pinyon Script, **bundled** in `frontend/assets/fonts` (SIL OFL licences alongside) |
| Images | Free Pexels photos, hotlinked (`images.pexels.com`, CORS-enabled) |
| Hosting | **Vercel**, static files only. Flutter is built by `scripts/build_web.sh` (locally via `scripts/deploy_vercel.sh`, or in GitHub Actions) and `frontend/build/web` is uploaded. `build_web.sh` writes the `vercel.json` there (SPA rewrite, security headers, no-cache app shell) |

**Constraints**

- **The web app is public code.** Everything compiled in (including `--dart-define` values) can be
  read by anyone. Only the Supabase URL and **publishable** key are compiled in; they are designed to be
  public because RLS protects the data. **No secret may ever be in the frontend.** The Mailgun key lives
  in Supabase secrets (Edge Function). There is deliberately **no service-role key** anywhere in this
  project; do not add one without 🟡 human review.
- **Money is integer cents everywhere.** Convert only for display (`core/formatting/money.dart`).
- **The browser never decides a price.** The cart sends `{slug, size, quantity}` only; the database
  re-prices and re-checks stock, sizes and the address inside `place_order`.
- **The database is authoritative.** Because the frontend can be bypassed (anyone can call the API),
  every rule the UI enforces must ALSO exist as a CHECK constraint, RLS policy or inside a SQL
  function. UI validation is for fast feedback only.
- **Build settings** come from `frontend/env.json` via `--dart-define-from-file` (git-ignored; copy
  `env.example.json`). Keys: `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `CURRENCY`.
- **Router:** path URLs (`usePathUrlStrategy`), so the host must rewrite every path to `index.html`.
  Dev port is fixed at **3000**: Supabase's allowed redirect URLs depend on it.
- **One codebase, three platforms.** Don't add web-only APIs without a guard (`kIsWeb`): path URL strategy and
  the Google redirect already branch. Phones use the same responsive layout (mobile < 700). Respect safe areas
  (`SiteShell` uses `SafeArea` and pads the footer for the home indicator).
- **Mobile Google sign-in** opens the system browser and returns through the deep link
  `com.lookers.lookers://login-callback` (`AppConfig.mobileAuthRedirect`). That value must stay identical in
  `AndroidManifest.xml` (intent-filter), `ios/Runner/Info.plist` (URL scheme) and Supabase's Redirect URLs.
  The deep link opens the home route, so `AuthController.takeReturnTo()` + the listener in `LookersApp` send the
  shopper back to where they started (e.g. checkout).
- **App icons** come from the logo (`scripts/make_icons.sh`): web, Android launcher + adaptive layers + launch
  splash, and the full iOS set + launch image. iOS icons must have no alpha; the script flattens them with `sips`.
- **Cart** is stored in browser localStorage through `shared_preferences` (`lookers.cart.v1`) and is
  treated as untrusted input when loaded. A cart line is product + size + colour.
- **Checkout draft** (`lookers.checkout.draft.v1`) keeps the delivery form across the sign-in round trip. It
  holds delivery details only, on the shopper's own device, and is cleared when the order is placed.
  **Card details are never collected, stored or sent**; the payment screen has no state.
- **Variants:** `products.colors` (`[{name, hex}]`) and `products.images` (extra gallery photos). Stock is per
  product, not per variant. `place_order` validates the chosen size AND colour against the product.
- **Flutter web images:** hosts must send CORS headers or CanvasKit can't draw them (the image widget
  falls back to an HTML element). Allowed hosts: `features/admin/domain/image_hosts.dart`.

---

## 2. Architecture

```
Presentation  ──►  Domain  ◄──  Data
```

| Layer | Contains | May depend on | Must not depend on |
|---|---|---|---|
| **Domain** | Entities, value types, repository **contracts** (abstract classes), use cases, validation, pure rules | Dart core only | Flutter, `supabase_flutter`, JSON, Data, Presentation |
| **Data** | Row parsing, repository **implementations** (Supabase), error mapping, storage adapters | Domain, `supabase_flutter`, `shared_preferences` | Presentation |
| **Presentation** | Pages, widgets, controllers (`ChangeNotifier`), routing, formatting for display, theme | Domain, `AppScope` | `supabase_flutter`, SQL, table names |

Rules:

- **Business logic never lives in widgets.** Examples already in the domain: cart merge/caps
  (`cart.dart`), shipping rule, address validation, `safeNextPath`, `ProductDraft` validation,
  catalogue filter/sort, stock levels, the `PlaceOrder` use case.
- **Widgets never touch Supabase.** They use repositories from `AppScope`.
- **Repository contracts live in domain; implementations in data.** Preview mode swaps in
  `PreviewCatalogRepository` / `UnavailableOrderRepository`.
- **Data converts** rows into entities once (`productFromRow`, `orderFromRow`; malformed rows are
  dropped, not thrown) and technical errors into `Failure`s (`supabase_error_mapper.dart`,
  `mapPlaceOrderError`).
- **Use cases:** one operation per use case. Today: `PlaceOrder`. Add more when an operation has
  rules or side effects; a repository call with no logic doesn't need one.
- **Navigation is presentation-only.** Domain code never navigates or shows messages.

**Composition root:** `lib/main.dart` is the only place that picks concrete implementations. It builds
repositories and controllers and passes them to `LookersApp`, which exposes them through `AppScope`.

---

## 3. Feature Organization

```
frontend/lib/
├── main.dart                        # composition root
├── app.dart                         # LookersApp (AppScope + MaterialApp.router + theme)
├── core/
│   ├── config/app_config.dart       # --dart-define values (the ONLY place they are read)
│   ├── error/failure.dart           # Failure + FailureKind
│   ├── formatting/money.dart
│   ├── routing/app_router.dart      # go_router routes + guard redirect
│   ├── theme/                       # app_colors (raw values), app_text, app_theme (tokens)
│   └── ui/                          # logo, site_shell (header/footer), layout, product_image, async_view, app_scope
└── features/
    ├── catalog/   domain · data (supabase + preview + generated seed_catalog.dart) · presentation (home, shop, product, cards)
    ├── cart/      domain (cart.dart) · data (cart_storage) · presentation (CartController, cart_page)
    ├── checkout/  domain (shipping_rules, shipping_address) · presentation (checkout_page, success_page)
    ├── orders/    domain (order, order_repository, place_order) · data (supabase_order_repository) · presentation (account, order details, status badge)
    ├── auth/      domain (app_user, auth_repository, safe_next_path) · data · presentation (AuthController, login, callback, RequireAuth)
    ├── admin/     domain (admin_repository, product_draft, image_hosts) · data · presentation (overview, products, orders)
    └── policies/  policy_page.dart (draft text)
frontend/test/                       # flutter_test
frontend/assets/fonts/               # bundled fonts + licences
seed/catalog.ts                      # single source of the starter catalogue
scripts/                             # generate-seed.ts, build_web.sh, serve_web.py
supabase/                            # migrations/0001_init.sql, seed.sql (generated), functions/send-order-confirmation
docs/SETUP.md                        # owner directives
```

New features get their own folder with the same three layers. Cross-feature code goes in `core/`
only when two or more features need it.

---

## 4. Separation of Concerns

Do not: put Supabase calls or table names in widgets; put business rules in presentation; navigate
from domain code; duplicate a rule across screens; grow god widgets or states (extract); create
`Utils` / `Helper` / `Manager` classes (name by responsibility: `safe_next_path.dart`, `money.dart`).
Before creating an abstraction, search for an existing one (`rg "class "` in `lib/`).

---

## 5. State Management

- **Server data** is loaded by pages through repositories (`AsyncView` provides loading / error with
  Retry / data states). Don't mirror it in global state.
- **Shared client state** is limited to two `ChangeNotifier`s: `CartController` and `AuthController`,
  read with `ListenableBuilder`. Keep logic out of them (rules live in domain files).
- **Local UI state** (form fields, selected size, busy flags) uses `StatefulWidget`.
- Don't add a state-management package (Provider, Riverpod, Bloc) without 🟡 human review.
- Dispose controllers and listeners. Don't call `setState` after `await` without checking `mounted`.

---

## 6. Dependency Injection

No container. `AppScope` (an `InheritedWidget`) carries the repositories and controllers; widgets
read them with `AppScope.of(context)` (`AppScope.read` in `initState`). Tests build `LookersApp` with
fakes (`test/helpers.dart`). Never construct a repository or `SupabaseClient` inside a widget.

---

## 7. Design System

**Direction:** **neumorphism ("soft UI") in purple hues, with light and dark modes.** Surfaces share the page
colour and are lifted (raised) or pressed in (inset) with a light highlight shadow (top-left) and a dark
shadow (bottom-right). Rounded corners everywhere, Jost typography, a purple primary. The layout pattern
(announcement strip, prominent search, category rail, product page structure) follows mainstream fast-fashion
shops; the look is Lookers' own. 🟡 **HUMAN REVIEW:** palette values and final brand look are the owner's call.

All visual values live in `lib/core/theme/`. **No raw colour** (`Color(0x…)`, `Colors.x`) outside that folder:
`test/design_system_test.dart` fails if one appears. Widgets use `AppColors`, `AppText`, `AppSizes` and the
neumorphic widgets in `lib/core/ui/neu.dart`.

**Dark mode.** `Palette.light` / `Palette.dark` in `app_colors.dart`. `AppColors.*` are getters that read the
*active* palette, so widgets never check the mode. `ThemeController` (persisted in localStorage; default
follows the OS) switches the palette, then `ThemeController.rebuildAll()` marks every element dirty so
widgets re-read colours while keeping state (typed text, scroll, selections). Rules for this to keep working:
read colours at build time (`AppColors.ink` inside `build`), **never cache an `AppColors` value in a `static
final`/field/`const`**, and give text styles `Color? color` defaults resolved at call time (see `AppText`).
The header sun/moon button toggles; `test/theme_test.dart` covers switching, persistence and that typed text
survives.

| Token (`AppColors`) | Light | Dark | Use |
|---|---|---|---|
| `background` | `#E6E1F3` | `#221C37` | Page and all raised surfaces |
| `surface` | `#DDD6EE` | `#1C1730` | Recessed areas: inset fields, panels, placeholders |
| `line` | `#CFC7E4` | `#342C50` | Faint dividers |
| `ink` / `inkSoft` / `inkMuted` | `#241C3D` / `#40375F` / `#5F5681` | `#F0ECFD` / `#D3CCEB` / `#A89FC8` | Text |
| `accent` | `#5B3FC4` | `#B9A5FF` | Links, focus, ratings, emphasis text |
| `accentSoft` | `#9B84E8` | `#7E64D8` | Decoration only (hover tints), never text |
| `primary` / `primaryDeep` / `onPrimary` | `#6342D6` / `#4A2FB0` / white | `#B7A2FF` / `#9B83F0` / `#1B1433` | Primary buttons (and pressed), text on them |
| `danger` / `success` | `#A32244` / `#2F6B4F` | `#FF8FA8` / `#7DD4A8` | Errors / confirmations |
| `shadowLight` / `shadowDark` | `#FBF9FF` / `#B9AFD8` | `#30284F` / `#130F23` | The two neumorphic shadows |
| `onPhoto`, `photoScrim*`, `clear` | white, ink scrim, transparent | same | Text over photos, overlays |

`test/theme_test.dart` enforces contrast in both modes: every text colour ≥ 4.5:1 on `background` (≥ 4:1 on
`surface`), and `onPrimary` ≥ 4.5:1 on `primary`/`primaryDeep`, plus that `shadowLight` is lighter and
`shadowDark` darker than the background (the effect needs that).

**Neumorphic widgets (`core/ui/neu.dart`):** `NeuBox` (raised or `inset: true`), `NeuButton` (primary purple /
`NeuButton.secondary`; sinks when pressed; same call shape as FilledButton), `NeuSelectable` (size chips,
swatches, payment options, category pills: raised idle, pressed when selected), `NeuIconButton` (round header
buttons with optional badge), `NeuTextField` (inset field, label above, error below), `NeuTapCard` (raised list
row). Don't use Material `FilledButton`/`OutlinedButton`/`TextField` directly. Use text buttons only for quiet
links. **Inset shadows** are painted with an even-odd path: do not use `Path.combine` (it flooded fields on the
web renderer). **Shadows need room:** keep ~24px gaps between raised cards or the shadows collide.

**Typography** (`AppText`): Jost for everything (`display()` headings, `body()`, `eyebrow()` small tracked
uppercase labels, `button()`); Pinyon Script for the logo only. Variable font weights via `fontVariations`.
**Shape:** rounded (cards 20-36, chips/buttons 14-16, photos 16-26). **Touch targets** ≥ 48px. **Breakpoints:**
mobile < 700, desktop ≥ 1000. **Header pattern:** purple announcement strip, raised bar with logo, search,
account, bag and theme toggle, category rail (desktop); on mobile the search sits under the logo row.
**App icon (all platforms):** the logo on a purple gradient, generated from the real `Logo` widget so they can't drift apart: run `scripts/make_icons.sh` (writes the web, Android and iOS icons, including maskable/adaptive versions with the mark kept inside the safe zone). Re-run it if the logo or purple palette changes.
**Logo:** `Logo` widget (cursive L over K, K in the accent purple; follows dark mode). 🟡 The owner may later
supply final artwork; replace the widget body, keep its parameters. **Images:** free Pexels photos.
**Product swatch colours** come from product data via `AppColors.fromHex` (the one place raw colour parsing is allowed).

---

## 8. UI/UX

- Every page handles **loading, empty, error (with Retry) and success** states: use `AsyncView`,
  `EmptyState`, `ErrorState`.
- Forms: visible labels, autofill hints, errors next to fields plus a top-level message; submit buttons
  show a busy state and are disabled while submitting (no double orders).
- Destructive admin actions ask for confirmation (delete product).
- Prices always via `formatMoney`; dates via `formatDate`.
- Mobile first: must work at 360px. Check shop grid, checkout and admin lists.
- Copy is calm and brand-appropriate: no exclamation marks, no jargon, never raw error text.
- Responsive behaviour uses `isMobile` / `isDesktop`; don't hard-code widths for whole pages.

---

## 9. Error Handling

Repositories throw `Failure(kind, message)`. Kinds: `validation`, `notFound`, `network`, `auth`,
`forbidden`, `outOfStock`, `server`, `unexpected`, `notConfigured`.

| Technical error | Becomes |
|---|---|
| `place_order` coded exception (`OUT_OF_STOCK:<slug>` …) | `mapPlaceOrderError` → friendly message |
| `PostgrestException` `42501` (RLS denied) | `forbidden` |
| Postgres unique violation `23505` (product slug) | validation message "slug already used" |
| Timeout, socket, client exceptions | `network` |
| Edge Function / Mailgun failure | swallowed by `PlaceOrder` (documented best effort) and logged server-side by order number |
| Missing Supabase settings | preview mode (`notConfigured`) |

**Supabase Dart gotcha:** `.order('col')` sorts **descending** by default. Always pass `ascending:` explicitly (this reversed the categories once).

Rules: users never see SQL text, status codes or stack traces. Never swallow errors silently; the
documented silent catches are: confirmation email, cart storage write, auth restore, shipping-rule
preview. Every request has a timeout (12–15 s).

---

## 10. Validation

Validate at every boundary; **the database is the last line** (CHECK constraints, RLS, `place_order`).

| Data | Where |
|---|---|
| Checkout address | `ShippingAddress.validate()` for feedback; `place_order` re-validates the same limits |
| Cart lines | DB checks: size ∈ product sizes, stock, active, quantity 1–10, ≤ 30 lines |
| Product form | `ProductDraft.validate()` (slug pattern, price `^\d{1,7}(\.\d{1,2})?$` → cents, stock integer, https image URL from allowed hosts); DB CHECKs (price ≥ 0, https image, slug pattern) |
| Order status | `OrderStatus.tryParse`; DB enum |
| `?next=` after login | `safeNextPath` (same-site relative paths only) |
| Stored cart | `parseStoredCart` (untrusted) |
| API rows | `productFromRow` / `orderFromRow` return null for malformed data |

When you change a limit, change it in the Dart validator **and** the SQL.

---

## 11. AI Integration

There are no AI features. If one is added: calls go through an Edge Function (never the browser), the
provider key is a Supabase secret, AI output is untrusted data validated before use, tests use a fake
client. 🟡 Adding any AI feature needs human review.

---

## 12. API and External Services

| Service | Used for | Where |
|---|---|---|
| Supabase (Postgres, Auth, Edge Functions) | Data, sign-in, RLS, email trigger | `data/` repositories, `supabase/` |
| Google Cloud Console (OAuth client) | Identity provider, **configured inside Supabase** | 🔧 OWNER STEP. No Google code or secret in this repo |
| Mailgun | Order confirmation email | Edge Function only |
| Pexels | Free product imagery (hotlinked) | `seed/catalog.ts`, `image_hosts.dart` |

Rules: all access goes through a repository; every request has a timeout; handle non-2xx explicitly;
a third-party failure must never break a core flow. Adding a new service (payments, shipping, analytics)
is 🟡 human review plus new 🔧 steps in `docs/SETUP.md`.

**Payments are not integrated.** Checkout records `pay_on_delivery`; the card option is a disabled screen.
When a provider is added, card fields must come from the provider's own hosted/embedded component so card
numbers never touch this app or our database. 🟡 The owner must choose a provider
(e.g. Stripe, Paystack, Flutterwave). Payment secrets can only live in an Edge Function; that decision
also changes the order flow (payment before/after order creation, webhooks, refunds).

---

## 13. Security

- **Never commit** `.env*`, `frontend/env.json`, keys, tokens or database passwords. Scan staged files
  before every commit.
- **RLS is on for every table** and is the real access control: customers read only their own orders;
  only admins write catalogue data or update order status; `profiles.role` can't be changed by users
  (column-level grants); orders are created only through `place_order`.
- **Admin checks are layered:** router redirect → `RequireAuth(adminOnly)` → RLS. The first two are
  convenience; **RLS is the boundary.** Never rely on hiding a button.
- **Authentication:** Google through Supabase. `SupabaseAuthRepository` validates with `auth.getUser()`.
- **Making someone an admin** is a manual SQL step by the owner (`docs/SETUP.md`). There is intentionally
  no UI or config list for it.
- The Edge Function forwards the caller's JWT, so a user can only trigger an email for their **own** order,
  and `claim_confirmation_email` makes each send one-shot (no spam by replay).
- Redirect targets are allow-listed (`safeNextPath`). Flutter renders text as text (no HTML injection);
  the Edge Function HTML-escapes every customer-supplied value in the email.
- Don't log personal data: log order numbers, not names, addresses or emails.
- 🟡 **Open items:** rate limiting on sign-in and checkout, bot protection, security headers / CSP at the
  host (static hosting config), a data-retention and deletion process.

---

## 14. Testing

`cd frontend && flutter test` (no network, no live services). Existing coverage: cart rules and controller,
shipping rule, address validation, `PlaceOrder` use case (email failure never fails an order, invalid input
never reaches the database), `place_order` error mapping, row parsing, catalogue filter/sort, product-form
validation, `safeNextPath`, design-token test, widget tests (header search, guest checkout needs sign-in, payment screen is display-only, product page requires colour and size, reviews show purchased variety, related items, admin guard).

Write tests for every domain function and error mapping, and a regression test for each bug. Edge cases:
empty/oversized cart, out-of-stock race, size not offered, hidden product in cart, double submit, session
expiring during checkout, blocked storage, Mailgun down, missing config.

The Edge Function's logic is covered by `node scripts/test_edge_function.mjs` (Supabase and Mailgun faked, so it proves our code, not the real services).

**Not automated yet (§27):** SQL / RLS behaviour (needs a Supabase test project or local `supabase start`),
the Edge Function against real Supabase/Mailgun, end-to-end browser flows. Until then, verify RLS by hand with two accounts after any
schema or policy change.

---

## 15. Code Quality

Before calling a task done (from `frontend/`):

```bash
~/fvm/versions/3.44.6/bin/dart format lib test
~/fvm/versions/3.44.6/bin/flutter analyze        # must print "No issues found!"
~/fvm/versions/3.44.6/bin/flutter test           # all pass
../scripts/build_web.sh                          # when UI/config changed
python3 ../scripts/serve_web.py                  # then check http://localhost:3000
# Deploy: ../scripts/deploy_vercel.sh [--prod], or push to main (GitHub Actions). Vercel's own Git builds are off.
```

Then: no unused code/imports, no `print`, no temporary TODOs, no raw colours (§7), check at 360px and
desktop width. Changing the catalogue seed: edit `seed/catalog.ts`, run `node scripts/generate-seed.ts`
(regenerates `supabase/seed.sql` and `seed_catalog.dart`).

---

## 16. Naming

Dart: `UpperCamelCase` types, `lowerCamelCase` members, `snake_case.dart` files, `_private` members.
SQL: `snake_case`, plural tables, `…_cents` money, `…_at` timestamps. Repositories: `list…`, `get…`,
`place…`; implementations `Supabase…Repository`. Domain terms: **product, category, bag/cart (UI says
"bag", code says `cart`), order, order item, shipping, customer, admin**. Equivalent things get equivalent
names; don't mix "item" and "product".

---

## 17. Comments

Explain **why**, not what. Good examples already present: why there is no service-role key, why the router
guard isn't the security boundary, why the DB re-prices, why the Mailgun call is in an Edge Function, why a
size chip uses `Align(widthFactor: 1)`. Public classes whose contract isn't obvious get a short `///` doc.

---

## 18. Dependencies

Before adding a package: does the project already solve it (`intl` for formatting, `go_router` for routing,
`supabase_flutter` for backend, `shared_preferences` for storage)? Is it maintained and necessary? Never add
a second package for the same job. Adding / removing / major-upgrading a dependency is 🟡 human review;
state the reason. Add with `flutter pub add`. Fonts are bundled, so don't add `google_fonts`.

---

## 19. Git Practices

One `main` branch (🟡 owner to confirm hosting/CI). Short imperative commit subjects. Run `git status`,
`git diff`, `git diff --staged` before committing and check for secrets and bulk (`frontend/build/`,
`.dart_tool/`). Don't rewrite shared history or bundle unrelated refactors. Schema changes go in a **new
numbered migration** (`supabase/migrations/000N_name.sql`) once the first one has been applied; never edit
an applied migration. Generated files (`seed.sql`, `seed_catalog.dart`) are not edited by hand.

---

## 20. Agent Workflow

1. Read the relevant code and this file. 2. Find existing patterns to reuse. 3. Decide the layer (§2–3).
4. List edge cases. 5. Implement the smallest solution. 6. Format → analyze → test → build. 7. Check in a
browser. 8. Review the diff. 9. Report what was and wasn't verified.

**Verify before assuming.** Confirm a file, class, table, function or env var exists before using it. Never
fabricate APIs. If this document and the code disagree, the code shows what *is*; §27 lists known gaps.
After rebuilding, browsers may serve the old build: `scripts/serve_web.py` sends `Cache-Control: no-cache`;
otherwise hard-refresh.

**Third-party integrations:** an agent writes the code and directives, but never creates accounts, enters or
invents keys, or edits production dashboards. Add each new manual step to `docs/SETUP.md` as a numbered
directive for the owner.

---

## 21. Change Discipline

Small incremental changes. Refactors keep behaviour. Migrate gaps in §27 when touching those areas. Don't add
architecture for its own sake.

---

## 22. Performance

Extract widgets and use `const`; use `GridView.builder` / lazy builders for long lists (current grids are
`shrinkWrap` inside a page scroll, fine for tens of items; revisit with pagination for hundreds). Don't
refetch what a page already has; query only the columns needed. Product photos are requested at `w=900`;
keep Pexels `auto=compress`. Don't optimise before measuring. 🟡 Initial load: Flutter web CanvasKit is
~2 MB+; consider the build's renderer settings if first load matters.

---

## 23. Accessibility

Target WCAG 2.1 AA. Contrast ≥ 4.5:1 with the tokens (never text on `accentSoft`). Icon-only controls have
`tooltip` / `Semantics(label)`. Touch targets ≥ 48px. Errors appear as text near the problem, not colour
alone; order status is a word plus colour. Live changes (cart count, "Added to your bag", errors) use
`Semantics(liveRegion: true)`. Keyboard: all actions reachable with Tab/Enter. Flutter web's accessibility
tree must be enabled by the user's assistive tech (🟡 consider auto-enabling semantics at startup).

---

## 24. Documentation

Update `README.md` and `docs/SETUP.md` when you add env keys, services, setup steps, routes, scripts.
Update §1 and §27 of this file when behaviour or gaps change.

---

## 25. Definition of Done

- [ ] Works, verified in a browser (mobile width too).
- [ ] Layers respected (§2); no Supabase call in a widget, no rule in presentation.
- [ ] `analyze` clean, formatted, all tests pass, release build succeeds.
- [ ] Loading / empty / error / success states handled.
- [ ] Validation in the UI **and** enforced by the database for anything security- or money-related.
- [ ] Tests added (incl. regression tests).
- [ ] No secrets, debug prints or raw colours.
- [ ] Docs updated; new owner steps added to `docs/SETUP.md`.
- [ ] Honest report of what was and wasn't verified.

---

## 26. Human Review

Stop and present options for: ambiguous product requirements; the **payment provider and flow**;
authentication/authorisation changes (roles, new providers); schema changes that alter or delete data;
security-sensitive changes (RLS, secrets, a service-role key, CORS); hosting, domains and the Vercel plan (Hobby is non-commercial); adding
dependencies; final brand/design values and logo artwork; legal text (policies are drafts); shipping rules,
currency and tax; SEO strategy (§27); anything that could lose customer or order data.

---

## 27. Current state vs. this contract

| Area | Today | Target |
|---|---|---|
| Supabase | Schema, RLS, seed and Edge Function written, **not yet applied** | 🔧 Project created, migration + seed run, function deployed |
| Google sign-in | Code done; needs 🔧 Google OAuth client + Supabase provider config | Working end to end |
| Mailgun | Edge Function done; needs 🔧 domain, key and `supabase secrets set` | Verified domain, test email received |
| Payments | Pay on delivery only | 🟡 Provider chosen and integrated |
| Real-backend verification | Everything that touches Supabase (auth, RLS, `place_order`, Edge Function, admin writes) is **untested against a live project** | Manual two-account test, then automated |
| SQL / RLS / Edge Function tests | None automated | Local Supabase or test project in CI |
| E2E tests | None | Browser smoke: browse → bag → checkout |
| SEO | A Flutter web app renders on a canvas: crawlers see little, no per-page titles/meta, no sitemap | 🟡 Decide: prerendered landing/product pages, or a hybrid (e.g. static pages for marketing) |
| Security headers / CSP | None (static host config) | 🟡 Set at the host |
| Accessibility | Semantics labels added; web semantics tree not auto-enabled | Auto-enable, audit with a screen reader |
| Mobile builds | Android debug APK and iOS simulator build compile; Android is checked in CI. iOS is checked locally only (macOS runners cost more) | Release signing (Android keystore, Apple team), store listings |
| Apple guideline 4.8 | Google is the only sign-in; Apple may reject an iPhone app that offers Google without Sign in with Apple | 🟡 Add Sign in with Apple (needs Apple Developer account + Supabase provider) |
| Account deletion | Not built; both stores require in-app deletion for apps with accounts | Delete-my-account action (SQL function + UI) |
| Mobile polish | No splash screen branding beyond defaults, no push notifications, no biometric lock | Branded splash, order-status push |
| Order cancel | Status change does not restock | Restock trigger |
| Product images | Pasted URLs from allowed hosts | Supabase Storage upload + multiple images |
| Category admin | Categories only via SQL | Admin UI |
| Customer profile | Name/email read-only | Edit profile, saved addresses |
| Rate limiting / bots | None | 🟡 Limits and CAPTCHA |
| CI / hosting | Workflow and deploy script written (Vercel hosts the prebuilt `frontend/build/web`); needs 🔧 owner steps (docs/SETUP.md step 6). Never run | Live site, pipeline green on `main` |
| Legal pages | Draft text | Reviewed by owner/legal |
| Sample products | Placeholder data | Real products entered in admin |
| Reviews | Dummy reviews seeded; customers can't write reviews | 🟡 Verified-buyer reviews (written through a SQL function that checks the purchase); remove dummies |
| Product photos per colour | One gallery for all colours; gallery photos are stand-ins from the same category | Per-colour images from the owner |
| Stock | Per product | Per size/colour variant |
| Search | Name/description substring match with suggestions | Ranking, typo tolerance (e.g. Postgres full-text) |

---

## Appendix: routes and data

| Route | Access | Notes |
|---|---|---|
| `/`, `/shop`, `/product/:slug`, `/cart`, `/policies/:slug` | Public | `/shop?category=&q=&sort=` |
| `/login`, `/auth/callback` | Public | Signed-in users are forwarded to `next` |
| `/checkout` | Public (form); placing the order needs sign-in | Guests are prompted to sign in when they press the button |
| `/checkout/success?order=` | Signed in | Redirect to `/login?next=…` |
| `/account`, `/account/orders/:id` | Signed in (own orders) | |
| `/admin`, `/admin/products[/new\|/:id]`, `/admin/orders[/:id]` | Admin | Non-admins are redirected home |

Tables: `profiles`, `categories`, `products` (with `colors`, `images`, `rating_*`), `reviews`, `store_settings`, `orders`, `order_items` (with `color`).
Functions: `place_order`, `claim_confirmation_email`, `release_confirmation_email`, `is_admin`.
Edge Function: `send-order-confirmation`. Build config keys: see `frontend/env.example.json`.
