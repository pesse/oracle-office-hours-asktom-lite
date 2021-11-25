create or replace package body ut_asktom_app as

  gc_testname constant varchar2(100) := 'A3-LPC';

  procedure create_new_question as
    c_actual sys_refcursor;
    c_expect sys_refcursor;

  begin
    -- Act
    asktom_app.NEW_QUESTION(
        'Dummy@gmail.com'
        ,gc_testname
        ,'Y'
        ,'How do I test in the database'
      );

    -- Assert
    open c_actual for
      select email, name, notify, question from questions where name = gc_testname;
    open c_expect for
      select
         'dummy@gmail.com' as email
        ,gc_testname as name
        ,'Y' as notify
        ,to_clob('How do I test in the database') as question
      from dual;
    ut.expect(c_actual).to_equal(c_expect);
  end;

  procedure questions_for_customer as
    l_lines dbmsoutput_linesarray;
    l_lines_expect dbmsoutput_linesarray :=
        dbmsoutput_linesarray('46        25.11.21  A3-LPC              ');
    l_numlines integer := 1000;
  begin
    -- Arrange
    asktom_app.NEW_QUESTION(
        'Dummy@gmail.com'
        ,gc_testname
        ,'Y'
        ,'How do I test in the database'
      );

    -- Act
    asktom_app.questions_for_customer('dummy@gmail.com');

    -- Assert
    dbms_output.get_lines(l_lines, l_numlines);
    ut.expect(l_numlines).to_equal(1);
    ut.expect(anydata.convertCollection(l_lines))
      .to_contain(anydata.convertCollection(l_lines_expect));
  end;

end;
/