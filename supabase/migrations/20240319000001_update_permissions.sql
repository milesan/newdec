-- Enable RLS
alter table bookings enable row level security;
alter table accommodations enable row level security;
alter table profiles enable row level security;

-- Create policies for bookings
create policy "Users can view their own bookings" 
  on bookings for select
  to authenticated 
  using (auth.uid() = user_id);

create policy "Users can insert their own bookings" 
  on bookings for insert 
  to authenticated
  with check (auth.uid() = user_id);

create policy "Admins can view all bookings" 
  on bookings for select
  to authenticated 
  using (auth.uid() in (
    select id from auth.users
    where email = 'miles@meetluna.com'
  ));

-- Create policies for accommodations
create policy "Anyone can view accommodations" 
  on accommodations for select
  to authenticated 
  using (true);

-- Create policies for profiles
create policy "Users can view their own profile"
  on profiles for select
  to authenticated
  using (auth.uid() = id);

-- Grant necessary permissions
grant usage on schema public to anon, authenticated;
grant select, insert on public.bookings to anon, authenticated;
grant select on public.accommodations to anon, authenticated;
grant select on public.profiles to anon, authenticated;