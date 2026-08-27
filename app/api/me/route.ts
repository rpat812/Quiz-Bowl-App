import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";

export async function GET(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  const requested = Number(new URL(request.url).searchParams.get("days") || 30);
  const days = [0, 7, 30, 90].includes(requested) ? requested : 30;
  const { data, error } = await supabase.rpc("get_my_product_data", { p_days: days });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json(data);
}
