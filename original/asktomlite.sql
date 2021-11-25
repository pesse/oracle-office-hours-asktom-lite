-----------------------------------------------------------------
--
-- USER CREATION
--
clear screen
drop user asktomlite cascade;

create user asktomlite identified by asktomlite;

grant connect, resource, unlimited tablespace to asktomlite;

drop table asktomlite.questions cascade constraints purge;
drop table asktomlite.feedback  cascade constraints purge;
drop table asktomlite.admins    cascade constraints purge;

-----------------------------------------------------------------
-- ADMINS
--
create table asktomlite.admins (
  admin_id    number generated as identity,
  admin_name  varchar2(100),
  admin_email varchar2(100),
  modified    date default sysdate
);

comment on table asktomlite.admins is 'List of authorised adminstrators that can answer questions from the public';
comment on column asktomlite.admins.admin_id is 'Auto-generated surrogate key that flows into questions and feedback tables';
comment on column asktomlite.admins.admin_name is 'Display name for the administrator';
comment on column asktomlite.admins.admin_email is 'Admin contact email address, forced to lowercase by trigger';
comment on column asktomlite.admins.modified is 'Every time we modify an administrators details, we will update this to reflect the last change';

alter table   asktomlite.admins add constraint admins_pk primary key ( admin_id );
alter table   asktomlite.admins add constraint admins_chk check ( admin_email like '%@%' );

create or replace
trigger asktomlite.trg_admins 
before insert or update 
on asktomlite.admins
for each row
begin
  --
  -- all emails must be lowercase for consistency
  --
  :new.admin_email := lower(:new.admin_email);
end;
/

--
-- sample data
--
insert into asktomlite.admins (admin_name, admin_email) values ('Connor','connor@oracle.com');
insert into asktomlite.admins (admin_name, admin_email) values ('Chris','chris@oracle.com');
insert into asktomlite.admins (admin_name, admin_email) values ('Tom','tom@oracle.com');
commit;

--
-- potential bugs/issues:
--  char vs byte semantics
--  admin_name  is nullable
--  admin_email is nullable
--  modified    is nullable
--  modified not changed on update
--  admin_email not fully verified as legit email address (prob needs a regex)
--  admin_name should be unique
--  admin_email should be unique

-----------------------------------------------------------------
-- QUESTIONS
--

create table asktomlite.questions (
  question_id number generated as identity,
  email       varchar2(255) not null,
  name        varchar2(60)  not null,
  notify      varchar2(1),
  title       varchar2(60),
  question    clob,
  answer      clob,
  admin_id    number,
  question_date  date default sysdate,
  answer_date    date);

comment on table asktomlite.questions is 'Questions that come in from the public asking for our assistance';
comment on column asktomlite.questions.question_id is 'Auto-generated surrogate key that flows into questions and feedback tables';
comment on column asktomlite.questions.email is 'Email address for customer who raised the question so we can contact them';
comment on column asktomlite.questions.name is 'Customers nominated name for display';
comment on column asktomlite.questions.notify is 'Y or N to indicate whether customer wants to be emailed when we answer the question';
comment on column asktomlite.questions.title is 'Customer''s brief subject line for the question';
comment on column asktomlite.questions.question is 'The full text of the question';
comment on column asktomlite.questions.answer is 'Initially null, populated with our answer when we respond to the question';
comment on column asktomlite.questions.admin_id is 'The ID of the admin that has answered this question';
comment on column asktomlite.questions.answer_date is 'The date/time when we answered the question';


alter table   asktomlite.questions add constraint questions_pk primary key ( question_id );
alter table   asktomlite.questions add constraint questions_chk check (email like '%@%' );
alter table   asktomlite.questions add constraint questions_fk foreign key (admin_id) references asktomlite.admins ( admin_id );

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

create or replace
trigger asktomlite.trg_questions 
after insert or update 
on asktomlite.questions
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


create index asktomlite.questions_ix1 on asktomlite.questions ( email );

--
-- potential bugs/issues:
--  notify is nullable and not restricted to 'Y' or 'N'
--  title is nullable
--  question is nullable
--  question_date is nullable
--  email not fully verified as legit email address
--  question count does not handle multiple sessions asking questions


create table asktomlite.feedback (
  feedback_id    number generated as identity,
  question_id    number,
  email          varchar2(255) not null,
  name           varchar2(60)  not null,
  admin_id       number,
  feedback       clob,
  feedback_date  date default sysdate);

comment on table asktomlite.feedback is 'Feedback to answered questions, either from customers (email,name) or our responses to their feedback(admin_id)';
comment on column asktomlite.feedback.feedback_id is 'Auto-generated surrogate key for each piece of feedback';
comment on column asktomlite.feedback.question_id is 'The original question that motivated this feedback/comment';
comment on column asktomlite.feedback.email is 'Email address for customer who raised the feedback so we can contact them';
comment on column asktomlite.feedback.name is 'Customers nominated name for display';
comment on column asktomlite.feedback.admin_id is 'Null for customer feedback, or the ID of the admin who added some feedback (typically as a response to customer feedback)';
comment on column asktomlite.feedback.feedback is 'The text of the customer/admin feedback';
comment on column asktomlite.feedback.feedback_date is 'The date/time of the feedback - uses for sorting the feedback chronologically';


alter table   asktomlite.feedback add constraint feedback_pk primary key ( feedback_id );
alter table   asktomlite.feedback add constraint feedback_chk check (email like '%@%' );
alter table   asktomlite.feedback add constraint feedback_fk1 foreign key (admin_id) references asktomlite.admins ( admin_id );
alter table   asktomlite.feedback add constraint feedback_fk2 foreign key (question_id) references asktomlite.questions ( question_id );

create index asktomlite.feedback_ix1 on asktomlite.feedback ( email );

create or replace
trigger asktomlite.trg_feedback 
before insert or update 
on asktomlite.feedback
for each row
begin
  --
  -- all emails must be lowercase for consistency
  --
  :new.email := lower(:new.email);
end;
/

--
-- potential bugs/issues:
--  question_id nullable
--  email/name should be mutually exclusive to admin_id
--  email not fully verified as legit email address
--  feedback must be ordered by date/time so feedback_date probably should be a timestamp (and maybe even a UTC one)



-----------------------------------------------------------------
--
-- SOURCE CODE
--


create or replace
package asktomlite.asktom_app is
  procedure new_admin(p_name varchar2, p_email varchar2);

  procedure modify_admin(p_admin_id number, p_name varchar2, p_email varchar2);

  procedure delete_admin(p_id number);

  procedure new_question(
        p_email       varchar2,
        p_name        varchar2,
        p_notify      varchar2,
        p_question    clob);

  procedure new_feedback(
        p_question_id    number,
        p_email          varchar2,
        p_name           varchar2,
        p_admin_id       number default null,
        p_feedback       clob);

  procedure question_page(p_page_size int, p_offset int);

  procedure questions_for_customer(p_email varchar2);

  procedure question_details(p_question_id number);
  
  procedure answer_question(p_question_id number, p_admin_id number, p_answer clob);

end;
/

create or replace
package body asktomlite.asktom_app is

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
  commit;
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
sho err

--
-- potential bugs/issues:
--  modify_admin does not commit (which in itself is truly a bug) but since all the others APIs *do* comment, its an inconsistency
--  also does not correctly set modified (which could be in this routine or via trigger)
--  question page is not using page size and offset correctly
--  question page sorts by id, when probably should sort by question_date
--  question page truncates fields 
--  question_for_customer does not use lower for email
    -- gets wrong results
    -- when corrected, will not use an index, thus need a function based index on email
--  new_question, there is no way to set the title/subject of a question
--  new_feedback has email/name incorrectly switched
--  new_feedback should not be allowed if the question has not been answered yet
--  new_feedback should probably be two routines - one for admin feedback and one for customer feedback
--  question_details, does not show the answer
--  question_details, the feedback is not ordered correctly
--  question_details, the feedback does not take into account admin feedback
--  all of the existence checks can be factored out trivially
--  answer_question, we forget to set answer_date
--  delete_admin really does not make sense, because the moment they have answered a question, you don't want to delete them.
--  Should probably allow delete if no questions answered, otherwise as a logically deleted flag on the admins table
    

-----------------------------------------------------------------
--
-- SAMPLE USAGE
--

--
-- customer asks a question
--
begin
  asktomlite.asktom_app.new_question(
      p_email       =>'johndoe@anon.com',
      p_name        =>'John',
      p_notify      =>'Y',
      p_question    =>'Hi. How do I drop a user in Oracle that is still connected?');
end;
/


--
-- admin answers it
--
begin
  asktomlite.asktom_app.answer_question(
      p_question_id =>1, 
      p_admin_id =>1,
      p_answer=>'Lock the account, then kill any sessions and then run drop user command');
end;
/

set serverout on
--
-- this will not work (due to the offset bug), but replace '1' with '0' to see it working
--
exec asktomlite.asktom_app.question_page(10,1);

--
-- customer feedback (will fail due to bug) but swap email/name to make it work
--
begin
  asktomlite.asktom_app.new_feedback(
        p_question_id    =>1,
        p_email          =>'janedoe@anon.com',
        p_name           =>'Jane',
        p_feedback       =>'Thanks this is very useful for me');
end;
/

--begin
--  asktomlite.asktom_app.new_feedback(
--        p_question_id    =>1,
--        p_name           =>'janedoe@anon.com',
--        p_email           =>'Jane',
--        p_feedback       =>'Thanks this is very useful for me');
--end;
--/



begin
  asktomlite.asktom_app.question_details(1);
end;
/

  