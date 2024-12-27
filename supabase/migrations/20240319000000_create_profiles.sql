-- Create a profiles table that automatically keeps user emails
create table profiles (
  id uuid references auth.users on delete cascade,
  email text,
  primary key (id)
);

-- Create a trigger to automatically create a profile and copy the email when a user signs up
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();