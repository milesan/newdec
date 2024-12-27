-- First, let's drop ALL existing policies
do $$ 
begin
  -- Drop all policies on bookings
  drop policy if exists "Users can view their own bookings" on bookings;
  drop policy if exists "Users can insert their own bookings" on bookings;
  drop policy if exists "Users can update their own bookings" on bookings;
  drop policy if exists "Users can create bookings" on bookings;
  drop policy if exists "Admins can view all bookings" on bookings;
  drop policy if exists "Admin full access to bookings" on bookings;

  -- Drop all policies on accommodations
  drop policy if exists "Anyone can view accommodations" on accommodations;
  drop policy if exists "Admins can manage accommodations" on accommodations;
  drop policy if exists "Public read access" on accommodations;
  drop policy if exists "Admin full access to accommodations" on accommodations;

  -- Drop all policies on availability
  drop policy if exists "Admin full access" on availability;
  drop policy if exists "Admins can manage availability" on availability;
  drop policy if exists "Public read access to availability" on availability;
  drop policy if exists "Admin full access to availability" on availability;
end $$;

-- Drop existing admin function
drop function if exists public.is_admin();

-- Create a secure admin check function
create or replace function public.is_admin()
returns boolean as $$
begin
  return (
    select email = 'andre@thegarden.pt'
    from auth.users
    where id = auth.uid()
  );
end;
$$ language plpgsql security definer;

-- Enable RLS on all tables
alter table accommodations enable row level security;
alter table availability enable row level security;
alter table bookings enable row level security;

-- Create new policies for accommodations
create policy "Public read access"
  on accommodations for select
  using (true);

create policy "Admin full access to accommodations"
  on accommodations for all
  using (public.is_admin());

-- Create new policies for availability
create policy "Public read access to availability"
  on availability for select
  using (true);

create policy "Admin full access to availability"
  on availability for all
  using (public.is_admin());

-- Create new policies for bookings
create policy "Users can create bookings"
  on bookings for insert
  with check (auth.uid() = user_id);

create policy "Users can view their own bookings"
  on bookings for select
  using (auth.uid() = user_id);

create policy "Admin full access to bookings"
  on bookings for all
  using (public.is_admin());

-- Grant necessary permissions
grant usage on schema public to anon, authenticated;
grant select on accommodations to anon, authenticated;
grant select on availability to anon, authenticated;
grant select, insert on bookings to authenticated;
grant all on accommodations to authenticated;
grant all on availability to authenticated;
grant all on bookings to authenticated;

-- Update inventory counts
update accommodations
set inventory_count = 
  case 
    when type = 'Tipi' then 40
    when title = '4 Meter Bell Tent' then 25
    when title = '5m Bell Tent' then 6
    when title = 'A-Frame Pod' then 1
    when title = 'Microcabin' then 3
    else inventory_count
  end;