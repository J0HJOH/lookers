"use client";

import Image from "next/image";
import Link from "next/link";
import { formatMoney } from "@/core/formatting/money";
import { shippingCents, type ShippingRules } from "@/features/checkout/domain/shipping";
import { MAX_QTY_PER_LINE } from "../domain/cart";
import { useCart } from "./CartProvider";

export function CartView({ rules }: { rules: ShippingRules }) {
  const { cart, subtotal, ready, update, remove } = useCart();
  if (!ready) return <p className="py-24 text-center text-ink-muted">Loading your bag…</p>;

  if (cart.length === 0) {
    return (
      <div className="py-24 text-center">
        <p className="display text-4xl">Your bag is empty.</p>
        <p className="mt-3 text-ink-muted">Find something you love.</p>
        <Link href="/shop" className="btn mt-8">Continue shopping</Link>
      </div>
    );
  }

  const shipping = shippingCents(subtotal, rules);
  const toFree = Math.max(0, rules.freeShippingThresholdCents - subtotal);

  return (
    <div className="grid gap-12 lg:grid-cols-[1fr_380px]">
      <ul className="divide-y divide-line border-y border-line">
        {cart.map((l) => (
          <li key={`${l.slug}-${l.size}`} className="flex gap-5 py-6">
            <Link href={`/product/${l.slug}`} className="relative h-36 w-28 shrink-0 bg-surface">
              <Image src={l.imageUrl} alt={l.name} fill sizes="112px" className="object-cover" />
            </Link>
            <div className="flex flex-1 flex-col">
              <div className="flex justify-between gap-3">
                <div>
                  <h2 className="display text-xl">{l.name}</h2>
                  <p className="mt-1 text-sm text-ink-muted">Size {l.size}</p>
                </div>
                <p className="text-sm">{formatMoney(l.priceCents * l.quantity)}</p>
              </div>
              <div className="mt-auto flex items-center justify-between pt-4">
                <div className="flex items-center border border-line">
                  <button type="button" className="h-11 w-11" aria-label={`Decrease quantity of ${l.name}`} onClick={() => update(l, l.quantity - 1)}>−</button>
                  <span className="w-8 text-center text-sm" aria-live="polite">{l.quantity}</span>
                  <button type="button" className="h-11 w-11 disabled:opacity-40" disabled={l.quantity >= MAX_QTY_PER_LINE} aria-label={`Increase quantity of ${l.name}`} onClick={() => update(l, l.quantity + 1)}>+</button>
                </div>
                <button type="button" className="text-[11px] uppercase tracking-[0.2em] text-ink-muted underline hover:text-danger" onClick={() => remove(l)}>Remove</button>
              </div>
            </div>
          </li>
        ))}
      </ul>

      <aside className="h-fit bg-surface p-7">
        <h2 className="display text-2xl">Order summary</h2>
        <dl className="mt-6 space-y-3 text-sm">
          <div className="flex justify-between"><dt>Subtotal</dt><dd>{formatMoney(subtotal)}</dd></div>
          <div className="flex justify-between"><dt>Shipping</dt><dd>{shipping === 0 ? "Free" : formatMoney(shipping)}</dd></div>
          <div className="flex justify-between border-t border-line pt-3 text-base"><dt>Total</dt><dd>{formatMoney(subtotal + shipping)}</dd></div>
        </dl>
        {toFree > 0 && <p className="mt-4 text-xs text-ink-muted">Add {formatMoney(toFree)} more for free shipping.</p>}
        <Link href="/checkout" className="btn mt-6 w-full">Checkout</Link>
        <p className="mt-3 text-center text-xs text-ink-muted">Final prices are confirmed at checkout.</p>
      </aside>
    </div>
  );
}
