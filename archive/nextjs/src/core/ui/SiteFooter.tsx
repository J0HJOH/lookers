import Link from "next/link";
import { Logo } from "./Logo";

export function SiteFooter() {
  return (
    <footer className="mt-24 border-t border-line bg-surface">
      <div className="container-page grid gap-10 py-14 md:grid-cols-4">
        <div className="md:col-span-2">
          <Logo size={64} withWordmark />
          <p className="mt-5 max-w-sm text-sm text-ink-muted">
            Considered clothing for men, women and little ones, with the hats, shoes and bags to finish every look.
          </p>
        </div>
        <div>
          <p className="eyebrow mb-4">Shop</p>
          <ul className="space-y-2 text-sm text-ink-soft">
            <li><Link href="/shop?category=mens-clothing" className="hover:text-gold-deep">Men</Link></li>
            <li><Link href="/shop?category=womens-clothing" className="hover:text-gold-deep">Women</Link></li>
            <li><Link href="/shop?category=baby-clothing" className="hover:text-gold-deep">Baby</Link></li>
            <li><Link href="/shop?category=shoes" className="hover:text-gold-deep">Shoes</Link></li>
          </ul>
        </div>
        <div>
          <p className="eyebrow mb-4">Help</p>
          <ul className="space-y-2 text-sm text-ink-soft">
            <li><Link href="/policies/shipping-returns" className="hover:text-gold-deep">Shipping &amp; returns</Link></li>
            <li><Link href="/policies/privacy" className="hover:text-gold-deep">Privacy</Link></li>
            <li><Link href="/policies/terms" className="hover:text-gold-deep">Terms</Link></li>
          </ul>
        </div>
      </div>
      <div className="border-t border-line py-5 text-center text-[11px] uppercase tracking-[0.2em] text-ink-muted">
        © {new Date().getFullYear()} Lookers. All rights reserved.
      </div>
    </footer>
  );
}
