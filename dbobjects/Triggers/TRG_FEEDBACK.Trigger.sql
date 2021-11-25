create trigger trg_feedback
  before insert or update
  on feedback
  for each row
begin
  --
  -- all emails must be lowercase for consistency
  --
  :new.email := lower(:new.email);
end;
/

