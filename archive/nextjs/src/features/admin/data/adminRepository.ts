import type { SupabaseClient } from "@supabase/supabase-js";

export interface AdminProduct {
  id: string;
  slug: string;
  name: string;
  description: string;
  priceCents: number;
  categoryId: string;
  categoryName: string;
  imageUrl: string;
  sizes: string[];
  stock: number;
  featured: boolean;
  active: boolean;
}

interface Row {
  id: string; slug: string; name: string; description: string; price_cents: number;
  category_id: string; image_url: string; sizes: string[]; stock: number; featured: boolean; active: boolean;
  categories: { name: string } | null;
}

const COLUMNS = "id, slug, name, description, price_cents, category_id, image_url, sizes, stock, featured, active, categories(name)";

const toAdminProduct = (r: Row): AdminProduct => ({
  id: r.id, slug: r.slug, name: r.name, description: r.description, priceCents: r.price_cents,
  categoryId: r.category_id, categoryName: r.categories?.name ?? "", imageUrl: r.image_url,
  sizes: r.sizes, stock: r.stock, featured: r.featured, active: r.active,
});

/** Includes inactive products; RLS only returns them to admins. */
export async function listAdminProducts(supabase: SupabaseClient): Promise<AdminProduct[]> {
  const { data } = await supabase.from("products").select(COLUMNS).order("created_at", { ascending: false });
  return ((data ?? []) as unknown as Row[]).map(toAdminProduct);
}

export async function getAdminProduct(supabase: SupabaseClient, id: string): Promise<AdminProduct | null> {
  const { data } = await supabase.from("products").select(COLUMNS).eq("id", id).maybeSingle();
  return data ? toAdminProduct(data as unknown as Row) : null;
}

export interface AdminStats {
  orderCount: number;
  pendingCount: number;
  revenueCents: number;
  customerCount: number;
  lowStock: { id: string; name: string; stock: number }[];
}

export async function getAdminStats(supabase: SupabaseClient): Promise<AdminStats> {
  const [orders, customers, low] = await Promise.all([
    supabase.from("orders").select("status, total_cents"),
    supabase.from("profiles").select("id", { count: "exact", head: true }),
    supabase.from("products").select("id, name, stock").eq("active", true).lte("stock", 5).order("stock").limit(8),
  ]);
  const rows = orders.data ?? [];
  return {
    orderCount: rows.length,
    pendingCount: rows.filter((o) => o.status === "pending").length,
    // Cancelled orders aren't revenue.
    revenueCents: rows.filter((o) => o.status !== "cancelled").reduce((s, o) => s + o.total_cents, 0),
    customerCount: customers.count ?? 0,
    lowStock: (low.data ?? []) as AdminStats["lowStock"],
  };
}
