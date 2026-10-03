/** Only same-site relative paths are allowed after sign-in, so `?next=` can't become an open redirect. */
export function safeNextPath(next: string | undefined | null, fallback = "/account"): string {
  if (!next || !next.startsWith("/") || next.startsWith("//") || next.includes("\\")) return fallback;
  return next;
}
