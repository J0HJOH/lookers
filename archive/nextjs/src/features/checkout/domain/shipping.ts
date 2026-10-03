// Mirrors the rule inside the place_order() SQL function. The database is authoritative;
// this only previews the cost in the cart. Values come from the store_settings table.
export interface ShippingRules {
  flatShippingCents: number;
  freeShippingThresholdCents: number;
}

export const DEFAULT_SHIPPING_RULES: ShippingRules = {
  flatShippingCents: 1500,
  freeShippingThresholdCents: 25000,
};

export function shippingCents(subtotal: number, rules: ShippingRules = DEFAULT_SHIPPING_RULES): number {
  if (subtotal <= 0) return 0;
  return subtotal >= rules.freeShippingThresholdCents ? 0 : rules.flatShippingCents;
}
