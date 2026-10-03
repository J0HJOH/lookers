import type { MetadataRoute } from "next";
import { getSiteUrl } from "@/core/config";
import { listCategories, listProducts } from "@/features/catalog/data/catalogRepository";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = getSiteUrl();
  const [categories, products] = await Promise.all([listCategories(), listProducts()]);
  return [
    { url: base },
    { url: `${base}/shop` },
    ...categories.map((c) => ({ url: `${base}/shop?category=${c.slug}` })),
    ...products.map((p) => ({ url: `${base}/product/${p.slug}` })),
  ];
}
