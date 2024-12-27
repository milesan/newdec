-- Add foreign key constraint for bookings.user_id
alter table bookings
drop constraint if exists bookings_user_id_fkey,
add constraint bookings_user_id_fkey
  foreign key (user_id)
  references profiles(id)
  on delete cascade;