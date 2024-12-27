-- Drop existing policies
drop policy if exists "Users can view their own bookings" on bookings;
drop policy if exists "Users can insert their own bookings" on bookings;
drop policy if exists "Admins can view all bookings" on bookings;
drop policy if exists "Anyone can view accommodations" on accommodations;

-- Recreate policies with correct permissions
create policy "Users can view their own bookings"
  on bookings for select
  using (auth.uid() = user_id);

create policy "Users can insert their own bookings"
  on bookings for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own bookings"
  on bookings for update
  using (auth.uid() = user_id);

create policy "Admins can view all bookings"
  on bookings for all
  using (
    auth.uid() in (
      select id from auth.users
      where email = 'miles@meetluna.com'
    )
  );

create policy "Anyone can view accommodations"
  on accommodations for select
  using (true);

-- Grant necessary permissions
grant usage on schema public to authenticated;
grant all on bookings to authenticated;
grant select on accommodations to authenticated;

-- Enable RLS
alter table bookings enable row level security;
alter table accommodations enable row level security;