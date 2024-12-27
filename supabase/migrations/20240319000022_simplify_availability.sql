-- Drop the existing availability table
drop table if exists availability;

-- Create a simpler availability table with a single date field
create table availability (
  id uuid primary key default gen_random_uuid(),
  accommodation_id uuid references accommodations(id) on delete cascade,
  date timestamp with time zone not null,
  status text not null check (status in ('AVAILABLE', 'HOLD', 'BOOKED')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  
  -- Add a unique constraint to prevent duplicate entries
  unique(accommodation_id, date)
);

-- Create index for faster queries
create index idx_availability_lookup on availability(accommodation_id, date);

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