create trigger trg_questions
  after insert or update
  on questions
declare
  l_unanswered int;
begin
  --
  -- we use this to make sure there are never more than 10 unanswered questions in the queue
  --
  select count(*)
  into   l_unanswered
  from   asktomlite.questions
  where  answer is null;

  if l_unanswered > 10 then
    raise_application_error(-20000,'Could not accept questions. Too much on the queue');
  end if;
end;
/

