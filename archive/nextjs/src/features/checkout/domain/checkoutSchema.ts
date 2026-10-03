import { z } from "zod";
import { MAX_LINES, MAX_QTY_PER_LINE } from "@/features/cart/domain/cart";

const text = (min: number, max: number, label: string) =>
  z
    .string()
    .trim()
    .min(min, `${label} is required.`)
    .max(max, `${label} is too long.`);

export const shippingSchema = z.object({
  fullName: text(2, 100, "Full name"),
  email: z.string().trim().email("Enter a valid email address.").max(200),
  phone: z
    .string()
    .trim()
    .regex(/^[+\d][\d\s().-]{6,24}$/, "Enter a valid phone number."),
  line1: text(3, 200, "Address"),
  line2: z.string().trim().max(200).optional().default(""),
  city: text(2, 100, "City"),
  region: text(2, 100, "State / region"),
  postalCode: text(2, 20, "Postal code"),
  country: text(2, 100, "Country"),
  notes: z.string().trim().max(500, "Notes are too long.").optional().default(""),
});

export const cartLinesSchema = z
  .array(
    z.object({
      slug: z.string().regex(/^[a-z0-9-]+$/).max(120),
      size: z.string().trim().min(1).max(20),
      quantity: z.number().int().min(1).max(MAX_QTY_PER_LINE),
    }),
  )
  .min(1, "Your bag is empty.")
  .max(MAX_LINES);

export type ShippingInput = z.infer<typeof shippingSchema>;
export type CartLinesInput = z.infer<typeof cartLinesSchema>;
