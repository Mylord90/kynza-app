import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export async function logActivity(
  supabase: SupabaseClient,
  params: {
    salonId: string;
    userId: string;
    typeAction: string;
    oldValues?: object;
    newValues?: object;
  },
) {
  await supabase.from("activity_logs").insert({
    salon_id: params.salonId,
    user_id: params.userId,
    type_action: params.typeAction,
    old_values: params.oldValues ?? null,
    new_values: params.newValues ?? null,
  });
}
