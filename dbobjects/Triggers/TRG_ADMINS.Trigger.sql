create trigger trg_admins
  before insert or update
  on admins
  for each row
begin
  --
  -- all emails must be lowercase for consistency
  --
  :new.admin_email := lower(:new.admin_email);
end;
/

