import { redirect } from "next/navigation";
import { createClient } from "@/utils/supabase/server";

export type AdminAccess = {
  userId: string;
  username: string;
  displayName: string;
  roles: string[];
  capabilities: string[];
};

export async function getAdminAccess(): Promise<AdminAccess | null> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;
  const { data, error } = await supabase.rpc("admin_current_access");
  if (error || !data) return null;
  return data as AdminAccess;
}

export async function requireAdmin(capability?: string) {
  const access = await getAdminAccess();
  if (!access) redirect("/admin/login?error=Admin access is required.");
  if (capability && !access.capabilities.includes(capability)) {
    redirect("/admin?error=You do not have permission to open that admin area.");
  }
  return access;
}
