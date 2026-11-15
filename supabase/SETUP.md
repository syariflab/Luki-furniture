# Setup Supabase — Luki Furniture

## 1. Create a project
1. Open https://supabase.com/dashboard
2. Create a new project and save its database password securely.
3. Wait until the project is ready.

## 2. Create the database
1. Open **SQL Editor** in the Supabase project.
2. Open this repository file: `supabase/schema.sql`.
3. Copy the complete SQL into a new SQL query and click **Run**.
4. Confirm that the tables `categories`, `products`, `product_images`, and `site_settings` exist.

## 3. Get the public connection details
Open **Project Settings → API** (or **Data API / API Keys**, depending on dashboard version).
Copy:
- Project URL
- Publishable key (preferred) or legacy anon key

These values are intended for browser-side public access when Row Level Security is enabled. Never put the service_role or secret key in website code.

## 4. Product images
The SQL creates a public Storage bucket named `product-images`. Upload product photos there from **Storage**. Store each image's public URL in `products.cover_image` or `product_images.image_url`.

## 5. Add products
Add categories and products through **Table Editor**. Set `is_active = true` to show a product in the public catalog. Set `is_featured = true` for featured products.

## Security notes
- Public website visitors can only read active catalog entries and settings.
- Public insert, update, and delete policies are intentionally not enabled.
- Manage products using the Supabase dashboard for now. An admin panel can be built later with Supabase Auth and restricted policies.
- Do not share your database password, service_role key, or secret key.

## Current status
The schema is committed. The live website connection still needs the project's URL and publishable/anon key. No Supabase project has been connected yet.
