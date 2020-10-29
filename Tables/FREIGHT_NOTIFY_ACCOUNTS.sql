--------------------------------------------------------
--  DDL for Procedure FREIGHT_NOTIFY_ACCOUNTS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."FREIGHT_NOTIFY_ACCOUNTS" (p_type varchar2,p_approve_user varchar2) as
l_email_ids varchar2(4000);
l_count pls_integer;
l_user_role um_user.user_role_id%type;
l_body      clob;
l_body_html clob;  
l_sql varchar2(2000);
type freightcurtype is ref cursor;
l_cv   freightcurtype;
l_loc_id freight.source_loc%type;
begin
    select user_role_id into l_user_role from um_user where user_id=p_approve_user;
    if p_type='UPLOAD' then    
    l_sql := 'select distinct source_loc from freight_temp';
    elsif p_type='APPROVE' then
    l_sql := 'select distinct source_loc from freight_temp_notify';
    end if;
    open l_cv for l_sql;
    loop
    fetch l_cv into l_loc_id;
    exit when l_cv%notfound;
      select nvl((select listagg(email_id,',') within group (order by 1) 
      from um_user where plant_code = l_loc_id
      and user_role_id='ACCOUNTS'
      and email_id is not null),'NA')
      into l_email_ids
      from dual;
      
      if l_email_ids <> 'NA' then
      if p_type='UPLOAD' then  
      select count(1) into l_count from freight_temp where source_loc=l_loc_id;
      elsif p_type='APPROVE' then
      select count(1) into l_count from freight_temp_notify where source_loc=l_loc_id;
      end if;
      l_body := 'To view the content of this message, please use an HTML enabled mail client.'||utl_tcp.crlf;

      l_body_html := '<html>
                      <body>';--||utl_tcp.crlf;
      if l_user_role = 'ADMIN' then
      l_body_html := l_body_html ||'Rates are uploaded by : '||p_approve_user||' on '||to_char(sysdate,'DD-MON-YYYY')||' with '||l_count||' lines.'||utl_tcp.crlf;
      else    
      l_body_html := l_body_html ||'Rates are approved by : '||p_approve_user||' on '||to_char(sysdate,'DD-MON-YYYY')||' with '||l_count||' lines.'||utl_tcp.crlf;
      end if;
      l_body_html := l_body_html ||'</body></html>'; 
      
      atl_util_pkg.send_email(
      l_email_ids,
      'XX',
      l_body,
      l_body_html,
      'Rates Notification');
        
      end if;
    end loop;
    close l_cv;
   
 
 
end;

/
