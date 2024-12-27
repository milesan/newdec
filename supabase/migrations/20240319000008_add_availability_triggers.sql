-- Add trigger to prevent overlapping availability periods
create or replace function check_availability_overlap()
returns trigger as $$
begin
  if exists (
    select 1 from availability
    where accommodation_id = new.accommodation_id
    and id != coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
    and (
      (new.start_date, new.end_date) overlaps (start_date, end_date)
    )
  ) then
    raise exception 'Availability periods cannot overlap for the same accommodation';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_availability_overlap_trigger
  before insert or update on availability
  for each row
  execute function check_availability_overlap();

-- Add trigger to automatically update updated_at timestamp
create or replace function update_availability_timestamp()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_availability_timestamp_trigger
  before update on availability
  for each row
  execute function update_availability_timestamp();