import { afterEach, describe, expect, it, vi } from "vitest";
import { sendEmail } from "@/core/email/mailgun";
import { buildOrderConfirmationEmail } from "@/features/orders/emails/orderConfirmationEmail";
import type { Order } from "@/features/orders/domain/order";

const order: Order = {
  id: "1", orderNumber: "LK-001001", status: "pending", email: "ada@example.com", createdAt: "2026-10-02T10:00:00Z",
  subtotalCents: 10000, shippingCents: 1500, totalCents: 11500, paymentMethod: "pay_on_delivery",
  shipTo: { name: "<script>alert(1)</script> Ada", phone: "1", line1: "1 St", line2: null, city: "Lagos", region: "LA", postalCode: "1", country: "NG" },
  items: [{ productName: "Noir Jacket", imageUrl: "https://x", size: "M", unitPriceCents: 10000, quantity: 1 }],
};

afterEach(() => vi.unstubAllEnvs());

describe("order confirmation email", () => {
  it("escapes customer-supplied HTML", () => {
    const mail = buildOrderConfirmationEmail(order, "https://lookers.test/o/1");
    expect(mail.html).not.toContain("<script>");
    expect(mail.html).toContain("&lt;script&gt;");
    expect(mail.subject).toContain("LK-001001");
    expect(mail.text).toContain("$115.00");
  });
});

describe("sendEmail", () => {
  const mail = { to: "a@b.com", subject: "s", text: "t", html: "<p>t</p>" };
  it("is skipped (not an error) when Mailgun isn't configured", async () => {
    vi.stubEnv("MAILGUN_API_KEY", "");
    const r = await sendEmail(mail, vi.fn());
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failure.kind).toBe("not_configured");
  });
  it("posts to the Mailgun messages endpoint with basic auth", async () => {
    vi.stubEnv("MAILGUN_API_KEY", "key-123");
    vi.stubEnv("MAILGUN_DOMAIN", "mg.lookers.test");
    const fetchMock = vi.fn().mockResolvedValue(new Response("{}", { status: 200 }));
    const r = await sendEmail(mail, fetchMock as unknown as typeof fetch);
    expect(r.ok).toBe(true);
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://api.mailgun.net/v3/mg.lookers.test/messages");
    expect((init.headers as Record<string, string>).Authorization).toBe(`Basic ${Buffer.from("api:key-123").toString("base64")}`);
  });
  it("maps HTTP errors and network failures to failures", async () => {
    vi.stubEnv("MAILGUN_API_KEY", "k");
    vi.stubEnv("MAILGUN_DOMAIN", "d");
    const bad = await sendEmail(mail, vi.fn().mockResolvedValue(new Response("", { status: 401 })) as unknown as typeof fetch);
    expect(!bad.ok && bad.failure.kind).toBe("external_service");
    const down = await sendEmail(mail, vi.fn().mockRejectedValue(new Error("x")) as unknown as typeof fetch);
    expect(!down.ok && down.failure.kind).toBe("network");
  });
});
