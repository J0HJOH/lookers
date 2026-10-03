import type { SupabaseClient } from "@supabase/supabase-js";
import { fail, ok, type Result } from "@/core/errors/failures";
import type { CartLinesInput, ShippingInput } from "@/features/checkout/domain/checkoutSchema";
import { isOrderStatus, type Order } from "../domain/order";

const ORDER_COLUMNS =
  "id, order_number, status, email, created_at, subtotal_cents, shipping_cents, total_cents, payment_method, ship_name, ship_phone, ship_line1, ship_line2, ship_city, ship_region, ship_postal_code, ship_country, order_items(product_name, image_url, size, unit_price_cents, quantity)";

interface OrderRow {
  id: string;
  order_number: string;
  status: string;
  email: string;
  created_at: string;
  subtotal_cents: number;
  shipping_cents: number;
  total_cents: number;
  payment_method: string;
  ship_name: string;
  ship_phone: string;
  ship_line1: string;
  ship_line2: string | null;
  ship_city: string;
  ship_region: string;
  ship_postal_code: string;
  ship_country: string;
  order_items: {
    product_name: string;
    image_url: string;
    size: string;
    unit_price_cents: number;
    quantity: number;
  }[];
}

function toOrder(row: OrderRow): Order | null {
  if (!isOrderStatus(row.status)) return null;
  return {
    id: row.id,
    orderNumber: row.order_number,
    status: row.status,
    email: row.email,
    createdAt: row.created_at,
    subtotalCents: row.subtotal_cents,
    shippingCents: row.shipping_cents,
    totalCents: row.total_cents,
    paymentMethod: row.payment_method,
    shipTo: {
      name: row.ship_name,
      phone: row.ship_phone,
      line1: row.ship_line1,
      line2: row.ship_line2,
      city: row.ship_city,
      region: row.ship_region,
      postalCode: row.ship_postal_code,
      country: row.ship_country,
    },
    items: row.order_items.map((i) => ({
      productName: i.product_name,
      imageUrl: i.image_url,
      size: i.size,
      unitPriceCents: i.unit_price_cents,
      quantity: i.quantity,
    })),
  };
}

/** Maps the coded exceptions raised by place_order() to messages a shopper can act on. */
export function mapPlaceOrderError(message: string): { kind: "out_of_stock" | "validation" | "auth" | "server"; message: string } {
  if (message.startsWith("AUTH_REQUIRED")) return { kind: "auth", message: "Please sign in to place your order." };
  if (message.startsWith("OUT_OF_STOCK")) return { kind: "out_of_stock", message: "One of the items just sold out or has less stock than you asked for. Please review your bag." };
  if (message.startsWith("PRODUCT_UNAVAILABLE")) return { kind: "validation", message: "An item in your bag is no longer available. Please remove it and try again." };
  if (message.startsWith("INVALID_SIZE") || message.startsWith("INVALID_QUANTITY") || message.startsWith("INVALID_CART"))
    return { kind: "validation", message: "Your bag has an invalid item. Please review it and try again." };
  return { kind: "server", message: "We couldn't place your order. Please try again." };
}

export async function placeOrder(
  supabase: SupabaseClient,
  items: CartLinesInput,
  shipping: ShippingInput,
): Promise<Result<{ orderId: string; orderNumber: string }>> {
  const { data, error } = await supabase.rpc("place_order", {
    p_items: items,
    p_shipping: shipping,
    p_notes: shipping.notes,
  });
  if (error) {
    const mapped = mapPlaceOrderError(error.message);
    return fail(mapped.kind, mapped.message);
  }
  const row = Array.isArray(data) ? data[0] : data;
  if (!row?.o_id || !row?.o_number) return fail("unexpected", "We couldn't confirm your order. Please check your account.");
  return ok({ orderId: row.o_id as string, orderNumber: row.o_number as string });
}

export async function getOrder(supabase: SupabaseClient, id: string): Promise<Order | null> {
  const { data } = await supabase.from("orders").select(ORDER_COLUMNS).eq("id", id).maybeSingle();
  return data ? toOrder(data as unknown as OrderRow) : null;
}

/** RLS decides what's visible: shoppers see their own orders, admins see all. */
export async function listOrders(supabase: SupabaseClient, limit = 100): Promise<Order[]> {
  const { data } = await supabase
    .from("orders")
    .select(ORDER_COLUMNS)
    .order("created_at", { ascending: false })
    .limit(limit);
  return ((data ?? []) as unknown as OrderRow[]).map(toOrder).filter((o): o is Order => o !== null);
}
