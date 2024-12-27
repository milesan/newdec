-- Drop existing table and policies
drop table if exists availability cascade;

-- Create extension if not exists
create extension if not exists btree_gist;

-- Create availability table with correct schema
create table availability (
  id uuid primary key default gen_random_uuid(),
  accommodation_id uuid references accommodations(id) on delete cascade,
  start_date timestamp with time zone not null,
  end_date timestamp with time zone not null,
  status text not null check (status in ('AVAILABLE', 'HOLD', 'BOOKED')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  
  -- Add a constraint to prevent overlapping dates for the same accommodation
  constraint no_date_overlap exclude using gist (
    accommodation_id with =,
    tstzrange(start_date, end_date, '[)') with &&
  )
);

-- Create indexes for faster queries
create index idx_availability_dates on availability(accommodation_id, start_date, end_date);
create index idx_availability_status on availability(status);

-- Enable RLS
alter table availability enable row level security;

-- Create policy for admin access
create policy "Admin full access to availability"
  on availability for all
  using (
    exists (
      select 1 from auth.users
      where id = auth.uid()
      and email = 'andre@thegarden.pt'
    )
  );

-- Grant permissions
grant all on availability to authenticated;