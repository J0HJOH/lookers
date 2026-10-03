import Link from "next/link";

export default function NotFound() {
  return (
    <div className="container-page py-32 text-center">
      <p className="eyebrow">404</p>
      <h1 className="display mt-4 text-5xl">This page isn&apos;t in the collection.</h1>
      <Link href="/shop" className="btn mt-10">Back to the shop</Link>
    </div>
  );
}
