import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin } from "@/features/auth/data/session";

export const metadata: Metadata = { title: "Admin", robots: { index: false, follow: false } };

export default async function AdminLayout({ children }: LayoutProps<"/admin">) {
  await requireAdmin();
  const links = [
    ["/admin", "Overview"],
    ["/admin/products", "Products"],
    ["/admin/orders", "Orders"],
  ];
  return (
    <div className="container-page py-10">
      <div className="mb-8 flex flex-wrap items-center gap-x-8 gap-y-2 border-b border-line pb-4">
        <p className="display text-2xl">Admin</p>
        <nav aria-label="Admin" className="flex gap-6">
          {links.map(([href, label]) => <Link key={href} href={href} className="text-[12px] uppercase tracking-[0.2em] hover:text-gold-deep">{label}</Link>)}
        </nav>
      </div>
      {children}
    </div>
  );
}
