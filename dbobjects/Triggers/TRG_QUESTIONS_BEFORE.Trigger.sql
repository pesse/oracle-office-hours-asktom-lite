create or replace
trigger asktomlite.trg_questions_before
before insert or update
on asktomlite.questions
for each row
begin
  --
  -- all emails must be lowercase for consistency
  --
  :new.email := lower(:new.email);
end;
/