-- Add inventory_count column if it doesn't exist
do $$ 
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'accommodations' 
    and column_name = 'inventory_count'
  ) then
    alter table accommodations 
    add column inventory_count integer not null default 1;
  end if;
end $$;

-- Update inventory counts for fungible accommodations
update accommodations
set inventory_count = 
  case 
    when type = 'Bell Tent' then 3
    when type = 'Tipi' then 2
    when type = 'Pod' then 2
    else 1
  end;

-- Ensure RLS is enabled
alter table accommodations enable row level security;

-- Drop existing policies
drop policy if exists "Anyone can view accommodations" on accommodations;
drop policy if exists "Admins can manage accommodations" on accommodations;

-- Recreate policies with proper permissions
create policy "Anyone can view accommodations"
  on accommodations for select
  using (true);

create policy "Admins can manage accommodations"
  on accommodations for all
  using (
    auth.uid() in (
      select id from auth.users
      where email = 'miles@meetluna.com'
    )
  );

-- Grant necessary permissions
grant usage on schema public to authenticated;
grant select, update on accommodations to authenticated;