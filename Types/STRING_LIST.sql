--------------------------------------------------------
--  DDL for Function STRING_LIST
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ATOM"."STRING_LIST" (p_in_list  IN  VARCHAR2)
  RETURN string_tab PIPELINED
AS
  l_text  VARCHAR2(32767) := p_in_list || ',';
  l_idx   NUMBER;
BEGIN
  LOOP
    l_idx := INSTR(l_text, ',');
    EXIT WHEN NVL(l_idx, 0) = 0;
    PIPE ROW (TRIM(SUBSTR(l_text, 1, l_idx - 1)));
    l_text := SUBSTR(l_text, l_idx + 1);
  END LOOP;

  RETURN;
END;

/
