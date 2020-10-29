--------------------------------------------------------
--  DDL for Package Body ATL_UTIL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_UTIL_PKG" AS
function csv_to_array (p_csv_line in varchar2,
                       p_separator in varchar2 := atl_app_config.c_default_separator) return t_str_array
as
  l_returnvalue      t_str_array     := t_str_array();
  l_length           pls_integer     := length(p_csv_line);
  l_idx              binary_integer  := 1;
  l_quoted           boolean         := false;  
  l_quote  constant  varchar2(1)     := '"';
  l_start            boolean := true;
  l_current          varchar2(1 char);
  l_next             varchar2(1 char);
  l_position         pls_integer := 1;
  l_current_column   varchar2(32767);
  
  --Set the start flag, save our column value
  procedure save_column is
  begin
    l_start := true;
    l_returnvalue.extend;        
    l_returnvalue(l_idx) := l_current_column;
    l_idx := l_idx + 1;            
    l_current_column := null;
  end save_column;
  
  --Append the value of l_current to l_current_column
  procedure append_current is
  begin
    l_current_column := l_current_column || l_current;
  end append_current;
begin

  /*
 
  Purpose:      convert CSV line to array of values
 
  Remarks:      based on code from http://www.experts-exchange.com/Database/Oracle/PL_SQL/Q_23106446.html
 
 
  */

  while l_position <= l_length loop
  
    --Set our variables with the current and next characters
    l_current := substr(p_csv_line, l_position, 1);
    l_next := substr(p_csv_line, l_position + 1, 1);    
    
    if l_start then
      l_start := false;
      l_current_column := null;
    
      --Check for leading quote and set our flag
      l_quoted := l_current = l_quote;
      
      --We skip a leading quote character
      if l_quoted then goto loop_again; end if;
    end if;

    --Check to see if we are inside of a quote    
    if l_quoted then      

      --The current character is a quote - is it the end of our quote or does
      --it represent an escaped quote?
      if l_current = l_quote then

        --If the next character is a quote, this is an escaped quote.
        if l_next = l_quote then
        
          --Append the literal quote to our column
          append_current;
          
          --Advance the pointer to ignore the duplicated (escaped) quote
          l_position := l_position + 1;
          
        --If the next character is a separator, current is the end quote
        elsif l_next = p_separator then
          
          --Get out of the quote and loop again - we will hit the separator next loop
          l_quoted := false;
          goto loop_again;
        
        --Ending quote, no more columns
        elsif l_next is null then

          --Save our current value, and iterate (end loop)
          save_column;
          goto loop_again;          
          
        --Next character is not a quote
        else
          append_current;
        end if;
      else
      
        --The current character is not a quote - append it to our column value
        append_current;     
      end if;
      
    -- Not quoted
    else
    
      --Check if the current value is a separator, save or append as appropriate
      if l_current = p_separator then
        save_column;
      else
        append_current;
      end if;
    end if;
    
    --Check to see if we've used all our characters
    if l_next is null then
      save_column;
    end if;

    --The continue statement was not added to PL/SQL until 11g. Use GOTO in 9i.
    <<loop_again>> l_position := l_position + 1;
  end loop ;
  
  return l_returnvalue;
end csv_to_array;
 
 
function array_to_csv (p_values in t_str_array,
                       p_separator in varchar2 := atl_app_config.c_default_separator) return varchar2
as
  l_value       varchar2(32767);
  l_returnvalue varchar2(32767);
begin
 
  /*
 
  Purpose:      convert array of values to CSV
 
  */
  
  for i in p_values.first .. p_values.last loop
  
    --Double quotes must be escaped
    l_value := replace(p_values(i), '"', '""');
    
    --Values containing the separator, a double quote, or a new line must be quoted.
    if instr(l_value, p_separator) > 0 or instr(l_value, '"') > 0 or instr(l_value, chr(10)) > 0 then
      l_value := '"' || l_value || '"';
    end if;
    
    --Append our value to our return value
    if i = p_values.first then
      l_returnvalue := l_value;
    else
      l_returnvalue := l_returnvalue || p_separator || l_value;
    end if;
  end loop;
 
  return l_returnvalue;
 
end array_to_csv;


function get_array_value (p_values in t_str_array,
                          p_position in number,
                          p_column_name in varchar2 := null) return varchar2
as
  l_returnvalue varchar2(4000);
begin
 
  /*
 
  Purpose:      get value from array by position
 
  Remarks:     
 
  */
  
  if p_values.count >= p_position then
    l_returnvalue := p_values(p_position);
  else
    if p_column_name is not null then
      raise_application_error (-20000, 'Column number ' || p_position || ' does not exist. Expected column: ' || p_column_name);
    else
      l_returnvalue := null;
    end if;
  end if;
 
  return l_returnvalue;
 
end get_array_value;


function clob_to_csv (p_csv_clob in clob,
                      p_separator in varchar2 := atl_app_config.c_default_separator,
                      p_skip_rows in number := 0) return t_csv_tab pipelined
as
  l_line_separator         varchar2(2) := chr(13) || chr(10);
  l_last                   pls_integer;
  l_current                pls_integer;
  l_line                   varchar2(32000);
  l_line_number            pls_integer := 0;
  l_from_line              pls_integer := p_skip_rows + 1;
  l_line_array             t_str_array;
  l_row                    t_csv_line := t_csv_line (null, null,  -- line number, line raw
                                                     null, null, null, null, null, null, null, null, null);  -- lines 11-20
begin
 
  /*
 
  Purpose:      convert clob to CSV
 
  Remarks:      based on code from http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:1352202934074
                              and  http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:744825627183
 
  */
  
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

      l_line_array := csv_to_array (l_line, p_separator);

      l_row.line_number := l_line_number;
      l_row.line_raw := substr(l_line,1,4000);
      l_row.c001 := get_array_value (l_line_array, 1);
      l_row.c002 := get_array_value (l_line_array, 2);
      l_row.c003 := get_array_value (l_line_array, 3);
      l_row.c004 := get_array_value (l_line_array, 4);
      l_row.c005 := get_array_value (l_line_array, 5);
      l_row.c006 := get_array_value (l_line_array, 6);
      l_row.c007 := get_array_value (l_line_array, 7);
      l_row.c008 := get_array_value (l_line_array, 8);
      l_row.c009 := get_array_value (l_line_array, 9);
      
      pipe row (l_row);
      
    end if;

    l_last := l_current + length (l_line_separator);

  end loop;

  return;
 
end clob_to_csv;

function clob_to_csv (p_csv_clob in clob,
                      p_skip_rows in number := 0) return exp_ship_csv_tab pipelined
as
  l_line_separator         varchar2(2) := chr(13) || chr(10);
  l_last                   pls_integer;
  l_current                pls_integer;
  l_line                   varchar2(32000);
  l_line_number            pls_integer := 0;
  l_from_line              pls_integer := p_skip_rows + 1;
  l_line_array             t_str_array;
  l_row                    exp_ship_csv_line := exp_ship_csv_line (null, null,  -- line number, line raw
                                                     null, null, null, null, null, null, null, null, null,null,
                                                     null, null, null, null, null, null, null, null, null,null,
                                                     null, null, null, null, null, null, null, null, null,null,
                                                     null, null, null, null, null, null, null, null);
begin
 
  /*
 
  Purpose:      convert clob to CSV
 
  Remarks:      based on code from http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:1352202934074
                              and  http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:744825627183
 
  */
  
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

      l_line_array := csv_to_array (l_line, atl_app_config.c_default_separator);

      l_row.line_number := l_line_number;
      l_row.line_raw := substr(l_line,1,4000);
      l_row.c001 := get_array_value (l_line_array, 1);
      l_row.c002 := get_array_value (l_line_array, 2);
      l_row.c003 := get_array_value (l_line_array, 3);
      l_row.c004 := get_array_value (l_line_array, 4);
      l_row.c005 := get_array_value (l_line_array, 5);
      l_row.c006 := get_array_value (l_line_array, 6);
      l_row.c007 := get_array_value (l_line_array, 7);
      l_row.c008 := get_array_value (l_line_array, 8);
      l_row.c009 := get_array_value (l_line_array, 9);
      l_row.c010:= get_array_value(l_line_array,10);
      l_row.c011:= get_array_value(l_line_array,11);
      l_row.c012:= get_array_value(l_line_array,12);
      l_row.c013:= get_array_value(l_line_array,13);
      l_row.c014:= get_array_value(l_line_array,14);
      l_row.c015:= get_array_value(l_line_array,15);
      l_row.c016:= get_array_value(l_line_array,16);
      l_row.c017:= get_array_value(l_line_array,17);
      l_row.c018:= get_array_value(l_line_array,18);
      l_row.c019:= get_array_value(l_line_array,19);
      l_row.c020:= get_array_value(l_line_array,20);
      l_row.c021:= get_array_value(l_line_array,21);
      l_row.c022:= get_array_value(l_line_array,22);
      l_row.c023:= get_array_value(l_line_array,23);
      l_row.c024:= get_array_value(l_line_array,24);
      l_row.c025:= get_array_value(l_line_array,25);
      l_row.c026:= get_array_value(l_line_array,26);
      l_row.c027:= get_array_value(l_line_array,27);
      l_row.c028:= get_array_value(l_line_array,28);
      l_row.c029:= get_array_value(l_line_array,29);
      l_row.c030:= get_array_value(l_line_array,30);
      l_row.c031:= get_array_value(l_line_array,31);
      l_row.c032:= get_array_value(l_line_array,32);
      l_row.c033:= get_array_value(l_line_array,33);
      l_row.c034:= get_array_value(l_line_array,34);
      l_row.c035:= get_array_value(l_line_array,35);
      l_row.c036:= get_array_value(l_line_array,36);
      l_row.c037:= get_array_value(l_line_array,37);
      l_row.c038:= get_array_value(l_line_array,38);

      
      pipe row (l_row);
      
    end if;

    l_last := l_current + length (l_line_separator);

  end loop;

  return;
 
end clob_to_csv;

function blob_to_csv (p_csv_blob in blob,
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

function date_to_epoch(p_date date) return number is
    c_base_date constant date := to_date('1970-01-01', 'YYYY-MM-DD');
    c_seconds_in_day constant number := 24 * 60 * 60;
    v_unix_timestamp number;
begin
    v_unix_timestamp := trunc((p_date - c_base_date) * c_seconds_in_day);
    
    if (v_unix_timestamp < 0 ) then
        raise_application_error(-20000, 'unix_timestamp:: unix_timestamp cannot be nagative');
    end if;
    
    return v_unix_timestamp;
end date_to_epoch;

procedure insert_error
  (
    p_api_name in varchar2 default null,
    p_err_msg  in varchar2,
    p_err_code in number,
    p_user     in varchar2,
    p_int_seq number
  )
as
pragma autonomous_transaction;
begin
  insert
  into integration_errors
    ( error_rec_id,
      error_desc,
      error_code,
      api_name,
      insert_user
    )
    values
    ( p_int_seq,
      dbms_utility.format_error_backtrace
      ||p_err_msg,
      p_err_code,
      p_api_name,
      p_user
    );
  commit;
end;

procedure insert_error
  (
    p_api_name in varchar2 default null,
    p_err_msg  in varchar2,
    p_err_code in number,
    p_user     in varchar2,
    p_int_err_seq number,
    p_int_seq number
  )
as
pragma autonomous_transaction;
begin
  insert
  into integration_errors
    ( error_rec_id,
      error_desc,
      error_code,
      api_name,
      insert_user
    )
    values
    ( p_int_err_seq,
      dbms_utility.format_error_backtrace
      ||p_err_msg,
      p_err_code,
      p_api_name,
      p_user
    );
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = p_int_err_seq
    where id       = p_int_seq;
  commit;
end;
function blob_to_clob
  (
    blob_in in blob
  )
  return clob
as
  v_clob clob;
  v_varchar varchar2(32767);
  v_start pls_integer  := 1;
  v_buffer pls_integer := 32767;
begin
  dbms_lob.createtemporary(v_clob, true);
  for i in 1..ceil
  (
    dbms_lob.getlength(blob_in) / v_buffer)
  loop
    v_varchar := utl_raw.cast_to_varchar2(dbms_lob.substr(blob_in, v_buffer, v_start));
    dbms_lob.writeappend(v_clob, length(v_varchar), v_varchar);
    v_start := v_start + v_buffer;
  end loop;
  return v_clob;
end;
function decode_base64
  (
    p_data in varchar2
  )
  return varchar2
as
begin
  return utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(p_data)));
end;
function encode_base64
  (
    p_data in varchar2
  )
  return varchar2
as
begin
  return utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_data)));
end;
function is_valid_auth
  (
    p_data in varchar2
  )
  return varchar2
as
  l_username varchar2(20);
  l_password varchar2(20);
  l_data varchar2(100);
  l_count pls_integer;
begin
  l_data := decode_base64(p_data);
  select instr(l_data,':') into l_count from dual;
  if l_count = 0 then
    return 'INVALID';
  else
    l_username   := substr(l_data,1,instr(l_data,':')-1);
    l_password   := substr(l_data,instr(l_data,':')  +1);
    if l_username = atl_app_config.c_int_username and l_password = atl_app_config.c_int_password then
      return 'VALID';
    else
      return 'INVALID';
    end if;
  end if;
end;


procedure send_email(
    p_email_to        in varchar2,
    p_email_from      in varchar2,
    p_email_body      in varchar2,
    p_email_body_html in varchar2 default null,
    p_email_subj      in varchar2 default null,
    p_email_cc        in varchar2 default null,
    p_email_bcc       in varchar2 default null,
    p_is_attachment in varchar2 default 'N',
    p_attachment in blob default null,
    p_filename varchar2 default null,
    p_mime_type varchar2 default null)
as
  l_workspace_id number;
  l_id number;
begin
  l_workspace_id := apex_util.find_security_group_id (p_workspace => atl_app_config.c_workspace_id);
  apex_util.set_security_group_id (p_security_group_id => l_workspace_id);
  l_id := apex_mail.send( p_to => p_email_to, 
                  p_from => atl_app_config.c_atom_email_from,--p_email_from, 
                  p_body => p_email_body, -- Body of the email in plain text, this text only displays for email clients that do not support HTML or have HTML disabled
                  p_body_html => p_email_body_html, 
                  p_subj => p_email_subj);
  if p_is_attachment ='N' then
  apex_mail.push_queue;
  else
  apex_mail.add_attachment(
            p_mail_id    => l_id,
            p_attachment => p_attachment,
            p_filename   => p_filename,
            p_mime_type  => p_mime_type);
  apex_mail.push_queue;
  end if;
end;

  /*function xml_to_json(
      p_xml_data in clob)
    return clob
  as
    l_xml sys.xmltype ;
    l_json_clob clob;
    --l_json       xmltype;
  begin
    -- formulate data as XML
    l_xml :=xmltype.createxml(p_xml_data);
    -- initialize APEX for JSON CLOB creation
    apex_json.initialize_clob_output;
    -- writting JSON data from XML 
    apex_json.write(l_xml);
    -- fetching generated JSON from memory
    l_json_clob :=apex_json.get_clob_output;
    -- frees up temp memory 
    apex_json.free_output;
    -- return to caller  
    return l_json_clob;
   
   
  end;*/

function xml_to_json(
    p_xml_data in clob)
  return clob
as
/*--l_xml_clob CLOB; 
l_xml XMLTYPE;
l_xsl XMLTYPE;
l_transformed XMLTYPE;
begin
  
   --select file_data into l_xml_clob from json_clob;
   l_xml :=xmltype.createxml(p_xml_data);
   l_xsl := XMLTYPE.CREATEXML(get_xml_to_json_stylesheet);
 
   SELECT XMLTRANSFORM(l_xml, l_xsl)
   INTO l_transformed
   FROM dual;
  
  return l_transformed.getclobval();
 */
 l_stylesheet clob;
 c_out clob;
 l_return_json clob;
 --out_buf varchar2(4000);
 --amount number := 4000;
 parser dbms_xmlparser.parser;
 t_doc dbms_xmldom.domdocument;
 s_doc dbms_xmldom.domdocument;
 sheet dbms_xslprocessor.stylesheet;
 proc dbms_xslprocessor.processor;

begin
  -- Get the stylesheet of XML to JSON
  -- select file_data into TST_DOC from json_clob;
  select xsl_clob into l_stylesheet
  from xsl_stylesheet where type = 'XML_TO_JSON_V2';
  
  parser := dbms_xmlparser.newparser;
  proc := dbms_xslprocessor.newprocessor;

  -- Parse the document into a DOM
  dbms_xmlparser.parseclob(parser, p_xml_data);
  t_doc := dbms_xmlparser.getdocument(parser);  
  -- Parse the style sheet into a DOM as well
  dbms_xmlparser.parseclob(parser, l_stylesheet);  
  s_doc := dbms_xmlparser.getdocument(parser);
  
  -- Convert this into a form the processor can use
  sheet := dbms_xslprocessor.newstylesheet(s_doc, '');
  
  -- Process the XSL directly to a textual (CLOB) output
   DBMS_LOB.CreateTemporary(C_OUT, FALSE);
  dbms_xslprocessor.processxsl(proc, sheet, t_doc, c_out);  
  l_return_json := c_out;
  dbms_lob.freetemporary(c_out);
  return l_return_json;
 
end;

function xmltojson(xmldata clob) return varchar2
	as
	  language java name 'xmlTojson.transform (java.sql.Clob)                          
	return java.lang.String';

function xmltype2clob(i_xml in xmltype) return clob is
  begin
    return(i_xml.getclobval());
  end;
  
function xml2json(i_xml in xmltype) return xmltype is
    l_json xmltype;
  begin
    l_json := i_xml.transform(xmltype(get_xml_to_json_stylesheet));
    return(l_json);
  end;

function get_servprov_stylesheet return varchar2 is
 l_xslt_string varchar2(32000);
  begin
  l_xslt_string :='<?xml version="1.0" encoding="UTF-8" ?>
                  <xsl:stylesheet version="1.0"
                      xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
                    <xsl:template match="/">
                      <Transmission>
                        <TransmissionHeader>
                          <SenderSystemId>ORACLE-PAAS</SenderSystemId>
                        </TransmissionHeader>
                        <TransmissionBody>
                          <GLogXMLElement>
                            <Location>
                              <TransactionCode>IU</TransactionCode>
                              <LocationGid>
                                <Gid>
                                  <DomainName>ATL</DomainName>
                                  <Xid>
                                    <xsl:value-of select="ROWSET/ROW/SEVPROV_ID"/>
                                  </Xid>
                                </Gid>
                              </LocationGid>
                              <LocationName>
                                <xsl:value-of select="ROWSET/ROW/SERVPROV_NAME"/>
                              </LocationName>
                              <Address>
                                <AddressLines>
                                  <SequenceNumber>1</SequenceNumber>
                                  <AddressLine>
                                    <xsl:value-of select="ROWSET/ROW/SERVPROV_ADD"/>
                                  </AddressLine>
                                </AddressLines>
                                <CountryCode3Gid>
                                  <Gid>
                                    <Xid>
                                      <xsl:value-of select="ROWSET/ROW/COUNTRY"/>
                                    </Xid>
                                  </Gid>
                                </CountryCode3Gid>
                                <CountryCode>
                                  <CountryCode3Gid>
                                    <Gid>
                                      <Xid>
                                        <xsl:value-of select="ROWSET/ROW/COUNTRY"/>
                                      </Xid>
                                    </Gid>
                                  </CountryCode3Gid>
                                </CountryCode>
                                <TimeZoneGid>
                                  <Gid>
                                    <Xid>Asia/Calcutta</Xid>
                                  </Gid>
                                </TimeZoneGid>          
                              </Address>
                              <LocationRole>
                                <LocationRoleGid>
                                  <Gid>
                                    <Xid>CARRIER</Xid>
                                  </Gid>
                                </LocationRoleGid>
                              </LocationRole>
                  
                              <ServiceProvider>
                                <ServiceProviderAlias>
                                  <ServiceProviderAliasQualifierGid>
                                    <Gid>
                                      <Xid>GLOG</Xid>
                                    </Gid>
                                  </ServiceProviderAliasQualifierGid>
                                  <ServiceProviderAliasValue>
                                    <xsl:value-of select="concat(''ATL.'',ROWSET/ROW/SEVPROV_ID)"/>
                                  </ServiceProviderAliasValue>
                                </ServiceProviderAlias>
                              </ServiceProvider>
                              <FlexFieldStrings>
                                <Attribute1>
                                  <xsl:value-of select="ROWSET/ROW/INDUSTRY_KEY"/>
                                </Attribute1>
                              </FlexFieldStrings>
                              <xsl:if test ="count(ROWSET/ROW/CONTACT_DETAILS/CONTACT_DETAILS_ROW) > 0 ">
                                <xsl:for-each select="ROWSET/ROW/CONTACT_DETAILS/CONTACT_DETAILS_ROW">
                                  <Contact>
                                    <ContactGid>
                                      <Gid>
                                        <DomainName>ATL</DomainName>
                                        <Xid>
                                          <xsl:value-of select="CONTACT_ID"/>
                                        </Xid>
                                      </Gid>
                                    </ContactGid>
                                    <TransactionCode>IU</TransactionCode>
                                    <EmailAddress>
                                      <xsl:value-of select="EMAIL"/>
                                    </EmailAddress>
                                    <!--IsPrimaryContact>Y</IsPrimaryContact-->
                                    <CommunicationMethod>
                                      <ComMethodRank>1</ComMethodRank>
                                      <ComMethodGid>
                                        <Gid>
                                          <Xid>EMAIL</Xid>
                                        </Gid>
                                      </ComMethodGid>
                                    </CommunicationMethod>
                                    <LocationGid>
                                      <Gid>
                                        <DomainName>ATL</DomainName>
                                        <Xid>
                                          <xsl:value-of select="../SEVPROV_ID"/>
                                        </Xid>
                                      </Gid>
                                    </LocationGid>
                                    <IsNotificationOn>Y</IsNotificationOn>
                                  </Contact>
                                </xsl:for-each>
                              </xsl:if>
                            </Location>
                          </GLogXMLElement>
                        </TransmissionBody>
                      </Transmission>
                    </xsl:template>
                  </xsl:stylesheet>';
    return(l_xslt_string);
  end;

function get_sap_sto_stylesheet return varchar2 is
 l_xslt_string varchar2(32000);
  begin
  l_xslt_string :='<?xml version="1.0" encoding="UTF-8" ?>
                    <xsl:stylesheet version="2.0" 	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
                      <xsl:template match="/">
                        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:i="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM">
                          <soapenv:Header/>
                          <soapenv:Body>
                            <i:STO_Req_Out>
                              <DATA>
                                <LOAD_SLIP>
                                  <xsl:value-of select="ROWSET/ROW/LOADSLIP_ID"/>
                                </LOAD_SLIP>
                                <OTM_SHIPMENT>
                                  <xsl:value-of select="ROWSET/ROW/SHIPMENT_ID"/>
                                </OTM_SHIPMENT>
                                <SOURCE_LOC>
                                  <xsl:value-of select="ROWSET/ROW/SOURCE_LOC"/>
                                </SOURCE_LOC>
                                <DEST_LOC>
                                  <xsl:value-of select="ROWSET/ROW/DEST_LOC"/>
                                </DEST_LOC>
                                <xsl:variable name="Plant" select="ROWSET/ROW/SOURCE_LOC"/>
                                <SOLD_TO_PARTY/>
                                <SHIP_TO_PARTY/>
                                <DOCUMENT_TYPE>
                                  <xsl:value-of select="ROWSET/ROW/DOC_TYPE"/>
                                </DOCUMENT_TYPE>
                                <START_DATE>
                                  <xsl:value-of select="ROWSET/ROW/START_DT"/>
                                </START_DATE>
                                <DESP_DATE>
                                  <xsl:value-of select="ROWSET/ROW/DESP_DT"/>
                                </DESP_DATE>
                                <CARR_ID>
                                  <xsl:value-of select="ROWSET/ROW/SHIPMENT_DETAILS/SHIPMENT_DETAILS_ROW/TRANSPORTER_SAP_CODE"/>
                                </CARR_ID>
                                <TRUCK_NO>
                                  <xsl:value-of select="ROWSET/ROW/SHIPMENT_DETAILS/SHIPMENT_DETAILS_ROW/TRUCK_NUMBER"/>
                                </TRUCK_NO>
                                <LR_NO>
                                  <xsl:value-of select="ROWSET/ROW/LR_NUM"/>
                                </LR_NO>
                                <LR_DATE>
                                  <xsl:value-of select="ROWSET/ROW/LR_DATE"/>
                                </LR_DATE>
                                <TRUCK_TYPE>
                                  <xsl:value-of select="ROWSET/ROW/SHIPMENT_DETAILS/SHIPMENT_DETAILS_ROW/TRUCK_TYPE"/>
                                </TRUCK_TYPE>
                                <USAGE/>
                                <xsl:for-each select="ROWSET/ROW/LOADSLIP_DETAILS/LOADSLIP_DETAILS_ROW">
                    
                                  <ITEM_DETAILS>
                                    <LINE_ITEM>
                                      <xsl:value-of select="LINE_NO"/>
                                    </LINE_ITEM>
                                    <MATERIAL>
                                      <xsl:value-of select="ITEM_ID"/>
                                    </MATERIAL>
                                    <QUANTITY>
                                      <xsl:value-of select="LOAD_QTY"/>
                                    </QUANTITY>
                                    <BATCH_NUMBER>
                                      <xsl:value-of select="BATCH_CODE"/>
                                    </BATCH_NUMBER>
                                    <PLANT>
                                      <xsl:value-of select="$Plant"/>
                                    </PLANT>
                                    <MEINS>
                                      <xsl:value-of select="MEINS"/>
                                    </MEINS>
                                  </ITEM_DETAILS>
                    
                                </xsl:for-each>
                              </DATA>
                    
                            </i:STO_Req_Out>
                          </soapenv:Body>
                        </soapenv:Envelope>
                      </xsl:template>
                    </xsl:stylesheet>';
    return(l_xslt_string);
  end;
  
function get_sap_so_stylesheet return varchar2 is
 l_xslt_string varchar2(32000);
  begin
  l_xslt_string :='<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0" 	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
<xsl:template match="/">
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:i="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM">
<soapenv:Header/>
<soapenv:Body>
<i:SalesOrder_Req_Out>
<DATA>
<LOAD_SLIP>
<xsl:value-of select="ROWSET/ROW/LOADSLIP_ID"/>
</LOAD_SLIP>
<OTM_SHIPMENT>
<xsl:value-of select="ROWSET/ROW/SHIPMENT_ID"/>
</OTM_SHIPMENT>
<SOURCE_LOC>
<xsl:value-of select="ROWSET/ROW/SOURCE_LOC"/>
</SOURCE_LOC>
<DEST_LOC>
<xsl:value-of select="ROWSET/ROW/DEST_LOC"/>
 </DEST_LOC>
<xsl:variable name="Plant" select="ROWSET/ROW/SOURCE_LOC"/>
<SOLD_TO_PARTY>
<xsl:value-of select="ROWSET/ROW/DEST_LOC"/>
</SOLD_TO_PARTY>
<xsl:choose>
<xsl:when test="ROWSET/ROW/SHIP_TO != ''''">
									<SHIP_TO_PARTY>
                <xsl:value-of select="ROWSET/ROW/SHIP_TO"/>
                </SHIP_TO_PARTY>
</xsl:when>
<xsl:otherwise>
<SHIP_TO_PARTY>
                <xsl:value-of select="ROWSET/ROW/DEST_LOC"/>
                </SHIP_TO_PARTY>
</xsl:otherwise>
</xsl:choose>
<DOCUMENT_TYPE>
  <xsl:value-of select="ROWSET/ROW/DOC_TYPE"/>
</DOCUMENT_TYPE>
<START_DATE>
  <xsl:value-of select="ROWSET/ROW/START_DT"/>
</START_DATE>
<DESP_DATE>
  <xsl:value-of select="ROWSET/ROW/DESP_DT"/>
</DESP_DATE>
<CARR_ID>
  <xsl:value-of select="ROWSET/ROW/SHIPMENT_DETAILS/SHIPMENT_DETAILS_ROW/TRANSPORTER_SAP_CODE"/>
</CARR_ID>
<TRUCK_NO>
  <xsl:value-of select="ROWSET/ROW/SHIPMENT_DETAILS/SHIPMENT_DETAILS_ROW/TRUCK_NUMBER"/>
</TRUCK_NO>
<LR_NO>
  <xsl:value-of select="ROWSET/ROW/LR_NUM"/>
</LR_NO>
<LR_DATE>
  <xsl:value-of select="ROWSET/ROW/LR_DATE"/>
</LR_DATE>
<TRUCK_TYPE>
  <xsl:value-of select="ROWSET/ROW/SHIPMENT_DETAILS/SHIPMENT_DETAILS_ROW/TRUCK_TYPE"/>
</TRUCK_TYPE>
<USAGE>COD</USAGE>
<xsl:for-each select="ROWSET/ROW/LOADSLIP_DETAILS/LOADSLIP_DETAILS_ROW">
                    
  <ITEM_DETAILS>
    <LINE_ITEM>
      <xsl:value-of select="LINE_NO"/>
    </LINE_ITEM>
    <MATERIAL>
      <xsl:value-of select="ITEM_ID"/>
    </MATERIAL>
    <QUANTITY>
      <xsl:value-of select="LOAD_QTY"/>
    </QUANTITY>
    <BATCH_NUMBER>
      <xsl:value-of select="BATCH_CODE"/>
    </BATCH_NUMBER>
    <PLANT>
      <xsl:value-of select="$Plant"/>
    </PLANT>
    <MEINS>
      <xsl:value-of select="MEINS"/>
    </MEINS>
  </ITEM_DETAILS>                    
</xsl:for-each>
                              </DATA>                    
                            </i:SalesOrder_Req_Out>
                          </soapenv:Body>
                        </soapenv:Envelope>
                      </xsl:template>
                    </xsl:stylesheet>';
    return(l_xslt_string);
  end;
  
function get_sap_ewaybill_stylesheet return varchar2 is
  l_xslt_string varchar2(32000);
  begin
  
  l_xslt_string :='<?xml version="1.0" encoding="UTF-8" ?>
                  <xsl:stylesheet version="2.0" 
                  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                  xmlns:xs="http://www.w3.org/2001/XMLSchema">
                  <xsl:template match="/">
                  <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                     <soapenv:Header/>
                     <soapenv:Body>
                        <EwayBillReq>
                      <xsl:for-each select="ROWSET/ROW/INV_DETAILS/INV_DETAILS_ROW">
                          <InvoiceDetails>
                            <InvoiceID><xsl:value-of select="INVOICE_NUMBER"/></InvoiceID>
                          </InvoiceDetails>
                      </xsl:for-each>
                        </EwayBillReq>
                     </soapenv:Body>
                  </soapenv:Envelope>
                  </xsl:template>
                  </xsl:stylesheet>';  
  return(l_xslt_string);
end;
  
function get_sap_ewaybill_stylesheet_s return varchar2 is
  l_xslt_string varchar2(32000);
  begin
  
  l_xslt_string :='<?xml version="1.0" encoding="UTF-8" ?>
                  <xsl:stylesheet version="2.0" 
                  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                  xmlns:xs="http://www.w3.org/2001/XMLSchema">
                  <xsl:template match="/">
                  <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                     <soapenv:Header/>
                     <soapenv:Body>
                        <EwayBillReq>
                      <xsl:for-each select="ROWSET/ROW">
                          <InvoiceDetails>
                            <InvoiceID><xsl:value-of select="INVOICE_NUMBER"/></InvoiceID>
                          </InvoiceDetails>
                      </xsl:for-each>
                        </EwayBillReq>
                     </soapenv:Body>
                  </soapenv:Envelope>
                  </xsl:template>
                  </xsl:stylesheet>';  
  return(l_xslt_string);
end;
  

function get_sap_barcode_stylesheet return varchar2 is
 l_xslt_string varchar2(32000);
  begin
  l_xslt_string :='<?xml version="1.0" encoding="UTF-8" ?>
                    <xsl:stylesheet version="2.0" 	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
                      <xsl:template match="/">
                        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:i="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM">
                          <soapenv:Header/>
                          <soapenv:Body>
                            <i:Barcode_Req_Out>
                              <Data>
                                <LoadSlipID>
                                  <xsl:value-of select="ROWSET/ROW/LOADSLIP_ID"/>
                                </LoadSlipID>						
                                <SourceLocation>
                                  <xsl:value-of select="ROWSET/ROW/SOURCE_LOC"/>
                                </SourceLocation>
                                <OECode>
                                  <xsl:value-of select="ROWSET/ROW/OE_DETAILS/CUST_ID"/>
                                </OECode>
                                <OEName>
                                  <xsl:value-of select="ROWSET/ROW/OE_DETAILS/CUST_NAME"/>
                                </OEName>
                                <DestinationLocation>
                                  <xsl:value-of select="ROWSET/ROW/DEST_LOC"/>
                                </DestinationLocation>												
                                <ShipDate>
                                  <xsl:value-of select="ROWSET/ROW/SHIP_DATE"/>
                                </ShipDate>
                                <CreateDate>
                                  <xsl:value-of select="ROWSET/ROW/CREATE_DATE"/>
                                </CreateDate>						
                                <xsl:for-each select="ROWSET/ROW/LOADSLIP_DETAILS/LOADSLIP_DETAILS_ROW">
                                  <Item_Details>
                                    <LineNo>
                                      <xsl:value-of select="LINE_NO"/>
                                    </LineNo>
                                    <MaterialCode>
                                      <xsl:value-of select="ITEM_ID"/>
                                    </MaterialCode>
                                    <MaterialDescription>
                                      <xsl:value-of select="ITEM_DESCRIPTION"/>
                                    </MaterialDescription>
                                    <LoadQty>
                                      <xsl:value-of select="LOAD_QTY"/>
                                    </LoadQty>
                                    <BatchCode>
                                      <xsl:value-of select="BATCH_CODE"/>
                                    </BatchCode>								
                                    <UOM>
                                      <xsl:value-of select="UOM"/>
                                    </UOM>
                                  </Item_Details>
                                </xsl:for-each>
                              </Data>
                            </i:Barcode_Req_Out>
                          </soapenv:Body>
                        </soapenv:Envelope>
                      </xsl:template>
                    </xsl:stylesheet>';
    return(l_xslt_string);
  end;
  
  function get_sap_ship_ls_stylesheet return varchar2 is
 l_xslt_string varchar2(32000);
  begin
  l_xslt_string :='<?xml version="1.0" encoding="UTF-8" ?>
                    <xsl:stylesheet version="2.0" 	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
                      <xsl:template match="/">
                        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:i="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM">
                          <soapenv:Header/>
                          <soapenv:Body>
                            <PaaSLSTransmission>                              
                                <ShipmentID>
                                  <xsl:value-of select="ROWSET/ROW/SHIPMENT_ID"/>
                                </ShipmentID>                               						
                                <xsl:for-each select="ROWSET/ROW/PASSLSLINE/PASSLSLINE_ROW">
                                  <PaaSLSLine>
                                    <LoadslipID>
                                      <xsl:value-of select="LOADSLIP_ID"/>
                                    </LoadslipID>
                                    <SOSTONumber>
                                      <xsl:value-of select="SO_STO_NUM"/>
                                    </SOSTONumber>
                                    <InvoiceNumber>
                                      <xsl:value-of select="INVOICE_NUMBER"/>
                                    </InvoiceNumber>
                                  </PaaSLSLine>
                                </xsl:for-each>                             
                            </PaaSLSTransmission>
                          </soapenv:Body>
                        </soapenv:Envelope>
                      </xsl:template>
                    </xsl:stylesheet>';
    return(l_xslt_string);
  end;

function get_xml_to_json_stylesheet return varchar2 is
    l_xslt_string varchar2(32000);
  begin

    l_xslt_string := '<?xml version="1.0" encoding="UTF-8" ?>
                        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
                          <xsl:output method="text" encoding="utf-8"/>
                          
                          <xsl:template match="/node()">
                            <xsl:text>{</xsl:text>
                            <xsl:apply-templates select="." mode="detect" />
                            <xsl:text>}</xsl:text>
                          </xsl:template>
                        
                          <xsl:template match="*" mode="detect">
                            <xsl:choose>
                              <xsl:when test="name(preceding-sibling::*[1]) = name(current()) and name(following-sibling::*[1]) != name(current())">
                                <xsl:apply-templates select="." mode="obj-content" />
                                <xsl:text>]</xsl:text>
                                <xsl:if test="count(following-sibling::*[name() != name(current())]) &gt; 0">, </xsl:if>
                              </xsl:when>
                              <xsl:when test="name(preceding-sibling::*[1]) = name(current())">
                                  <xsl:apply-templates select="." mode="obj-content" />
                                  <xsl:if test="name(following-sibling::*) = name(current())">, </xsl:if>
                              </xsl:when>
                              <xsl:when test="following-sibling::*[1][name() = name(current())]">
                                <xsl:text>"</xsl:text><xsl:value-of select="name()"/><xsl:text>" : [</xsl:text>
                                  <xsl:apply-templates select="." mode="obj-content" /><xsl:text>, </xsl:text> 
                              </xsl:when>
                              <xsl:when test="count(./child::*) > 0 or count(@*) > 0">
                                <xsl:text>"</xsl:text><xsl:value-of select="name()"/>" : <xsl:apply-templates select="." mode="obj-content" />
                                <xsl:if test="count(following-sibling::*) &gt; 0">, </xsl:if>
                              </xsl:when>
                              <xsl:when test="count(./child::*) = 0">
                                <xsl:text>"</xsl:text><xsl:value-of select="name()"/>" : "<xsl:apply-templates select="."/><xsl:text>"</xsl:text>
                                <xsl:if test="count(following-sibling::*) &gt; 0">, </xsl:if>
                              </xsl:when>
                            </xsl:choose>
                          </xsl:template>
                        
                          <xsl:template match="*" mode="obj-content">
                            <xsl:text>{</xsl:text>
                              <xsl:apply-templates select="@*" mode="attr" />
                              <xsl:if test="count(@*) &gt; 0 and (count(child::*) &gt; 0 or text())">, </xsl:if>
                              <xsl:apply-templates select="./*" mode="detect" />
                              <xsl:if test="count(child::*) = 0 and text() and not(@*)">
                                <xsl:text>"</xsl:text><xsl:value-of select="name()"/>" : "<xsl:value-of select="text()"/><xsl:text>"</xsl:text>
                              </xsl:if>
                              <xsl:if test="count(child::*) = 0 and text() and @*">
                                <xsl:text>"text" : "</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
                              </xsl:if>
                            <xsl:text>}</xsl:text>
                            <xsl:if test="position() &lt; last()">, </xsl:if>
                          </xsl:template>
                          
                          <xsl:template match="@*" mode="attr">
                            <xsl:text>"</xsl:text><xsl:value-of select="name()"/>" : "<xsl:value-of select="."/><xsl:text>"</xsl:text>
                            <xsl:if test="position() &lt; last()">,</xsl:if>
                          </xsl:template>
                        
                          <xsl:template match="node/@TEXT | text()" name="removeBreaks">
                            <xsl:param name="pText" select="normalize-space(.)"/>
                            <xsl:choose>
                              <xsl:when test="not(contains($pText, ''&#xA;''))"><xsl:copy-of select="$pText"/></xsl:when>
                              <xsl:otherwise>
                                <xsl:value-of select="concat(substring-before($pText, ''&#xD;&#xA;''), '' '')"/>
                                <xsl:call-template name="removeBreaks">
                                  <xsl:with-param name="pText" select="substring-after($pText, ''&#xD;&#xA;'')"/>
                                </xsl:call-template>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:template>
                          
                        </xsl:stylesheet>';

    return(l_xslt_string);
  end get_xml_to_json_stylesheet;
  
  function sql2xml(i_sql_string in varchar2) return xmltype is
    l_context_handle dbms_xmlgen.ctxhandle;
    l_xml            xmltype;
    l_rows           number;
  begin

    l_context_handle := dbms_xmlgen.newcontext(i_sql_string);
    dbms_xmlgen.setnullhandling(l_context_handle, dbms_xmlgen.empty_tag);

    l_xml  := dbms_xmlgen.getxmltype(l_context_handle, dbms_xmlgen.none);
    l_rows := dbms_xmlgen.getnumrowsprocessed(l_context_handle);

    dbms_xmlgen.closecontext(l_context_handle);

    if l_rows > 0 then
      return(l_xml);
    else
      return(null);
    end if;

  end;
  
  procedure insert_integration_log(p_json_data in clob,
                                   p_int_in_out in varchar2,
                                   p_interface_name in varchar2,
                                   p_api_name in varchar2,
                                   p_status in varchar2,
                                   p_insert_user in varchar2,
                                   p_int_num in number) as
  
  begin
  
  insert into integration_log (id,is_inbound,interface_name,api_name,clob_data,status,insert_user,insert_date) 
  values (p_int_num,p_int_in_out,p_interface_name,p_api_name,p_json_data,p_status,p_insert_user,sysdate) ;
  commit;
  
  end;
  
  procedure recompile_invalid_objects is
        cursor c1 is select 'ALTER '||DECODE(OBJECT_TYPE,'PACKAGE BODY','PACKAGE',OBJECT_TYPE)||' '||OBJECT_NAME||
        DECODE(OBJECT_TYPE,'PACKAGE BODY',' COMPILE BODY',' COMPILE') sql_statement,object_type,object_name
         FROM USER_OBJECTS
         WHERE STATUS = 'INVALID'
         AND OBJECT_TYPE IN ('TRIGGER','PACKAGE','PROCEDURE','FUNCTION','VIEW','PACKAGE BODY');
      begin
         for c1_rec in c1 loop
         begin
            execute immediate c1_rec.sql_statement||chr(0);
         exception
           when others then
              raise;
         end;
         end loop;
  end;
  
  function generate_business_number(
      p_type   varchar2,
      p_attribute1 varchar2,
      p_attribute2   varchar2)
    return varchar2
  as
    pragma autonomous_transaction;
    l_bn_context1 business_number_sequence.bn_context1%type;
    l_bn_context2 business_number_sequence.bn_context2%type := to_char(sysdate, 'DDMMYY');
    l_bn_seq business_number_sequence.curvalue%type;
    l_bn_type business_number_sequence.bn_type%type;
    l_count pls_integer;
    l_num_chk pls_integer;
    l_att1 varchar2(200);
    l_att2 varchar2(200);
    l_qt varchar2(10) := TO_CHAR(sysdate, 'Q');
  begin
    
    -- To supress leading zeros
    l_num_chk := atl_util_pkg.is_number(p_attribute1);
    if l_num_chk = 1 then
    l_att1 := to_number(p_attribute1);
    else
    l_att1 := p_attribute1;
    end if;
    
    l_num_chk := atl_util_pkg.is_number(p_attribute2);
    if l_num_chk = 1 then
    l_att2 := to_number(p_attribute2);
    else
    l_att2 := p_attribute2;
    end if;
    
  
    if p_type        = 'SH' then
      l_bn_type     := 'SHIPMENT';
      l_bn_context1 := p_type || l_att1;
    elsif p_type     = 'LS' then
      l_bn_type     := 'LOADSLIP';
      l_bn_context1 := p_type || (l_att1) || (l_att2);
    elsif p_type     = 'IND' then
      l_bn_type     := 'INDENT';
      --l_bn_context1 := p_type ||'-'|| l_att1||'-' || l_att2;
      --l_bn_context1 := p_type || l_att1 || l_att2||to_char(sysdate, 'MMYY');
      l_bn_context1 := p_type || l_att1 ||to_char(sysdate, 'MMYY');
      l_bn_context2 := l_att1||'-'||to_char(sysdate, 'YYYY')||'-'||l_qt;
    elsif p_type     = 'GC' then
      l_bn_type     := 'GATE_CONTROL';
      l_bn_context1 := l_att1;
    end if;
    if p_type  <> 'IND' then
    select count(1)
    into l_count
    from business_number_sequence
    where bn_context1 = l_bn_context1
    and bn_context2   = l_bn_context2;
    if l_count        > 0 then
      select curvalue
      into l_bn_seq
      from business_number_sequence
      where bn_context1 = l_bn_context1
      and bn_context2   = l_bn_context2;
      l_bn_seq         := lpad(l_bn_seq + 1, 3, 0);
      update business_number_sequence
      set curvalue      = l_bn_seq,
        update_date     = sysdate,
        update_user     = 'SYSTEM'
      where bn_context1 = l_bn_context1
      and bn_context2   = l_bn_context2;
      commit;
    else
      l_bn_seq := '001';
      insert
      into business_number_sequence
        (
          bn_type,
          bn_context1,
          bn_context2,
          curvalue,
          insert_user,
          insert_date
        )
        values
        (
          l_bn_type,
          l_bn_context1,
          l_bn_context2,
          l_bn_seq,
          'SYSTEM',
          sysdate
        );
      commit;
    end if;
    else 
    select count(1)
    into l_count
    from business_number_sequence
    where bn_context2   = l_bn_context2;
    if l_count        > 0 then    
    select curvalue
      into l_bn_seq
      from business_number_sequence
      where bn_context2   = l_bn_context2;
      l_bn_seq := l_bn_seq+1;
      update business_number_sequence
      set curvalue      = l_bn_seq,
        update_date     = sysdate,
        update_user     = 'SYSTEM'
      where bn_context2   = l_bn_context2;
      commit;      
      else
      l_bn_seq := 1;
      insert
      into business_number_sequence
        (
          bn_type,
          bn_context1,
          bn_context2,
          curvalue,
          insert_user,
          insert_date
        )
        values
        (
          l_bn_type,
          l_bn_context1,
          l_bn_context2,
          l_bn_seq,
          'SYSTEM',
          sysdate
        );
      commit;
    end if;
    end if;
    --return l_bn_context1 || '-' || l_bn_context2 || '-' || l_bn_seq;
    if p_type  <> 'IND' then
    return l_bn_context1 || l_bn_context2 || l_bn_seq;
    else
    l_bn_context1 := p_type || l_att1 || l_att2||to_char(sysdate, 'MMYY');
    return l_bn_context1 || '-'||l_bn_seq;
    end if;
  exception
  when others then
    raise;
  end;
  
  function is_number (p_string in varchar2) return int
  is
    v_num number;
  begin
    v_num := to_number(p_string);
    return 1;
  exception
  when value_error then
    return 0;
  end;

end atl_util_pkg;

/
