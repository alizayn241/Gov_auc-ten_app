-- Notifications setup for auctions/tenders in Supabase
-- Run this in the Supabase SQL Editor as the `postgres` role.

begin;

-- Make sure RLS is enabled.
alter table public.notifications enable row level security;

-- Replace notifications policies with a minimal working set.
drop policy if exists "notifications_select_own" on public.notifications;
drop policy if exists "notifications_update_own" on public.notifications;
drop policy if exists "notifications_insert_admin_staff" on public.notifications;

create policy "notifications_select_own"
on public.notifications
for select
to authenticated
using (auth.uid() = user_id);

create policy "notifications_update_own"
on public.notifications
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "notifications_insert_admin_staff"
on public.notifications
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'staff')
  )
);

-- Trigger function: whenever an auction becomes published,
-- create one notification per citizen profile.
create or replace function public.notify_citizens_on_published_auction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from 'published' then
    return new;
  end if;

  if tg_op = 'UPDATE' and old.status is not distinct from 'published' then
    return new;
  end if;

  insert into public.notifications (
    user_id,
    title,
    body,
    type,
    entity_type,
    entity_id
  )
  select
    p.id,
    'New auction available',
    coalesce(new.title, 'Auction') || ' was added in ' || coalesce(new.category, 'Other') || '.',
    'auction_created',
    'auction',
    new.id
  from public.profiles p
  where lower(coalesce(p.role, '')) = 'citizen';

  return new;
end;
$$;

drop trigger if exists trg_notify_citizens_on_published_auction on public.auctions;

create trigger trg_notify_citizens_on_published_auction
after insert or update of status, title, category
on public.auctions
for each row
execute function public.notify_citizens_on_published_auction();

commit;

-- Optional check queries after running:
-- select id, role, display_name from public.profiles order by created_at desc;
-- select * from public.notifications order by created_at desc;
