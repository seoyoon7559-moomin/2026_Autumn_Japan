begin;
set local role anon;
insert into public.autumn_trip_items(trip_id,id,kind,data) values('2026AutumnJapan','anonymous-verification','place','{"name":"verification"}');
update public.autumn_trip_items set data='{"name":"updated"}',version=2 where trip_id='2026AutumnJapan' and id='anonymous-verification' and version=1;
select count(*)=1 as anonymous_insert_update_read_pass from public.autumn_trip_items where id='anonymous-verification' and version=2 and data->>'name'='updated';
with changed as (update public.autumn_trip_items set version=3 where id='anonymous-verification' and version=1 returning id) select count(*)=0 as stale_write_blocked from changed;
do $$ begin
 begin
 insert into public.autumn_trip_items(trip_id,id,kind,data) values('other-trip','forbidden','place','{}');
 raise exception 'TEST FAILED: cross-trip insert allowed';
 exception when check_violation or insufficient_privilege then null;
 end;
 begin
 perform * from public.autumn_trip_members;
 raise exception 'TEST FAILED: membership readable';
 exception when insufficient_privilege then null;
 end;
end $$;
rollback;
