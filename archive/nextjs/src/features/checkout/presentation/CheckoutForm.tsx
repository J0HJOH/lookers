"use client";

import Image from "next/image";
import Link from "next/link";
import { useActionState } from "react";
import { placeOrderAction, type CheckoutState } from "@/app/checkout/actions";
import { formatMoney } from "@/core/formatting/money";
import { useCart } from "@/features/cart/presentation/CartProvider";
import { shippingCents, type ShippingRules } from "../domain/shipping";

const initial: CheckoutState = {};

function Field({ name, label, error, type = "text", defaultValue, autoComplete, required = true }: {
  name: string; label: string; error?: string; type?: string; defaultValue?: string; autoComplete?: string; required?: boolean;
}) {
  return (
    <div>
      <label htmlFor={name} className="label">{label}</label>
      <input id={name} name={name} type={type} defaultValue={defaultValue} autoComplete={autoComplete} required={required} aria-invalid={Boolean(error)} aria-describedby={error ? `${name}-err` : undefined} className="field" />
      {error && <p id={`${name}-err`} className="mt-1 text-xs text-danger">{error}</p>}
    </div>
  );
}

export function CheckoutForm({ rules, defaults }: { rules: ShippingRules; defaults: { name: string; email: string } }) {
  const { cart, subtotal, ready } = useCart();
  const [state, formAction, pending] = useActionState(placeOrderAction, initial);
  const e = state.fieldErrors ?? {};

  if (!ready) return <p className="py-24 text-center text-ink-muted">Loading…</p>;
  if (cart.length === 0) {
    return (
      <div className="py-24 text-center">
        <p className="display text-4xl">Your bag is empty.</p>
        <Link href="/shop" className="btn mt-8">Continue shopping</Link>
      </div>
    );
  }

  const shipping = shippingCents(subtotal, rules);
  const items = JSON.stringify(cart.map((l) => ({ slug: l.slug, size: l.size, quantity: l.quantity })));

  return (
    <form action={formAction} className="grid gap-12 lg:grid-cols-[1fr_400px]">
      <input type="hidden" name="items" value={items} />
      <div className="space-y-10">
        <section aria-labelledby="contact">
          <h2 id="contact" className="display mb-5 text-2xl">Contact</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field name="fullName" label="Full name" defaultValue={defaults.name} error={e.fullName} autoComplete="name" />
            <Field name="email" label="Email" type="email" defaultValue={defaults.email} error={e.email} autoComplete="email" />
            <Field name="phone" label="Phone" type="tel" error={e.phone} autoComplete="tel" />
          </div>
        </section>

        <section aria-labelledby="ship">
          <h2 id="ship" className="display mb-5 text-2xl">Delivery address</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="sm:col-span-2"><Field name="line1" label="Address" error={e.line1} autoComplete="address-line1" /></div>
            <div className="sm:col-span-2"><Field name="line2" label="Apartment, suite (optional)" required={false} error={e.line2} autoComplete="address-line2" /></div>
            <Field name="city" label="City" error={e.city} autoComplete="address-level2" />
            <Field name="region" label="State / region" error={e.region} autoComplete="address-level1" />
            <Field name="postalCode" label="Postal code" error={e.postalCode} autoComplete="postal-code" />
            <Field name="country" label="Country" error={e.country} autoComplete="country-name" />
            <div className="sm:col-span-2">
              <label htmlFor="notes" className="label">Delivery notes (optional)</label>
              <textarea id="notes" name="notes" rows={3} maxLength={500} className="field" />
              {e.notes && <p className="mt-1 text-xs text-danger">{e.notes}</p>}
            </div>
          </div>
        </section>

        <section aria-labelledby="pay">
          <h2 id="pay" className="display mb-5 text-2xl">Payment</h2>
          <p className="border border-line bg-surface p-5 text-sm text-ink-soft">
            <strong>Pay on delivery.</strong> You&apos;ll pay when your order arrives. Online card payment is coming soon.
          </p>
        </section>
      </div>

      <aside className="h-fit bg-surface p-7">
        <h2 className="display text-2xl">Your order</h2>
        <ul className="mt-5 space-y-4">
          {cart.map((l) => (
            <li key={`${l.slug}-${l.size}`} className="flex gap-4 text-sm">
              <div className="relative h-20 w-16 shrink-0 bg-paper"><Image src={l.imageUrl} alt="" fill sizes="64px" className="object-cover" /></div>
              <div className="flex-1">
                <p className="font-medium">{l.name}</p>
                <p className="text-ink-muted">Size {l.size} · Qty {l.quantity}</p>
              </div>
              <p>{formatMoney(l.priceCents * l.quantity)}</p>
            </li>
          ))}
        </ul>
        <dl className="mt-6 space-y-3 border-t border-line pt-5 text-sm">
          <div className="flex justify-between"><dt>Subtotal</dt><dd>{formatMoney(subtotal)}</dd></div>
          <div className="flex justify-between"><dt>Shipping</dt><dd>{shipping === 0 ? "Free" : formatMoney(shipping)}</dd></div>
          <div className="flex justify-between text-base"><dt>Total</dt><dd>{formatMoney(subtotal + shipping)}</dd></div>
        </dl>
        {state.message && <p role="alert" className="mt-5 text-sm text-danger">{state.message}</p>}
        <button type="submit" className="btn mt-6 w-full" disabled={pending}>{pending ? "Placing order…" : "Place order"}</button>
        <p className="mt-3 text-center text-xs text-ink-muted">Totals are confirmed by our server when you place the order.</p>
      </aside>
    </form>
  );
}
