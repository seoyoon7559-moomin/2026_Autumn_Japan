-- Read-only checks after setup. These do not modify summer data or policies.
select c.relname,c.relrowsecurity
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in ('autumn_trip_items','autumn_trip_members');
select tablename,policyname,roles,cmd,qual,with_check from pg_policies
where schemaname='public' and tablename in ('autumn_trip_items','autumn_trip_members');
select table_name,grantee,privilege_type from information_schema.role_table_grants
where table_schema='public' and table_name in ('autumn_trip_items','autumn_trip_members')
and grantee in ('anon','authenticated') order by table_name,grantee,privilege_type;
-- Expected: anon has no grants; authenticated can SELECT members, SELECT/INSERT/UPDATE items.
select trip_id,count(*) from public.autumn_trip_members group by trip_id;
select trip_id,kind,count(*) from public.autumn_trip_items group by trip_id,kind;
-- Expected before user edits: 25 events, 15 places; exactly 2 members after enrollment.
-- Runtime checks required: member read/write allowed; anonymous denied;
-- nonmember reads empty and writes denied; trip reassignment denied;
-- stale version update changes zero rows; other member's like cannot be changed.
