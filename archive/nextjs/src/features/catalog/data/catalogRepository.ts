import { isSupabaseConfigured } from "@/core/config";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { seedCategories, seedProducts } from "../../../../seed/catalog";
import {
  applyCatalogQuery,
  type CatalogQuery,
  type Category,
  type Product,
} from "../domain/product";

interface ProductRow {
  id: string;
  slug: string;
  name: string;
  description: string;
  price_cents: number;
  image_url: string;
  sizes: string[];
  stock: number;
  featured: boolean;
  active: boolean;
  categories: { slug: string; name: string } | null;
}

const PRODUCT_COLUMNS =
  "id, slug, name, description, price_cents, image_url, sizes, stock, featured, active, categories(slug, name)";

// Parsing happens once, here. A malformed row is dropped rather than crashing the page.
function toProduct(row: ProductRow): Product | null {
  if (!row.categories || typeof row.price_cents !== "number") return null;
  return {
    id: row.id,
    slug: row.slug,
    name: row.name,
    description: row.description,
    priceCents: row.price_cents,
    categorySlug: row.categories.slug,
    categoryName: row.categories.name,
    imageUrl: row.image_url,
    sizes: row.sizes,
    stock: row.stock,
    featured: row.featured,
    active: row.active,
  };
}

const previewProducts = (): Product[] =>
  seedProducts.map((p, i) => ({
    id: `preview-${i}`,
    slug: p.slug,
    name: p.name,
    description: p.description,
    priceCents: p.priceCents,
    categorySlug: p.categorySlug,
    categoryName: seedCategories.find((c) => c.slug === p.categorySlug)?.name ?? "",
    imageUrl: p.imageUrl,
    sizes: p.sizes,
    stock: p.stock,
    featured: p.featured,
    active: true,
  }));

/**
 * Catalogue reads. With Supabase configured they hit the database (RLS limits shoppers to
 * active products). Without it, the bundled seed catalogue is served so the design can be
 * previewed. Preview mode can't take orders (checkout needs the database).
 */
export async function listCategories(): Promise<Category[]> {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return seedCategories;
  const { data, error } = await supabase
    .from("categories")
    .select("slug, name, tagline, image_url, sort_order")
    .order("sort_order");
  if (error || !data) return [];
  return data.map((c) => ({ slug: c.slug, name: c.name, tagline: c.tagline, imageUrl: c.image_url }));
}

export async function listProducts(query: CatalogQuery = {}): Promise<Product[]> {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return applyCatalogQuery(previewProducts(), query);

  let request = supabase.from("products").select(PRODUCT_COLUMNS).eq("active", true);
  if (query.categorySlug) request = request.eq("categories.slug", query.categorySlug);
  const term = query.search?.trim().replace(/[%,()]/g, " ");
  if (term) request = request.or(`name.ilike.%${term}%,description.ilike.%${term}%`);
  if (query.sort === "price-asc") request = request.order("price_cents", { ascending: true });
  else if (query.sort === "price-desc") request = request.order("price_cents", { ascending: false });
  else request = request.order("created_at", { ascending: false });

  const { data, error } = await request.overrideTypes<ProductRow[], { merge: false }>();
  if (error || !data) return [];
  const products = data.map(toProduct).filter((p): p is Product => p !== null);
  // `categories.slug` filtering on an embedded table keeps rows; filter strictly here.
  return query.categorySlug ? products.filter((p) => p.categorySlug === query.categorySlug) : products;
}

export async function getFeaturedProducts(limit = 8): Promise<Product[]> {
  return (await listProducts()).filter((p) => p.featured).slice(0, limit);
}

export async function getProductBySlug(slug: string): Promise<Product | null> {
  return (await listProducts()).find((p) => p.slug === slug) ?? null;
}

export function usingPreviewCatalog(): boolean {
  return !isSupabaseConfigured();
}
