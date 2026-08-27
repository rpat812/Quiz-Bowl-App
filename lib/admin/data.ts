import { createClient } from "@/utils/supabase/server";

export async function adminRpc<T>(name: string, params: Record<string, unknown> = {}): Promise<T> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc(name, params);
  if (error) {
    console.error("[admin-rpc] request failed", { name, code: error.code, message: error.message });
    throw new Error("Admin data could not be loaded.");
  }
  return data as T;
}

export function single(value: string | string[] | undefined, fallback = "") {
  return Array.isArray(value) ? value[0] ?? fallback : value ?? fallback;
}

export function integer(value: string | string[] | undefined, fallback: number) {
  const parsed = Number(single(value));
  return Number.isInteger(parsed) ? parsed : fallback;
}

export function formatAdminDate(value: string | null | undefined) {
  if (!value) return "Never";
  return new Intl.DateTimeFormat("en-US", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
}
