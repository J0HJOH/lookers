// Environment access lives here only. Nothing secret may be read in client code:
// only NEXT_PUBLIC_* values are ever shipped to the browser.

export const SITE_NAME = "Lookers";

export const CURRENCY = process.env.NEXT_PUBLIC_CURRENCY ?? "USD";

export function getSiteUrl(): string {
  return (process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000").replace(/\/$/, "");
}

export function getSupabasePublicConfig(): { url: string; key: string } | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  return url && key ? { url, key } : null;
}

export function isSupabaseConfigured(): boolean {
  return getSupabasePublicConfig() !== null;
}

export interface MailgunConfig {
  apiKey: string;
  domain: string;
  from: string;
  apiBase: string;
}

/** Server only. Returns null when Mailgun isn't set up, so emails are skipped, not fatal. */
export function getMailgunConfig(): MailgunConfig | null {
  const apiKey = process.env.MAILGUN_API_KEY;
  const domain = process.env.MAILGUN_DOMAIN;
  if (!apiKey || !domain) return null;
  return {
    apiKey,
    domain,
    from: process.env.MAILGUN_FROM ?? `Lookers <orders@${domain}>`,
    // Use https://api.eu.mailgun.net for EU-region domains.
    apiBase: process.env.MAILGUN_API_BASE ?? "https://api.mailgun.net",
  };
}
