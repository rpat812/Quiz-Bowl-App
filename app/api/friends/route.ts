import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";

export async function GET(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  const url = new URL(request.url);
  const search = url.searchParams.get("search")?.trim();
  const rpc = search ? supabase.rpc("search_users_for_friends", { p_search: search }) :
    url.searchParams.get("leaderboard") === "true" ? supabase.rpc("get_friends_leaderboard") : supabase.rpc("get_friends_data");
  const { data, error } = await rpc;
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json(data);
}

export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  const body = await request.json().catch(() => null);
  if (!body || !["send", "accept", "decline", "remove"].includes(body.action) || typeof body.target !== "string")
    return NextResponse.json({ error: "Invalid friend action" }, { status: 400 });
  const { error } = await supabase.rpc("manage_friend", { p_action: body.action, p_target: body.target });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}
