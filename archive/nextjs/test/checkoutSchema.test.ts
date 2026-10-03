import { describe, expect, it } from "vitest";
import { cartLinesSchema, shippingSchema } from "@/features/checkout/domain/checkoutSchema";

const valid = { fullName: "Ada Obi", email: "ada@example.com", phone: "+234 801 234 5678", line1: "12 Marina Road", city: "Lagos", region: "Lagos", postalCode: "101233", country: "Nigeria" };

describe("shippingSchema", () => {
  it("accepts a valid address", () => expect(shippingSchema.safeParse(valid).success).toBe(true));
  it("rejects a bad email and phone", () => {
    expect(shippingSchema.safeParse({ ...valid, email: "nope" }).success).toBe(false);
    expect(shippingSchema.safeParse({ ...valid, phone: "abc" }).success).toBe(false);
  });
  it("rejects whitespace-only fields", () => expect(shippingSchema.safeParse({ ...valid, city: "   " }).success).toBe(false));
});

describe("cartLinesSchema", () => {
  it("rejects empty carts, bad slugs and huge quantities", () => {
    expect(cartLinesSchema.safeParse([]).success).toBe(false);
    expect(cartLinesSchema.safeParse([{ slug: "A B", size: "M", quantity: 1 }]).success).toBe(false);
    expect(cartLinesSchema.safeParse([{ slug: "a", size: "M", quantity: 11 }]).success).toBe(false);
    expect(cartLinesSchema.safeParse([{ slug: "a", size: "M", quantity: 1 }]).success).toBe(true);
  });
  it("never accepts client-sent prices as a field", () => {
    const parsed = cartLinesSchema.parse([{ slug: "a", size: "M", quantity: 1, priceCents: 1 }]);
    expect(parsed[0]).not.toHaveProperty("priceCents");
  });
});
