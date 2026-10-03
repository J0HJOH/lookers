import type { MetadataRoute } from "next";
import { getSiteUrl } from "@/core/config";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/", disallow: ["/admin", "/account", "/checkout", "/auth"] },
    sitemap: `${getSiteUrl()}/sitemap.xml`,
  };
}
