import type { Metadata } from "next";
import { CheckoutForm } from "@/features/checkout/presentation/CheckoutForm";
import { getShippingRules } from "@/features/checkout/settingsRepository";
import { requireUser } from "@/features/auth/data/session";

export const metadata: Metadata = { title: "Checkout", robots: { index: false } };

export default async function CheckoutPage() {
  const [user, rules] = await Promise.all([requireUser("/checkout"), getShippingRules()]);
  return (
    <div className="container-page py-12">
      <h1 className="display mb-10 text-5xl">Checkout</h1>
      <CheckoutForm rules={rules} defaults={{ name: user.fullName ?? "", email: user.email }} />
    </div>
  );
}
