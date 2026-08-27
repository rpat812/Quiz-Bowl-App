import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";

export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  const body = await request.json().catch(() => null);
  if (!body || typeof body.enabled !== "boolean" || !/^([01]\d|2[0-3]):[0-5]\d$/.test(body.time) || typeof body.timezone !== "string" || body.timezone.length > 80)
    return NextResponse.json({ error: "Invalid notification preferences" }, { status: 400 });
  const { error } = await supabase.rpc("save_notification_preferences", { p_enabled: body.enabled, p_time: body.time, p_timezone: body.timezone });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}
