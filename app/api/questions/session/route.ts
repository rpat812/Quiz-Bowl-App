import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";
import type { PracticeQuestion } from "@/types/questions";

export async function GET(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const category = searchParams.get("category")?.trim() || null;
  const requestedCount = Number(searchParams.get("count") || 10);
  const count = Number.isInteger(requestedCount)
    ? Math.max(1, Math.min(requestedCount, 20))
    : 10;

  if (category && category.length > 50) {
    return NextResponse.json({ error: "Invalid category" }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("get_practice_questions", {
    p_category: category,
    p_count: count,
  });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ questions: (data ?? []) as PracticeQuestion[] });
}
