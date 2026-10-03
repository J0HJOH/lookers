/// Mirrors the rule inside the `place_order` SQL function. The database is authoritative;
/// this only previews the shipping cost in the bag. Values come from the `store_settings` table.
class ShippingRules {
  const ShippingRules({
    this.flatShippingCents = 1500,
    this.freeShippingThresholdCents = 25000,
  });

  final int flatShippingCents;
  final int freeShippingThresholdCents;

  int shippingFor(int subtotal) {
    if (subtotal <= 0) return 0;
    return subtotal >= freeShippingThresholdCents ? 0 : flatShippingCents;
  }
}
