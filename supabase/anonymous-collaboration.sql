-- User explicitly opted into link-accessible, login-free shared editing.
-- RLS remains enabled. Only the isolated autumn trip is exposed.
begin;
grant select,insert,update on public.autumn_trip_items to anon;
create policy autumn_public_read on public.autumn_trip_items for select to anon
 using (trip_id='2026AutumnJapan');
create policy autumn_public_insert on public.autumn_trip_items for insert to anon
 with check (trip_id='2026AutumnJapan');
create policy autumn_public_update on public.autumn_trip_items for update to anon
 using (trip_id='2026AutumnJapan') with check (trip_id='2026AutumnJapan');
-- No membership access or physical delete grants. Deletion uses versioned tombstones.
commit;
