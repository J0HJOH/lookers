import { STATUS_LABEL, type OrderStatus } from "../domain/order";

const STYLE: Record<OrderStatus, string> = {
  pending: "border-gold-deep text-gold-deep",
  confirmed: "border-ink text-ink",
  shipped: "border-success text-success",
  delivered: "border-success bg-success text-paper",
  cancelled: "border-danger text-danger",
};

// Status is always shown as a word, never colour alone.
export function StatusBadge({ status }: { status: OrderStatus }) {
  return <span className={`inline-block border px-2.5 py-1 text-[10px] uppercase tracking-[0.2em] ${STYLE[status]}`}>{STATUS_LABEL[status]}</span>;
}
