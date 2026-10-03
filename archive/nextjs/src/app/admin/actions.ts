"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { requireAdmin } from "@/features/auth/data/session";
import { productSchema } from "@/features/admin/domain/productSchema";
import { isOrderStatus } from "@/features/orders/domain/order";

export interface ProductFormState {
  message?: string;
  fieldErrors?: Record<string, string>;
}

// Every admin action re-checks the role itself; the proxy and layout are only convenience.
export async function saveProductAction(_prev: ProductFormState, formData: FormData): Promise<ProductFormState> {
  await requireAdmin();
  const supabase = await createSupabaseServerClient();
  if (!supabase) return { message: "The database isn't connected." };

  const parsed = productSchema.safeParse({
    name: formData.get("name"),
    slug: formData.get("slug"),
    description: formData.get("description") ?? "",
    price: formData.get("price"),
    categoryId: formData.get("categoryId"),
    imageUrl: formData.get("imageUrl"),
    sizes: formData.get("sizes") ?? "",
    stock: formData.get("stock"),
    featured: formData.get("featured") === "on",
    active: formData.get("active") === "on",
  });
  if (!parsed.success) {
    const fieldErrors: Record<string, string> = {};
    for (const issue of parsed.error.issues) fieldErrors[String(issue.path[0])] ??= issue.message;
    return { message: "Please fix the highlighted fields.", fieldErrors };
  }

  const v = parsed.data;
  const row = {
    name: v.name, slug: v.slug, description: v.description, price_cents: v.price,
    category_id: v.categoryId, image_url: v.imageUrl, sizes: v.sizes, stock: v.stock,
    featured: v.featured, active: v.active,
  };
  const id = formData.get("id");
  const { error } =
    typeof id === "string" && id
      ? await supabase.from("products").update(row).eq("id", id)
      : await supabase.from("products").insert(row);

  if (error) {
    return error.code === "23505"
      ? { message: "That slug is already used.", fieldErrors: { slug: "Choose a different slug." } }
      : { message: "Couldn't save the product. Please try again." };
  }
  revalidatePath("/", "layout");
  redirect("/admin/products");
}

export async function deleteProductAction(formData: FormData): Promise<void> {
  await requireAdmin();
  const supabase = await createSupabaseServerClient();
  const id = formData.get("id");
  if (!supabase || typeof id !== "string") return;
  // Past orders keep their line items (product_id is set null), so deleting is safe.
  await supabase.from("products").delete().eq("id", id);
  revalidatePath("/", "layout");
  redirect("/admin/products");
}

export async function updateOrderStatusAction(formData: FormData): Promise<void> {
  await requireAdmin();
  const supabase = await createSupabaseServerClient();
  const id = formData.get("id");
  const status = formData.get("status");
  if (!supabase || typeof id !== "string" || !isOrderStatus(status)) return;
  await supabase.from("orders").update({ status }).eq("id", id);
  revalidatePath("/admin", "layout");
  revalidatePath("/account", "layout");
}
