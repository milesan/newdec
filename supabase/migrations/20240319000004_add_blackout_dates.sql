-- Create blackout_dates table
create table blackout_dates (
  id uuid primary key default gen_random_uuid(),
  accommodation_id uuid references accommodations not null,
  start_date timestamp with time zone not null,
  end_date timestamp with time zone not null,
  reason text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table blackout_dates enable row level security;

-- Create policies for blackout_dates
create policy "Admins can manage blackout dates"
  on blackout_dates for all
  using (
    auth.uid() in (
      select id from auth.users
      where email = 'miles@meetluna.com'
    )
  );

-- Grant necessary permissions
grant all on blackout_dates to authenticated;