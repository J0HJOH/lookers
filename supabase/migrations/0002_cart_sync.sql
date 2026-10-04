-- Lookers: synced shopping bag (migration 0002). Run in Supabase Dashboard > SQL Editor.
-- Signed-in shoppers' bags live here, so a change on the website appears on the phone app (and the
-- other way round) through Supabase Realtime. Signed-out shoppers keep a local bag on their device.
-- Safe to run once on top of 0001. Do NOT edit 0001; schema changes go in new numbered files.

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  size text not null check (char_length(size) between 1 and 20),
  -- '' means "no colour choice" (so the uniqueness rule below also works for those products).
  color text not null default '' check (char_length(color) <= 30),
  quantity integer not null check (quantity between 1 and 10),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, product_id, size, color)
);
create index cart_items_user_idx on public.cart_items (user_id, created_at);

-- Shoppers can only READ their own rows. All writes go through the functions below, which validate
-- the product, size, colour and quantity (the browser/phone is never trusted).
alter table public.cart_items enable row level security;
create policy "cart read own" on public.cart_items for select using (user_id = auth.uid());

-- Realtime: broadcast changes. REPLICA IDENTITY FULL lets DELETE events carry user_id, so the
-- per-user filter also works for removals.
alter table public.cart_items replica identity full;
alter publication supabase_realtime add table public.cart_items;

-- ───────── write functions ─────────
create function public.cart_validate(p_slug text, p_size text, p_color text)
returns table (v_product_id uuid, v_color text)
language plpgsql security definer set search_path = public as $$
declare
  v_product public.products%rowtype;
  v_clean text := coalesce(nullif(btrim(coalesce(p_color, '')), ''), '');
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_product from public.products where slug = p_slug and active;
  if not found then raise exception 'PRODUCT_UNAVAILABLE'; end if;
  if p_size is null or not (p_size = any (v_product.sizes)) then raise exception 'INVALID_SIZE'; end if;
  if jsonb_array_length(v_product.colors) > 0 then
    if v_clean = '' or not exists (
      select 1 from jsonb_array_elements(v_product.colors) c where c ->> 'name' = v_clean
    ) then
      raise exception 'INVALID_COLOR';
    end if;
  else
    v_clean := '';
  end if;
  return query select v_product.id, v_clean;
end $$;

-- Add to the bag. Atomic (two devices adding at once both count) and capped at 10 per line, 30 lines.
create function public.cart_add(p_slug text, p_size text, p_color text, p_qty integer)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_pid uuid;
  v_col text;
begin
  select v.v_product_id, v.v_color into v_pid, v_col from public.cart_validate(p_slug, p_size, p_color) v;
  if p_qty is null or p_qty < 1 or p_qty > 10 then raise exception 'INVALID_QUANTITY'; end if;
  if (select count(*) from public.cart_items where user_id = v_user) >= 30
     and not exists (select 1 from public.cart_items
                     where user_id = v_user and product_id = v_pid and size = p_size and color = v_col) then
    raise exception 'CART_FULL';
  end if;
  insert into public.cart_items (user_id, product_id, size, color, quantity)
  values (v_user, v_pid, p_size, v_col, p_qty)
  on conflict (user_id, product_id, size, color)
  do update set quantity = least(10, public.cart_items.quantity + excluded.quantity), updated_at = now();
end $$;

-- Set an exact quantity (0 removes the line).
create function public.cart_set_qty(p_slug text, p_size text, p_color text, p_qty integer)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_pid uuid;
  v_col text;
begin
  select v.v_product_id, v.v_color into v_pid, v_col from public.cart_validate(p_slug, p_size, p_color) v;
  if p_qty is null or p_qty < 0 or p_qty > 10 then raise exception 'INVALID_QUANTITY'; end if;
  if p_qty = 0 then
    delete from public.cart_items where user_id = v_user and product_id = v_pid and size = p_size and color = v_col;
  else
    update public.cart_items set quantity = p_qty, updated_at = now()
      where user_id = v_user and product_id = v_pid and size = p_size and color = v_col;
  end if;
end $$;

create function public.cart_remove(p_slug text, p_size text, p_color text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  delete from public.cart_items ci using public.products p
    where ci.user_id = auth.uid() and ci.product_id = p.id and p.slug = p_slug
      and ci.size = p_size and ci.color = coalesce(nullif(btrim(coalesce(p_color, '')), ''), '');
end $$;

create function public.cart_clear()
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  delete from public.cart_items where user_id = auth.uid();
end $$;

revoke all on function public.cart_validate(text, text, text) from public, anon, authenticated;
revoke all on function public.cart_add(text, text, text, integer) from public, anon;
revoke all on function public.cart_set_qty(text, text, text, integer) from public, anon;
revoke all on function public.cart_remove(text, text, text) from public, anon;
revoke all on function public.cart_clear() from public, anon;
grant execute on function public.cart_add(text, text, text, integer) to authenticated;
grant execute on function public.cart_set_qty(text, text, text, integer) to authenticated;
grant execute on function public.cart_remove(text, text, text) to authenticated;
grant execute on function public.cart_clear() to authenticated;

-- ───────── place_order: also empty the synced bag, so the other devices clear it ─────────
create or replace function public.place_order(p_items jsonb, p_shipping jsonb, p_notes text default null)
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

  -- The order is placed: empty the shopper's synced bag so their other devices clear it too.
  delete from public.cart_items where user_id = v_user;

  return query select v_order, v_number, v_subtotal + v_shipping;
end $$;

revoke all on function public.place_order(jsonb, jsonb, text) from public, anon;
grant execute on function public.place_order(jsonb, jsonb, text) to authenticated;
