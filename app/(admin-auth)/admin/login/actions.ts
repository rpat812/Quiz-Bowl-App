"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/utils/supabase/server";

export async function adminLogin(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  if (!email || !password) redirect("/admin/login?error=Enter your admin email and password.");

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) redirect(`/admin/login?error=${encodeURIComponent("The admin credentials were not accepted.")}`);

  const { data } = await supabase.rpc("admin_current_access");
  if (!data) {
    await supabase.auth.signOut();
    redirect("/admin/login?error=This account is not authorized for the admin console.");
  }
  redirect("/admin");
}
