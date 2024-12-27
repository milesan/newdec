-- Create availability table
create table availability (
  id uuid primary key default gen_random_uuid(),
  accommodation_id uuid references accommodations not null,
  start_date timestamp with time zone not null,
  end_date timestamp with time zone not null,
  status text not null check (status in ('AVAILABLE', 'BOOKED', 'HOLD')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table availability enable row level security;

-- Create policies for availability
create policy "Admins can manage availability"
  on availability for all
  using (
    auth.uid() in (
      select id from auth.users
      where email = 'miles@meetluna.com'
    )
  );

-- Grant necessary permissions
grant all on availability to authenticated;

-- Add indexes for better performance
create index availability_accommodation_id_idx on availability(accommodation_id);
create index availability_dates_idx on availability(start_date, end_date);