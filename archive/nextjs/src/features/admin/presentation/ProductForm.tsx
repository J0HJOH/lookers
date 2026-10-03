"use client";

import { useActionState } from "react";
import { saveProductAction, type ProductFormState } from "@/app/admin/actions";
import type { Category } from "@/features/catalog/domain/product";
import type { AdminProduct } from "../data/adminRepository";

const initial: ProductFormState = {};

export function ProductForm({ product, categories }: { product?: AdminProduct; categories: (Category & { id: string })[] }) {
  const [state, action, pending] = useActionState(saveProductAction, initial);
  const e = state.fieldErrors ?? {};
  const err = (k: string) => e[k] && <p className="mt-1 text-xs text-danger">{e[k]}</p>;

  return (
    <form action={action} className="grid max-w-3xl gap-5 sm:grid-cols-2">
      {product && <input type="hidden" name="id" value={product.id} />}
      <div className="sm:col-span-2"><label className="label" htmlFor="name">Name</label><input id="name" name="name" required defaultValue={product?.name} className="field" />{err("name")}</div>
      <div><label className="label" htmlFor="slug">Slug (URL)</label><input id="slug" name="slug" required defaultValue={product?.slug} className="field" placeholder="noir-leather-jacket" />{err("slug")}</div>
      <div><label className="label" htmlFor="categoryId">Category</label>
        <select id="categoryId" name="categoryId" required defaultValue={product?.categoryId ?? ""} className="field">
          <option value="" disabled>Choose…</option>
          {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>{err("categoryId")}</div>
      <div className="sm:col-span-2"><label className="label" htmlFor="description">Description</label><textarea id="description" name="description" rows={4} defaultValue={product?.description} className="field" />{err("description")}</div>
      <div><label className="label" htmlFor="price">Price</label><input id="price" name="price" required inputMode="decimal" defaultValue={product ? (product.priceCents / 100).toFixed(2) : ""} className="field" placeholder="49.99" />{err("price")}</div>
      <div><label className="label" htmlFor="stock">Stock</label><input id="stock" name="stock" required inputMode="numeric" defaultValue={product?.stock ?? 0} className="field" />{err("stock")}</div>
      <div className="sm:col-span-2"><label className="label" htmlFor="sizes">Sizes (comma separated)</label><input id="sizes" name="sizes" required defaultValue={product?.sizes.join(", ") ?? "S, M, L"} className="field" />{err("sizes")}</div>
      <div className="sm:col-span-2"><label className="label" htmlFor="imageUrl">Image URL</label><input id="imageUrl" name="imageUrl" required type="url" defaultValue={product?.imageUrl} className="field" placeholder="https://images.pexels.com/photos/…" />{err("imageUrl")}</div>
      <label className="flex items-center gap-3 text-sm"><input type="checkbox" name="featured" defaultChecked={product?.featured} className="h-4 w-4" /> Featured on the homepage</label>
      <label className="flex items-center gap-3 text-sm"><input type="checkbox" name="active" defaultChecked={product?.active ?? true} className="h-4 w-4" /> Visible in the shop</label>
      {state.message && <p role="alert" className="text-sm text-danger sm:col-span-2">{state.message}</p>}
      <div className="sm:col-span-2"><button className="btn" type="submit" disabled={pending}>{pending ? "Saving…" : product ? "Save changes" : "Create product"}</button></div>
    </form>
  );
}
