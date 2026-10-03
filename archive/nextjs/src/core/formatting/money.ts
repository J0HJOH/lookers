import { CURRENCY } from "@/core/config";

/** All prices are stored and calculated as integer minor units (cents); only display converts. */
export function formatMoney(cents: number, currency: string = CURRENCY): string {
  return new Intl.NumberFormat("en-US", { style: "currency", currency }).format(cents / 100);
}

export function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("en-GB", { dateStyle: "medium" }).format(new Date(iso));
}
