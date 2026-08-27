"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/admin/auth";
import { createClient } from "@/utils/supabase/server";

async function mutate(capability: string, rpc: string, params: Record<string, unknown>, path: string) {
  await requireAdmin(capability);
  const supabase = await createClient();
  const { error } = await supabase.rpc(rpc, params);
  if (error) {
    console.error("[admin-action] mutation failed", { rpc, code: error.code, message: error.message });
    redirect(`${path}?error=${encodeURIComponent("The admin change could not be saved.")}`);
  }
  revalidatePath("/admin", "layout");
}

export async function updateUserAction(formData: FormData) {
  const userId = String(formData.get("userId"));
  await mutate("users.manage", "admin_update_user", {
    p_user_id: userId, p_status: String(formData.get("status")),
    p_eligible: formData.get("eligible") === "true", p_reason: String(formData.get("reason") ?? ""),
  }, `/admin/users/${userId}`);
  redirect(`/admin/users/${userId}?message=User access updated.`);
}

export async function setQuestionStatusAction(formData: FormData) {
  await mutate("questions.manage", "admin_set_question_status", {
    p_question_id: String(formData.get("questionId")), p_status: String(formData.get("status")), p_reason: String(formData.get("reason") ?? "Admin content update"),
  }, "/admin/content");
  redirect("/admin/content?message=Question status updated.");
}

export async function saveQuestionAction(formData: FormData) {
  await mutate("questions.manage", "admin_upsert_question", {
    p_id: String(formData.get("id")), p_question: String(formData.get("question")), p_answer: String(formData.get("answer")),
    p_category: String(formData.get("category")), p_subcategory: String(formData.get("subcategory")),
    p_difficulty: String(formData.get("difficulty")), p_type: String(formData.get("type")),
    p_explanation: String(formData.get("explanation")), p_status: String(formData.get("status")),
  }, "/admin/content");
  redirect("/admin/content?message=Question saved.");
}

export async function assignRoleAction(formData: FormData) {
  await mutate("admins.manage", "admin_assign_role", {
    p_user: String(formData.get("user")), p_role: String(formData.get("role")), p_remove: formData.get("remove") === "true",
  }, "/admin/settings");
  redirect("/admin/settings?message=Admin access updated.");
}

export async function updateSettingAction(formData: FormData) {
  const raw = String(formData.get("value") ?? "");
  let value: unknown = raw;
  if (raw === "true" || raw === "false") value = raw === "true";
  else if (/^\d+$/.test(raw)) value = Number(raw);
  await mutate("settings.manage", "admin_update_setting", { p_key: String(formData.get("key")), p_value: value }, "/admin/settings");
  redirect("/admin/settings?message=Setting updated.");
}
