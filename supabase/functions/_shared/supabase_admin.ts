import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

/// service_role client — bypasses RLS entirely. Never expose this key to
/// Flutter; it must only ever live in Edge Function environment variables.
export function createServiceRoleClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

/// Resolves the calling user (role, salon_id) from the request's bearer
/// JWT, using an RLS-respecting client scoped to that JWT — never trust a
/// salon_id/role sent in the request body (R02).
export async function getAuthenticatedUser(req: Request) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const client = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) throw new Error("unauthenticated");

  const admin = createServiceRoleClient();
  const { data: profile, error: profileError } = await admin
    .from("users")
    .select("id, role, salon_id, phone")
    .eq("id", data.user.id)
    .single();
  if (profileError || !profile) throw new Error("profile_not_found");

  return profile as { id: string; role: string; salon_id: string | null; phone: string | null };
}
