export const MAX_QTY_PER_LINE = 10;
export const MAX_LINES = 30;

export interface CartLine {
  slug: string;
  name: string;
  imageUrl: string;
  priceCents: number; // display only; the database re-prices at checkout
  size: string;
  quantity: number;
}

export type Cart = CartLine[];

const sameLine = (a: Pick<CartLine, "slug" | "size">, b: Pick<CartLine, "slug" | "size">) =>
  a.slug === b.slug && a.size === b.size;

export function addLine(cart: Cart, line: CartLine): Cart {
  const existing = cart.find((l) => sameLine(l, line));
  if (existing) {
    return cart.map((l) =>
      l === existing ? { ...l, quantity: Math.min(MAX_QTY_PER_LINE, l.quantity + line.quantity) } : l,
    );
  }
  if (cart.length >= MAX_LINES) return cart;
  return [...cart, { ...line, quantity: Math.min(MAX_QTY_PER_LINE, Math.max(1, line.quantity)) }];
}

export function setQuantity(cart: Cart, key: Pick<CartLine, "slug" | "size">, quantity: number): Cart {
  if (quantity <= 0) return removeLine(cart, key);
  return cart.map((l) => (sameLine(l, key) ? { ...l, quantity: Math.min(MAX_QTY_PER_LINE, quantity) } : l));
}

export const removeLine = (cart: Cart, key: Pick<CartLine, "slug" | "size">): Cart =>
  cart.filter((l) => !sameLine(l, key));

export const itemCount = (cart: Cart): number => cart.reduce((n, l) => n + l.quantity, 0);
export const subtotalCents = (cart: Cart): number =>
  cart.reduce((sum, l) => sum + l.priceCents * l.quantity, 0);

/** Guards against tampered or outdated localStorage content. */
export function parseStoredCart(raw: string | null): Cart {
  if (!raw) return [];
  try {
    const data: unknown = JSON.parse(raw);
    if (!Array.isArray(data)) return [];
    return data
      .filter(
        (l): l is CartLine =>
          typeof l?.slug === "string" &&
          typeof l?.name === "string" &&
          typeof l?.imageUrl === "string" &&
          typeof l?.size === "string" &&
          Number.isInteger(l?.priceCents) &&
          Number.isInteger(l?.quantity) &&
          l.quantity >= 1 &&
          l.quantity <= MAX_QTY_PER_LINE,
      )
      .slice(0, MAX_LINES);
  } catch {
    return [];
  }
}
