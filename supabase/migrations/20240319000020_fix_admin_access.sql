-- Drop existing policies and functions
drop policy if exists "Admin full access" on availability;
drop policy if exists "Admins can manage accommodations" on accommodations;
drop function if exists public.is_admin();

-- Create a more secure admin check function with proper schema search path
create or replace function public.is_admin()
returns boolean as $$
declare
  current_email text;
begin
  select email into current_email
  from auth.users
  where id = auth.uid();
  
  return current_email = 'andre@thegarden.pt';
end;
$$ language plpgsql security definer set search_path = public, auth;

-- Update availability policies
create policy "Admin full access"
on availability
for all
using (
  (select email from auth.users where id = auth.uid()) = 'andre@thegarden.pt'
);

-- Update accommodations policies
create policy "Anyone can view accommodations"
on accommodations
for select
using (true);

create policy "Admins can manage accommodations"
on accommodations
for all
using (
  (select email from auth.users where id = auth.uid()) = 'andre@thegarden.pt'
);

-- Grant necessary permissions
grant usage on schema public to authenticated, anon;
grant select on accommodations to authenticated, anon;
grant all on availability to authenticated;
grant all on accommodations to authenticated;