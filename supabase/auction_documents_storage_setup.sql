-- Auction documents storage setup
-- Run this in Supabase SQL Editor.
-- It creates the `auction-docs` bucket if needed and allows admin/staff uploads.

insert into storage.buckets (id, name, public)
values ('auction-docs', 'auction-docs', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "auction_docs_public_read" on storage.objects;
drop policy if exists "auction_docs_admin_staff_insert" on storage.objects;
drop policy if exists "auction_docs_admin_staff_update" on storage.objects;
drop policy if exists "auction_docs_admin_staff_delete" on storage.objects;

create policy "auction_docs_public_read"
on storage.objects
for select
to public
using (bucket_id = 'auction-docs');

create policy "auction_docs_admin_staff_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'auction-docs'
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'staff')
  )
);

create policy "auction_docs_admin_staff_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'auction-docs'
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'staff')
  )
)
with check (
  bucket_id = 'auction-docs'
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'staff')
  )
);

create policy "auction_docs_admin_staff_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'auction-docs'
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'staff')
  )
);
