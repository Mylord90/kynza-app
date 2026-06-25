-- owner_journey_progress was never added to the supabase_realtime
-- publication, so JourneyRepositoryImpl.watchJourney()'s .stream() never
-- emits and JourneyProgressCard stays hidden for every owner.
ALTER PUBLICATION supabase_realtime ADD TABLE public.owner_journey_progress;