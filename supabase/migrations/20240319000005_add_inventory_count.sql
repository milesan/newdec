-- Add inventory_count column to accommodations
alter table accommodations 
add column inventory_count integer not null default 1;

-- Update inventory counts for fungible accommodations
update accommodations
set inventory_count = 
  case 
    when type = 'Bell Tent' then 3
    when type = 'Tipi' then 2
    when type = 'Pod' then 2
    else 1
  end;