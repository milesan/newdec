-- Update admin check function to use the new email
create or replace function is_admin(user_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 
    from auth.users 
    where id = user_id 
    and email = 'andre@thegarden.pt'
  );
end;
$$ language plpgsql security definer;