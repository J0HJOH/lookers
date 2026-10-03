import Link from "next/link";
import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { updateOrderStatusAction } from "@/app/admin/actions";
import { getOrder } from "@/features/orders/data/orderRepository";
import { ORDER_STATUSES, STATUS_LABEL } from "@/features/orders/domain/order";
import { OrderDetails } from "@/features/orders/presentation/OrderDetails";

export default async function AdminOrderPage(props: PageProps<"/admin/orders/[id]">) {
  const { id } = await props.params;
  const supabase = await createSupabaseServerClient();
  if (!supabase || !/^[0-9a-f-]{36}$/.test(id)) notFound();
  const order = await getOrder(supabase, id);
  if (!order) notFound();
  return (
    <div>
      <Link href="/admin/orders" className="eyebrow hover:text-gold-deep">← All orders</Link>
      <form action={updateOrderStatusAction} className="my-6 flex flex-wrap items-end gap-3 bg-surface p-5">
        <input type="hidden" name="id" value={order.id} />
        <div><label htmlFor="status" className="label">Update status</label>
          <select id="status" name="status" defaultValue={order.status} className="field w-48">{ORDER_STATUSES.map((s) => <option key={s} value={s}>{STATUS_LABEL[s]}</option>)}</select></div>
        <button className="btn min-h-11" type="submit">Save</button>
        <p className="w-full text-xs text-ink-muted">Customers see the new status in their account. Cancelling does not restock items yet; adjust stock on the product.</p>
      </form>
      <OrderDetails order={order} />
    </div>
  );
}
