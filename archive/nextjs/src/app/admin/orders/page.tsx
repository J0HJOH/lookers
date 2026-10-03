import Link from "next/link";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { formatDate, formatMoney } from "@/core/formatting/money";
import { listOrders } from "@/features/orders/data/orderRepository";
import { StatusBadge } from "@/features/orders/presentation/StatusBadge";

export default async function AdminOrders() {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return <p>The database isn&apos;t connected.</p>;
  const orders = await listOrders(supabase, 200);
  return (
    <div>
      <h1 className="display mb-6 text-4xl">Orders</h1>
      {orders.length === 0 ? <p className="py-12 text-center text-ink-muted">No orders yet.</p> : (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead className="eyebrow border-b border-line"><tr><th className="py-3">Order</th><th>Date</th><th>Customer</th><th>Total</th><th>Status</th></tr></thead>
            <tbody className="divide-y divide-line">
              {orders.map((o) => (
                <tr key={o.id} className="hover:bg-surface">
                  <td className="py-3"><Link href={`/admin/orders/${o.id}`} className="font-medium underline">{o.orderNumber}</Link></td>
                  <td>{formatDate(o.createdAt)}</td><td>{o.shipTo.name}<br /><span className="text-ink-muted">{o.email}</span></td>
                  <td>{formatMoney(o.totalCents)}</td><td><StatusBadge status={o.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
