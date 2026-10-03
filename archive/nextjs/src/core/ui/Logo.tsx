/**
 * Lookers monogram: a large cursive "L" with a "K" tucked beneath it, optionally with the wordmark.
 * Uses the --font-script (Pinyon Script) font loaded in the root layout.
 */
export function Logo({ size = 56, withWordmark = false, className = "" }: { size?: number; withWordmark?: boolean; className?: string }) {
  return (
    <span className={`inline-flex flex-col items-center leading-none text-ink ${className}`} aria-label="Lookers">
      <svg width={size} height={size} viewBox="8 0 92 100" role="img" aria-hidden="true" className="overflow-visible">
        <text x="14" y="66" fontFamily="var(--font-pinyon), cursive" fontSize="104" fill="currentColor">L</text>
        <text x="42" y="96" fontFamily="var(--font-pinyon), cursive" fontSize="74" fill="var(--color-gold-deep)">K</text>
      </svg>
      {withWordmark && (
        <span className="mt-1 font-display text-[13px] uppercase tracking-[0.5em] pl-[0.5em]">Lookers</span>
      )}
    </span>
  );
}
