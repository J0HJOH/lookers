import { formatMoney } from "@/core/formatting/money";
import type { OutgoingEmail } from "@/core/email/mailgun";
import type { Order } from "../domain/order";

const escapeHtml = (s: string): string =>
  s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] as string);

/**
 * Builds the confirmation email. Every customer-supplied value is escaped, because the
 * HTML body is assembled from user input (names, addresses).
 * Email clients ignore external CSS and web fonts, so styles are inline and colours literal.
 */
export function buildOrderConfirmationEmail(order: Order, orderUrl: string): OutgoingEmail {
  const rows = order.items
    .map(
      (i) =>
        `<tr><td style="padding:10px 0;border-bottom:1px solid #e8e0d0">${escapeHtml(i.productName)}<br><span style="color:#6b635b;font-size:12px">Size ${escapeHtml(i.size)} · Qty ${i.quantity}</span></td><td style="padding:10px 0;border-bottom:1px solid #e8e0d0;text-align:right">${formatMoney(i.unitPriceCents * i.quantity)}</td></tr>`,
    )
    .join("");

  const addressLines = [
    order.shipTo.name,
    order.shipTo.line1,
    order.shipTo.line2,
    `${order.shipTo.city}, ${order.shipTo.region} ${order.shipTo.postalCode}`,
    order.shipTo.country,
  ].filter((l): l is string => Boolean(l));

  const html = `<!doctype html><html><body style="margin:0;background:#faf7f1;font-family:Georgia,serif;color:#14110f">
<div style="max-width:560px;margin:0 auto;padding:40px 24px">
<h1 style="font-weight:400;letter-spacing:4px;text-align:center;font-size:22px">LOOKERS</h1>
<h2 style="font-weight:400;font-size:24px">Thank you, ${escapeHtml(order.shipTo.name.split(" ")[0] ?? order.shipTo.name)}.</h2>
<p>Your order <strong>${escapeHtml(order.orderNumber)}</strong> is confirmed. We'll email you again when it ships.</p>
<table style="width:100%;border-collapse:collapse;font-size:14px">${rows}
<tr><td style="padding-top:12px">Subtotal</td><td style="padding-top:12px;text-align:right">${formatMoney(order.subtotalCents)}</td></tr>
<tr><td>Shipping</td><td style="text-align:right">${order.shippingCents === 0 ? "Free" : formatMoney(order.shippingCents)}</td></tr>
<tr><td style="padding-top:8px"><strong>Total</strong></td><td style="padding-top:8px;text-align:right"><strong>${formatMoney(order.totalCents)}</strong></td></tr></table>
<h3 style="font-weight:400;margin-top:32px">Delivering to</h3>
<p style="line-height:1.6">${addressLines.map(escapeHtml).join("<br>")}</p>
<p style="margin-top:32px"><a href="${escapeHtml(orderUrl)}" style="color:#8f6f3f">View your order</a></p>
</div></body></html>`;

  const text = [
    `Thank you for your order ${order.orderNumber}.`,
    "",
    ...order.items.map((i) => `- ${i.productName} (${i.size}) x${i.quantity}  ${formatMoney(i.unitPriceCents * i.quantity)}`),
    "",
    `Subtotal: ${formatMoney(order.subtotalCents)}`,
    `Shipping: ${order.shippingCents === 0 ? "Free" : formatMoney(order.shippingCents)}`,
    `Total: ${formatMoney(order.totalCents)}`,
    "",
    "Delivering to:",
    ...addressLines,
    "",
    `View your order: ${orderUrl}`,
  ].join("\n");

  return { to: order.email, subject: `Your Lookers order ${order.orderNumber}`, text, html };
}
