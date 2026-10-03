export const ORDER_STATUSES = ["pending", "confirmed", "shipped", "delivered", "cancelled"] as const;
export type OrderStatus = (typeof ORDER_STATUSES)[number];

export const isOrderStatus = (v: unknown): v is OrderStatus =>
  typeof v === "string" && (ORDER_STATUSES as readonly string[]).includes(v);

export interface OrderItem {
  productName: string;
  imageUrl: string;
  size: string;
  unitPriceCents: number;
  quantity: number;
}

export interface Order {
  id: string;
  orderNumber: string;
  status: OrderStatus;
  email: string;
  createdAt: string;
  subtotalCents: number;
  shippingCents: number;
  totalCents: number;
  paymentMethod: string;
  shipTo: {
    name: string;
    phone: string;
    line1: string;
    line2: string | null;
    city: string;
    region: string;
    postalCode: string;
    country: string;
  };
  items: OrderItem[];
}

export const STATUS_LABEL: Record<OrderStatus, string> = {
  pending: "Pending",
  confirmed: "Confirmed",
  shipped: "Shipped",
  delivered: "Delivered",
  cancelled: "Cancelled",
};
