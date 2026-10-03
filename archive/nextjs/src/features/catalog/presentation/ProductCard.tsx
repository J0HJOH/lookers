import Image from "next/image";
import Link from "next/link";
import { formatMoney } from "@/core/formatting/money";
import { stockLabel, type Product } from "../domain/product";

export function ProductCard({ product, priority = false }: { product: Product; priority?: boolean }) {
  const stock = stockLabel(product);
  return (
    <Link href={`/product/${product.slug}`} className="group block">
      <div className="relative aspect-[3/4] overflow-hidden bg-surface">
        <Image
          src={product.imageUrl}
          alt={product.name}
          fill
          priority={priority}
          sizes="(min-width: 1024px) 25vw, (min-width: 640px) 33vw, 50vw"
          className="object-cover transition-transform duration-700 group-hover:scale-105"
        />
        {stock !== "in" && (
          <span className="absolute left-3 top-3 bg-paper px-2.5 py-1 text-[10px] uppercase tracking-[0.2em] text-ink">
            {stock === "out" ? "Sold out" : "Few left"}
          </span>
        )}
      </div>
      <div className="mt-4 flex items-start justify-between gap-3">
        <div>
          <p className="eyebrow">{product.categoryName}</p>
          <h3 className="display mt-1 text-xl">{product.name}</h3>
        </div>
        <p className="pt-1 text-sm">{formatMoney(product.priceCents)}</p>
      </div>
    </Link>
  );
}
