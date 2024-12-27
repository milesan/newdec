-- Create admin check function
create or replace function is_admin(user_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 
    from auth.users 
    where id = user_id 
    and email = 'miles@meetluna.com'
  );
end;
$$ language plpgsql security definer;

-- Update accommodations policies
drop policy if exists "Anyone can view accommodations" on accommodations;
drop policy if exists "Admins can manage accommodations" on accommodations;

create policy "Anyone can view accommodations"
  on accommodations for select
  using (true);

create policy "Admins can manage accommodations"
  on accommodations for update
  using (is_admin(auth.uid()));

-- Update availability policies
drop policy if exists "Admins can manage availability" on availability;

create policy "Admins can manage availability"
  on availability for all
  using (is_admin(auth.uid()));

-- Grant necessary permissions
grant usage on schema public to authenticated;
grant select, update on accommodations to authenticated;
grant all on availability to authenticated;

-- Ensure admin function is accessible
grant execute on function is_admin(uuid) to authenticated;