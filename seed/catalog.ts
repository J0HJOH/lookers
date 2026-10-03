// Single source for the starter catalogue. `npm run db:seed-sql` turns it into
// supabase/seed.sql, and the app uses it as a preview when Supabase isn't configured.
// Images are free Pexels photos (https://www.pexels.com/license/): no attribution required.

const px = (id: number) =>
  `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=900`;

export interface SeedCategory {
  slug: string;
  name: string;
  tagline: string;
  imageUrl: string;
  sortOrder: number;
}

export interface SeedProduct {
  slug: string;
  name: string;
  description: string;
  priceCents: number;
  categorySlug: string;
  imageUrl: string;
  sizes: string[];
  stock: number;
  featured: boolean;
  colors: SeedColor[];
  /** Extra gallery photos after the main one (stand-in photos from the same category). */
  images: string[];
}

export interface SeedColor {
  name: string;
  hex: string;
}

export interface SeedReview {
  productSlug: string;
  authorName: string;
  rating: number;
  title: string;
  body: string;
  size: string | null;
  color: string | null;
  createdAt: string;
}

const CLOTHING_SIZES = ["XS", "S", "M", "L", "XL"];
const BABY_SIZES = ["0-3M", "3-6M", "6-12M", "12-18M"];
const SHOE_SIZES = ["38", "39", "40", "41", "42", "43", "44"];
const ONE_SIZE = ["One size"];

export const seedCategories: SeedCategory[] = [
  { slug: "mens-clothing", name: "Men's Clothing", tagline: "Tailored, relaxed, unmistakable.", imageUrl: px(15869797), sortOrder: 1 },
  { slug: "womens-clothing", name: "Women's Clothing", tagline: "Evening to everyday, effortlessly.", imageUrl: px(31410216), sortOrder: 2 },
  { slug: "baby-clothing", name: "Baby's Clothing", tagline: "Soft first moments.", imageUrl: px(7973642), sortOrder: 3 },
  { slug: "hats", name: "Hats", tagline: "The finishing line.", imageUrl: px(34200743), sortOrder: 4 },
  { slug: "shoes", name: "Shoes", tagline: "Step into the collection.", imageUrl: px(17630275), sortOrder: 5 },
  { slug: "bags-accessories", name: "Bags & Accessories", tagline: "Carried with intent.", imageUrl: px(9327162), sortOrder: 6 },
];

const baseProducts: Omit<SeedProduct, "colors" | "images">[] = [
  { slug: "noir-leather-jacket", name: "Noir Leather Jacket", description: "Butter-soft lambskin cut close to the body, with a clean collar and hidden zip pockets.", priceCents: 48000, categorySlug: "mens-clothing", imageUrl: px(15869797), sizes: CLOTHING_SIZES, stock: 12, featured: true },
  { slug: "atelier-knit-sweater", name: "Atelier Knit Sweater", description: "Fine-gauge merino in a relaxed crew neck. Light enough for layering, warm enough alone.", priceCents: 16500, categorySlug: "mens-clothing", imageUrl: px(9558897), sizes: CLOTHING_SIZES, stock: 25, featured: true },
  { slug: "weekend-denim-vest", name: "Weekend Denim Vest", description: "Washed denim with a structured shoulder, made to sit over knits and tees.", priceCents: 12500, categorySlug: "mens-clothing", imageUrl: px(7668398), sizes: CLOTHING_SIZES, stock: 18, featured: false },
  { slug: "city-casual-set", name: "City Casual Set", description: "A checked shirt and straight denim, styled as a ready-to-wear pairing.", priceCents: 21000, categorySlug: "mens-clothing", imageUrl: px(3944693), sizes: CLOTHING_SIZES, stock: 15, featured: false },
  { slug: "rose-evening-dress", name: "Rose Evening Dress", description: "Fluid satin in dusty rose, with a draped neckline and a long, clean line.", priceCents: 34000, categorySlug: "womens-clothing", imageUrl: px(8619007), sizes: CLOTHING_SIZES, stock: 10, featured: true },
  { slug: "midnight-slip-dress", name: "Midnight Slip Dress", description: "Black crepe slip dress that goes from dinner to late without a second thought.", priceCents: 29000, categorySlug: "womens-clothing", imageUrl: px(31410216), sizes: CLOTHING_SIZES, stock: 14, featured: true },
  { slug: "solstice-summer-dress", name: "Solstice Summer Dress", description: "Lightweight printed cotton with a flattering waist and a floating hem.", priceCents: 18500, categorySlug: "womens-clothing", imageUrl: px(36594454), sizes: CLOTHING_SIZES, stock: 20, featured: false },
  { slug: "denim-and-sun-set", name: "Denim & Sun Set", description: "A cropped denim jacket styled with a wide-brim hat for sunny days.", priceCents: 15500, categorySlug: "womens-clothing", imageUrl: px(12083001), sizes: CLOTHING_SIZES, stock: 16, featured: false },
  { slug: "little-bear-hoodie", name: "Little Bear Hoodie", description: "Brushed organic cotton with soft bear ears. Gentle on new skin.", priceCents: 4800, categorySlug: "baby-clothing", imageUrl: px(7973642), sizes: BABY_SIZES, stock: 40, featured: true },
  { slug: "forest-onesie", name: "Forest Onesie", description: "A snap-close onesie in breathable cotton jersey.", priceCents: 2800, categorySlug: "baby-clothing", imageUrl: px(29015875), sizes: BABY_SIZES, stock: 60, featured: false },
  { slug: "stripe-play-set", name: "Stripe Play Set", description: "Top, trousers, booties and a hat in a monochrome stripe.", priceCents: 6200, categorySlug: "baby-clothing", imageUrl: px(34121887), sizes: BABY_SIZES, stock: 30, featured: false },
  { slug: "teddy-jumper", name: "Teddy Jumper", description: "A cosy knitted jumper with an embroidered teddy.", priceCents: 4200, categorySlug: "baby-clothing", imageUrl: px(7484842), sizes: BABY_SIZES, stock: 22, featured: false },
  { slug: "heritage-fedora", name: "Heritage Fedora", description: "Wool-felt fedora with a grosgrain band and a structured crown.", priceCents: 9500, categorySlug: "hats", imageUrl: px(34200743), sizes: ONE_SIZE, stock: 20, featured: true },
  { slug: "boulevard-trilby", name: "Boulevard Trilby", description: "A shorter brim and a sharper line, made for city walking.", priceCents: 8800, categorySlug: "hats", imageUrl: px(19272485), sizes: ONE_SIZE, stock: 17, featured: false },
  { slug: "wide-brim-sun-hat", name: "Wide-Brim Sun Hat", description: "Woven wide-brim hat with UV protection and a soft inner band.", priceCents: 7200, categorySlug: "hats", imageUrl: px(20295253), sizes: ONE_SIZE, stock: 24, featured: false },
  { slug: "crimson-runner", name: "Crimson Runner", description: "Low-profile leather sneaker in a deep red with a cushioned sole.", priceCents: 14500, categorySlug: "shoes", imageUrl: px(1027130), sizes: SHOE_SIZES, stock: 30, featured: true },
  { slug: "pure-white-court", name: "Pure White Court", description: "A minimal white court sneaker in full-grain leather.", priceCents: 13500, categorySlug: "shoes", imageUrl: px(11946030), sizes: SHOE_SIZES, stock: 35, featured: false },
  { slug: "azure-street-sneaker", name: "Azure Street Sneaker", description: "Blue suede panels with a bold white accent for everyday wear.", priceCents: 15500, categorySlug: "shoes", imageUrl: px(17630275), sizes: SHOE_SIZES, stock: 18, featured: false },
  { slug: "monochrome-pair", name: "Monochrome Pair", description: "Black and white low-tops. Two pairs, one idea.", priceCents: 12800, categorySlug: "shoes", imageUrl: px(4271563), sizes: SHOE_SIZES, stock: 26, featured: false },
  { slug: "sable-leather-tote", name: "Sable Leather Tote", description: "A roomy structured tote in tan leather with an inner zip pocket.", priceCents: 31000, categorySlug: "bags-accessories", imageUrl: px(14806252), sizes: ONE_SIZE, stock: 9, featured: true },
  { slug: "ivory-chain-bag", name: "Ivory Chain Bag", description: "A compact white leather bag with a gold chain strap.", priceCents: 27500, categorySlug: "bags-accessories", imageUrl: px(27835299), sizes: ONE_SIZE, stock: 11, featured: true },
  { slug: "capsule-handbag", name: "Capsule Handbag", description: "Smooth leather with a magnetic closure, in a small, useful size.", priceCents: 19800, categorySlug: "bags-accessories", imageUrl: px(9327162), sizes: ONE_SIZE, stock: 14, featured: false },
  { slug: "beige-day-bag", name: "Beige Day Bag", description: "A soft beige bag that goes with every outfit in the wardrobe.", priceCents: 22000, categorySlug: "bags-accessories", imageUrl: px(8989582), sizes: ONE_SIZE, stock: 8, featured: false },
];

// ───────── variants (colours, gallery) and dummy reviews ─────────
// Colours are product data (not UI theme), so hex values are allowed here.
const PALETTES: Record<string, SeedColor[]> = {
  "mens-clothing": [{ name: "Black", hex: "#14110F" }, { name: "Camel", hex: "#B58B5A" }, { name: "Navy", hex: "#1F2A44" }, { name: "Olive", hex: "#5A6140" }],
  "womens-clothing": [{ name: "Black", hex: "#14110F" }, { name: "Ivory", hex: "#F3EEE4" }, { name: "Rose", hex: "#C98B8B" }, { name: "Burgundy", hex: "#6E1F2B" }],
  "baby-clothing": [{ name: "Cream", hex: "#F3EBDD" }, { name: "Sky", hex: "#A9C7E0" }, { name: "Blush", hex: "#EBC3C3" }],
  hats: [{ name: "Black", hex: "#14110F" }, { name: "Camel", hex: "#B58B5A" }, { name: "Stone", hex: "#BDB7AB" }],
  shoes: [{ name: "White", hex: "#F5F5F2" }, { name: "Black", hex: "#14110F" }, { name: "Red", hex: "#B02A2A" }, { name: "Navy", hex: "#1F2A44" }],
  "bags-accessories": [{ name: "Tan", hex: "#B58B5A" }, { name: "Black", hex: "#14110F" }, { name: "Ivory", hex: "#F3EEE4" }],
};

const GALLERY_POOL: Record<string, number[]> = {
  "mens-clothing": [15869797, 9558897, 7668398, 3944693, 19272485],
  "womens-clothing": [8619007, 31410216, 36594454, 12083001],
  "baby-clothing": [29015875, 7973642, 34121887, 7484842],
  hats: [34200743, 19272485, 20295253, 12083001],
  shoes: [1027130, 11946030, 17630275, 4271563],
  "bags-accessories": [9327162, 14806252, 27835299, 8989582, 7953286],
};

export const seedProducts: SeedProduct[] = baseProducts.map((p, i) => {
  const palette = PALETTES[p.categorySlug];
  const count = Math.min(palette.length, 2 + (i % 3));
  const colors = Array.from({ length: count }, (_, k) => palette[(i + k) % palette.length]);
  const pool = (GALLERY_POOL[p.categorySlug] ?? []).map(px).filter((u) => u !== p.imageUrl);
  const images = [pool[i % pool.length], pool[(i + 1) % pool.length]].filter((u, k, a) => u && a.indexOf(u) === k);
  return { ...p, colors, images };
});

const REVIEWERS = ["Amara O.", "Daniel K.", "Chioma E.", "Sofia M.", "Tunde A.", "Lina R.", "James P.", "Zainab B.", "Mia T.", "Kwame D.", "Ife N.", "Hannah S."];

const COPY: Record<string, { title: string; body: string }[]> = {
  "mens-clothing": [
    { title: "Fits perfectly", body: "True to size and the fabric feels premium. I've already worn it three times this week." },
    { title: "Great quality", body: "Stitching is clean and the cut is sharp. Looks even better in person." },
    { title: "Worth it", body: "Delivery was quick and it goes with everything in my wardrobe." },
  ],
  "womens-clothing": [
    { title: "Beautiful on", body: "The drape is lovely and I got so many compliments. Runs true to size." },
    { title: "Elegant and comfortable", body: "Soft fabric that doesn't crease easily. Perfect for the evening." },
    { title: "Exactly as pictured", body: "Colour matches the photos and the finish is neat. Would buy again." },
  ],
  "baby-clothing": [
    { title: "So soft", body: "Gentle on my baby's skin and it survived several washes without shrinking." },
    { title: "Adorable", body: "Everyone asked where it's from. Easy to put on, which matters at 3am." },
    { title: "Lovely gift", body: "Bought it for my niece and the parents loved it. Good quality for the price." },
  ],
  hats: [
    { title: "Holds its shape", body: "Structured crown, comfortable band and it looks smart with a coat." },
    { title: "Stylish", body: "Exactly the finishing touch I wanted. The colour is rich and even." },
    { title: "Great fit", body: "Sits well and doesn't feel tight. Packaged carefully too." },
  ],
  shoes: [
    { title: "Comfortable from day one", body: "No break-in needed. The sole is cushioned and they look sharp." },
    { title: "Clean design", body: "Minimal and goes with everything. Runs true to size for me." },
    { title: "Good quality", body: "Leather feels solid and the stitching is neat. Very happy." },
  ],
  "bags-accessories": [
    { title: "Roomy and chic", body: "Fits my laptop and daily things. The leather feels substantial." },
    { title: "Lovely finish", body: "Hardware is smooth and the colour is gorgeous. Gets lots of attention." },
    { title: "Perfect size", body: "Compact but practical. Zip pockets are a thoughtful touch." },
  ],
};

/** Deterministic dummy reviews (2 or 3 per product) from made-up customers. Replace with real reviews later. */
export const seedReviews: SeedReview[] = seedProducts.flatMap((p, i) => {
  const copy = COPY[p.categorySlug];
  const n = 2 + (i % 2);
  return Array.from({ length: n }, (_, k) => {
    const c = copy[(i + k) % copy.length];
    const rating = (i + k) % 5 === 3 ? 3 + (k % 2) : 5 - ((i + k) % 3 === 2 ? 1 : 0);
    const day = 1 + ((i * 3 + k * 7) % 27);
    const month = 6 + ((i + k) % 3);
    return {
      productSlug: p.slug,
      authorName: REVIEWERS[(i * 2 + k * 5) % REVIEWERS.length],
      rating,
      title: c.title,
      body: c.body,
      size: p.sizes[(i + k) % p.sizes.length],
      color: p.colors[(i + k) % p.colors.length].name,
      createdAt: `2026-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}T10:00:00Z`,
    };
  });
});
