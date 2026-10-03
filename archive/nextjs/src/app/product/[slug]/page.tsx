import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getProductBySlug, listProducts } from "@/features/catalog/data/catalogRepository";
import { stockLabel } from "@/features/catalog/domain/product";
import { AddToBag } from "@/features/catalog/presentation/AddToBag";
import { ProductCard } from "@/features/catalog/presentation/ProductCard";
import { formatMoney } from "@/core/formatting/money";

export async function generateMetadata(props: PageProps<"/product/[slug]">): Promise<Metadata> {
  const { slug } = await props.params;
  const product = await getProductBySlug(slug);
  if (!product) return { title: "Not found" };
  return { title: product.name, description: product.description, openGraph: { images: [product.imageUrl] } };
}

export default async function ProductPage(props: PageProps<"/product/[slug]">) {
  const { slug } = await props.params;
  const product = await getProductBySlug(slug);
  if (!product) notFound();
  const stock = stockLabel(product);
  const related = (await listProducts({ categorySlug: product.categorySlug })).filter((p) => p.slug !== product.slug).slice(0, 4);

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: product.name,
    description: product.description,
    image: product.imageUrl,
    offers: {
      "@type": "Offer",
      price: (product.priceCents / 100).toFixed(2),
      priceCurrency: process.env.NEXT_PUBLIC_CURRENCY ?? "USD",
      availability: stock === "out" ? "https://schema.org/OutOfStock" : "https://schema.org/InStock",
    },
  };

  return (
    <div className="container-page py-10">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c") }} />
      <nav aria-label="Breadcrumb" className="eyebrow mb-8">
        <Link href="/shop" className="hover:text-gold-deep">Shop</Link> /{" "}
        <Link href={`/shop?category=${product.categorySlug}`} className="hover:text-gold-deep">{product.categoryName}</Link>
      </nav>
      <div className="grid gap-10 lg:grid-cols-2">
        <div className="relative aspect-[4/5] overflow-hidden bg-surface">
          <Image src={product.imageUrl} alt={product.name} fill priority sizes="(min-width: 1024px) 50vw, 100vw" className="object-cover" />
        </div>
        <div className="lg:pt-8">
          <p className="eyebrow">{product.categoryName}</p>
          <h1 className="display mt-3 text-5xl">{product.name}</h1>
          <p className="mt-4 text-2xl">{formatMoney(product.priceCents)}</p>
          <p className="mt-6 max-w-prose leading-relaxed text-ink-soft">{product.description}</p>
          {stock === "low" && <p className="mt-4 text-sm text-danger">Only {product.stock} left.</p>}
          <AddToBag product={product} />
          <ul className="mt-10 space-y-2 border-t border-line pt-6 text-sm text-ink-muted">
            <li>Free shipping on orders over $250.</li>
            <li>30-day returns on unworn items.</li>
            <li><Link href="/policies/shipping-returns" className="underline hover:text-gold-deep">Shipping &amp; returns details</Link></li>
          </ul>
        </div>
      </div>
      {related.length > 0 && (
        <section className="mt-24" aria-labelledby="rel">
          <h2 id="rel" className="display mb-8 text-3xl">You may also like</h2>
          <div className="grid grid-cols-2 gap-x-4 gap-y-10 lg:grid-cols-4">
            {related.map((p) => <ProductCard key={p.slug} product={p} />)}
          </div>
        </section>
      )}
    </div>
  );
}
