# Lookers setup: steps only you can do

The code is written. These steps need your accounts, so they are done by you. Do them in order
and tick them off. Nothing here needs code changes.

Keep every key private. Never paste keys into chat, code files or git. They go only in
`.env.local` (your computer) and your hosting provider's environment settings.

---

## 0. Run the site in preview mode (no accounts needed)

```bash
cd ~/projects/lookers
npm install
cp .env.example .env.local
npm run dev
```

Open http://localhost:3000. You'll see the full design with a sample catalogue. Sign-in, checkout,
account and admin stay disabled until steps 1–4.

---

## 1. Supabase (database + login backend)

1. Go to https://supabase.com → **New project**. Name it `lookers`. Pick the region closest to
   your customers and save the **database password** in your password manager.
2. Wait for the project to finish setting up.
3. **Project Settings → API** (or **Connect**). Copy:
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **Publishable key** (older projects call it *anon public*) → `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`

   Do **not** copy the `service_role` / secret key. This project doesn't use it.
4. Put both in `.env.local`.
5. **SQL Editor → New query.** Open `supabase/migrations/0001_init.sql` from this repo, paste it
   all, press **Run**. It should say "Success".
6. New query again. Paste `supabase/seed.sql` and **Run**. This adds the 6 categories and 23
   sample products. (If you change `seed/catalog.ts`, run `npm run db:seed-sql` first.)
7. Check **Table Editor**: you should see `categories`, `products`, `orders`, `order_items`,
   `profiles`, `store_settings`.
8. Restart `npm run dev`. The preview banner on the homepage should disappear.

---

## 2. Google sign-in (Google Cloud Console + Supabase)

**A. Get your Supabase callback address**

1. Supabase → **Authentication → Sign In / Providers → Google**. Copy the **Callback URL**. It looks
   like `https://<project-ref>.supabase.co/auth/v1/callback`. Keep this tab open.

**B. Create the Google credentials**

1. https://console.cloud.google.com → create a project named `Lookers` (or pick one).
2. **APIs & Services → OAuth consent screen** (may show as *Google Auth Platform → Branding*).
   - User type **External**. App name `Lookers`. Add your support email and developer email.
   - Under data access/scopes keep the defaults: `email`, `profile`, `openid`.
   - Add your own Google account as a **test user** while the app is in *Testing*.
3. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
   - Application type: **Web application**. Name: `Lookers web`.
   - **Authorized JavaScript origins:** `http://localhost:3000` and (later) your real domain.
   - **Authorized redirect URIs:** paste the Supabase **Callback URL** from step A.
     (Only that URL. Google talks to Supabase, and Supabase redirects to your site.)
4. Create. Copy the **Client ID** and **Client secret**.

**C. Give them to Supabase**

1. Back in Supabase → **Authentication → Sign In / Providers → Google**: turn it **on**, paste the
   Client ID and Client secret, **Save**. The secret lives only in Supabase.
2. **Authentication → URL Configuration:**
   - **Site URL:** `http://localhost:3000` (change to your real domain when you deploy).
   - **Redirect URLs:** add `http://localhost:3000/**` (and `https://YOUR-DOMAIN/**` later).

**D. Test:** open http://localhost:3000/login → *Continue with Google*. You should land on
`/account`. Check **Authentication → Users** in Supabase to see yourself, and **Table Editor →
profiles** for your profile row.

**Before launch:** on the OAuth consent screen, click **Publish app** so people other than test
users can sign in.

---

## 3. Make yourself the admin

1. Sign in once on the site with the Google account you'll use as admin (step 2D).
2. Supabase → **SQL Editor**, run (use your email):

```sql
update public.profiles set role = 'admin' where email = 'you@example.com';
```

3. Refresh the site. An **Admin** link appears in the header. `/admin` now works.

To add another admin later, repeat with their email (they must have signed in once).

---

## 4. Mailgun (order confirmation emails)

1. https://www.mailgun.com → create an account.
2. **Sending → Domains → Add domain.** Best practice is a subdomain such as `mg.yourdomain.com`.
   Choose the region (US or EU) you want.
3. Mailgun shows DNS records (TXT for SPF and DKIM, MX, CNAME). Add them at your domain
   registrar's DNS settings, then click **Verify**. This can take from minutes to a day.
4. **Sending → Domain settings → Sending API keys → Add sending key.** Copy the key. This is
   shown once.
5. Put in `.env.local`:

```
MAILGUN_API_KEY=your-key
MAILGUN_DOMAIN=mg.yourdomain.com
MAILGUN_FROM=Lookers <orders@mg.yourdomain.com>
# EU region only:
# MAILGUN_API_BASE=https://api.eu.mailgun.net
```

6. **Sandbox shortcut for testing before DNS:** Mailgun gives a sandbox domain
   (`sandboxXXXX.mailgun.org`). Use it as `MAILGUN_DOMAIN` and add your own email under
   **Authorized recipients** (confirm the email Mailgun sends you). Sandbox only delivers to
   authorised addresses.
7. Restart `npm run dev`, place a test order, check your inbox (and spam folder). If nothing
   arrives, check the terminal for a line starting `Order confirmation email failed`. The order
   itself still succeeds.

---

## 5. Try a full purchase

1. Sign in → add a product to the bag → **Checkout** → fill the form → **Place order**.
2. You should see the success page, receive the email, and see the order in `/account`.
3. As admin, open `/admin/orders`, open the order, and change its status. Refresh `/account`
   to see the customer's view update.
4. Check **Table Editor → products**: the stock number dropped.

---

## 6. Deploy (when ready; Vercel suggested)

1. Push the project to a **private** GitHub repository (never commit `.env.local`).
2. https://vercel.com → **Add New → Project** → import the repo.
3. **Settings → Environment Variables:** add everything from `.env.local`, with
   `NEXT_PUBLIC_SITE_URL=https://YOUR-DOMAIN`. Mark `MAILGUN_API_KEY` as sensitive.
4. Deploy. Then add your domain under **Settings → Domains**.
5. Update the production URLs:
   - Supabase → Authentication → URL Configuration: Site URL + Redirect URL `https://YOUR-DOMAIN/**`
   - Google Cloud → your OAuth client → Authorized JavaScript origins: `https://YOUR-DOMAIN`
   - Google OAuth consent screen: **Publish app**.
6. Repeat the full purchase test on the live site.

---

## Decisions still open (tell the agent when you've decided)

- **Online payments:** which provider (Stripe, Paystack, Flutterwave, …), and which currency.
  Today checkout is *pay on delivery* only.
- **Currency and shipping rules:** set `NEXT_PUBLIC_CURRENCY`; edit the single row in
  `store_settings` (flat shipping fee and free-shipping threshold, in cents).
- **Real product photography/data:** replace the sample products in **/admin/products**. Image
  URLs must come from an allowed host (`src/core/imageHosts.ts`; today Pexels).
- **Policies:** review and replace the draft text in `/policies/*`.
- **Final logo artwork** and a comparison against your Behance reference.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Homepage still says "Preview mode" | `.env.local` values missing or dev server not restarted |
| Google says `redirect_uri_mismatch` | The redirect URI in Google must be exactly the Supabase callback URL |
| Sign-in loops back to `/login?error=1` | Supabase Redirect URLs don't include `http://localhost:3000/**` |
| `/admin` sends you home | Your profile `role` isn't `admin`, or you're signed in with a different Google account |
| Checkout says "no longer available" | The product is hidden or deleted; remove it from the bag |
| No email, order fine | Mailgun domain unverified, sandbox recipient not authorised, or wrong region base URL |
| Product image fails to load | Image URL host isn't in `src/core/imageHosts.ts` |
