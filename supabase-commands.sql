-- 1. Create availability table
create table if not exists availability (
  id uuid primary key default gen_random_uuid(),
  accommodation_id uuid references accommodations not null,
  start_date timestamp with time zone not null,
  end_date timestamp with time zone not null,
  status text not null check (status in ('AVAILABLE', 'BOOKED', 'HOLD')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Create indexes
create index if not exists idx_availability_accommodation_dates 
on availability (accommodation_id, start_date, end_date);

-- 3. Enable RLS
alter table availability enable row level security;

-- 4. Create availability policies
create policy "Admins can manage availability"
  on availability for all
  using (
    auth.uid() in (
      select id from auth.users
      where email = 'miles@meetluna.com'
    )
  );

-- 5. Update accommodations policies
drop policy if exists "Anyone can view accommodations" on accommodations;
drop policy if exists "Admins can manage accommodations" on accommodations;

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

-- 6. Grant permissions
grant usage on schema public to authenticated;
grant all on availability to authenticated;
grant select, update on accommodations to authenticated;