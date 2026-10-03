import { z } from "zod";
import { ALLOWED_IMAGE_HOSTS } from "@/core/imageHosts";

const imageUrl = z
  .string()
  .trim()
  .max(2000)
  .refine((v) => {
    try {
      const u = new URL(v);
      return u.protocol === "https:" && (ALLOWED_IMAGE_HOSTS as readonly string[]).includes(u.hostname);
    } catch {
      return false;
    }
  }, `Image must be an https URL from: ${ALLOWED_IMAGE_HOSTS.join(", ")}.`);

export const productSchema = z.object({
  name: z.string().trim().min(1, "Name is required.").max(120),
  slug: z.string().trim().toLowerCase().regex(/^[a-z0-9]+(-[a-z0-9]+)*$/, "Use lowercase letters, numbers and hyphens.").max(120),
  description: z.string().trim().max(2000),
  price: z
    .string()
    .trim()
    .regex(/^\d{1,7}(\.\d{1,2})?$/, "Enter a price like 49.99.")
    .transform((v) => Math.round(Number(v) * 100)),
  categoryId: z.string().uuid("Choose a category."),
  imageUrl,
  sizes: z
    .string()
    .transform((v) => v.split(",").map((s) => s.trim()).filter(Boolean))
    .pipe(z.array(z.string().max(20)).min(1, "Add at least one size.").max(15)),
  stock: z.string().regex(/^\d{1,6}$/, "Stock must be a whole number.").transform(Number),
  featured: z.boolean(),
  active: z.boolean(),
});

export type ProductInput = z.infer<typeof productSchema>;
