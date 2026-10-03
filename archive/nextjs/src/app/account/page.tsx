import type { Metadata } from "next";
import Link from "next/link";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { formatDate, formatMoney } from "@/core/formatting/money";
import { requireUser } from "@/features/auth/data/session";
import { listOrders } from "@/features/orders/data/orderRepository";
import { StatusBadge } from "@/features/orders/presentation/StatusBadge";

export const metadata: Metadata = { title: "My account", robots: { index: false } };

export default async function AccountPage() {
  const user = await requireUser("/account");
  const supabase = await createSupabaseServerClient();
  const orders = supabase ? await listOrders(supabase) : [];

  return (
    <div className="container-page py-12">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="eyebrow">My account</p>
          <h1 className="display mt-3 text-5xl">Hello, {user.fullName?.split(" ")[0] ?? "there"}.</h1>
          <p className="mt-2 text-ink-muted">{user.email}</p>
        </div>
        <form action="/auth/signout" method="post"><button className="btn-ghost" type="submit">Sign out</button></form>
      </div>

      <h2 className="display mb-6 mt-14 text-3xl">Your orders</h2>
      {orders.length === 0 ? (
        <div className="border border-line py-16 text-center">
          <p className="display text-2xl">No orders yet.</p>
          <Link href="/shop" className="btn mt-6">Start shopping</Link>
        </div>
      ) : (
        <ul className="divide-y divide-line border-y border-line">
          {orders.map((o) => (
            <li key={o.id}>
              <Link href={`/account/orders/${o.id}`} className="flex flex-wrap items-center justify-between gap-3 py-5 hover:bg-surface">
                <div><p className="font-medium">{o.orderNumber}</p><p className="text-sm text-ink-muted">{formatDate(o.createdAt)} · {o.items.length} item{o.items.length === 1 ? "" : "s"}</p></div>
                <div className="flex items-center gap-6"><StatusBadge status={o.status} /><span className="text-sm">{formatMoney(o.totalCents)}</span></div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
