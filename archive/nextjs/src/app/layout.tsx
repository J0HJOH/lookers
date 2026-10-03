import type { Metadata } from "next";
import { Cormorant_Garamond, Jost, Pinyon_Script } from "next/font/google";
import "./globals.css";
import { CartProvider } from "@/features/cart/presentation/CartProvider";
import { SiteHeader } from "@/core/ui/SiteHeader";
import { SiteFooter } from "@/core/ui/SiteFooter";
import { getSiteUrl } from "@/core/config";

const cormorant = Cormorant_Garamond({ variable: "--font-cormorant", subsets: ["latin"], weight: ["400", "500", "600"] });
const jost = Jost({ variable: "--font-jost", subsets: ["latin"] });
const pinyon = Pinyon_Script({ variable: "--font-pinyon", subsets: ["latin"], weight: "400" });

export const metadata: Metadata = {
  metadataBase: new URL(getSiteUrl()),
  title: { default: "Lookers — Considered clothing", template: "%s | Lookers" },
  description: "Lookers: men's, women's and baby's clothing, hats, shoes and bags. Considered pieces, delivered to your door.",
  openGraph: { siteName: "Lookers", type: "website" },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${cormorant.variable} ${jost.variable} ${pinyon.variable}`}>
      <body className="flex min-h-screen flex-col">
        <CartProvider>
          <SiteHeader />
          <main className="flex-1">{children}</main>
          <SiteFooter />
        </CartProvider>
      </body>
    </html>
  );
}
