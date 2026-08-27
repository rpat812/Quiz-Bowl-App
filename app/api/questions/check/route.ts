import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";
import type { AnswerCheck } from "@/types/questions";

export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  const body = await request.json().catch(() => null);
  const questionId = body?.questionId;
  const submitted = body?.submitted;
  const timedOut = body?.timedOut === true;

  if (
    typeof questionId !== "string" ||
    !/^HIST-\d{4}$/.test(questionId) ||
    typeof submitted !== "string" ||
    (!timedOut && !submitted.trim()) ||
    submitted.length > 200
  ) {
    return NextResponse.json({ error: "Invalid answer submission" }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("check_practice_answer", {
    p_question_id: questionId,
    p_submitted: submitted,
  });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json(data as AnswerCheck);
}
