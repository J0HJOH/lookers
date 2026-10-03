import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

// Raw colour values may only live in the token file. Exceptions are third-party brand marks
// and the email template (email clients ignore CSS variables).
const ALLOWED = ["globals.css", "orderConfirmationEmail.ts", "GoogleButton.tsx"];
const HEX = /#[0-9a-fA-F]{3,8}\b/;

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((f) => {
    const p = join(dir, f);
    return statSync(p).isDirectory() ? files(p) : /\.(tsx?|css)$/.test(f) ? [p] : [];
  });
}

describe("design system", () => {
  it("has no hard-coded colours outside the token file", () => {
    const offenders = files("src").filter((f) => !ALLOWED.some((a) => f.endsWith(a)) && HEX.test(readFileSync(f, "utf8")));
    expect(offenders).toEqual([]);
  });
});
