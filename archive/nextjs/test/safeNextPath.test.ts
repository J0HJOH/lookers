import { describe, expect, it } from "vitest";
import { safeNextPath } from "@/features/auth/domain/safeNextPath";

describe("safeNextPath", () => {
  it("allows same-site paths", () => expect(safeNextPath("/checkout")).toBe("/checkout"));
  it("blocks open redirects", () => {
    for (const bad of ["https://evil.com", "//evil.com", "/\\evil.com", "evil", "", null, undefined]) {
      expect(safeNextPath(bad as string)).toBe("/account");
    }
  });
});
