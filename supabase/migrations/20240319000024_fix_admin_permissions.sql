-- Drop existing policies and functions
drop policy if exists "Admin full access to availability" on availability;
drop policy if exists "Admin full access to accommodations" on accommodations;
drop function if exists public.is_admin();

-- Create a more secure admin check function
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1 
    from auth.users 
    where id = auth.uid() 
    and email = 'andre@thegarden.pt'
  );
end;
$$ language plpgsql security definer;

-- Enable RLS on all tables
alter table accommodations enable row level security;
alter table availability enable row level security;

-- Create policies for accommodations
create policy "Public read access to accommodations"
  on accommodations for select
  using (true);

create policy "Admin full access to accommodations"
  on accommodations for all
  using (public.is_admin());

-- Create policies for availability
create policy "Public read access to availability"
  on availability for select
  using (true);

create policy "Admin full access to availability"
  on availability for all
  using (public.is_admin());

-- Grant necessary permissions
grant usage on schema public to authenticated;
grant select on accommodations to authenticated;
grant select on availability to authenticated;
grant all on accommodations to authenticated;
grant all on availability to authenticated;
grant execute on function public.is_admin() to authenticated;