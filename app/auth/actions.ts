"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/utils/supabase/server";
import { getSiteUrl } from "@/lib/site-url";

function authError(path: string, message: string): never {
  redirect(`${path}?error=${encodeURIComponent(message)}`);
}

export async function login(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  if (!email || !password) authError("/login", "Enter your email and password.");

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) authError("/login", error.message);
  redirect("/");
}

export async function signup(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const username = String(formData.get("username") ?? "").trim().toLowerCase();
  const displayName = String(formData.get("displayName") ?? "").trim();
  const referralCode = String(formData.get("referralCode") ?? "").trim().toUpperCase();

  if (!/^[a-z0-9_]{3,24}$/.test(username)) {
    authError("/signup", "Username must be 3-24 letters, numbers, or underscores.");
  }
  if (password.length < 8) authError("/signup", "Password must be at least 8 characters.");

  const requestHeaders = await headers();
  const siteUrl = getSiteUrl(requestHeaders.get("origin"));
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: `${siteUrl}/auth/callback`,
      data: { username, display_name: displayName || username, referral_code: referralCode || undefined },
    },
  });
  if (error) authError("/signup", error.message);
  if (!data.session) redirect("/login?message=Check your email to confirm your account.");
  redirect("/");
}

export async function signout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
