create or replace package ut_asktom_app as
  -- %suite(AskTom Lite)

  -- %test
  procedure create_new_question;

  -- %test
  procedure questions_for_customer;
end;
/