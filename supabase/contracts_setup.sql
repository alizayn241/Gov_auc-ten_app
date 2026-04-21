-- Contracts setup for Supabase
-- Run this in the Supabase SQL Editor as the `postgres` role.

begin;

-- Create contracts table if it doesn't exist
create table if not exists public.contracts (
  id uuid not null default gen_random_uuid(),
  tender_id uuid not null,
  vendor_id uuid not null,
  contract_value numeric not null,
  status text not null default 'draft'::text,
  start_date date null,
  end_date date null,
  signed_at timestamp with time zone null,
  created_at timestamp with time zone not null default now(),
  constraint contracts_pkey primary key (id),
  constraint contracts_tender_id_key unique (tender_id),
  constraint contracts_tender_id_fkey foreign key (tender_id) references tenders (id) on delete cascade
) tablespace pg_default;

-- Enable RLS
alter table public.contracts enable row level security;

-- Policies
drop policy if exists "contracts_select_admin_staff" on public.contracts;
drop policy if exists "contracts_insert_admin_staff" on public.contracts;
drop policy if exists "contracts_update_admin_staff" on public.contracts;

create policy "contracts_select_admin_staff"
on public.contracts
for select
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'staff')
  )
);

create policy "contracts_insert_admin_staff"
on public.contracts
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

create policy "contracts_update_admin_staff"
on public.contracts
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'staff')
  )
)
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'staff')
  )
);

commit;