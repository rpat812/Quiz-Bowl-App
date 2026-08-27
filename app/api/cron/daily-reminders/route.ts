import { createClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";
import { getSiteUrl } from "@/lib/site-url";

export async function GET(request: Request) {
  if (!process.env.CRON_SECRET || request.headers.get("authorization") !== `Bearer ${process.env.CRON_SECRET}`)
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const resendKey = process.env.RESEND_API_KEY;
  if (!serviceKey || !resendKey) return NextResponse.json({ error: "Reminder provider is not configured" }, { status: 503 });
  const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, serviceKey, { auth: { persistSession: false } });
  const { data: preferences, error } = await supabase.from("notification_preferences").select("user_id,daily_practice_email_time,timezone").eq("daily_practice_email_enabled", true);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  const now = new Date(); let sent = 0; let skipped = 0; let failed = 0;
  for (const preference of preferences ?? []) {
    const parts = new Intl.DateTimeFormat("en-CA", { timeZone: preference.timezone, year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).formatToParts(now);
    const read = (type: Intl.DateTimeFormatPartTypes) => parts.find((part) => part.type === type)?.value || "";
    const localDate = `${read("year")}-${read("month")}-${read("day")}`;
    const localTime = `${read("hour")}:${read("minute")}`;
    if (localTime < String(preference.daily_practice_email_time).slice(0, 5)) continue;
    const { data: existing } = await supabase.from("notification_deliveries").select("id").eq("user_id", preference.user_id).eq("notification_type", "daily_practice").eq("channel", "email").eq("local_date", localDate).maybeSingle();
    if (existing) continue;
    const { data: completed } = await supabase.from("daily_progress").select("session_id").eq("user_id", preference.user_id).eq("practice_date", localDate).maybeSingle();
    if (completed) {
      await supabase.from("notification_deliveries").insert({ user_id: preference.user_id, notification_type: "daily_practice", channel: "email", local_date: localDate, status: "skipped", metadata: { reason: "practice_completed" } }); skipped++; continue;
    }
    const { data: authUser } = await supabase.auth.admin.getUserById(preference.user_id);
    const { data: profile } = await supabase.from("profiles").select("display_name,current_streak").eq("id", preference.user_id).single();
    if (!authUser.user?.email) continue;
    const response = await fetch("https://api.resend.com/emails", { method: "POST", headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" }, body: JSON.stringify({ from: process.env.REMINDER_FROM_EMAIL || "QuizForge <reminders@quizforge.app>", to: authUser.user.email, subject: "Keep your QuizForge streak alive", html: `<p>Hi ${profile?.display_name || "Scholar"},</p><p>You have not completed today's QuizForge practice yet.</p><p>Current streak: <strong>${profile?.current_streak || 0} days</strong></p><p><a href="${getSiteUrl()}">Start practice</a> · <a href="${getSiteUrl()}/?view=settings">Manage reminders</a></p>` }) });
    const payload = await response.json().catch(() => ({})) as { id?: string; message?: string };
    await supabase.from("notification_deliveries").insert({ user_id: preference.user_id, notification_type: "daily_practice", channel: "email", local_date: localDate, status: response.ok ? "sent" : "failed", sent_at: response.ok ? new Date().toISOString() : null, provider_message_id: payload.id, metadata: response.ok ? {} : { error: payload.message || "Provider error" } });
    response.ok ? sent++ : failed++;
  }
  return NextResponse.json({ checked: preferences?.length ?? 0, sent, skipped, failed });
}
