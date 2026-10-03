import { describe, expect, it } from "vitest";
import { addLine, itemCount, parseStoredCart, removeLine, setQuantity, subtotalCents, type CartLine } from "@/features/cart/domain/cart";

const line = (over: Partial<CartLine> = {}): CartLine => ({ slug: "a", name: "A", imageUrl: "https://x", priceCents: 1000, size: "M", quantity: 1, ...over });

describe("cart", () => {
  it("merges the same product and size", () => {
    const c = addLine(addLine([], line()), line({ quantity: 2 }));
    expect(c).toHaveLength(1);
    expect(c[0].quantity).toBe(3);
  });
  it("keeps different sizes as separate lines", () => {
    expect(addLine(addLine([], line()), line({ size: "L" }))).toHaveLength(2);
  });
  it("caps quantity at 10", () => {
    expect(addLine([line({ quantity: 9 })], line({ quantity: 5 }))[0].quantity).toBe(10);
  });
  it("removes a line when quantity drops to 0", () => {
    expect(setQuantity([line()], { slug: "a", size: "M" }, 0)).toEqual([]);
  });
  it("computes totals", () => {
    const c = [line({ quantity: 2 }), line({ slug: "b", priceCents: 500 })];
    expect(itemCount(c)).toBe(3);
    expect(subtotalCents(c)).toBe(2500);
    expect(removeLine(c, { slug: "b", size: "M" })).toHaveLength(1);
  });
  it("ignores tampered or invalid stored carts", () => {
    expect(parseStoredCart("not json")).toEqual([]);
    expect(parseStoredCart(JSON.stringify([{ slug: "a", quantity: 999 }]))).toEqual([]);
    expect(parseStoredCart(JSON.stringify({ a: 1 }))).toEqual([]);
    expect(parseStoredCart(JSON.stringify([line()]))).toHaveLength(1);
  });
});
