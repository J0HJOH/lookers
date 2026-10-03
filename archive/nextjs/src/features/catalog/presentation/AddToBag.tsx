"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useCart } from "@/features/cart/presentation/CartProvider";
import type { Product } from "../domain/product";

export function AddToBag({ product }: { product: Product }) {
  const { add } = useCart();
  const router = useRouter();
  const [size, setSize] = useState<string | null>(product.sizes.length === 1 ? product.sizes[0] : null);
  const [error, setError] = useState<string | null>(null);
  const [added, setAdded] = useState(false);
  const soldOut = product.stock <= 0;

  function handleAdd(goToBag: boolean) {
    if (!size) {
      setError("Please choose a size.");
      return;
    }
    setError(null);
    add({ slug: product.slug, name: product.name, imageUrl: product.imageUrl, priceCents: product.priceCents, size, quantity: 1 });
    setAdded(true);
    if (goToBag) router.push("/cart");
  }

  return (
    <div className="mt-8">
      {product.sizes.length > 1 && (
        <fieldset>
          <legend className="label">Size</legend>
          <div className="flex flex-wrap gap-2">
            {product.sizes.map((s) => (
              <button
                key={s}
                type="button"
                onClick={() => {
                  setSize(s);
                  setError(null);
                  setAdded(false);
                }}
                aria-pressed={size === s}
                className={`min-h-11 min-w-12 border px-3 text-sm transition-colors ${size === s ? "border-ink bg-ink text-background" : "border-line bg-paper hover:border-ink"}`}
              >
                {s}
              </button>
            ))}
          </div>
        </fieldset>
      )}
      {error && <p role="alert" className="mt-3 text-sm text-danger">{error}</p>}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row">
        <button type="button" className="btn flex-1" disabled={soldOut} onClick={() => handleAdd(false)}>
          {soldOut ? "Sold out" : "Add to bag"}
        </button>
        <button type="button" className="btn-ghost flex-1" disabled={soldOut} onClick={() => handleAdd(true)}>
          Buy now
        </button>
      </div>
      <p role="status" className="mt-3 min-h-5 text-sm text-success">{added ? "Added to your bag." : ""}</p>
    </div>
  );
}
