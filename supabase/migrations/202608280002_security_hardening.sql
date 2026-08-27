-- Trigger-only bootstrap helper. Authenticated users must not be able to
-- initialize enhancement records or referral attribution for another user.
revoke all on function public.ensure_user_enhancements(uuid,text) from anon,authenticated;
