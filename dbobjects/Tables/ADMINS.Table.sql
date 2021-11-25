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