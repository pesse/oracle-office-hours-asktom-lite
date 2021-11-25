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


create index asktomlite.questions_ix1 on asktomlite.questions ( email );