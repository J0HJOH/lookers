export interface Category {
  slug: string;
  name: string;
  tagline: string;
  imageUrl: string;
}

export interface Product {
  id: string;
  slug: string;
  name: string;
  description: string;
  priceCents: number;
  categorySlug: string;
  categoryName: string;
  imageUrl: string;
  sizes: string[];
  stock: number;
  featured: boolean;
  active: boolean;
}

export const LOW_STOCK_THRESHOLD = 5;

export type SortKey = "newest" | "price-asc" | "price-desc";

export interface CatalogQuery {
  categorySlug?: string;
  search?: string;
  sort?: SortKey;
}

export const isSortKey = (v: string | undefined): v is SortKey =>
  v === "newest" || v === "price-asc" || v === "price-desc";

export const stockLabel = (p: Pick<Product, "stock">): "out" | "low" | "in" =>
  p.stock <= 0 ? "out" : p.stock <= LOW_STOCK_THRESHOLD ? "low" : "in";

/** Pure filter/sort used for the preview catalogue; Supabase does the same in SQL. */
export function applyCatalogQuery(products: Product[], q: CatalogQuery): Product[] {
  const term = q.search?.trim().toLowerCase();
  const filtered = products.filter(
    (p) =>
      p.active &&
      (!q.categorySlug || p.categorySlug === q.categorySlug) &&
      (!term || p.name.toLowerCase().includes(term) || p.description.toLowerCase().includes(term)),
  );
  if (q.sort === "price-asc") return [...filtered].sort((a, b) => a.priceCents - b.priceCents);
  if (q.sort === "price-desc") return [...filtered].sort((a, b) => b.priceCents - a.priceCents);
  return filtered;
}
