import { describe, expect, it } from "vitest";
import { shippingCents } from "@/features/checkout/domain/shipping";

describe("shipping", () => {
  it("is free for an empty bag and over the threshold", () => {
    expect(shippingCents(0)).toBe(0);
    expect(shippingCents(25000)).toBe(0);
  });
  it("charges the flat fee under the threshold", () => {
    expect(shippingCents(24999)).toBe(1500);
  });
});
