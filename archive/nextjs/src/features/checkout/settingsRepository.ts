import { createSupabaseServerClient } from "@/core/supabase/server";
import { DEFAULT_SHIPPING_RULES, type ShippingRules } from "./domain/shipping";

export async function getShippingRules(): Promise<ShippingRules> {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return DEFAULT_SHIPPING_RULES;
  const { data } = await supabase
    .from("store_settings")
    .select("flat_shipping_cents, free_shipping_threshold_cents")
    .maybeSingle();
  if (!data) return DEFAULT_SHIPPING_RULES;
  return { flatShippingCents: data.flat_shipping_cents, freeShippingThresholdCents: data.free_shipping_threshold_cents };
}
