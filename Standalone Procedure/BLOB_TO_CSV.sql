--------------------------------------------------------
--  DDL for Function BLOB_TO_CSV
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ATOM"."BLOB_TO_CSV" (p_csv_blob in blob,
                      p_separator in varchar2 := atl_app_config.c_default_separator,
                      p_skip_rows in number := 0) return exp_ship_csv_tab pipelined
as
  p_csv_clob clob;
  l_line_separator         varchar2(2) := chr(13) || chr(10);
  l_last                   pls_integer;
  l_current                pls_integer;
  l_line                   varchar2(32000);
  l_line_number            pls_integer := 0;
  l_from_line              pls_integer := p_skip_rows + 1;
  l_line_array             t_str_array;
  --l_row                    t_csv_line := t_csv_line (null, null,  -- line number, line raw
  --                                                   null, null, null, null, null, null, null, null, null);  -- lines 11-20
  l_row                    exp_ship_csv_line := exp_ship_csv_line (null, null,  -- line number, line raw
                                                     null, null, null, null, null, null, null, null, null,null,
                                                     null, null, null, null, null, null, null, null, null,null,
                                                     null, null, null, null, null, null, null, null, null,null,
                                                     null, null, null, null, null, null, null, null);

begin

  
  p_csv_clob := atl_util_pkg.blob_to_clob(p_csv_blob);
  
  -- If the file has a DOS newline (cr+lf), use that
  -- If the file does not have a DOS newline, use a Unix newline (lf)
  if (nvl(dbms_lob.instr(p_csv_clob, l_line_separator, 1, 1),0) = 0) then
    l_line_separator := chr(10);
  end if;

  l_last := 1;

  loop
  
    l_current := dbms_lob.instr (p_csv_clob || l_line_separator, l_line_separator, l_last, 1);
    exit when (nvl(l_current,0) = 0);
    
    l_line_number := l_line_number + 1;
    
    if l_from_line <= l_line_number then
    
      l_line := dbms_lob.substr(p_csv_clob || l_line_separator, l_current - l_last + 1, l_last);
      --l_line := replace(l_line, l_line_separator, '');
      l_line := replace(l_line, chr(10), '');
      l_line := replace(l_line, chr(13), '');

      l_line_array := atl_util_pkg.csv_to_array (l_line, p_separator);

      l_row.line_number := l_line_number;
      l_row.line_raw := substr(l_line,1,4000);
      l_row.c001:= atl_util_pkg.get_array_value(l_line_array,1);
      l_row.c002:= atl_util_pkg.get_array_value(l_line_array,2);
      l_row.c003:= atl_util_pkg.get_array_value(l_line_array,3);
      l_row.c004:= atl_util_pkg.get_array_value(l_line_array,4);
      l_row.c005:= atl_util_pkg.get_array_value(l_line_array,5);
      l_row.c006:= atl_util_pkg.get_array_value(l_line_array,6);
      l_row.c007:= atl_util_pkg.get_array_value(l_line_array,7);
      l_row.c008:= atl_util_pkg.get_array_value(l_line_array,8);
      l_row.c009:= atl_util_pkg.get_array_value(l_line_array,9);
      l_row.c010:= atl_util_pkg.get_array_value(l_line_array,10);
      l_row.c011:= atl_util_pkg.get_array_value(l_line_array,11);
      l_row.c012:= atl_util_pkg.get_array_value(l_line_array,12);
      l_row.c013:= atl_util_pkg.get_array_value(l_line_array,13);
      l_row.c014:= atl_util_pkg.get_array_value(l_line_array,14);
      l_row.c015:= atl_util_pkg.get_array_value(l_line_array,15);
      l_row.c016:= atl_util_pkg.get_array_value(l_line_array,16);
      l_row.c017:= atl_util_pkg.get_array_value(l_line_array,17);
      l_row.c018:= atl_util_pkg.get_array_value(l_line_array,18);
      l_row.c019:= atl_util_pkg.get_array_value(l_line_array,19);
      l_row.c020:= atl_util_pkg.get_array_value(l_line_array,20);
      l_row.c021:= atl_util_pkg.get_array_value(l_line_array,21);
      l_row.c022:= atl_util_pkg.get_array_value(l_line_array,22);
      l_row.c023:= atl_util_pkg.get_array_value(l_line_array,23);
      l_row.c024:= atl_util_pkg.get_array_value(l_line_array,24);
      l_row.c025:= atl_util_pkg.get_array_value(l_line_array,25);
      l_row.c026:= atl_util_pkg.get_array_value(l_line_array,26);
      l_row.c027:= atl_util_pkg.get_array_value(l_line_array,27);
      l_row.c028:= atl_util_pkg.get_array_value(l_line_array,28);
      l_row.c029:= atl_util_pkg.get_array_value(l_line_array,29);
      l_row.c030:= atl_util_pkg.get_array_value(l_line_array,30);
      l_row.c031:= atl_util_pkg.get_array_value(l_line_array,31);
      l_row.c032:= atl_util_pkg.get_array_value(l_line_array,32);
      l_row.c033:= atl_util_pkg.get_array_value(l_line_array,33);
      l_row.c034:= atl_util_pkg.get_array_value(l_line_array,34);
      l_row.c035:= atl_util_pkg.get_array_value(l_line_array,35);
      l_row.c036:= atl_util_pkg.get_array_value(l_line_array,36);
      l_row.c037:= atl_util_pkg.get_array_value(l_line_array,37);
      l_row.c038:= atl_util_pkg.get_array_value(l_line_array,38);

      
      pipe row (l_row);
      
    end if;

    l_last := l_current + length (l_line_separator);

  end loop;

  return;
 
end blob_to_csv;

/
