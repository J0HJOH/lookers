import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { formatMoney } from "@/core/formatting/money";
import { requireUser } from "@/features/auth/data/session";
import { ClearCartOnMount } from "@/features/checkout/presentation/ClearCartOnMount";
import { getOrder } from "@/features/orders/data/orderRepository";

export const metadata: Metadata = { title: "Order confirmed", robots: { index: false } };

export default async function SuccessPage(props: PageProps<"/checkout/success">) {
  const sp = await props.searchParams;
  const id = typeof sp.order === "string" ? sp.order : "";
  await requireUser("/account");
  const supabase = await createSupabaseServerClient();
  const order = supabase && /^[0-9a-f-]{36}$/.test(id) ? await getOrder(supabase, id) : null;
  if (!order) notFound();

  return (
    <div className="container-page max-w-2xl py-20 text-center">
      <ClearCartOnMount />
      <p className="eyebrow">Order confirmed</p>
      <h1 className="display mt-4 text-5xl">Thank you.</h1>
      <p className="mt-5 text-ink-soft">
        Your order <strong>{order.orderNumber}</strong> is in. A confirmation has been sent to {order.email}.
      </p>
      <p className="mt-2 text-ink-muted">Total {formatMoney(order.totalCents)} · pay on delivery</p>
      <div className="mt-10 flex flex-wrap justify-center gap-3">
        <Link href={`/account/orders/${order.id}`} className="btn">View order</Link>
        <Link href="/shop" className="btn-ghost">Keep shopping</Link>
      </div>
    </div>
  );
}
