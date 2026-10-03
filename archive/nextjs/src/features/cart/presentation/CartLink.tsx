"use client";

import Link from "next/link";
import { useCart } from "./CartProvider";

export function CartLink() {
  const { count, ready } = useCart();
  return (
    <Link href="/cart" className="relative text-[12px] uppercase tracking-[0.2em] hover:text-gold-deep" aria-label={`Bag, ${ready ? count : 0} items`}>
      Bag{ready && count > 0 ? ` (${count})` : ""}
    </Link>
  );
}
