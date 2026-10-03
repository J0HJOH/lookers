import { createSupabaseServerClient } from "@/core/supabase/server";
import { listCategoriesWithId } from "@/features/admin/data/categories";
import { ProductForm } from "@/features/admin/presentation/ProductForm";

export default async function NewProductPage() {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return <p>The database isn&apos;t connected.</p>;
  const categories = await listCategoriesWithId(supabase);
  return (<div><h1 className="display mb-8 text-4xl">New product</h1><ProductForm categories={categories} /></div>);
}
