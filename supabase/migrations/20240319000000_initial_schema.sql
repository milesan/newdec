-- Drop existing tables if they exist
drop table if exists bookings;
drop table if exists accommodations;

-- Create accommodations table
create table accommodations (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  location text not null,
  price integer not null,
  rating numeric,
  reviews integer default 0,
  image_url text not null,
  type text not null,
  beds integer not null,
  bathrooms numeric not null,
  superhost boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create bookings table
create table bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  accommodation_id uuid references accommodations not null,
  check_in timestamp with time zone not null,
  check_out timestamp with time zone not null,
  total_price integer not null,
  status text default 'pending' not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table bookings enable row level security;
alter table accommodations enable row level security;

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

-- Grant necessary permissions
grant usage on schema public to anon, authenticated;
grant select, insert on public.bookings to anon, authenticated;
grant select on public.accommodations to anon, authenticated;