// Supabase Edge Function (Deno). Sends the order confirmation through Mailgun.
// Why a function: the Flutter app is public code and can't hold the Mailgun key. The key lives in
// Supabase secrets (`supabase secrets set ...`, see docs/SETUP.md).
// Security: the caller's JWT is forwarded, so Row Level Security means a user can only trigger
// the email for their OWN order, and `claim_confirmation_email` makes each order email one-shot.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": Deno.env.get("ALLOWED_ORIGIN") ?? "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const esc = (s: string) =>
  s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);

const money = (cents: number, currency: string) =>
  new Intl.NumberFormat("en-US", { style: "currency", currency }).format(cents / 100);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const apiKey = Deno.env.get("MAILGUN_API_KEY");
  const domain = Deno.env.get("MAILGUN_DOMAIN");
  if (!apiKey || !domain) return json({ sent: false, reason: "not_configured" });

  let orderId: unknown;
  try {
    ({ orderId } = await req.json());
  } catch {
    return json({ error: "bad_request" }, 400);
  }
  if (typeof orderId !== "string" || !/^[0-9a-f-]{36}$/.test(orderId)) return json({ error: "bad_request" }, 400);

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: userData } = await supabase.auth.getUser();
  if (!userData.user) return json({ error: "unauthorized" }, 401);

  const { data: order } = await supabase
    .from("orders")
    .select("id, order_number, email, subtotal_cents, shipping_cents, total_cents, ship_name, ship_line1, ship_line2, ship_city, ship_region, ship_postal_code, ship_country, order_items(product_name, size, color, unit_price_cents, quantity)")
    .eq("id", orderId)
    .maybeSingle();
  if (!order) return json({ error: "not_found" }, 404);

  const { data: claimed } = await supabase.rpc("claim_confirmation_email", { p_order: orderId });
  if (!claimed) return json({ sent: false, reason: "already_sent" });

  const currency = Deno.env.get("CURRENCY") ?? "USD";
  const siteUrl = (Deno.env.get("SITE_URL") ?? "http://localhost:3000").replace(/\/$/, "");
  const first = esc(String(order.ship_name).split(" ")[0]);
  const rows = order.order_items
    .map((i: { product_name: string; size: string; color: string | null; unit_price_cents: number; quantity: number }) =>
      `<tr><td style="padding:10px 0;border-bottom:1px solid #e8e0d0">${esc(i.product_name)}<br><span style="color:#6b635b;font-size:12px">${i.color ? `Color ${esc(i.color)} · ` : ""}Size ${esc(i.size)} · Qty ${i.quantity}</span></td><td style="padding:10px 0;border-bottom:1px solid #e8e0d0;text-align:right">${money(i.unit_price_cents * i.quantity, currency)}</td></tr>`)
    .join("");
  const address = [order.ship_name, order.ship_line1, order.ship_line2, `${order.ship_city}, ${order.ship_region} ${order.ship_postal_code}`, order.ship_country]
    .filter(Boolean).map((l) => esc(String(l))).join("<br>");

  const html = `<!doctype html><html><body style="margin:0;background:#faf7f1;font-family:Georgia,serif;color:#14110f"><div style="max-width:560px;margin:0 auto;padding:40px 24px">
<h1 style="font-weight:400;letter-spacing:4px;text-align:center;font-size:22px">LOOKERS</h1>
<h2 style="font-weight:400;font-size:24px">Thank you, ${first}.</h2>
<p>Your order <strong>${esc(order.order_number)}</strong> is confirmed. We'll email you again when it ships.</p>
<table style="width:100%;border-collapse:collapse;font-size:14px">${rows}
<tr><td style="padding-top:12px">Subtotal</td><td style="padding-top:12px;text-align:right">${money(order.subtotal_cents, currency)}</td></tr>
<tr><td>Shipping</td><td style="text-align:right">${order.shipping_cents === 0 ? "Free" : money(order.shipping_cents, currency)}</td></tr>
<tr><td style="padding-top:8px"><strong>Total</strong></td><td style="padding-top:8px;text-align:right"><strong>${money(order.total_cents, currency)}</strong></td></tr></table>
<h3 style="font-weight:400;margin-top:32px">Delivering to</h3><p style="line-height:1.6">${address}</p>
<p style="margin-top:32px"><a href="${siteUrl}/account/orders/${order.id}" style="color:#8f6f3f">View your order</a></p></div></body></html>`;

  const text = `Thank you for your order ${order.order_number}.\nTotal: ${money(order.total_cents, currency)}\nView your order: ${siteUrl}/account/orders/${order.id}`;

  const body = new URLSearchParams({
    from: Deno.env.get("MAILGUN_FROM") ?? `Lookers <orders@${domain}>`,
    to: order.email,
    subject: `Your Lookers order ${order.order_number}`,
    text,
    html,
  });
  const base = Deno.env.get("MAILGUN_API_BASE") ?? "https://api.mailgun.net";

  try {
    const res = await fetch(`${base}/v3/${domain}/messages`, {
      method: "POST",
      headers: { Authorization: `Basic ${btoa(`api:${apiKey}`)}` },
      body,
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) throw new Error(`mailgun_${res.status}`);
    return json({ sent: true });
  } catch (e) {
    await supabase.rpc("release_confirmation_email", { p_order: orderId });
    console.error(`Confirmation email failed for order ${order.order_number}: ${(e as Error).message}`);
    return json({ sent: false, reason: "mailgun_failed" });
  }
});
