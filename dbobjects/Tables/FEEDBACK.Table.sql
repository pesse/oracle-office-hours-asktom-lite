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