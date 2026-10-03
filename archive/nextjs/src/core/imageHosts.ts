// Hosts product images may come from. Used by next.config.ts (next/image) and by admin
// validation, so an admin can't save an image URL the site can't render.
// To allow Supabase Storage later, add "<project-ref>.supabase.co".
export const ALLOWED_IMAGE_HOSTS = ["images.pexels.com"] as const;
