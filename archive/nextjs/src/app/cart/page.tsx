import type { Metadata } from "next";
import { CartView } from "@/features/cart/presentation/CartView";
import { getShippingRules } from "@/features/checkout/settingsRepository";

export const metadata: Metadata = { title: "Your bag" };

export default async function CartPage() {
  const rules = await getShippingRules();
  return (
    <div className="container-page py-12">
      <h1 className="display mb-10 text-5xl">Your bag</h1>
      <CartView rules={rules} />
    </div>
  );
}
