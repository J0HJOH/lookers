-- Lookers: initial schema. Run in Supabase Dashboard > SQL Editor (or `supabase db push`).
-- Safe to read top to bottom: types, tables, helper functions, RLS policies, place_order().

create type public.user_role as enum ('customer', 'admin');
create type public.order_status as enum ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled');

-- ───────── profiles (one per auth user, filled by trigger on first Google sign-in) ─────────
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  avatar_url text,
  role public.user_role not null default 'customer',
  created_at timestamptz not null default now()
);

create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- ───────── catalogue ─────────
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name text not null check (char_length(name) between 1 and 80),
  tagline text not null default '',
  image_url text not null,
  sort_order integer not null default 0
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name text not null check (char_length(name) between 1 and 120),
  description text not null default '' check (char_length(description) <= 2000),
  price_cents integer not null check (price_cents >= 0),
  category_id uuid not null references public.categories (id),
  image_url text not null check (image_url ~ '^https://' and char_length(image_url) <= 2000),
  sizes text[] not null default '{"One size"}' check (cardinality(sizes) >= 1),
  stock integer not null default 0 check (stock >= 0),
  featured boolean not null default false,
  active boolean not null default true,
  -- Variants: [{"name": "Black", "hex": "#14110F"}, ...]. Empty = no colour choice.
  colors jsonb not null default '[]'::jsonb check (jsonb_typeof(colors) = 'array' and jsonb_array_length(colors) <= 12),
  -- Extra gallery photos after image_url (https URLs; only admins can write products).
  images text[] not null default '{}' check (cardinality(images) <= 8),
  -- Maintained by a trigger on reviews.
  rating_avg numeric(3, 2) not null default 0,
  rating_count integer not null default 0,
  created_at timestamptz not null default now()
);
create index products_category_idx on public.products (category_id);
create index products_active_idx on public.products (active, created_at desc);

-- Reviews. Dummy reviews for now (is_dummy). Only admins can write; a verified-buyer
-- review flow is a future feature (needs a purchase check inside a SQL function).
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  author_name text not null check (char_length(author_name) between 1 and 60),
  rating smallint not null check (rating between 1 and 5),
  title text not null default '' check (char_length(title) <= 120),
  body text not null check (char_length(body) between 1 and 2000),
  size text,
  color text,
  is_dummy boolean not null default false,
  created_at timestamptz not null default now()
);
create index reviews_product_idx on public.reviews (product_id, created_at desc);

create function public.refresh_product_rating()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_product uuid := coalesce(new.product_id, old.product_id);
begin
  update public.products p set
    rating_avg = coalesce((select round(avg(rating)::numeric, 2) from public.reviews where product_id = v_product), 0),
    rating_count = (select count(*) from public.reviews where product_id = v_product)
  where p.id = v_product;
  return null;
end $$;

create trigger reviews_refresh_rating
  after insert or update or delete on public.reviews
  for each row execute function public.refresh_product_rating();

-- Single-row store settings (shipping rules). Row id is always true.
create table public.store_settings (
  id boolean primary key default true check (id),
  flat_shipping_cents integer not null default 1500 check (flat_shipping_cents >= 0),
  free_shipping_threshold_cents integer not null default 25000 check (free_shipping_threshold_cents >= 0)
);
insert into public.store_settings default values;

-- ───────── orders ─────────
create sequence public.order_number_seq start 1001;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  user_id uuid not null references auth.users (id),
  email text not null,
  status public.order_status not null default 'pending',
  payment_method text not null default 'pay_on_delivery',
  subtotal_cents integer not null default 0,
  shipping_cents integer not null default 0,
  total_cents integer not null default 0,
  ship_name text not null,
  ship_phone text not null,
  ship_line1 text not null,
  ship_line2 text,
  ship_city text not null,
  ship_region text not null,
  ship_postal_code text not null,
  ship_country text not null,
  notes text,
  confirmation_email_sent_at timestamptz,
  created_at timestamptz not null default now()
);
create index orders_user_idx on public.orders (user_id, created_at desc);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  product_name text not null,
  image_url text not null,
  size text not null,
  color text,
  unit_price_cents integer not null,
  quantity integer not null check (quantity between 1 and 10)
);
create index order_items_order_idx on public.order_items (order_id);

-- ───────── row level security ─────────
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.store_settings enable row level security;
alter table public.reviews enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- profiles: read own (admins read all). Users may edit only name/avatar, never role.
create policy "profiles read own or admin" on public.profiles
  for select using (id = auth.uid() or public.is_admin());
create policy "profiles update own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());
revoke update on public.profiles from authenticated, anon;
grant update (full_name, avatar_url) on public.profiles to authenticated;

-- catalogue: public read of active items; only admins write.
create policy "categories public read" on public.categories for select using (true);
create policy "categories admin write" on public.categories
  for all using (public.is_admin()) with check (public.is_admin());

create policy "products public read" on public.products
  for select using (active or public.is_admin());
create policy "products admin write" on public.products
  for all using (public.is_admin()) with check (public.is_admin());

create policy "reviews public read" on public.reviews for select using (true);
create policy "reviews admin write" on public.reviews
  for all using (public.is_admin()) with check (public.is_admin());

create policy "settings public read" on public.store_settings for select using (true);
create policy "settings admin write" on public.store_settings
  for update using (public.is_admin()) with check (public.is_admin());

-- orders: customers read their own; admins read all and may update (status). No direct inserts:
-- orders are created only through place_order() below, which prices everything server-side.
create policy "orders read own or admin" on public.orders
  for select using (user_id = auth.uid() or public.is_admin());
create policy "orders admin update" on public.orders
  for update using (public.is_admin()) with check (public.is_admin());
revoke update on public.orders from authenticated, anon;
grant update (status) on public.orders to authenticated;

create policy "order items read own or admin" on public.order_items
  for select using (
    exists (
      select 1 from public.orders o
      where o.id = order_id and (o.user_id = auth.uid() or public.is_admin())
    )
  );

-- ───────── checkout ─────────
-- Prices, stock and shipping are decided HERE from the database, never from the browser.
-- Errors are coded (AUTH_REQUIRED, INVALID_CART, PRODUCT_UNAVAILABLE:<slug>, ...) and the
-- app maps them to friendly messages.
create function public.place_order(p_items jsonb, p_shipping jsonb, p_notes text default null)
returns table (o_id uuid, o_number text, o_total integer)
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_email text;
  v_order uuid;
  v_number text;
  v_subtotal integer := 0;
  v_shipping integer;
  v_item jsonb;
  v_qty integer;
  v_size text;
  v_color text;
  v_product public.products%rowtype;
  v_settings public.store_settings%rowtype;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) = 0
     or jsonb_array_length(p_items) > 30 then
    raise exception 'INVALID_CART';
  end if;

  -- The browser is untrusted: re-validate the address here, not only in the app.
  if char_length(btrim(coalesce(p_shipping ->> 'fullName', ''))) not between 2 and 100
     or char_length(btrim(coalesce(p_shipping ->> 'line1', ''))) not between 3 and 200
     or char_length(coalesce(p_shipping ->> 'line2', '')) > 200
     or char_length(btrim(coalesce(p_shipping ->> 'city', ''))) not between 2 and 100
     or char_length(btrim(coalesce(p_shipping ->> 'region', ''))) not between 2 and 100
     or char_length(btrim(coalesce(p_shipping ->> 'postalCode', ''))) not between 2 and 20
     or char_length(btrim(coalesce(p_shipping ->> 'country', ''))) not between 2 and 100
     or coalesce(p_shipping ->> 'phone', '') !~ '^[+0-9][0-9 ().-]{6,24}$'
     or coalesce(p_shipping ->> 'email', '') !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
     or char_length(coalesce(p_notes, '')) > 500 then
    raise exception 'INVALID_ADDRESS';
  end if;

  select * into v_settings from public.store_settings where id;
  select email into v_email from public.profiles where id = v_user;
  v_number := 'LK-' || lpad(nextval('public.order_number_seq')::text, 6, '0');

  insert into public.orders (
    order_number, user_id, email, ship_name, ship_phone, ship_line1, ship_line2,
    ship_city, ship_region, ship_postal_code, ship_country, notes
  ) values (
    v_number, v_user, coalesce(nullif(p_shipping ->> 'email', ''), v_email, ''),
    p_shipping ->> 'fullName', p_shipping ->> 'phone', p_shipping ->> 'line1',
    nullif(p_shipping ->> 'line2', ''), p_shipping ->> 'city', p_shipping ->> 'region',
    p_shipping ->> 'postalCode', p_shipping ->> 'country', nullif(p_notes, '')
  ) returning id into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item ->> 'quantity')::integer;
    v_size := v_item ->> 'size';
    if v_qty is null or v_qty < 1 or v_qty > 10 then raise exception 'INVALID_QUANTITY'; end if;

    select * into v_product from public.products
      where slug = v_item ->> 'slug' and active for update;
    if not found then raise exception 'PRODUCT_UNAVAILABLE:%', v_item ->> 'slug'; end if;
    if v_size is null or not (v_size = any (v_product.sizes)) then
      raise exception 'INVALID_SIZE:%', v_product.slug;
    end if;
    v_color := nullif(btrim(coalesce(v_item ->> 'color', '')), '');
    if jsonb_array_length(v_product.colors) > 0 then
      if v_color is null or not exists (
        select 1 from jsonb_array_elements(v_product.colors) c where c ->> 'name' = v_color
      ) then
        raise exception 'INVALID_COLOR:%', v_product.slug;
      end if;
    else
      v_color := null;
    end if;
    if v_product.stock < v_qty then raise exception 'OUT_OF_STOCK:%', v_product.slug; end if;

    update public.products set stock = stock - v_qty where id = v_product.id;
    insert into public.order_items (
      order_id, product_id, product_name, image_url, size, color, unit_price_cents, quantity
    ) values (
      v_order, v_product.id, v_product.name, v_product.image_url, v_size, v_color, v_product.price_cents, v_qty
    );
    v_subtotal := v_subtotal + v_product.price_cents * v_qty;
  end loop;

  v_shipping := case when v_subtotal >= v_settings.free_shipping_threshold_cents
                     then 0 else v_settings.flat_shipping_cents end;
  update public.orders
    set subtotal_cents = v_subtotal, shipping_cents = v_shipping, total_cents = v_subtotal + v_shipping
    where id = v_order;

  return query select v_order, v_number, v_subtotal + v_shipping;
end $$;

revoke all on function public.place_order(jsonb, jsonb, text) from public, anon;
grant execute on function public.place_order(jsonb, jsonb, text) to authenticated;

-- ───────── confirmation email bookkeeping ─────────
-- The send-order-confirmation Edge Function calls claim first, so refreshing the success page
-- or retrying can never send the same email twice. If Mailgun fails it calls release.
create function public.claim_confirmation_email(p_order uuid)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_count integer;
begin
  update public.orders set confirmation_email_sent_at = now()
    where id = p_order and user_id = auth.uid() and confirmation_email_sent_at is null;
  get diagnostics v_count = row_count;
  return v_count = 1;
end $$;

create function public.release_confirmation_email(p_order uuid)
returns void language sql security definer set search_path = public as $$
  update public.orders set confirmation_email_sent_at = null
    where id = p_order and user_id = auth.uid();
$$;

revoke all on function public.claim_confirmation_email(uuid) from public, anon;
revoke all on function public.release_confirmation_email(uuid) from public, anon;
grant execute on function public.claim_confirmation_email(uuid) to authenticated;
grant execute on function public.release_confirmation_email(uuid) to authenticated;
