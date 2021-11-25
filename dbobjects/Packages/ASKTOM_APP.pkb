create or replace package body asktom_app is

procedure new_admin(p_name varchar2, p_email varchar2) is
begin
  insert into admins (admin_name, admin_email)
  values (p_name, p_email);
  commit;
end;

procedure modify_admin(p_admin_id number, p_name varchar2, p_email varchar2) is
begin
  update admins
  set    admin_name = p_name,
         admin_email = p_email
  where  admin_id = p_admin_id;
end;


procedure delete_admin(p_id number) is
begin
  delete from admins
  where admin_id = p_id;
  commit;
end;

procedure new_question(
      p_email       varchar2,
      p_name        varchar2,
      p_notify      varchar2,
      p_question    clob) is
begin
  insert into questions (email, name, notify,question)
  values (p_email,p_name,p_notify,p_question);
end;

procedure new_feedback(
        p_question_id    number,
        p_email          varchar2,
        p_name           varchar2,
        p_admin_id       number default null,
        p_feedback       clob) is
begin
  insert into feedback (question_id, email, name, feedback, admin_id)
  values (p_question_id, p_name, p_email, p_feedback,p_admin_id);
  commit;
end;

procedure question_page(p_page_size int, p_offset int) is
begin
  for i in (
    select *
    from (
      select rownum r, x.*
      from (
        select * from questions
        order by question_id desc
      ) x
      where rownum < p_offset+p_page_size
    )
    where r > p_offset  )
  loop
    dbms_output.put_line(
      rpad(i.question_id,10)||
      rpad(i.question_date,10)||
      rpad(i.name,20)||
      i.title);
  end loop;
end;

procedure questions_for_customer(p_email varchar2) is
begin
  for i in (
        select * from questions
        where  email = p_email
        order by question_id desc
        )
  loop
    dbms_output.put_line(
      rpad(i.question_id,10)||
      rpad(i.question_date,10)||
      rpad(i.name,20)||
      i.title);
  end loop;
end;

procedure question_details(p_question_id number) is
  l_exists   int;
  l_question questions%rowtype;
begin
  select count(*)
  into   l_exists
  from   questions
  where  question_id = p_question_id;

  if l_exists = 0 then
    raise_application_error(-20000,'Question does not exist');
  end if;

  select *
  into   l_question
  from   questions
  where  question_id = p_question_id;

  dbms_output.put_line('ID: '||l_question.question_id);
  dbms_output.put_line('DATE: '||l_question.question_date);
  dbms_output.put_line('EMAIL: '||l_question.email);
  dbms_output.put_line('NAME: '||l_question.name);
  dbms_output.put_line('TITLE: '||l_question.title);
  dbms_output.put_line('QUESTION: '||l_question.question);

  select count(*)
  into   l_exists
  from   feedback
  where  question_id = p_question_id;

  if l_exists > 0 then
    for feed in (
      select * from feedback
      where  question_id = p_question_id )
    loop
      dbms_output.put_line('ID: '||feed.feedback_id);
      dbms_output.put_line('DATE: '||feed.feedback_date);
      dbms_output.put_line('EMAIL: '||feed.email);
      dbms_output.put_line('NAME: '||feed.name);
      dbms_output.put_line('COMMENT: '||feed.feedback);
    end loop;
  end if;
end;

procedure answer_question(p_question_id number, p_admin_id number, p_answer clob) is
  l_exists   int;
begin
  select count(*)
  into   l_exists
  from   questions
  where  question_id = p_question_id;

  if l_exists = 0 then
    raise_application_error(-20000,'Question does not exist');
  end if;

  update questions
  set    admin_id    = p_admin_id,
         answer      = p_answer
  where  question_id = p_question_id;
  commit;
end;


end;
/

