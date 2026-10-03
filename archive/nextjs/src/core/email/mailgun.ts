import { getMailgunConfig } from "@/core/config";
import { fail, ok, type Result } from "@/core/errors/failures";

export interface OutgoingEmail {
  to: string;
  subject: string;
  text: string;
  html: string;
}

/**
 * Sends one email through the Mailgun HTTP API. Server only (the API key is a secret).
 * Callers treat failure as non-fatal: a missing confirmation email must never undo an order.
 */
export async function sendEmail(email: OutgoingEmail, fetchImpl: typeof fetch = fetch): Promise<Result<true>> {
  const config = getMailgunConfig();
  if (!config) return fail("not_configured", "Email is not configured.");

  const body = new URLSearchParams({
    from: config.from,
    to: email.to,
    subject: email.subject,
    text: email.text,
    html: email.html,
  });

  try {
    const response = await fetchImpl(`${config.apiBase}/v3/${config.domain}/messages`, {
      method: "POST",
      headers: { Authorization: `Basic ${Buffer.from(`api:${config.apiKey}`).toString("base64")}` },
      body,
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) return fail("external_service", `Mailgun responded with ${response.status}.`);
    return ok(true);
  } catch {
    return fail("network", "Could not reach Mailgun.");
  }
}
