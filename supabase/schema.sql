-- Luki Furniture catalog database
-- Run this file in Supabase Dashboard > SQL Editor.
-- Public visitors can read active catalog data. Writes remain dashboard/admin-only.

create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  slug text not null unique,
  short_description text,
  description text,
  price numeric(14,2),
  discount_price numeric(14,2),
  material text,
  dimensions text,
  color text,
  stock integer not null default 0 check (stock >= 0),
  cover_image text,
  is_featured boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint products_price_nonnegative check (price is null or price >= 0),
  constraint products_discount_nonnegative check (discount_price is null or discount_price >= 0)
);

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_url text not null,
  alt_text text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.site_settings (
  key text primary key,
  value text,
  updated_at timestamptz not null default now()
);

create index if not exists products_category_id_idx on public.products(category_id);
create index if not exists products_active_featured_idx on public.products(is_active, is_featured);
create index if not exists products_created_at_idx on public.products(created_at desc);
create index if not exists product_images_product_sort_idx on public.product_images(product_id, sort_order);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.site_settings enable row level security;

drop policy if exists "Public can read active categories" on public.categories;
create policy "Public can read active categories"
on public.categories for select
to anon, authenticated
using (is_active = true);

drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products"
on public.products for select
to anon, authenticated
using (is_active = true);

drop policy if exists "Public can read images of active products" on public.product_images;
create policy "Public can read images of active products"
on public.product_images for select
to anon, authenticated
using (
  exists (
    select 1 from public.products p
    where p.id = product_images.product_id and p.is_active = true
  )
);

drop policy if exists "Public can read site settings" on public.site_settings;
create policy "Public can read site settings"
on public.site_settings for select
to anon, authenticated
using (true);

-- Public image bucket. Upload/delete permissions are intentionally not granted to visitors.
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'product-images');

-- Starter categories (safe to run repeatedly).
insert into public.categories (name, slug, sort_order) values
  ('Living Room', 'living-room', 1),
  ('Bedroom', 'bedroom', 2),
  ('Dining Room', 'dining-room', 3),
  ('Workspace', 'workspace', 4),
  ('Storage', 'storage', 5)
on conflict (slug) do nothing;

-- Optional store settings. Replace values when store details are ready.
insert into public.site_settings (key, value) values
  ('store_name', 'Luki Furniture'),
  ('whatsapp_number', ''),
  ('instagram_url', '')
on conflict (key) do nothing;
