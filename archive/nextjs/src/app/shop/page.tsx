import type { Metadata } from "next";
import Link from "next/link";
import { listCategories, listProducts } from "@/features/catalog/data/catalogRepository";
import { isSortKey } from "@/features/catalog/domain/product";
import { ProductCard } from "@/features/catalog/presentation/ProductCard";

export const metadata: Metadata = { title: "Shop" };

export default async function ShopPage(props: PageProps<"/shop">) {
  const sp = await props.searchParams;
  const category = typeof sp.category === "string" ? sp.category : undefined;
  const search = typeof sp.q === "string" ? sp.q.slice(0, 80) : undefined;
  const sortParam = typeof sp.sort === "string" ? sp.sort : undefined;
  const sort = isSortKey(sortParam) ? sortParam : "newest";

  const [categories, products] = await Promise.all([
    listCategories(),
    listProducts({ categorySlug: category, search, sort }),
  ]);
  const active = categories.find((c) => c.slug === category);

  return (
    <div className="container-page py-12">
      <p className="eyebrow">{active ? "Category" : "Collection"}</p>
      <h1 className="display mt-3 text-5xl sm:text-6xl">{active?.name ?? "All pieces"}</h1>
      {active && <p className="mt-3 text-ink-muted">{active.tagline}</p>}

      <div className="mt-10 flex flex-col gap-6 border-y border-line py-5 md:flex-row md:items-center md:justify-between">
        <nav aria-label="Categories" className="flex flex-wrap gap-x-6 gap-y-2">
          <Link href="/shop" className={`text-[12px] uppercase tracking-[0.2em] ${!category ? "text-gold-deep" : "text-ink-soft hover:text-gold-deep"}`}>All</Link>
          {categories.map((c) => (
            <Link key={c.slug} href={`/shop?category=${c.slug}`} aria-current={c.slug === category ? "page" : undefined} className={`text-[12px] uppercase tracking-[0.2em] ${c.slug === category ? "text-gold-deep" : "text-ink-soft hover:text-gold-deep"}`}>
              {c.name}
            </Link>
          ))}
        </nav>
        <form action="/shop" className="flex flex-wrap gap-2">
          {category && <input type="hidden" name="category" value={category} />}
          <label className="sr-only" htmlFor="q">Search</label>
          <input id="q" name="q" defaultValue={search} placeholder="Search" className="field w-44" />
          <label className="sr-only" htmlFor="sort">Sort</label>
          <select id="sort" name="sort" defaultValue={sort} className="field w-44">
            <option value="newest">Newest</option>
            <option value="price-asc">Price: low to high</option>
            <option value="price-desc">Price: high to low</option>
          </select>
          <button className="btn-ghost min-h-11 px-5" type="submit">Apply</button>
        </form>
      </div>

      {products.length === 0 ? (
        <div className="py-24 text-center">
          <p className="display text-3xl">Nothing found.</p>
          <p className="mt-2 text-ink-muted">Try another category or search.</p>
          <Link href="/shop" className="btn mt-8">Clear filters</Link>
        </div>
      ) : (
        <div className="mt-10 grid grid-cols-2 gap-x-4 gap-y-10 lg:grid-cols-4">
          {products.map((p, i) => <ProductCard key={p.slug} product={p} priority={i < 4} />)}
        </div>
      )}
    </div>
  );
}
