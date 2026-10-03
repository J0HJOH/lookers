"use server";

import { redirect } from "next/navigation";
import { getSiteUrl } from "@/core/config";
import { sendEmail } from "@/core/email/mailgun";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { cartLinesSchema, shippingSchema } from "@/features/checkout/domain/checkoutSchema";
import { getOrder, placeOrder } from "@/features/orders/data/orderRepository";
import { buildOrderConfirmationEmail } from "@/features/orders/emails/orderConfirmationEmail";

export interface CheckoutState {
  message?: string;
  fieldErrors?: Record<string, string>;
}

/**
 * Validates input, places the order through the database function (which re-prices every
 * item), sends the Mailgun confirmation, then redirects to the success page.
 */
export async function placeOrderAction(_prev: CheckoutState, formData: FormData): Promise<CheckoutState> {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return { message: "Checkout isn't available until the store is connected to its database." };

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login?next=/checkout");

  const shipping = shippingSchema.safeParse(Object.fromEntries(formData.entries()));
  if (!shipping.success) {
    const fieldErrors: Record<string, string> = {};
    for (const issue of shipping.error.issues) fieldErrors[String(issue.path[0])] ??= issue.message;
    return { message: "Please check the highlighted fields.", fieldErrors };
  }

  let rawItems: unknown;
  try {
    rawItems = JSON.parse(String(formData.get("items") ?? "[]"));
  } catch {
    return { message: "Your bag couldn't be read. Please refresh and try again." };
  }
  const items = cartLinesSchema.safeParse(rawItems);
  if (!items.success) return { message: items.error.issues[0]?.message ?? "Your bag is invalid." };

  const result = await placeOrder(supabase, items.data, shipping.data);
  if (!result.ok) return { message: result.failure.message };

  // Best effort: a failed email must never undo or hide a placed order.
  const order = await getOrder(supabase, result.value.orderId);
  if (order) {
    const email = buildOrderConfirmationEmail(order, `${getSiteUrl()}/account/orders/${order.id}`);
    const sent = await sendEmail(email);
    if (!sent.ok && sent.failure.kind !== "not_configured") {
      console.error(`Order confirmation email failed for order ${order.orderNumber}: ${sent.failure.kind}`);
    }
  }

  redirect(`/checkout/success?order=${result.value.orderId}`);
}
