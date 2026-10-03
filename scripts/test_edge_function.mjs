// Tests the send-order-confirmation Edge Function's LOGIC with Supabase and Mailgun faked.
// It does not prove real Mailgun/Supabase behaviour (that needs your keys; docs/SETUP.md step 4).
// Run: node scripts/test_edge_function.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";

// Node strips the TypeScript types for us; only the Deno-specific import is swapped for a fake.
const source = stripTypeScriptTypes(
  readFileSync(new URL("../supabase/functions/send-order-confirmation/index.ts", import.meta.url), "utf8"),
).replace(/^import \{ createClient \} from .*$/m, "const createClient = globalThis.__createClient;");

const order = {
  id: "11111111-1111-1111-1111-111111111111", order_number: "LK-001001", email: "ada@example.com",
  subtotal_cents: 10000, shipping_cents: 1500, total_cents: 11500,
  ship_name: "<script>alert(1)</script> Ada", ship_line1: "1 St", ship_line2: null, ship_city: "Lagos", ship_region: "LA",
  ship_postal_code: "1", ship_country: "NG",
  order_items: [{ product_name: "Noir Jacket", size: "M", color: "Black", unit_price_cents: 10000, quantity: 1 }],
};

async function run({ env = {}, body = { orderId: order.id }, user = { id: "u" }, row = order, claimed = true, mailgunStatus = 200, method = "POST" } = {}) {
  const calls = { rpc: [], fetch: [] };
  globalThis.__createClient = () => ({
    auth: { getUser: async () => ({ data: { user } }) },
    from: () => ({ select: () => ({ eq: () => ({ maybeSingle: async () => ({ data: row }) }) }) }),
    rpc: async (name, args) => { calls.rpc.push([name, args]); return { data: name === "claim_confirmation_email" ? claimed : null }; },
  });
  globalThis.fetch = async (url, init) => { calls.fetch.push([url, init]); return new Response("{}", { status: mailgunStatus }); };
  let handler;
  const values = { SUPABASE_URL: "https://x.supabase.co", SUPABASE_ANON_KEY: "k", MAILGUN_API_KEY: "key-1", MAILGUN_DOMAIN: "mg.lookers.test", ...env };
  globalThis.Deno = { env: { get: (k) => values[k] || undefined }, serve: (h) => { handler = h; } };
  const url = "data:text/javascript;base64," + Buffer.from(source + `\n// ${Math.random()}`).toString("base64");
  await import(url);
  const res = await handler(new Request("http://x", { method, headers: { Authorization: "Bearer t" }, body: method === "POST" ? JSON.stringify(body) : undefined }));
  return { status: res.status, json: await res.json().catch(() => null), calls };
}

const tests = {
  async "sends the email through Mailgun with basic auth and the right fields"() {
    const r = await run();
    assert.deepEqual(r.json, { sent: true });
    const [url, init] = r.calls.fetch[0];
    assert.equal(url, "https://api.mailgun.net/v3/mg.lookers.test/messages");
    assert.equal(init.headers.Authorization, "Basic " + Buffer.from("api:key-1").toString("base64"));
    const form = new URLSearchParams(init.body.toString());
    assert.equal(form.get("to"), "ada@example.com");
    assert.equal(form.get("subject"), "Your Lookers order LK-001001");
    assert.match(form.get("html"), /Color Black · Size M/);
    assert.match(form.get("text"), /\$115\.00/);
  },
  async "escapes customer-supplied HTML"() {
    const html = new URLSearchParams((await run()).calls.fetch[0][1].body.toString()).get("html");
    assert.ok(!html.includes("<script>"));
    assert.ok(html.includes("&lt;script&gt;"));
  },
  async "is one-shot: an already-claimed order sends nothing"() {
    const r = await run({ claimed: false });
    assert.deepEqual(r.json, { sent: false, reason: "already_sent" });
    assert.equal(r.calls.fetch.length, 0);
  },
  async "releases the claim when Mailgun fails so a retry can send"() {
    const r = await run({ mailgunStatus: 401 });
    assert.deepEqual(r.json, { sent: false, reason: "mailgun_failed" });
    assert.ok(r.calls.rpc.some(([n]) => n === "release_confirmation_email"));
  },
  async "skips quietly when Mailgun isn't configured"() {
    const r = await run({ env: { MAILGUN_API_KEY: "" } });
    assert.deepEqual(r.json, { sent: false, reason: "not_configured" });
    assert.equal(r.calls.fetch.length, 0);
  },
  async "uses the EU base URL when set"() {
    const r = await run({ env: { MAILGUN_API_BASE: "https://api.eu.mailgun.net" } });
    assert.ok(r.calls.fetch[0][0].startsWith("https://api.eu.mailgun.net/v3/"));
  },
  async "rejects bad input, strangers and other people's orders"() {
    assert.equal((await run({ body: { orderId: "nope" } })).status, 400);
    assert.equal((await run({ user: null })).status, 401);
    const missing = await run({ row: null });
    assert.equal(missing.status, 404);
    assert.equal(missing.calls.fetch.length, 0);
    assert.equal((await run({ method: "GET" })).status, 405);
  },
};

let failed = 0;
for (const [name, fn] of Object.entries(tests)) {
  try { await fn(); console.log("ok   ", name); } catch (e) { failed++; console.log("FAIL ", name, "\n     ", e.message); }
}
process.exit(failed ? 1 : 0);
