-- Atomic stamp add/redeem — avoids a read-then-write race between two
-- staff members tapping "add stamp" for the same client at once.
-- SECURITY INVOKER: RLS on loyalty_cards/loyalty_stamp_logs (salon_manage_*)
-- still applies to every row touched inside these functions.
CREATE OR REPLACE FUNCTION public.add_loyalty_stamp(
  p_card_id UUID, p_booking_id UUID DEFAULT NULL
)
RETURNS public.loyalty_cards
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
DECLARE
  v_card public.loyalty_cards;
BEGIN
  UPDATE public.loyalty_cards
  SET stamps_count = stamps_count + 1,
      total_stamps_earned = total_stamps_earned + 1,
      last_stamp_at = NOW()
  WHERE id = p_card_id AND deleted_at IS NULL
  RETURNING * INTO v_card;

  IF v_card.id IS NULL THEN
    RAISE EXCEPTION 'loyalty_card_not_found';
  END IF;

  INSERT INTO public.loyalty_stamp_logs
    (card_id, salon_id, client_id, booking_id, action, stamps_delta)
  VALUES
    (v_card.id, v_card.salon_id, v_card.client_id, p_booking_id, 'earned', 1);

  RETURN v_card;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.add_loyalty_stamp(UUID, UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.add_loyalty_stamp(UUID, UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.redeem_loyalty_reward(p_card_id UUID)
RETURNS public.loyalty_cards
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
DECLARE
  v_card public.loyalty_cards;
  v_redeemed INT;
BEGIN
  SELECT stamps_count INTO v_redeemed
  FROM public.loyalty_cards WHERE id = p_card_id AND deleted_at IS NULL;

  IF v_redeemed IS NULL THEN
    RAISE EXCEPTION 'loyalty_card_not_found';
  END IF;

  UPDATE public.loyalty_cards
  SET stamps_count = 0,
      total_redeemed = total_redeemed + 1
  WHERE id = p_card_id
  RETURNING * INTO v_card;

  INSERT INTO public.loyalty_stamp_logs
    (card_id, salon_id, client_id, action, stamps_delta)
  VALUES
    (v_card.id, v_card.salon_id, v_card.client_id, 'redeemed', -v_redeemed);

  RETURN v_card;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.redeem_loyalty_reward(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.redeem_loyalty_reward(UUID) TO authenticated;