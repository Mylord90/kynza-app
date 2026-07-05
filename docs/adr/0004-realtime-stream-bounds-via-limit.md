# ADR-0004: Bound Realtime streams with `.order().limit()`, not a server-side range filter

**Status**: Accepted (Enterprise Final 100 CP8, 2026-07-05).

## Context

3 Realtime `.stream()` call sites (`getSalonBookings`/`getPractitionerBookings` in
`booking_repository_impl.dart`, `getNotifications` in `notification_repository_impl.dart`) synced
a caller's **entire** history for a given `salon_id`/`practitioner_id`/`user_id`, then filtered to
the relevant date/count client-side in Dart. Measured 46× slower at 400k rows than a properly
bounded equivalent (Master Inventory P2-23).

The natural first instinct — add a server-side date-range filter (`.gte()`/`.lt()`) alongside the
existing `.eq()` — **does not work**: `supabase_flutter`'s `SupabaseStreamBuilder` (confirmed by
reading the SDK source directly, not assumed) only supports a single `.eq()` filter plus
`.order()`/`.limit()`. It has no multi-column filter chaining and no range-comparison methods at
all. This is a real, current SDK limitation, not a KYNZA-specific gap.

## Decision

Add `.order(<sort column>, ascending: false).limit(200)` to each of the 3 sites. This doesn't
perfectly replicate "only today's bookings" or "only the last N notifications" server-side — it
bounds the actual measured problem instead: worst-case row count/transfer size, which is what
scaled badly, not the precision of the date filter (the existing client-side date/channel filters
still narrow the bounded set down to what's actually displayed).

**Live-verified against the real Realtime endpoint** (a standalone Dart script against
`kynza-dr-scratch`, not just a compile check): `.stream().eq().order().limit(3)` returned exactly
3 rows, correctly ordered — proving the chain works against the actual platform.

## Consequences

- 200 is a deliberately generous cap — large enough that any realistic salon/user's relevant
  window (today's bookings, the last 20 notifications) is almost certainly within it, while still
  bounding the worst case that caused the 46× slowdown.
- If `supabase_flutter`'s `SupabaseStreamBuilder` ever gains multi-filter/range support in a future
  SDK version, revisit this — a true server-side date-range filter would be strictly better than
  a row-count cap and should replace it once available.
- The same platform limitation applies to any *future* Realtime stream added on a table that can
  grow large per key (`salon_id`, `user_id`, etc.) — default to `.order().limit()` from the start,
  per the same reasoning as ADR-0003.
