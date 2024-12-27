-- Drop all existing tables and start fresh
drop table if exists availability cascade;
drop table if exists bookings cascade;
drop table if exists accommodations cascade;
drop table if exists profiles cascade;

-- Create profiles table
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

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
  inventory_count integer not null default 1,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create availability table
create table availability (
  id uuid primary key default gen_random_uuid(),
  accommodation_id uuid references accommodations on delete cascade not null,
  date date not null,
  status text not null check (status in ('AVAILABLE', 'HOLD', 'BOOKED')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(accommodation_id, date)
);

-- Create bookings table
create table bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  accommodation_id uuid references accommodations on delete cascade not null,
  check_in date not null,
  check_out date not null,
  total_price integer not null,
  status text default 'pending' not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create indexes
create index idx_availability_lookup on availability(accommodation_id, date);
create index idx_bookings_dates on bookings(check_in, check_out);
create index idx_bookings_user on bookings(user_id);

-- Enable RLS
alter table profiles enable row level security;
alter table accommodations enable row level security;
alter table availability enable row level security;
alter table bookings enable row level security;

-- Create admin function
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

-- Create policies
create policy "Public read access to accommodations"
  on accommodations for select
  using (true);

create policy "Admin full access to accommodations"
  on accommodations for all
  using (public.is_admin());

create policy "Public read access to availability"
  on availability for select
  using (true);

create policy "Admin full access to availability"
  on availability for all
  using (public.is_admin());

create policy "Users can view their own bookings"
  on bookings for select
  using (auth.uid() = user_id);

create policy "Users can create bookings"
  on bookings for insert
  with check (auth.uid() = user_id);

create policy "Admin full access to bookings"
  on bookings for all
  using (public.is_admin());

-- Insert initial data
insert into accommodations (title, location, price, rating, reviews, image_url, type, beds, bathrooms, superhost, inventory_count)
values
  ('Your Own Tent', 'The Garden', 190, 4.9, 45, 'https://storage.tally.so/46092536-82aa-4efc-a845-d84097c62a4b/photo_2023-09-07_18-55-35.jpg', 'Camping', 1, 0, false, 1),
  ('2.2 Meter Tipi', 'The Garden', 290, 4.8, 32, 'https://storage.tally.so/3b239e63-e5d3-439b-9536-6384ceb4314c/PXL_20220718_152819137-1-.jpg', 'Tipi', 1, 0, false, 40),
  ('Shared Dorm', 'The Garden', 270, 4.7, 89, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm', 1, 1, false, 1),
  ('Van Parking', 'The Garden', 190, 4.85, 27, 'https://storage.tally.so/530c1104-341b-42ec-8c10-8aaa5ad56b87/DOG_9426.jpg', 'Parking', 0, 0, false, 1),
  ('4 Meter Bell Tent', 'The Garden', 330, 4.9, 56, 'https://storage.tally.so/f385d036-6b48-4a0b-b119-2e334c0bc1f0/photo_2023-09-07_18-55-18.jpg', 'Bell Tent', 2, 0, true, 25),
  ('5m Bell Tent', 'The Garden', 385, 4.95, 42, 'https://storage.tally.so/eb9c15bb-7cb3-4b61-a84e-1c131c23ab38/2023-08-17_Synesthesia-Portugal-by-Alexa-Ashley-0011.jpg', 'Bell Tent', 2, 0, true, 6),
  ('Microcabin', 'The Garden', 410, 4.92, 73, 'https://storage.tally.so/93a554e1-8d1b-4606-947a-33059b65d5b9/IMG-20230516-WA0004.jpg', 'Cabin', 2, 0, true, 3),
  ('Writer''s Room', 'The Garden', 465, 4.97, 38, 'https://storage.tally.so/78ab26bd-f87a-4d2e-9d58-9257e275e17c/20221227_124015-1-.jpg', 'Room', 2, 1, true, 1),
  ('Valleyview Room', 'The Garden', 515, 4.98, 64, 'https://storage.tally.so/065194a8-e63d-4328-aa76-0ebbc6cc59fe/20221227_123043-1-.jpg', 'Room', 2, 1, true, 1),
  ('The Hearth', 'The Garden', 630, 5.0, 29, 'https://storage.tally.so/43e64ccc-a48c-44c4-890b-635d3b5d8e21/image-4-1-.jpg', 'Suite', 2, 1, true, 1),
  ('A-Frame Pod', 'The Garden', 410, 4.9, 18, 'https://storage.tally.so/8ad5a3bd-26cb-4210-b33e-16a4e015d5f7/a-framephoto_2024-02-29_14-57-04.jpg', 'Pod', 2, 0, true, 1);

-- Grant permissions
grant usage on schema public to anon, authenticated;
grant select on accommodations to anon, authenticated;
grant select on availability to anon, authenticated;
grant select, insert on bookings to authenticated;
grant all on accommodations to authenticated;
grant all on availability to authenticated;
grant all on bookings to authenticated;
grant execute on function public.is_admin() to authenticated;