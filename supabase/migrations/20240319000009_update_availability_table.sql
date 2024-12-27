-- Drop existing triggers if they exist
drop trigger if exists check_availability_overlap_trigger on availability;
drop function if exists check_availability_overlap();
drop trigger if exists update_availability_timestamp_trigger on availability;
drop function if exists update_availability_timestamp();

-- Recreate availability table with updated structure
drop table if exists availability;
create table availability (
  id uuid primary key default gen_random_uuid(),
  accommodation_id uuid references accommodations not null,
  start_date timestamp with time zone not null,
  end_date timestamp with time zone not null,
  status text not null check (status in ('AVAILABLE', 'BOOKED', 'HOLD')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create indexes for better performance
create index idx_availability_accommodation_dates on availability (accommodation_id, start_date, end_date);

-- Enable RLS
alter table availability enable row level security;

-- Create policies
create policy "Admins can manage availability"
  on availability for all
  using (
    auth.uid() in (
      select id from auth.users
      where email = 'miles@meetluna.com'
    )
  );

-- Grant permissions
grant all on availability to authenticated;