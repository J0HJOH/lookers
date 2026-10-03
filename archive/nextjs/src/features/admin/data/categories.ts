import type { SupabaseClient } from "@supabase/supabase-js";
import type { Category } from "@/features/catalog/domain/product";

export async function listCategoriesWithId(supabase: SupabaseClient): Promise<(Category & { id: string })[]> {
  const { data } = await supabase.from("categories").select("id, slug, name, tagline, image_url").order("sort_order");
  return (data ?? []).map((c) => ({ id: c.id, slug: c.slug, name: c.name, tagline: c.tagline, imageUrl: c.image_url }));
}
