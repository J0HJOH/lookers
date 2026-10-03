import Link from "next/link";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { formatDate, formatMoney } from "@/core/formatting/money";
import { getAdminStats } from "@/features/admin/data/adminRepository";
import { listOrders } from "@/features/orders/data/orderRepository";
import { StatusBadge } from "@/features/orders/presentation/StatusBadge";

export default async function AdminOverview() {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return <p>The database isn&apos;t connected.</p>;
  const [stats, recent] = await Promise.all([getAdminStats(supabase), listOrders(supabase, 6)]);

  const tiles = [
    ["Revenue", formatMoney(stats.revenueCents)],
    ["Orders", String(stats.orderCount)],
    ["Pending", String(stats.pendingCount)],
    ["Customers", String(stats.customerCount)],
  ];

  return (
    <div className="space-y-12">
      <dl className="grid grid-cols-2 gap-4 md:grid-cols-4">
        {tiles.map(([k, v]) => (
          <div key={k} className="bg-surface p-6"><dt className="eyebrow">{k}</dt><dd className="display mt-3 text-4xl">{v}</dd></div>
        ))}
      </dl>
      <div className="grid gap-10 lg:grid-cols-2">
        <section aria-labelledby="recent">
          <h2 id="recent" className="display mb-4 text-2xl">Recent orders</h2>
          {recent.length === 0 ? <p className="text-ink-muted">No orders yet.</p> : (
            <ul className="divide-y divide-line border-y border-line">
              {recent.map((o) => (
                <li key={o.id}><Link href={`/admin/orders/${o.id}`} className="flex items-center justify-between gap-3 py-4 hover:bg-surface">
                  <span><span className="font-medium">{o.orderNumber}</span> <span className="text-sm text-ink-muted">· {formatDate(o.createdAt)}</span></span>
                  <span className="flex items-center gap-4"><StatusBadge status={o.status} /><span className="text-sm">{formatMoney(o.totalCents)}</span></span>
                </Link></li>
              ))}
            </ul>
          )}
        </section>
        <section aria-labelledby="low">
          <h2 id="low" className="display mb-4 text-2xl">Low stock</h2>
          {stats.lowStock.length === 0 ? <p className="text-ink-muted">Everything is well stocked.</p> : (
            <ul className="divide-y divide-line border-y border-line">
              {stats.lowStock.map((p) => (
                <li key={p.id}><Link href={`/admin/products/${p.id}`} className="flex justify-between py-4 hover:bg-surface"><span>{p.name}</span><span className={p.stock === 0 ? "text-danger" : ""}>{p.stock === 0 ? "Sold out" : `${p.stock} left`}</span></Link></li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </div>
  );
}
