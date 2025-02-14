-- First drop all policies that depend on is_admin()
drop policy if exists "Admin full access to availability" on availability;
drop policy if exists "Admin full access to accommodations" on accommodations;
drop policy if exists "Admin full access to bookings" on bookings;
drop policy if exists "Admins can manage accommodations" on accommodations;
drop policy if exists "Admins can manage availability" on availability;

-- Now we can safely drop and recreate the is_admin function
drop function if exists public.is_admin() cascade;

-- Create a more secure admin check function
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1 
    from auth.users 
    where id = auth.uid() 
    and email = 'andre@thegarden.pt'
  );
end;
$$ language plpgsql security definer;

-- Enable RLS on all tables
alter table accommodations enable row level security;
alter table availability enable row level security;
alter table bookings enable row level security;

-- Create policies for accommodations
create policy "Public read access to accommodations"
  on accommodations for select
  using (true);

create policy "Admin full access to accommodations"
  on accommodations for all
  using (public.is_admin());

-- Create policies for availability
create policy "Public read access to availability"
  on availability for select
  using (true);

create policy "Admin full access to availability"
  on availability for all
  using (public.is_admin());

-- Create policies for bookings
create policy "Users can view their own bookings"
  on bookings for select
  using (auth.uid() = user_id);

create policy "Users can create bookings"
  on bookings for insert
  with check (auth.uid() = user_id);

create policy "Admin full access to bookings"
  on bookings for all
  using (public.is_admin());

-- Grant necessary permissions
grant usage on schema public to authenticated;
grant select on accommodations to authenticated;
grant select on availability to authenticated;
grant select, insert on bookings to authenticated;
grant all on accommodations to authenticated;
grant all on availability to authenticated;
grant all on bookings to authenticated;
grant execute on function public.is_admin() to authenticated;