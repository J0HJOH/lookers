import { describe, expect, it } from "vitest";
import { mapPlaceOrderError } from "@/features/orders/data/orderRepository";

describe("mapPlaceOrderError", () => {
  it("turns coded database errors into friendly messages without leaking internals", () => {
    expect(mapPlaceOrderError("OUT_OF_STOCK:noir-leather-jacket").kind).toBe("out_of_stock");
    expect(mapPlaceOrderError("PRODUCT_UNAVAILABLE:x").kind).toBe("validation");
    expect(mapPlaceOrderError("AUTH_REQUIRED").kind).toBe("auth");
    const unknown = mapPlaceOrderError('relation "orders" does not exist');
    expect(unknown.kind).toBe("server");
    expect(unknown.message).not.toContain("relation");
  });
});
