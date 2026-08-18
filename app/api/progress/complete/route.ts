import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";

type SubmittedAnswer = { questionId?: unknown; submitted?: unknown };

export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Authentication required" }, { status: 401 });

  const body = await request.json().catch(() => null);
  const answers = body?.answers as SubmittedAnswer[] | undefined;
  if (!Array.isArray(answers) || answers.length < 1 || answers.length > 20 ||
      answers.some((a) => typeof a.questionId !== "string" || typeof a.submitted !== "string")) {
    return NextResponse.json({ error: "Invalid session answers" }, { status: 400 });
  }

  const sessionType = body.sessionType === "daily" ? "daily" : "category";
  const category = typeof body.category === "string" ? body.category : "";
  const timezone = typeof body.timezone === "string" && body.timezone.length < 80 ? body.timezone : "UTC";
  const { data, error } = await supabase.rpc("complete_practice_session", {
    p_session_type: sessionType,
    p_category: category,
    p_answers: answers,
    p_timezone: timezone,
  });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json(data);
}
