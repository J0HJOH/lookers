# Lookers setup: steps only you can do

The code is written. These steps need your own accounts, so you do them. Go in order and tick them off.

Keep every key private. Never paste keys into chat, code files or git. Where each one goes is stated
below. The Flutter app is public code, so it only ever receives the Supabase **URL** and **publishable
key**. The Mailgun key goes into Supabase, never into the app.

---

## 0. Run the site in preview mode (no accounts needed)

```bash
cd ~/projects/lookers/frontend
~/fvm/versions/3.44.6/bin/flutter pub get
~/fvm/versions/3.44.6/bin/flutter run -d chrome --web-port 3000
```

(If `flutter` is already on your PATH for this folder, plain `flutter run -d chrome --web-port 3000` works.)
You'll see the full design with a sample catalogue and a "Preview mode" banner. Sign-in, checkout,
account and admin stay disabled until steps 1-4. **Always use port 3000**: Supabase's allowed redirect
addresses depend on it.

---

## 1. Supabase (database + login backend)

1. https://supabase.com → **New project**. Name it `lookers`, pick the region closest to your customers,
   and save the **database password** in your password manager.
2. **Project Settings → API** (or **Connect**). Copy:
   - **Project URL**
   - **Publishable key** (older projects call it *anon public*)

   Do **not** use the `service_role` / secret key anywhere. This project doesn't need it.
3. In `frontend/`, copy `env.example.json` to `env.json` and fill it in:

```json
{
  "SUPABASE_URL": "https://abcdxyz.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_...",
  "CURRENCY": "USD"
}
```

   `env.json` is git-ignored.
4. Supabase → **SQL Editor → New query**. Paste all of `supabase/migrations/0001_init.sql`, press **Run**.
   It should say "Success".
5. New query again. Paste `supabase/seed.sql` and **Run**: 6 categories and 23 sample products.
6. Check **Table Editor**: `categories`, `products`, `orders`, `order_items`, `profiles`, `store_settings`.
7. Run the app with your settings (the preview banner should disappear):

```bash
cd frontend
~/fvm/versions/3.44.6/bin/flutter run -d chrome --web-port 3000 --dart-define-from-file=env.json
```

---

## 2. Google sign-in (Google Cloud Console + Supabase)

**A. Get your Supabase callback address**
Supabase → **Authentication → Sign In / Providers → Google**. Copy the **Callback URL**
(`https://<project-ref>.supabase.co/auth/v1/callback`). Keep the tab open.

**B. Create the Google credentials**
1. https://console.cloud.google.com → create a project named `Lookers`.
2. **APIs & Services → OAuth consent screen** (or *Google Auth Platform → Branding*):
   - User type **External**, app name `Lookers`, your support and developer emails.
   - Keep the default scopes (`email`, `profile`, `openid`).
   - Add your own Google account as a **test user** while the app is in *Testing*.
3. **Credentials → Create credentials → OAuth client ID**:
   - Type **Web application**, name `Lookers web`.
   - **Authorized JavaScript origins:** `http://localhost:3000` (add your real domain later).
   - **Authorized redirect URIs:** the Supabase **Callback URL** from step A, and only that.
4. Create, then copy the **Client ID** and **Client secret**.

**C. Give them to Supabase**
1. Supabase → **Authentication → Sign In / Providers → Google**: switch **on**, paste the Client ID and
   Client secret, **Save**. The secret lives only in Supabase.
2. **Authentication → URL Configuration**:
   - **Site URL:** `http://localhost:3000`
   - **Redirect URLs:** add `http://localhost:3000/**` (and `https://YOUR-DOMAIN/**` later).

**D. Test:** open http://localhost:3000/login → *Continue with Google*. You should land on `/account`.
Supabase → **Authentication → Users** shows you, and **Table Editor → profiles** has your row.

**Before launch:** on the OAuth consent screen, click **Publish app** so people other than test users can sign in.

---

## 3. Make yourself the admin

1. Sign in once with the Google account you'll use as admin.
2. Supabase → **SQL Editor**, run (use your email):

```sql
update public.profiles set role = 'admin' where email = 'you@example.com';
```

3. Reload the site. An **Admin** link appears in the header and `/admin` works.

---

## 4. Mailgun (order confirmation emails)

Emails are sent by a Supabase **Edge Function**, because the app itself can't keep a secret.

**A. Mailgun**
1. https://www.mailgun.com → create an account.
2. **Sending → Domains → Add domain** (a subdomain such as `mg.yourdomain.com` is best). Choose US or EU.
3. Add the DNS records Mailgun shows (SPF, DKIM, MX, CNAME) at your domain registrar, then **Verify**.
4. **Sending → Domain settings → Sending API keys → Add sending key**. Copy it (shown once).
5. *Testing shortcut before DNS:* use the sandbox domain (`sandboxXXXX.mailgun.org`) and add your own
   email under **Authorized recipients**. Sandbox only delivers to authorised addresses.

**B. Supabase CLI**

```bash
brew install supabase/tap/supabase
supabase login
cd ~/projects/lookers
supabase link --project-ref YOUR-PROJECT-REF      # the part before .supabase.co
```

**C. Store the secrets in Supabase (not in files)**

```bash
supabase secrets set MAILGUN_API_KEY=your-key MAILGUN_DOMAIN=mg.yourdomain.com \
  MAILGUN_FROM="Lookers <orders@mg.yourdomain.com>" SITE_URL=http://localhost:3000 CURRENCY=USD
# EU region only:
# supabase secrets set MAILGUN_API_BASE=https://api.eu.mailgun.net
```

**D. Deploy the function**

```bash
supabase functions deploy send-order-confirmation
```

**E. Test:** place an order (step 5). The email should arrive; check spam too. If it doesn't, the order
still succeeds. Look at Supabase → **Edge Functions → send-order-confirmation → Logs**.
Remember to change `SITE_URL` to your real domain when you deploy.

---

## 5. Try a full purchase

1. Add a product (choose a colour and size) → **Bag → Checkout** → fill the form. While signed out the button says **Sign in to place order**: press it, sign in with Google (this also creates the account), and you return to checkout with your details kept → **Place order**.
2. You should see the success page, get the email, and see the order in `/account`.
3. As admin: `/admin/orders` → open the order → change its status. Reload `/account` to see it update.
4. **Table Editor → products**: the stock number dropped.

---

## 6. Deploy to Vercel

Vercel can't build Flutter, so the site is **built on your computer or in GitHub Actions** and Vercel only
**hosts the finished files** (`frontend/build/web`). `scripts/build_web.sh` writes the hosting rules Vercel
needs into that folder (every path serves the app, security headers, no stale app shell).

Do steps 1-4 of this guide first (Supabase, Google, admin, Mailgun), otherwise the live site runs in
preview mode with the sample catalogue.

### A. First deploy from your computer (about 10 minutes)

1. Create an account at https://vercel.com (the free Hobby plan is fine to start).
2. Log in and link a new project (answer the prompts: *Set up and link?* yes, scope = your account,
   *Link to existing project?* no, name `lookers`; accept the defaults for the rest):

```bash
cd ~/projects/lookers
npx vercel login
npx vercel link
```

   This creates `.vercel/project.json` (git-ignored). It only stores ids, not secrets.
3. Make sure `frontend/env.json` has your Supabase URL and publishable key (step 1).
4. Deploy a **preview** first, and open the URL it prints:

```bash
./scripts/deploy_vercel.sh
```

5. When it looks right, deploy to **production**:

```bash
./scripts/deploy_vercel.sh --prod
```

   Vercel prints your address, for example `https://lookers.vercel.app`.

### B. Tell the other services your real address (required, or sign-in fails)

Use the production address from A.5 (or your own domain from C):

1. Supabase → Authentication → URL Configuration: **Site URL** = `https://YOUR-ADDRESS`, and add the Redirect
   URL `https://YOUR-ADDRESS/**` (keep the `http://localhost:3000/**` one for development).
2. Google Cloud → your OAuth client → **Authorized JavaScript origins**: add `https://YOUR-ADDRESS`.
   (The redirect URI stays the Supabase callback URL; do not change it.)
3. Email links: `supabase secrets set SITE_URL=https://YOUR-ADDRESS`
   then `supabase functions deploy send-order-confirmation`.
4. Google OAuth consent screen: click **Publish app** so people other than test users can sign in.
5. Place a real test order on the live site: sign in, order, check the email and the admin dashboard.

### C. Your own domain (optional)

Vercel → your project → **Settings → Domains → Add**, then add the DNS records Vercel shows at your domain
registrar. HTTPS is automatic. Afterwards repeat **B** with the new domain.

### D. Automatic deploys on every push (recommended, after A works)

GitHub builds, tests and deploys for you whenever you push to `main`
(`.github/workflows/ci-deploy.yml`).

1. Create a **private** GitHub repository, then from `~/projects/lookers`:

```bash
git add -A && git status        # check nothing secret is listed (.env*, env.json, .vercel must NOT appear)
git commit -m "Lookers storefront"
git branch -M main
git remote add origin git@github.com:YOUR-USER/lookers.git
git push -u origin main
```

2. GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**. Add:

| Secret | Where to get it |
|---|---|
| `VERCEL_TOKEN` | Vercel → Account Settings → **Tokens** → Create |
| `VERCEL_ORG_ID` | `orgId` inside `.vercel/project.json` |
| `VERCEL_PROJECT_ID` | `projectId` inside `.vercel/project.json` |
| `SUPABASE_URL` | Same as in `frontend/env.json` |
| `SUPABASE_PUBLISHABLE_KEY` | Same as in `frontend/env.json` (the publishable key is public by design) |

   Optional: a repository **variable** (same page, *Variables* tab) named `CURRENCY`.
   **Never** add the Mailgun key or a Supabase `service_role` key here.
3. Push any change to `main`. Watch **Actions**: it runs format, analyze, tests, then builds and deploys.
4. Pull requests run the checks but do not deploy.

### Things to know

- **Rollback:** Vercel → project → **Deployments** → pick an older one → **Promote to Production**.
- **Page refresh on `/shop` or `/admin` shows a 404:** the deploy used an old build without `vercel.json`;
  rebuild with `scripts/build_web.sh` and deploy again.
- **Site still looks old after a deploy:** hard-refresh once; the app shell is served `no-cache` so this should
  be rare.
- **Search engines:** see "Decisions still open". Hosting on Vercel doesn't change how Flutter web is indexed.
- **Cost:** a static site on Hobby is free; Vercel's terms restrict Hobby to non-commercial use, so a real
  shop should be on the Pro plan.

---

## 7. Synced shopping bag (real time across web and phone)

While signed in, the bag lives in your Supabase database, so adding an item on the website shows up on the phone
(and the other way round) within a moment. It uses Supabase Realtime (a WebSocket connection). Signed-out
visitors keep a bag on their own device, which is merged into their account when they sign in.

1. Run `supabase/migrations/0002_cart_sync.sql` in Supabase → SQL Editor (New query → paste → Run). It adds the
   `cart_items` table, the safe write functions, switches on real time for it, and updates `place_order` so an order
   also empties the bag. Run it **once**; it is a new numbered file and does not change 0001.
2. Test it with two devices:
   - Open the website, sign in with Google, and add a product to the bag.
   - Run the phone app (or a simulator) signed in with the **same** Google account. The same item should be in the
     bag. Now add another item on the phone and watch the website's bag update without reloading.
   - Place an order on one device: the other device's bag should empty.
3. If an item doesn't appear live: Supabase → Database → Publications → `supabase_realtime` must list
   `cart_items`, and Project Settings → API should show Realtime enabled.

---

## 8. Mobile apps (Android and iOS)

The same Flutter code runs as a phone app. The Android and iOS projects are in `frontend/android` and
`frontend/ios`. Build settings come from the same `frontend/env.json` as the website.

### A. Run it on a simulator, emulator or your phone

```bash
cd ~/projects/lookers/frontend
~/fvm/versions/3.44.6/bin/flutter devices                       # lists what is available
~/fvm/versions/3.44.6/bin/flutter run -d <device> --dart-define-from-file=env.json
```

**Important: always pass `--dart-define-from-file=env.json`** (the command above does). Without it the app starts in
*preview mode* and Google sign-in says the build has no Supabase settings. Pressing the Run button in Xcode or Android
Studio does **not** pass it. Easiest ways to run correctly:
- Terminal: `./scripts/run_mobile.sh` (or `./scripts/run_mobile.sh <device-id>`).
- VS Code: open the project folder and pick **Lookers (phone or simulator, with Supabase)** in Run and Debug.
- Android Studio: Run → Edit Configurations → your Flutter config → **Additional run args** →
  `--dart-define-from-file=env.json`. (Xcode alone can't do this: start the app with one of the ways above.)
- Release builds for the stores need the same flag (section C).

- **iPhone simulator:** open Xcode once so it finishes installing, then pick a simulator from `flutter devices`.
- **Android emulator:** create a virtual device in Android Studio (Device Manager), start it, then run.
- **A real phone:** plug it in (Android: enable USB debugging; iPhone: enable Developer Mode, trust the Mac,
  and in Xcode set your Apple ID as the signing team once: open `ios/Runner.xcworkspace` → Runner → Signing).

### B. Tell Supabase about the app's sign-in address (required for Google sign-in on phones)

On a phone, Google sign-in opens the browser and comes back to the app through a link. Supabase must allow it:

1. Supabase → **Authentication → URL Configuration → Redirect URLs → Add URL**:
   `com.lookers.lookers://login-callback`
2. Save. Nothing changes in Google Cloud: Google still returns to Supabase's own callback address.

If you change the app id (see D), the link changes too: update `AppConfig.mobileAuthRedirect`, the Android
`AndroidManifest.xml` intent-filter, the iOS `Info.plist` URL scheme, and this Supabase entry together.

### C. Release builds you can upload to the stores

```bash
~/fvm/versions/3.44.6/bin/flutter build appbundle --release --dart-define-from-file=env.json   # Android (Play Store)
~/fvm/versions/3.44.6/bin/flutter build ipa --release --dart-define-from-file=env.json         # iOS (App Store), needs signing
```

**Android (Google Play):**
1. Create a Google Play Console account (one-time fee, about $25).
2. Create an upload keystore once and keep it (and its password) safe. Losing it blocks updates:
   `keytool -genkey -v -keystore ~/lookers-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
3. Tell the agent when you have it, and it will wire up `android/key.properties` (never committed) so release
   builds are signed.
4. Upload the `.aab`, fill in the store listing, content rating, data-safety form and privacy-policy link.

**iOS (App Store):**
1. Join the Apple Developer Program (about $99 a year).
2. In Xcode: `ios/Runner.xcworkspace` → Runner → Signing & Capabilities → pick your team.
3. Create the app in App Store Connect with the same bundle id, then upload the build (Xcode Organizer or
   Transporter) and complete the listing, privacy details and screenshots.

### D. Decisions before publishing

- **App id / bundle id** is `com.lookers.lookers`. Change it now if you want something else (for example one
  matching your domain); it can't be changed after the first store release.
- **Apple rule 4.8:** an iPhone app that offers Google sign-in must also offer an equivalent sign-in with
  limited data collection, normally **Sign in with Apple**. Apple may reject the app without it. This needs an
  Apple Developer account first, then a Supabase Apple provider and code. Ask the agent when you're ready.
- **Account deletion:** Apple and Google both require that an app which lets people create an account also lets
  them delete it from inside the app. This is not built yet.
- **Privacy policy:** both stores need a public privacy-policy page. The one in `/policies/privacy` is a draft.
- **Payments:** card payment isn't live. Physical goods may use an outside payment provider on both stores.

---

## Decisions still open

- **Dummy reviews:** the seed adds 2-3 made-up reviews per product so the page looks complete. Remove them before launch (`delete from public.reviews where is_dummy;`) or replace them with real ones; fake reviews are misleading and illegal in many countries.
- **Online payments:** which provider (Stripe, Paystack, Flutterwave, …) and currency. Today: pay on delivery.
- **Search engines (SEO):** a Flutter web app is drawn on a canvas, so Google sees very little of it and
  there are no per-page titles. If organic search matters to Lookers, decide on prerendered product pages
  or a separate marketing site. This is the main trade-off of choosing Flutter for a shop.
- **Shipping rules and currency:** edit the single row in `store_settings` (flat fee, free-shipping
  threshold, in cents); set `CURRENCY` in `env.json`.
- **Real products:** replace the samples in **/admin/products**. Image URLs must come from an allowed
  host (`frontend/lib/features/admin/domain/image_hosts.dart`; today Pexels).
- **Policies:** review and replace the draft text.
- **Final logo artwork** and sign-off on the purple neumorphic look (light and dark).

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Homepage still says "Preview mode" | Not started with `--dart-define-from-file=env.json`, or `env.json` has wrong keys |
| Google says `redirect_uri_mismatch` | The redirect URI in Google must be exactly the Supabase callback URL |
| Sign-in returns to `/login?error=1` | Supabase Redirect URLs don't include `http://localhost:3000/**`, or you ran on a different port |
| `/admin` sends you home | Your profile `role` isn't `admin`, or you signed in with another Google account |
| Checkout says "no longer available" | The product was hidden or deleted; remove it from the bag |
| Order fine, no email | Function not deployed, secrets missing, Mailgun domain unverified, or sandbox recipient not authorised (see function logs) |
| Product image doesn't show | Image host isn't allowed or doesn't send CORS headers |
| Page refresh gives 404 on your host | The host is missing the "rewrite everything to index.html" rule |
