"use client";

import { createContext, useCallback, useContext, useMemo, useSyncExternalStore, type ReactNode } from "react";
import {
  addLine,
  itemCount,
  parseStoredCart,
  removeLine,
  setQuantity,
  subtotalCents,
  type Cart,
  type CartLine,
} from "../domain/cart";

const STORAGE_KEY = "lookers.cart.v1";
const EMPTY: Cart = [];

// The bag lives in localStorage and is read through useSyncExternalStore, so the server
// render (empty bag) and the first client render match, then the stored bag appears.
let cachedRaw: string | null = null;
let cachedCart: Cart = EMPTY;
const listeners = new Set<() => void>();
let memoryOnly: Cart | null = null; // used when storage is blocked (private mode)

function readCart(): Cart {
  if (memoryOnly) return memoryOnly;
  let raw: string | null = null;
  try {
    raw = window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return cachedCart;
  }
  if (raw !== cachedRaw) {
    cachedRaw = raw;
    cachedCart = raw ? parseStoredCart(raw) : EMPTY;
  }
  return cachedCart;
}

function writeCart(next: Cart): void {
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    memoryOnly = null;
  } catch {
    memoryOnly = next;
  }
  listeners.forEach((l) => l());
}

function subscribe(onChange: () => void): () => void {
  listeners.add(onChange);
  const onStorage = (e: StorageEvent) => {
    if (e.key === STORAGE_KEY) onChange(); // another tab changed the bag
  };
  window.addEventListener("storage", onStorage);
  return () => {
    listeners.delete(onChange);
    window.removeEventListener("storage", onStorage);
  };
}

const noopSubscribe = () => () => {};

interface CartContextValue {
  cart: Cart;
  count: number;
  subtotal: number;
  ready: boolean;
  add: (line: CartLine) => void;
  update: (key: Pick<CartLine, "slug" | "size">, quantity: number) => void;
  remove: (key: Pick<CartLine, "slug" | "size">) => void;
  clear: () => void;
}

const CartContext = createContext<CartContextValue | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const cart = useSyncExternalStore(subscribe, readCart, () => EMPTY);
  const ready = useSyncExternalStore(noopSubscribe, () => true, () => false);

  const add = useCallback((line: CartLine) => writeCart(addLine(readCart(), line)), []);
  const update = useCallback((k: Pick<CartLine, "slug" | "size">, q: number) => writeCart(setQuantity(readCart(), k, q)), []);
  const remove = useCallback((k: Pick<CartLine, "slug" | "size">) => writeCart(removeLine(readCart(), k)), []);
  const clear = useCallback(() => writeCart(EMPTY), []);

  const value = useMemo(
    () => ({ cart, count: itemCount(cart), subtotal: subtotalCents(cart), ready, add, update, remove, clear }),
    [cart, ready, add, update, remove, clear],
  );
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart(): CartContextValue {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used inside CartProvider");
  return ctx;
}
