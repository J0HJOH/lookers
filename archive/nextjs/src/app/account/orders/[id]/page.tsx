import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { requireUser } from "@/features/auth/data/session";
import { getOrder } from "@/features/orders/data/orderRepository";
import { OrderDetails } from "@/features/orders/presentation/OrderDetails";

export const metadata: Metadata = { title: "Order", robots: { index: false } };

export default async function AccountOrderPage(props: PageProps<"/account/orders/[id]">) {
  const { id } = await props.params;
  await requireUser(`/account/orders/${id}`);
  const supabase = await createSupabaseServerClient();
  // RLS means someone else's order id simply returns nothing.
  const order = supabase && /^[0-9a-f-]{36}$/.test(id) ? await getOrder(supabase, id) : null;
  if (!order) notFound();
  return (
    <div className="container-page py-12">
      <Link href="/account" className="eyebrow hover:text-gold-deep">← All orders</Link>
      <div className="mt-6"><OrderDetails order={order} /></div>
    </div>
  );
}
