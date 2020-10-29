--------------------------------------------------------
--  DDL for Procedure POST_TO_ATOM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."POST_TO_ATOM" (
      p_loadslip_id varchar2,
      p_inv_can_flag varchar2 default 'N')
  authid current_user as    
    l_resp_clob clob;
    l_status_code varchar2(100);
    l_request_data clob;
    l_user um_user.user_id%type;
    l_user_pass um_user.password%type;
    l_int_num        NUMBER := integration_seq.nextval;
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(100);
  begin
    
    select a.insert_user,b.password
    into l_user,l_user_pass
    from loadslip a, um_user b
    where a.loadslip_id=p_loadslip_id
    and a.insert_user = b.user_id;
    l_user_pass := atl_util_pkg.decode_base64(l_user_pass);
    l_user_pass := substr(l_user_pass,instr(l_user_pass,':')+1);
    dbms_output.put_line('Username : '||l_user||' Paasword : '||l_user_pass);
    -- Create the XML as SQL
   -- l_xml     := atl_util_pkg.sql2xml(p_sql_string);
    
    -- Transform XML using OTM XSL
  --  l_otm_xml := l_xml.transform(xmltype(atl_util_pkg.get_servprov_stylesheet));
    --dbms_output.put_line('OTM XML: '||l_otm_xml.getclobval()); 
    
    --l_request_data := '<loadslipid>'||p_loadslip_id||'</loadslipid>';
    
    select json_object('itemsData' value 
           json_arrayagg(json_object('itemId' value item_id,'batchCode' value batch_code)),
           'loadslipId' value loadslip_id,
           'password' value l_user_pass,
           'username' value l_user)
    into l_request_data
    from loadslip_detail where loadslip_id=p_loadslip_id
    group by loadslip_id;
    
   
    dbms_output.put_line('Request payload : '||l_request_data);
    -- insert into integration log table
      atl_util_pkg.insert_integration_log(p_json_data => l_request_data, p_int_in_out => 'N', p_interface_name => 'ATOM', p_api_name => '/user/update-dispatchQty', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => l_int_num);
      
    
    -- Sets character set of the body
    utl_http.set_body_charset('UTF-8');
    
    -- Clear headers before setting up
    apex_web_service.g_request_headers.delete();
    
    -- Build request header with content type
    apex_web_service.g_request_headers(1).name := 'Content-Type';  
    apex_web_service.g_request_headers(1).value := 'application/json';  
    --apex_web_service.g_request_headers(1).name  := 'userId';
    --apex_web_service.g_request_headers(1).value := l_user;
    apex_web_service.g_request_headers(2).name  := 'toDispatch';
    if p_inv_can_flag = 'N' then
    apex_web_service.g_request_headers(2).value := 'true';
    else
    apex_web_service.g_request_headers(2).value := 'false';
    end if;
    --apex_web_service.g_request_headers(3).name  := 'loadslipId';
    --apex_web_service.g_request_headers(3).value := p_loadslip_id;
    
    -- Call OTM Integration API for XML processing
    
      l_resp_clob   := apex_web_service.make_rest_request
                      (p_url => 'https://atomcloud-test.apollotyres.com/v7/api/v1/user/update-dispatchQty', 
                       p_http_method => 'POST', 
                       p_body => l_request_data);
    
    dbms_output.put_line('ATOM: '||l_resp_clob ||' Response code '||apex_web_service.g_status_code);
    apex_json.parse (l_resp_clob);
    l_status_code := apex_json.get_varchar2 ('statusCode');
    dbms_output.put_line (apex_json.get_varchar2 ('statusCode'));
    if l_status_code = '200' then
    update integration_log set status ='PROCESSED',
    update_user='INTEGRATION' , update_date= sysdate
    where id = l_int_num;
    commit;
    else
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('ATOM API',l_resp_clob,-1,'INTEGRATION',l_int_error_seq);
    update integration_log set status ='ERROR',
    error_log_id = l_int_error_seq,update_user='INTEGRATION' , update_date= sysdate
    where id = l_int_num;
    commit;
    end if;
    
  exception
  when others then
  l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('ATOM API',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    
    update integration_log set status ='ERROR',
    error_log_id = l_int_error_seq,update_user='INTEGRATION' , update_date= sysdate
    where id = l_int_num;
    commit;
   raise;
  end;

/
