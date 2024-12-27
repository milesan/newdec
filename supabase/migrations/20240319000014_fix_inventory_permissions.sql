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
      where email = 'andre@thegarden.pt'
    )
  );

-- Ensure inventory_count column exists and has proper default
alter table accommodations 
  alter column inventory_count set default 1,
  alter column inventory_count set not null;

-- Grant necessary permissions
grant usage on schema public to authenticated;
grant all on accommodations to authenticated;