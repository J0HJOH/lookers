import Image from "next/image";
import Link from "next/link";
import { getFeaturedProducts, listCategories, usingPreviewCatalog } from "@/features/catalog/data/catalogRepository";
import { ProductCard } from "@/features/catalog/presentation/ProductCard";
import { Logo } from "@/core/ui/Logo";

export default async function HomePage() {
  const [categories, featured] = await Promise.all([listCategories(), getFeaturedProducts(8)]);
  const hero = categories[0];

  return (
    <>
      {usingPreviewCatalog() && (
        <p className="bg-ink px-4 py-2 text-center text-[11px] uppercase tracking-[0.2em] text-background">
          Preview mode: Supabase isn&apos;t connected yet, so this is the bundled sample catalogue. See docs/SETUP.md.
        </p>
      )}

      <section className="relative">
        <div className="container-page grid min-h-[78vh] items-center gap-10 py-12 lg:grid-cols-2">
          <div>
            <p className="eyebrow">The new collection</p>
            <h1 className="display mt-5 text-6xl sm:text-7xl lg:text-8xl">
              Dressed with <em className="font-normal text-gold-deep">intent.</em>
            </h1>
            <p className="mt-6 max-w-md text-base leading-relaxed text-ink-soft">
              Men, women and little ones. Tailoring, knitwear and the finishing pieces, hats, shoes and bags,
              chosen to be worn and kept.
            </p>
            <div className="mt-10 flex flex-wrap gap-3">
              <Link href="/shop" className="btn">Shop the collection</Link>
              <Link href="/shop?category=womens-clothing" className="btn-ghost">Women</Link>
            </div>
          </div>
          <div className="relative aspect-[4/5] w-full overflow-hidden bg-surface lg:aspect-[3/4]">
            {hero && (
              <Image src={hero.imageUrl} alt="Lookers collection" fill priority sizes="(min-width: 1024px) 50vw, 100vw" className="object-cover" />
            )}
            <div className="absolute bottom-6 left-6 bg-background/90 p-4 backdrop-blur"><Logo size={44} /></div>
          </div>
        </div>
      </section>

      <section className="container-page py-16" aria-labelledby="cats">
        <div className="mb-10 flex items-end justify-between">
          <h2 id="cats" className="display text-4xl sm:text-5xl">Shop by category</h2>
          <Link href="/shop" className="eyebrow hover:text-gold-deep">View all</Link>
        </div>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-3">
          {categories.map((c) => (
            <Link key={c.slug} href={`/shop?category=${c.slug}`} className="group relative aspect-[4/5] overflow-hidden bg-surface">
              <Image src={c.imageUrl} alt="" fill sizes="(min-width: 768px) 33vw, 50vw" className="object-cover transition-transform duration-700 group-hover:scale-105" />
              <div className="absolute inset-0 bg-gradient-to-t from-ink/70 via-transparent to-transparent" />
              <div className="absolute bottom-5 left-5 right-5 text-paper">
                <h3 className="display text-2xl sm:text-3xl">{c.name}</h3>
                <p className="mt-1 text-xs uppercase tracking-[0.18em] opacity-90">{c.tagline}</p>
              </div>
            </Link>
          ))}
        </div>
      </section>

      <section className="container-page py-16" aria-labelledby="featured">
        <h2 id="featured" className="display mb-10 text-4xl sm:text-5xl">Featured pieces</h2>
        <div className="grid grid-cols-2 gap-x-4 gap-y-10 lg:grid-cols-4">
          {featured.map((p) => <ProductCard key={p.slug} product={p} />)}
        </div>
      </section>

      <section className="bg-ink py-20 text-background">
        <div className="container-page grid gap-8 text-center md:grid-cols-3">
          {[
            ["Free shipping", "On orders over $250."],
            ["Easy returns", "30 days, unworn, no fuss."],
            ["Secure checkout", "Your details stay protected."],
          ].map(([t, d]) => (
            <div key={t}>
              <p className="display text-2xl">{t}</p>
              <p className="mt-2 text-sm opacity-75">{d}</p>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
