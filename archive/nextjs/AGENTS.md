<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# AGENTS.md — Lookers

The engineering contract for any AI coding agent working on **Lookers**. Read all of it before
changing anything. Where this document describes a target the code doesn't meet yet, the gap is
listed in [§27](#27-current-state-vs-this-contract). Do not assume the target already exists.

> **🟡 HUMAN REVIEW** marks a decision an agent must not make alone. Explain the options and
> trade-offs, then wait for a human.
>
> **🔧 OWNER STEP** marks work only the owner can do (creating accounts, keys, dashboards).
> An agent never does these; it gives the owner clear directives (see `docs/SETUP.md`).

Carried over from the owner's Task App contract: Clean Architecture, feature folders,
design tokens enforced by a test, failures instead of raw errors, validation at every
boundary, "Definition of Done", human-review gates.

---

## 1. Project Context

**What it is.** Lookers is an e-commerce website for a clothing brand of the same name, in a
luxury-editorial style. Logo: a large cursive **L** with a **K** beneath it (`core/ui/Logo.tsx`).

**Categories:** Men's Clothing, Women's Clothing, Baby's Clothing, Hats, Shoes, Bags & Accessories
(rows in the `categories` table; seed in `seed/catalog.ts`).

**Priorities (owner's order):** 1) Authentication, 2) the customer dashboard, 3) checkout,
4) the Supabase database, 5) the admin dashboard. Everything else is secondary.

**Implemented today:**

- Storefront: home, shop (category filter, search, sort), product page (size picker, stock
  badges, JSON-LD), bag (`/cart`), policy pages, 404, `robots.txt`, `sitemap.xml`, security headers.
- **Auth:** Google sign-in via Supabase Auth; `/login`, `/auth/callback`, `/auth/signout` (POST).
  Session refreshed in `src/proxy.ts`.
- **Customer dashboard** (`/account`, `/account/orders/[id]`): order history and details.
- **Checkout** (`/checkout`, `/checkout/success`): contact + address form, server-side
  validation, atomic order placement via the `place_order` SQL function (prices, stock and
  shipping decided in the database), **pay on delivery**.
- **Confirmation email** via Mailgun after each order (best effort, never blocks an order).
- **Admin dashboard** (`/admin`): overview (revenue, orders, pending, customers, low stock),
  products (create, edit, hide, delete), orders (view, change status).
- **Database:** Supabase Postgres with Row Level Security (`supabase/migrations/0001_init.sql`).

**Not implemented (do not write code or docs that assume otherwise):** online card payment,
wishlist, reviews, discount codes, product image upload (admins paste image URLs), multiple
images per product, category management UI, order cancellation restocking, refunds/returns
flow, shipping carriers/tracking, email-verified marketing list, multi-currency, i18n,
analytics, AI features, a mobile app.

**Preview mode.** With no Supabase env vars the site serves the bundled sample catalogue
(`seed/catalog.ts`) so the design can be viewed. Sign-in, checkout, account and admin need the
database and show "not connected" states. Keep this working.

**Technologies**

| Part | Technology |
|---|---|
| Web app | **Next.js 16** (App Router, Server Components, Server Actions, `proxy.ts`), React 19, TypeScript (strict), Tailwind CSS v4 |
| Database + Auth | **Supabase** (Postgres, RLS, Auth with Google), `@supabase/ssr`, `@supabase/supabase-js` |
| Email | **Mailgun** HTTP API (`core/email/mailgun.ts`, plain `fetch`) |
| Validation | `zod` |
| Tests | `vitest` (node environment) |
| Fonts | Cormorant Garamond (display), Jost (body), Pinyon Script (logo) via `next/font/google` |
| Images | Free Pexels photos through `next/image`; allowed hosts in `core/imageHosts.ts` |
| Hosting | 🟡 Not decided. Vercel is the expected target (see `docs/SETUP.md`). |

**Constraints**

- **Secrets stay on the server.** Only `NEXT_PUBLIC_*` values reach the browser. There is
  deliberately **no Supabase service-role key** in this project: everything runs as the signed-in
  user under RLS, and privileged work happens in `SECURITY DEFINER` SQL functions. Do not add a
  service-role key without 🟡 human review.
- **Money is integer cents everywhere** (`price_cents`, `priceCents`). Convert only for display
  (`core/formatting/money.ts`).
- **The browser never decides a price.** The cart sends `{slug, size, quantity}` only; the
  database re-prices. A test asserts a client-sent price is dropped.
- **The database is authoritative** for stock, shipping rules (`store_settings`) and order totals.
  `features/checkout/domain/shipping.ts` only previews and must mirror the SQL.
- **Next.js 16 specifics:** `params` / `searchParams` / `cookies()` are async; middleware is
  now `src/proxy.ts`; use the global `PageProps<'/route'>` / `LayoutProps<'/route'>` helpers
  (run `npx next typegen` after adding routes). Read `node_modules/next/dist/docs/` first.
- **Cart** lives in `localStorage` (`lookers.cart.v1`), read with `useSyncExternalStore`.
  Never read `window` during render; never put cart state in a server component.

---

## 2. Architecture

```
Presentation (app/ routes, components)  ──►  Domain  ◄──  Data (Supabase, Mailgun)
```

| Layer | Contains | May depend on | Must not depend on |
|---|---|---|---|
| **Domain** (`features/*/domain`) | Types, pure rules, zod schemas, calculations | TypeScript, `zod` | React, Next, Supabase, `fetch`, env |
| **Data** (`features/*/data`, `core/supabase`, `core/email`) | Queries, row → entity mapping, RPC calls, HTTP clients | Domain, Supabase, `fetch` | Presentation |
| **Presentation** (`app/`, `features/*/presentation`, `core/ui`) | Pages, components, server actions (thin), formatting | Domain, Data (through repositories) | Raw SQL / table names |

Rules:

- **Business rules never live in components.** "Free shipping over X", cart merge rules, stock
  labels, `safeNextPath`, status sets: all in domain files with tests.
- **Components never build queries.** They call repository functions.
- **Server actions are thin:** authenticate → validate (zod) → call a repository → send side
  effects → redirect/return state. See `app/checkout/actions.ts`.
- **Data layer converts** rows into domain types once (`toProduct`, `toOrder`) and DB errors
  into `Failure`s (`core/errors/failures.ts`). A malformed row is dropped, never a crash.
- Prefer reusing an existing function. Search (`rg "export function"`) before adding one.

---

## 3. Feature Organization

```
src/
├── proxy.ts                         # session refresh + convenience redirects for /account /checkout /admin
├── app/                             # routes only: thin pages that compose features
│   ├── (storefront) page.tsx, shop/, product/[slug]/, cart/, policies/[slug]/
│   ├── login/, auth/{callback,signout}/
│   ├── checkout/{page,actions.ts,success/}
│   ├── account/, account/orders/[id]/
│   └── admin/{layout,page,actions.ts,products/,orders/}
├── core/                            # shared, feature-agnostic
│   ├── config.ts                    # the ONLY place env vars are read
│   ├── supabase/{server,browser}.ts
│   ├── email/mailgun.ts
│   ├── errors/failures.ts           # Result<T> + FailureKind
│   ├── formatting/money.ts
│   ├── imageHosts.ts
│   └── ui/                          # Logo, SiteHeader, SiteFooter
└── features/
    ├── catalog/   domain (product.ts) · data (catalogRepository.ts) · presentation (ProductCard, AddToBag)
    ├── cart/      domain (cart.ts) · presentation (CartProvider, CartView, CartLink)
    ├── checkout/  domain (shipping.ts, checkoutSchema.ts) · settingsRepository.ts · presentation (CheckoutForm)
    ├── orders/    domain (order.ts) · data (orderRepository.ts) · emails/ · presentation (OrderDetails, StatusBadge)
    ├── auth/      domain (safeNextPath.ts) · data (session.ts) · presentation (GoogleButton)
    └── admin/     domain (productSchema.ts) · data (adminRepository.ts, categories.ts) · presentation (ProductForm)
seed/catalog.ts                      # single source of the starter catalogue
supabase/{migrations/0001_init.sql, seed.sql (generated)}
scripts/generate-seed-sql.ts
test/                                # vitest
docs/SETUP.md                        # owner directives for Supabase, Google, Mailgun, deploy
```

New features get their own folder with the same three layers. Cross-feature code goes in
`core/` only when two or more features need it.

---

## 4. Separation of Concerns

Do not: put queries or table names in components; put business rules in presentation; put
navigation in domain code; duplicate a rule across screens; grow god components (extract);
create `utils`/`helpers`/`manager` dumping grounds (name by responsibility:
`safeNextPath.ts`, `money.ts`).

---

## 5. State Management

- **Server state** (catalogue, orders, user) is fetched in Server Components via repositories.
  Mutations are Server Actions followed by `revalidatePath` / redirect. Don't mirror server data
  into client state.
- **Client state** is limited to: the cart (`CartProvider`), form pending/error state
  (`useActionState`), and UI toggles (size selection). Keep it minimal.
- The cart store is module-level with `useSyncExternalStore`; add cart operations as pure
  functions in `cart.ts`, then expose them in `CartProvider`.
- Don't add a state library (Redux, Zustand) without 🟡 review.

---

## 6. Dependency Injection

No container. Dependencies are passed as arguments: repositories take a `SupabaseClient`
(`placeOrder(supabase, …)`), `sendEmail(email, fetchImpl = fetch)` accepts a fetch for tests.
Create the Supabase client once per request at the route/action boundary
(`createSupabaseServerClient()`), then pass it down. Tests use fakes, never live services.

---

## 7. Design System

**Direction:** luxury editorial, inspired by the owner's Behance reference
(*AI Luxury Fashion E-Commerce Website Design*). The reference page could not be fetched by the
agent (HTTP 403), so the look is an interpretation: ivory canvas, near-black ink, antique gold
accent, large serif headlines, wide-tracked uppercase labels, generous whitespace, full-bleed
photography. 🟡 **HUMAN REVIEW:** the owner should compare against the reference and request
adjustments (colours, type, layout).

All visual values are **tokens in `src/app/globals.css`** and used through Tailwind names.
`test/designSystem.test.ts` fails if a raw hex colour appears in `src/` outside that file (allowed:
the email template, which needs inline literals, and the Google logo).

| Token (Tailwind name) | Value | Use |
|---|---|---|
| `background` | `#faf7f1` | Page |
| `surface` | `#f3eee4` | Panels, image placeholders |
| `line` | `#e8e0d0` | Borders, dividers |
| `ink` / `ink-soft` / `ink-muted` | `#14110f` / `#3a342f` / `#6b635b` | Text (all ≥ 4.5:1 on `background`) |
| `gold` | `#b08d57` | Decoration, selection only. Not for text. |
| `gold-deep` | `#8f6f3f` | Accent text/links, hover |
| `danger` | `#6e1f2b` | Errors, "few left" |
| `success` | `#3f5a45` | Confirmations |
| `paper` | `#ffffff` | Cards, inputs |

**Typography:** `font-display` (Cormorant Garamond) for headings via `.display`; `font-sans`
(Jost) for body; `font-script` (Pinyon Script) for the logo only. Labels use `.eyebrow`.
**Components:** use `.btn`, `.btn-ghost`, `.field`, `.label`, `.container-page` from
`globals.css`. Touch targets ≥ 44px (`min-h-11`/`min-h-12`).
**Logo:** `core/ui/Logo.tsx` (SVG text in Pinyon Script, gold K under ink L). 🟡 The owner may
later supply a final artwork file; replace the component body, keep the props.
**Images:** free Pexels photos (licence: free, no attribution required). Hotlinked via
`images.pexels.com`, optimised by `next/image`. Add new hosts in `core/imageHosts.ts` only.

---

## 8. UI/UX

- Every page handles **loading, empty, error and success** states. Examples: empty bag, no
  search results, "Sold out" / "Few left", checkout field errors + a top-level alert, 404.
- Forms: visible labels, `autoComplete` attributes, errors next to the field and as text.
- Destructive/irreversible admin actions have an explanatory note (delete product).
- Prices always use `formatMoney`. Dates use `formatDate`.
- Don't use browser `alert`/`confirm`.
- Mobile first: the layout must work at 360px. Check the shop grid, checkout and admin tables
  (tables scroll horizontally in `overflow-x-auto`).
- Copy is calm and brand-appropriate: no exclamation marks, no jargon, no raw error text.

---

## 9. Error Handling

Data-layer functions return `Result<T>` (`ok` / `fail`) or domain values. `FailureKind`s:
`validation`, `not_found`, `network`, `auth`, `forbidden`, `out_of_stock`, `external_service`,
`server`, `unexpected`, `not_configured`.

| Technical error | Becomes |
|---|---|
| `place_order` coded exception (`OUT_OF_STOCK:<slug>` etc.) | `mapPlaceOrderError` → friendly message |
| Postgres unique violation `23505` (product slug) | field error "Choose a different slug." |
| Mailgun non-2xx / network error | `external_service` / `network` (logged by order number only; never blocks the order) |
| Missing env (Supabase / Mailgun) | `not_configured` (preview mode / emails skipped) |
| Unknown / unexpected DB error | `server`, generic message |

Rules: users never see SQL text, status codes or stack traces. Never swallow errors silently:
the only silent catches are documented (cart `localStorage` blocked; `setAll` cookies in Server
Components). Use `notFound()` for missing/foreign records (RLS makes other people's orders look
missing).

---

## 10. Validation

Validate at every boundary; the **database is the last line** (CHECK constraints, RLS, the
`place_order` function).

| Data | Where |
|---|---|
| Checkout address, notes | `shippingSchema` (zod) in the server action; DB NOT NULL columns |
| Cart lines | `cartLinesSchema`: slug pattern, size ≤ 20, quantity 1–10, max 30 lines. Unknown keys (e.g. a price) are dropped. DB re-checks size ∈ product sizes, stock, active |
| Product form (admin) | `productSchema`: slug pattern, price `^\d{1,7}(\.\d{1,2})?$` → cents, stock integer, https image URL from allowed hosts |
| Order status | `isOrderStatus` allow-list; DB enum |
| `?next=` redirect after login | `safeNextPath` (same-site relative paths only) |
| Order / product ids in URLs | UUID shape check before querying |
| Stored cart (localStorage) | `parseStoredCart` (treated as untrusted) |

---

## 11. AI Integration

There are no AI features. If one is added: calls go through a server route/action (never the
browser), the provider key is a server env var, AI output is untrusted data validated with zod,
and tests use a fake client. 🟡 Adding any AI feature needs human review.

---

## 12. API and External Services

| Service | Used for | Where |
|---|---|---|
| Supabase (Postgres, Auth) | Data, sign-in, RLS | `core/supabase/*`, repositories, `supabase/migrations` |
| Google Cloud Console (OAuth client) | Identity provider **configured inside Supabase** | 🔧 OWNER STEP, `docs/SETUP.md`. No Google code or secret in this repo. |
| Mailgun | Order confirmation email | `core/email/mailgun.ts`, `features/orders/emails/` |
| Pexels | Free product imagery (hotlinked) | `seed/catalog.ts`, `core/imageHosts.ts` |

Rules: every outbound HTTP call has a timeout (Mailgun: 10 s); handle non-2xx explicitly; never
let a third-party failure break a core flow (order placement); never send secrets to the browser.
Adding a new service (payments, shipping, analytics) is 🟡 human review plus new 🔧 owner steps
in `docs/SETUP.md`.

**Payments are not integrated.** Checkout records `payment_method = 'pay_on_delivery'`.
🟡 The owner must choose a provider (e.g. Stripe, Paystack, Flutterwave) based on country and
currency; that decision also changes the order flow (payment before/after order creation,
webhooks, refunds).

---

## 13. Security

- **Never commit** `.env*` (git-ignored), keys, tokens or database passwords. `.env.example`
  documents variable names only. Scan staged files before every commit.
- **RLS is on for every table** and is the real access control. Customers read only their own
  orders; only admins write catalogue data or update order status; `profiles.role` cannot be
  changed by users (column-level grants); orders are created only through `place_order`.
- **Admin checks are layered:** `proxy.ts` (convenience) → `app/admin/layout.tsx`
  (`requireAdmin`) → every admin server action calls `requireAdmin()` again → RLS. Never rely
  on hiding a link.
- **Authentication:** always use `supabase.auth.getUser()` (validated server-side) for
  decisions, not `getSession()` / the raw cookie.
- **Making someone an admin** is a manual SQL step run by the owner in Supabase
  (`docs/SETUP.md`). There is intentionally no UI or env-based admin list.
- Sign-out is POST-only. Redirect targets are allow-listed (`safeNextPath`).
- User-supplied text is rendered as React text; the email template HTML-escapes every value
  (tested). The only `dangerouslySetInnerHTML` is JSON-LD, with `<` escaped.
- Don't log personal data. Log order numbers / ids, not names, addresses or emails.
- Security headers are set in `next.config.ts`.
- 🟡 **Open items:** rate limiting on checkout and sign-in, bot protection (CAPTCHA), a
  Content-Security-Policy, and a data-retention/deletion process.

---

## 14. Testing

Testing is part of the feature. `npm test` (vitest, no network, no live services).

Existing coverage: cart rules, shipping rule, checkout/cart schemas, `safeNextPath`, email
escaping + Mailgun client (mocked `fetch`), `place_order` error mapping, design-token test.

Write tests for: every domain function, every zod schema (valid, invalid, hostile input), every
error mapping, email content, and each bug fix (regression test). Edge cases to consider:
empty/oversized cart, out-of-stock race, size not offered, hidden product in cart, double
submit, expired session mid-checkout, blocked localStorage, Mailgun down, missing env.

**Not automated yet (§27):** SQL/RLS behaviour (needs a Supabase test project or local
`supabase start`), end-to-end browser flows. Until then, verify RLS by hand with two accounts
after any schema or policy change.

---

## 15. Code Quality

Before calling a task done:

```bash
npm run lint
npm run typecheck
npm test
npm run build          # when routes, config or UI changed
```

Then check the change in a browser (`npm run dev`, http://localhost:3000), including a narrow
(360px) window. Also: no unused code/imports, no `console.log` (the single allowed
`console.error` is the email-failure log), no leftover TODOs, no raw colours (§7).

---

## 16. Naming

- Components/types `PascalCase`; functions/variables `camelCase`; constants `UPPER_SNAKE_CASE`;
  files: components `PascalCase.tsx`, everything else `camelCase.ts`; routes lowercase.
- Domain terms: **product, category, bag/cart (UI says "bag"; code says `cart`), order, order
  item, shipping, customer, admin**. Don't mix in "item" for product or "basket".
- Repository functions: `list…`, `get…`, `place…`. Server actions end in `Action`.
- SQL: `snake_case`, plural table names, `…_cents` for money, `…_at` for timestamps.

---

## 17. Comments

Explain **why**, not what. Good examples already present: why there is no service-role key,
why the proxy isn't the security boundary, why the email template has inline hex, why the cart
uses `useSyncExternalStore`, why the DB re-prices. Add a short doc comment to public functions
whose contract isn't obvious.

---

## 18. Dependencies

Before adding a package: does the project already solve it (zod for validation, `fetch` for
HTTP, Tailwind for styling, `Intl` for formatting)? Is it maintained and necessary? Never add a
second library for the same job. Adding/removing/major-upgrading a dependency is 🟡 human
review; state the reason. Don't add a Mailgun SDK (the HTTP call is ~20 lines), an ORM, or a UI
kit without review.

---

## 19. Git Practices

One `main` branch (🟡 owner to confirm hosting/CI). Short imperative commit subjects. Run
`git status`, `git diff`, `git diff --staged` before committing and check for secrets and bulk
(`.next/`, `node_modules/`). Don't rewrite shared history, don't bundle unrelated refactors.
Schema changes go in a **new numbered migration** (`supabase/migrations/000N_name.sql`); never
edit an applied migration. `supabase/seed.sql` is generated: edit `seed/catalog.ts` and run
`npm run db:seed-sql`.

---

## 20. Agent Workflow

1. Read the relevant code and this file. For Next.js APIs, read `node_modules/next/dist/docs/`.
2. Find existing patterns to reuse. 3. Decide the layer (§2–3). 4. List edge cases.
5. Implement the smallest solution. 6. `lint` → `typecheck` → `test` → `build`.
7. Check in the browser. 8. Review the diff. 9. Report what was and wasn't verified.

**Verify before assuming.** Confirm a file, table, function or env var exists before using it.
Never fabricate APIs. If this document and the code disagree, the code shows what *is*; §27
lists known gaps.

**Third-party integrations:** an agent writes the code and the directives, but never creates
accounts, never enters or invents keys, and never edits production dashboards. Add each new
manual step to `docs/SETUP.md` as a numbered directive for the owner.

---

## 21. Change Discipline

Small incremental changes. Refactors keep behaviour. Migrate gaps in §27 when touching those
areas. Don't add architecture for its own sake.

---

## 22. Performance

Default to Server Components; add `"use client"` only for interactivity. Use `next/image` with
accurate `sizes`, `priority` only for above-the-fold images. Don't refetch what the page
already has. Query only the columns needed. Index columns used in filters (`products_category_idx`,
`orders_user_idx`). Don't optimise before measuring. 🟡 Caching strategy for the catalogue
(`revalidate`/ISR) is open; pages are currently dynamic when Supabase is configured.

---

## 23. Accessibility

Target WCAG 2.1 AA. Text contrast ≥ 4.5:1 using the tokens (never put text on `gold`). Every
control reachable by keyboard; icon-only controls get `aria-label`. Form fields have labels and
`aria-invalid` / `aria-describedby` for errors. Status is never colour-only (order badges show
words; "Sold out" is text). Cart changes are announced (`role="status"`, `aria-live`). One `h1`
per page. Respect reduced motion for any new animation.

---

## 24. Documentation

Update `README.md` and `docs/SETUP.md` when you add: env vars, services, setup steps, routes,
scripts. Update §1 and §27 of this file when behaviour or gaps change.

---

## 25. Definition of Done

- [ ] Works, verified in a browser for UI changes (mobile width too).
- [ ] Layers respected (§2); no query in a component, no rule in presentation.
- [ ] `lint`, `typecheck`, `test`, `build` pass.
- [ ] Loading / empty / error / success states handled.
- [ ] Validation on the server; RLS/DB constraints updated for any new data.
- [ ] Tests added (incl. regression test for bugs).
- [ ] No secrets, debug logging or raw colours.
- [ ] Docs updated; new owner steps added to `docs/SETUP.md`.
- [ ] Honest report of what was and wasn't verified.

---

## 26. Human Review

Stop and present options for: ambiguous product requirements; the **payment provider and
payment flow**; authentication/authorisation changes (roles, new providers); schema changes
that alter or delete data; security-sensitive changes (RLS, headers, CORS, secrets, a
service-role key); hosting and domains; adding dependencies; final brand/design values and the
logo artwork; legal text (policies are draft placeholders); shipping rules and currency; tax
handling; anything that could lose customer or order data.

---

## 27. Current state vs. this contract

| Area | Today | Target |
|---|---|---|
| Supabase | Schema, RLS and seed are written but **not yet applied**: needs 🔧 owner steps | Project created, migration + seed run, env vars set |
| Google sign-in | Code done; needs 🔧 Google Cloud OAuth client + Supabase provider config | Working end to end |
| Mailgun | Code done; needs 🔧 domain + API key. Emails are skipped when unset | Verified domain, test email received |
| Payments | Pay on delivery only | 🟡 Provider chosen and integrated |
| RLS / SQL tests | None automated | Local Supabase or test project in CI |
| E2E tests | None | Playwright smoke: browse → bag → checkout |
| Order cancel | Status change does not restock | Restock on cancel (SQL trigger) |
| Product images | Pasted URLs from allowed hosts | Supabase Storage upload + multiple images |
| Category admin | Categories only via SQL | Admin UI |
| Customer profile | Name/email read-only | Edit profile, saved addresses |
| Rate limiting / bots | None | 🟡 Per-IP limits, CAPTCHA on sign-in/checkout |
| CSP | Basic headers only | 🟡 Content-Security-Policy |
| CI / hosting | None | 🟡 Pipeline running lint, typecheck, test, build; deployment |
| Legal pages | Draft text | Reviewed by the owner/legal |
| Preview catalogue | Sample products are placeholders | Final product data entered by the owner in admin |

---

## Appendix: routes and data

| Route | Access | Notes |
|---|---|---|
| `/`, `/shop`, `/product/[slug]`, `/cart`, `/policies/[slug]` | Public | |
| `/login`, `/auth/callback`, `/auth/signout` | Public | Signed-in users are redirected from `/login` |
| `/checkout`, `/checkout/success` | Signed in | Redirect to `/login?next=…` |
| `/account`, `/account/orders/[id]` | Signed in (own orders) | |
| `/admin`, `/admin/products[/new\|/id]`, `/admin/orders[/id]` | Admin | Non-admins are redirected home |

Tables: `profiles`, `categories`, `products`, `store_settings`, `orders`, `order_items`.
Function: `place_order(p_items, p_shipping, p_notes)`. Helper: `is_admin()`.
Env vars: see `.env.example`.
