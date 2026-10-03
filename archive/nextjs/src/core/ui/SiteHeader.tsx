import Link from "next/link";
import { Logo } from "./Logo";
import { CartLink } from "@/features/cart/presentation/CartLink";
import { getCurrentUser } from "@/features/auth/data/session";
import { listCategories } from "@/features/catalog/data/catalogRepository";

export async function SiteHeader() {
  const [user, categories] = await Promise.all([getCurrentUser(), listCategories()]);
  return (
    <header className="sticky top-0 z-40 border-b border-line bg-background/90 backdrop-blur">
      <div className="container-page flex h-20 items-center justify-between gap-4">
        <nav className="hidden flex-1 gap-6 lg:flex" aria-label="Shop">
          <Link href="/shop" className="text-[12px] uppercase tracking-[0.2em] hover:text-gold-deep">Shop</Link>
          {categories.slice(0, 3).map((c) => (
            <Link key={c.slug} href={`/shop?category=${c.slug}`} className="text-[12px] uppercase tracking-[0.2em] text-ink-soft hover:text-gold-deep">
              {c.name.replace(" Clothing", "")}
            </Link>
          ))}
        </nav>
        <Link href="/" aria-label="Lookers home" className="lg:flex-none">
          <Logo size={64} />
        </Link>
        <nav className="flex flex-1 items-center justify-end gap-5" aria-label="Account">
          <Link href="/shop" className="text-[12px] uppercase tracking-[0.2em] lg:hidden">Shop</Link>
          {user?.isAdmin && (
            <Link href="/admin" className="text-[12px] uppercase tracking-[0.2em] text-gold-deep">Admin</Link>
          )}
          {user ? (
            <Link href="/account" className="text-[12px] uppercase tracking-[0.2em] hover:text-gold-deep">Account</Link>
          ) : (
            <Link href="/login" className="text-[12px] uppercase tracking-[0.2em] hover:text-gold-deep">Sign in</Link>
          )}
          <CartLink />
        </nav>
      </div>
    </header>
  );
}
