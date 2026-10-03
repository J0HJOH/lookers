import Image from "next/image";
import Link from "next/link";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { formatMoney } from "@/core/formatting/money";
import { listAdminProducts } from "@/features/admin/data/adminRepository";

export default async function AdminProducts() {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return <p>The database isn&apos;t connected.</p>;
  const products = await listAdminProducts(supabase);
  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="display text-4xl">Products</h1>
        <Link href="/admin/products/new" className="btn">New product</Link>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[640px] text-left text-sm">
          <thead className="eyebrow border-b border-line"><tr><th className="py-3">Product</th><th>Category</th><th>Price</th><th>Stock</th><th>Status</th></tr></thead>
          <tbody className="divide-y divide-line">
            {products.map((p) => (
              <tr key={p.id} className="hover:bg-surface">
                <td className="py-3"><Link href={`/admin/products/${p.id}`} className="flex items-center gap-3"><span className="relative h-14 w-11 shrink-0 bg-surface"><Image src={p.imageUrl} alt="" fill sizes="44px" className="object-cover" /></span><span className="font-medium">{p.name}</span></Link></td>
                <td>{p.categoryName}</td><td>{formatMoney(p.priceCents)}</td>
                <td className={p.stock <= 5 ? "text-danger" : ""}>{p.stock}</td>
                <td>{p.active ? "Visible" : "Hidden"}{p.featured ? " · Featured" : ""}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {products.length === 0 && <p className="py-12 text-center text-ink-muted">No products yet. Run supabase/seed.sql or add one.</p>}
      </div>
    </div>
  );
}
