import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { deleteProductAction } from "@/app/admin/actions";
import { getAdminProduct } from "@/features/admin/data/adminRepository";
import { listCategoriesWithId } from "@/features/admin/data/categories";
import { ProductForm } from "@/features/admin/presentation/ProductForm";

export default async function EditProductPage(props: PageProps<"/admin/products/[id]">) {
  const { id } = await props.params;
  const supabase = await createSupabaseServerClient();
  if (!supabase || !/^[0-9a-f-]{36}$/.test(id)) notFound();
  const [product, categories] = await Promise.all([getAdminProduct(supabase, id), listCategoriesWithId(supabase)]);
  if (!product) notFound();
  return (
    <div>
      <h1 className="display mb-8 text-4xl">{product.name}</h1>
      <ProductForm product={product} categories={categories} />
      <form action={deleteProductAction} className="mt-12 border-t border-line pt-6">
        <input type="hidden" name="id" value={product.id} />
        <p className="mb-3 text-sm text-ink-muted">Deleting removes the product from the shop. Past orders keep their details. To hide it instead, untick &ldquo;Visible in the shop&rdquo;.</p>
        <button type="submit" className="text-[12px] uppercase tracking-[0.2em] text-danger underline">Delete product</button>
      </form>
    </div>
  );
}
