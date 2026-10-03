import Image from "next/image";
import { formatDate, formatMoney } from "@/core/formatting/money";
import type { Order } from "../domain/order";
import { StatusBadge } from "./StatusBadge";

export function OrderDetails({ order }: { order: Order }) {
  const a = order.shipTo;
  return (
    <div className="grid gap-10 lg:grid-cols-[1fr_320px]">
      <div>
        <div className="flex flex-wrap items-center gap-4">
          <h2 className="display text-3xl">{order.orderNumber}</h2>
          <StatusBadge status={order.status} />
        </div>
        <p className="mt-1 text-sm text-ink-muted">Placed {formatDate(order.createdAt)}</p>
        <ul className="mt-6 divide-y divide-line border-y border-line">
          {order.items.map((i, idx) => (
            <li key={idx} className="flex gap-4 py-4 text-sm">
              <div className="relative h-20 w-16 shrink-0 bg-surface"><Image src={i.imageUrl} alt="" fill sizes="64px" className="object-cover" /></div>
              <div className="flex-1"><p className="font-medium">{i.productName}</p><p className="text-ink-muted">Size {i.size} · Qty {i.quantity}</p></div>
              <p>{formatMoney(i.unitPriceCents * i.quantity)}</p>
            </li>
          ))}
        </ul>
      </div>
      <aside className="space-y-6 bg-surface p-6 text-sm">
        <div>
          <p className="eyebrow mb-2">Delivering to</p>
          <p className="leading-relaxed">{a.name}<br />{a.line1}{a.line2 && <><br />{a.line2}</>}<br />{a.city}, {a.region} {a.postalCode}<br />{a.country}<br />{a.phone}</p>
        </div>
        <dl className="space-y-2 border-t border-line pt-4">
          <div className="flex justify-between"><dt>Subtotal</dt><dd>{formatMoney(order.subtotalCents)}</dd></div>
          <div className="flex justify-between"><dt>Shipping</dt><dd>{order.shippingCents === 0 ? "Free" : formatMoney(order.shippingCents)}</dd></div>
          <div className="flex justify-between text-base"><dt>Total</dt><dd>{formatMoney(order.totalCents)}</dd></div>
        </dl>
        <p className="text-xs text-ink-muted">Payment: pay on delivery</p>
      </aside>
    </div>
  );
}
