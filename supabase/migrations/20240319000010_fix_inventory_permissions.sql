-- Update RLS policies for accommodations table
drop policy if exists "Anyone can view accommodations" on accommodations;
drop policy if exists "Admins can manage accommodations" on accommodations;

-- Create new policies
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