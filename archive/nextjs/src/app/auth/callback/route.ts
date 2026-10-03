import { NextResponse, type NextRequest } from "next/server";
import { createSupabaseServerClient } from "@/core/supabase/server";
import { safeNextPath } from "@/features/auth/domain/safeNextPath";

export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  const code = searchParams.get("code");
  const next = safeNextPath(searchParams.get("next"));
  const supabase = await createSupabaseServerClient();

  if (supabase && code) {
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(`${origin}${next}`);
  }
  return NextResponse.redirect(`${origin}/login?error=1`);
}
