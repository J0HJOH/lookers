import type { Metadata } from "next";
import { notFound } from "next/navigation";

const POLICIES: Record<string, { title: string; body: string[] }> = {
  "shipping-returns": {
    title: "Shipping & returns",
    body: [
      "Orders ship within 2 business days. Standard delivery takes 3–7 business days.",
      "Shipping is a flat fee, free on orders over $250.",
      "Returns are accepted within 30 days for unworn items with tags attached. Contact us to start a return.",
    ],
  },
  privacy: {
    title: "Privacy",
    body: [
      "We collect the details you give us (name, email, delivery address, phone) to process orders and send confirmations.",
      "Sign-in is handled by Google through Supabase. We never see your Google password.",
      "We don't sell your data. Contact us to request a copy or deletion of your data.",
    ],
  },
  terms: {
    title: "Terms of service",
    body: [
      "By placing an order you agree to provide accurate delivery and contact details.",
      "Prices are shown in the store currency and confirmed when you place your order.",
      "We may cancel orders where stock or pricing errors occur and will tell you promptly.",
    ],
  },
};

export async function generateMetadata(props: PageProps<"/policies/[slug]">): Promise<Metadata> {
  const { slug } = await props.params;
  return { title: POLICIES[slug]?.title ?? "Policy" };
}

export default async function PolicyPage(props: PageProps<"/policies/[slug]">) {
  const { slug } = await props.params;
  const policy = POLICIES[slug];
  if (!policy) notFound();
  return (
    <div className="container-page max-w-2xl py-16">
      <h1 className="display text-5xl">{policy.title}</h1>
      <div className="mt-8 space-y-4 leading-relaxed text-ink-soft">
        {policy.body.map((p) => <p key={p}>{p}</p>)}
      </div>
      <p className="mt-10 text-xs text-ink-muted">Draft text. Have it reviewed before launch.</p>
    </div>
  );
}
