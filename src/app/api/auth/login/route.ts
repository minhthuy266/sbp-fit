import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  let body: { email?: unknown; password?: unknown };
  try { body = await request.json(); } catch {
    return NextResponse.json({ error: "Invalid request" }, { status: 400 });
  }
  if (typeof body.email !== "string" || typeof body.password !== "string" || !body.email || !body.password) {
    return NextResponse.json({ error: "Email and password are required" }, { status: 400 });
  }
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithPassword({ email: body.email, password: body.password });
  if (error || !data.session) {
    return NextResponse.json({ error: error?.message ?? "Sign in failed" }, { status: 401 });
  }
  return NextResponse.json({ ok: true }, { headers: { "Cache-Control": "no-store" } });
}
