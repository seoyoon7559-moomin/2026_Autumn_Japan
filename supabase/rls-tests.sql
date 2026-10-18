-- Transactional live RLS checks. All synthetic users, rows and changes roll back.
begin;
create temporary table autumn_test_results(name text,passed boolean);
create temporary table autumn_test_users(label text,id uuid default gen_random_uuid());
insert into autumn_test_users(label) values ('a'),('b'),('outsider');
insert into auth.users(id,aud,role,email,email_confirmed_at)
select id,'authenticated','authenticated','autumn-rls-'||id::text||'@example.invalid',now() from autumn_test_users;
insert into public.autumn_trip_members(trip_id,user_id)
select '2026AutumnJapan',id from autumn_test_users where label in ('a','b');
grant select on autumn_test_users to authenticated,anon;
grant insert,select on autumn_test_results to authenticated,anon;
create function pg_temp.autumn_denied(statement text) returns boolean
language plpgsql security invoker set search_path='' as $$
begin
 execute statement;
 return false;
exception when insufficient_privilege or check_violation or raise_exception then
 return true;
end; $$;

set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',id,'role','authenticated')::text,true) from autumn_test_users where label='a';
insert into autumn_test_results select 'member reads seed',count(*)>=40 from public.autumn_trip_items where trip_id='2026AutumnJapan';
insert into autumn_test_results select 'member sees own membership only',count(*)=1 from public.autumn_trip_members;
insert into public.autumn_trip_items(trip_id,id,kind,data)
values ('2026AutumnJapan','rls-test-event','event','{"day":0,"time":"12:00","title":"test"}');
insert into autumn_test_results select 'member inserts',count(*)=1 from public.autumn_trip_items where id='rls-test-event';
update public.autumn_trip_items set data=jsonb_set(data,'{title}','"edited"'),version=version+1 where id='rls-test-event' and version=1;
insert into autumn_test_results select 'member updates',version=2 and data->>'title'='edited' from public.autumn_trip_items where id='rls-test-event';
with changed as (update public.autumn_trip_items set version=version+1 where id='rls-test-event' and version=1 returning id)
insert into autumn_test_results select 'stale version changes zero rows',count(*)=0 from changed;
insert into autumn_test_results values ('identity reassignment denied',pg_temp.autumn_denied($q$update public.autumn_trip_items set trip_id='other-trip',version=version+1 where id='rls-test-event'$q$));
insert into autumn_test_results values ('membership self-enrollment denied',pg_temp.autumn_denied($q$insert into public.autumn_trip_members(trip_id,user_id) select '2026AutumnJapan',id from autumn_test_users where label='outsider'$q$));
insert into public.autumn_trip_items(trip_id,id,kind,data)
select '2026AutumnJapan','like-place-1-'||id::text,'like',jsonb_build_object('placeId','place-1','actor',id::text,'on',true) from autumn_test_users where label='a';
insert into autumn_test_results values ('physical delete denied',pg_temp.autumn_denied($q$delete from public.autumn_trip_items where id='rls-test-event'$q$));

select set_config('request.jwt.claims',json_build_object('sub',id,'role','authenticated')::text,true) from autumn_test_users where label='b';
with changed as (update public.autumn_trip_items set data=jsonb_set(data,'{on}','false'),version=version+1 where kind='like' and data->>'actor'=(select id::text from autumn_test_users where label='a') returning id)
insert into autumn_test_results select 'other member cannot alter a like',count(*)=0 from changed;
update public.autumn_trip_items set deleted=true,version=version+1 where id='rls-test-event';
insert into autumn_test_results select 'second member may delete shared event via tombstone',deleted from public.autumn_trip_items where id='rls-test-event';

select set_config('request.jwt.claims',json_build_object('sub',id,'role','authenticated')::text,true) from autumn_test_users where label='outsider';
insert into autumn_test_results select 'nonmember reads zero items',count(*)=0 from public.autumn_trip_items;
insert into autumn_test_results values ('nonmember insert denied',pg_temp.autumn_denied($q$insert into public.autumn_trip_items(trip_id,id,kind,data) values('2026AutumnJapan','outsider-test','place','{"name":"denied"}')$q$));
with changed as (update public.autumn_trip_items set version=version+1 where id='rls-test-event' returning id)
insert into autumn_test_results select 'nonmember update changes zero rows',count(*)=0 from changed;

set local role anon;
select set_config('request.jwt.claims','{"role":"anon"}',true);
insert into autumn_test_results values ('anonymous read denied',pg_temp.autumn_denied('select * from public.autumn_trip_items'));
insert into autumn_test_results values ('anonymous write denied',pg_temp.autumn_denied($q$insert into public.autumn_trip_items(trip_id,id,kind,data) values('2026AutumnJapan','anon-test','place','{"name":"denied"}')$q$));
reset role;
select count(*) as checks,bool_and(passed) as all_passed,jsonb_agg(jsonb_build_object('name',name,'passed',passed)) as results from autumn_test_results;
rollback;
