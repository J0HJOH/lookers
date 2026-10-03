import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { Logo } from "@/core/ui/Logo";
import { getCurrentUser } from "@/features/auth/data/session";
import { GoogleButton } from "@/features/auth/presentation/GoogleButton";
import { safeNextPath } from "@/features/auth/domain/safeNextPath";

export const metadata: Metadata = { title: "Sign in" };

export default async function LoginPage(props: PageProps<"/login">) {
  const sp = await props.searchParams;
  const next = safeNextPath(typeof sp.next === "string" ? sp.next : undefined);
  if (await getCurrentUser()) redirect(next);

  return (
    <div className="container-page flex min-h-[70vh] items-center justify-center py-16">
      <div className="w-full max-w-md bg-paper p-10 text-center shadow-sm">
        <Logo size={80} withWordmark className="mx-auto" />
        <h1 className="display mt-8 text-4xl">Welcome back</h1>
        <p className="mt-2 text-sm text-ink-muted">Sign in to check out, track orders and save your details.</p>
        {sp.error && <p role="alert" className="mt-4 text-sm text-danger">Sign-in didn&apos;t complete. Please try again.</p>}
        <div className="mt-8"><GoogleButton next={next} /></div>
        <p className="mt-6 text-xs text-ink-muted">By continuing you agree to our terms and privacy policy.</p>
      </div>
    </div>
  );
}
