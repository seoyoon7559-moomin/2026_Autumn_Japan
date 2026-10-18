-- Run once in the existing project's SQL Editor, AFTER project restoration.
-- This file never reads/writes the summer trip_shared_state table.
begin;
create table if not exists public.autumn_trip_members (
 trip_id text not null check (trip_id = '2026AutumnJapan'),
 user_id uuid not null references auth.users(id) on delete cascade,
 primary key (trip_id,user_id)
);
create table if not exists public.autumn_trip_items (
 trip_id text not null check (trip_id = '2026AutumnJapan'),
 id text not null check (id ~ '^[A-Za-z0-9_-]{1,100}$'),
 kind text not null check (kind in ('event','place','like')),
 data jsonb not null check (jsonb_typeof(data)='object' and octet_length(data::text)<30000),
 deleted boolean not null default false,
 version integer not null default 1 check(version>0),
 updated_at timestamptz not null default now(),
 primary key(trip_id,id)
);
alter table public.autumn_trip_members enable row level security;
alter table public.autumn_trip_items enable row level security;
revoke all on public.autumn_trip_members,public.autumn_trip_items from anon,authenticated;
grant select on public.autumn_trip_members to authenticated;
grant select,insert,update on public.autumn_trip_items to authenticated;
create policy autumn_member_self on public.autumn_trip_members for select to authenticated
 using (user_id=(select auth.uid()));
create policy autumn_item_read on public.autumn_trip_items for select to authenticated
 using (exists(select 1 from public.autumn_trip_members m where m.trip_id=autumn_trip_items.trip_id and m.user_id=(select auth.uid())));
create policy autumn_item_insert on public.autumn_trip_items for insert to authenticated
 with check (exists(select 1 from public.autumn_trip_members m where m.trip_id=autumn_trip_items.trip_id and m.user_id=(select auth.uid()))
 and (kind<>'like' or (data->>'actor'=(select auth.uid())::text and id='like-'||(data->>'placeId')||'-'||(select auth.uid())::text)));
create policy autumn_item_update on public.autumn_trip_items for update to authenticated
 using (exists(select 1 from public.autumn_trip_members m where m.trip_id=autumn_trip_items.trip_id and m.user_id=(select auth.uid())) and (kind<>'like' or data->>'actor'=(select auth.uid())::text))
 with check (exists(select 1 from public.autumn_trip_members m where m.trip_id=autumn_trip_items.trip_id and m.user_id=(select auth.uid()))
 and (kind<>'like' or (data->>'actor'=(select auth.uid())::text and id='like-'||(data->>'placeId')||'-'||(select auth.uid())::text)));
create or replace function public.autumn_item_version_guard() returns trigger
 language plpgsql security invoker set search_path='' as $$
begin
 if new.trip_id<>old.trip_id or new.id<>old.id or new.kind<>old.kind then
  raise exception 'Item identity cannot be changed';
 end if;
 if new.version<>old.version+1 then raise exception 'Version must increment exactly once'; end if;
 new.updated_at=now();
 return new;
end; $$;
revoke all on function public.autumn_item_version_guard() from public,anon,authenticated;
create trigger autumn_item_version before update on public.autumn_trip_items
 for each row execute function public.autumn_item_version_guard();
commit;

-- After the two people sign in, an administrator adds their verified auth.users IDs:
-- insert into public.autumn_trip_members(trip_id,user_id)
-- values ('2026AutumnJapan','FIRST_AUTH_USER_UUID'),('2026AutumnJapan','SECOND_AUTH_USER_UUID');
-- Do NOT grant INSERT/UPDATE on the membership table to browser roles.
