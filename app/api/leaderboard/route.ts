import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";

export async function GET(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Authentication required" }, { status: 401 });

  const period = new URL(request.url).searchParams.get("period") === "all_time" ? "all_time" : "weekly";
  const scope = new URL(request.url).searchParams.get("scope");
  if (scope === "friends") {
    const { data, error } = await supabase.rpc("get_friends_leaderboard");
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });
    const leaders = ((data ?? []) as Array<Record<string, unknown>>).map((row) => ({
      rank: row.rank, display_name: row.displayName, username: row.username, xp: row.xp,
      is_current_user: row.isCurrentUser, accuracy: row.accuracy, quizzes: row.quizzes, streak: row.streak,
    }));
    return NextResponse.json({ leaders });
  }
  const { data, error } = await supabase.rpc("get_leaderboard", {
    p_period: period,
    p_limit: 50,
  });

  if (error) {
    console.error("[api/leaderboard] Supabase RPC failed", { code: error.code, message: error.message });
    return NextResponse.json({ error: "The leaderboard could not be loaded. Please try again." }, { status: 500 });
  }
  return NextResponse.json({ leaders: data ?? [] });
}
