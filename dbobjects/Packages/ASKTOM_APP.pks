create or replace package asktom_app is
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

