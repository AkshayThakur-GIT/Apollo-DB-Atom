--------------------------------------------------------
--  DDL for Package Body ATL_SAP_INTEGRATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_SAP_INTEGRATION_PKG" 
as
  procedure send_loadslip_to_sap_sto(
      p_ls_id varchar2,
      p_int_seq in number)
  as
    l_sql_string varchar2(2000);
    l_xml xmltype;
    l_sto_xml xmltype;
    --l_int_num number := integration_seq.nextval;
    l_result        varchar2(100);
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
    l_sap_doc_type order_type_lookup.sap_doc_type%type;
  begin
    
     select sap_doc_type 
     into l_sap_doc_type
     from order_type_lookup 
     where order_type=(select loadslip_type from loadslip 
     where loadslip_id = p_ls_id);
  
    -- Build data query
    l_sql_string := 'select a.loadslip_id,                   
                      a.shipment_id,                   
                      a.source_loc,                   
                      a.dest_loc,                   
                      a.lr_num,
                      a.lr_date,
                      '||''''||l_sap_doc_type||''' as doc_type,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as start_dt,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as desp_dt,                   
                      cursor(select b.transporter_sap_code,                                 
                      atl_business_flow_pkg.get_sap_tt_code(b.shipment_id) as truck_type,                                 
                      b.truck_number                          
                      from shipment b where b.shipment_id=a.shipment_id) as shipment_details,                   
                      cursor(select c.line_no,                                 
                      c.item_id,                                 
                      c.qty as load_qty,                                 
                      c.batch_code,                                 
                      ''EA'' as meins                          
                      from loadslip_line_detail c where c.loadslip_id=a.loadslip_id) as loadslip_details                  
                      from loadslip a where a.loadslip_id='||''''||p_ls_id||'''';
    -- Create the XML as SQL
    l_xml := atl_util_pkg.sql2xml(l_sql_string);
    -- Transform XML using SAP XSL (Build SOAP envelope)
    l_sto_xml := l_xml.transform(xmltype(atl_util_pkg.get_sap_sto_stylesheet));
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_sto_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'STO Create', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_sto_create,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_sto_xml.getclobval(), p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
    -- DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
    -- Pull out the specific value of interest.
    l_result := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//ns1:STO_Resp_In/DATA/ORDER_ID/text()', p_ns => 'xmlns:ns1="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM"');
    --DBMS_OUTPUT.put_line('l_result=' || l_result);
    
    if l_result is not null then
    update loadslip
    set sto_so_num    = l_result,
      update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'SUCCESS'
    where loadslip_id = p_ls_id;
    update integration_log
    set status    ='PROCESSED',
      update_user = 'INTEGRATION',
      update_date = sysdate
    where id      = p_int_seq;
    
    else
    l_int_error_seq := integration_error_seq.nextval;
    l_err_msg       := substr(l_xml.getStringVal(), 1, 4000);
    atl_util_pkg.insert_error('STO Create',l_err_msg,-1,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    update loadslip
    set update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'ERROR',
      int_message     = l_err_msg
    where loadslip_id = p_ls_id;
    end if;
    
    commit;
  exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('STO Create',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    update loadslip
    set update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'ERROR',
      int_message     = l_err_msg
    where loadslip_id = p_ls_id;
    commit;
    raise;
  end;
  
  procedure send_loadslip_to_sap_sto(
      p_ls_id varchar2,
      p_int_seq in number,
      p_status out varchar2)
  as
    l_sql_string varchar2(2000);
    l_xml xmltype;
    l_sto_xml xmltype;
    --l_int_num number := integration_seq.nextval;
    l_result        varchar2(100);
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
    l_sap_doc_type order_type_lookup.sap_doc_type%type;
  begin
     insert_loadslip_lines(p_ls_id);
     select sap_doc_type 
     into l_sap_doc_type
     from order_type_lookup 
     where order_type=(select loadslip_type from loadslip 
     where loadslip_id = p_ls_id);
  
    -- Build data query
    l_sql_string := 'select a.loadslip_id,                   
                      a.shipment_id,                   
                      a.source_loc,                   
                      a.dest_loc,                   
                      a.lr_num,
                      a.lr_date,
                      '||''''||l_sap_doc_type||''' as doc_type,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as start_dt,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as desp_dt,                   
                      cursor(select b.transporter_sap_code,                                 
                      atl_business_flow_pkg.get_sap_tt_code(b.shipment_id) as truck_type,                                 
                      b.truck_number                          
                      from shipment b where b.shipment_id=a.shipment_id) as shipment_details,                   
                      cursor(select c.line_no,                                 
                      c.item_id,                                 
                      c.qty as load_qty,                                 
                      c.batch_code,                                 
                      ''EA'' as meins                          
                      from loadslip_line_detail c where c.loadslip_id=a.loadslip_id) as loadslip_details                  
                      from loadslip a where a.loadslip_id='||''''||p_ls_id||'''';
    -- Create the XML as SQL
    l_xml := atl_util_pkg.sql2xml(l_sql_string);
    -- Transform XML using SAP XSL (Build SOAP envelope)
    l_sto_xml := l_xml.transform(xmltype(atl_util_pkg.get_sap_sto_stylesheet));
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_sto_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'STO Create', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_sto_create,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_sto_xml.getclobval(), p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
    -- DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
    -- Pull out the specific value of interest.
    l_result := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//ns1:STO_Resp_In/DATA/ORDER_ID/text()', p_ns => 'xmlns:ns1="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM"');
    --DBMS_OUTPUT.put_line('l_result=' || l_result);
    
       
    if l_result is not null then
    update loadslip
    set sto_so_num    = l_result,
      update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'SUCCESS',
      int_message     = null,
      status          = 'SENT_SAP',
      confirm_date    = sysdate
    where loadslip_id = p_ls_id;
    update integration_log
    set status    ='PROCESSED',
      update_user = 'INTEGRATION',
      update_date = sysdate
    where id      = p_int_seq;
    commit;
    -- Return to client
    p_status := l_result;
     else
    l_int_error_seq := integration_error_seq.nextval;
    l_err_msg       := substr(l_xml.getStringVal(), 1, 4000);
    atl_util_pkg.insert_error('STO Create',l_err_msg,-1,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    update loadslip
    set update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'ERROR',
      int_message     = l_err_msg,
      status          = 'LOADED',
      confirm_date    = null
    where loadslip_id = p_ls_id;
    commit;
    select atl_integration_pkg.upd_loadslip_error(p_ls_id) into l_err_msg 
    from loadslip where loadslip_id = p_ls_id;
    update loadslip
    set int_message     = l_err_msg
    where loadslip_id = p_ls_id;
    commit;
    -- Return to client
    p_status := 'ERROR';
    end if;
  
    
    
  exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('STO Create',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    update loadslip
    set update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'ERROR',
      int_message     = l_err_msg,
      status          = 'LOADED',
      confirm_date    = null
    where loadslip_id = p_ls_id;
    commit;
    select atl_integration_pkg.upd_loadslip_error(p_ls_id) into l_err_msg 
    from loadslip where loadslip_id = p_ls_id;
    update loadslip
    set int_message     = l_err_msg
    where loadslip_id = p_ls_id;
    commit;
    raise;
  end;
  
  procedure send_loadslip_to_sap_so(
      p_ls_id varchar2,
      p_int_seq in number)
  as
    l_sql_string varchar2(2000);
    l_xml xmltype;
    l_so_xml xmltype;
    --l_int_num number := integration_seq.nextval;
    l_result        varchar2(100);
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
    l_sap_doc_type order_type_lookup.sap_doc_type%type;
  begin
  
  select sap_doc_type 
     into l_sap_doc_type
     from order_type_lookup 
     where order_type=(select loadslip_type from loadslip 
     where loadslip_id = p_ls_id);
     
    -- Build data query
    l_sql_string := 'select a.loadslip_id,                   
                      a.shipment_id,                   
                      a.source_loc,                   
                      a.dest_loc,
                      a.ship_to,
                      a.lr_num,  
                      a.lr_date,
                      '||''''||l_sap_doc_type||''' as doc_type,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as start_dt,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as desp_dt,                   
                      cursor(select b.transporter_sap_code,                                 
                      atl_business_flow_pkg.get_sap_tt_code(b.shipment_id) as truck_type,                                 
                      b.truck_number                          
                      from shipment b where b.shipment_id=a.shipment_id) as shipment_details,                   
                      cursor(select c.line_no,                                 
                      c.item_id,                                 
                      c.qty as load_qty,                                 
                      c.batch_code,                                 
                      ''EA'' as meins                          
                      from loadslip_line_detail c where c.loadslip_id=a.loadslip_id) as loadslip_details                  
                      from loadslip a where a.loadslip_id='||''''||p_ls_id||'''';
    -- Create the XML as SQL
    l_xml := atl_util_pkg.sql2xml(l_sql_string);
    -- Transform XML using SAP XSL (Build SOAP envelope)
    l_so_xml := l_xml.transform(xmltype(atl_util_pkg.get_sap_so_stylesheet));
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_so_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'SO Create', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_so_create,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_so_xml.getclobval(), p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
    -- DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
    -- Pull out the specific value of interest.
    l_result := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//ns1:SalesOrder_Resp_In/DATA/ORDER_ID/text()', p_ns => 'xmlns:ns1="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM"');
    --DBMS_OUTPUT.put_line('l_result=' || l_result);
    
    if l_result is not null then
    update loadslip
    set sto_so_num    = l_result,
      update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'SUCCESS'
    where loadslip_id = p_ls_id;
    update integration_log
    set status    ='PROCESSED',
      update_user = 'INTEGRATION',
      update_date = sysdate
    where id      = p_int_seq;
    else
    l_int_error_seq := integration_error_seq.nextval;
    l_err_msg       := substr(l_xml.getStringVal(), 1, 4000);
    atl_util_pkg.insert_error('SO Create',l_err_msg,-1,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;  
    update loadslip
    set update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'ERROR',
      int_message     = l_err_msg
    where loadslip_id = p_ls_id;
    end if;
    commit;
  exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('SO Create',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    update loadslip
    set update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'ERROR',
      int_message     = l_err_msg
    where loadslip_id = p_ls_id;
    commit;
    raise;
  end;
  
  procedure send_loadslip_to_sap_so(
      p_ls_id varchar2,
      p_int_seq in number,
      p_status out varchar2)
  as
    l_sql_string varchar2(2000);
    l_xml xmltype;
    l_so_xml xmltype;
    --l_int_num number := integration_seq.nextval;
    l_result        varchar2(100);
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
    l_sap_doc_type order_type_lookup.sap_doc_type%type;
  begin 
  insert_loadslip_lines(p_ls_id);
  select sap_doc_type 
     into l_sap_doc_type
     from order_type_lookup 
     where order_type=(select loadslip_type from loadslip 
     where loadslip_id = p_ls_id);
     
    -- Build data query
    l_sql_string := 'select a.loadslip_id,                   
                      a.shipment_id,                   
                      a.source_loc,                   
                      a.dest_loc,
                      a.ship_to,
                      a.lr_num,  
                      a.lr_date,
                      '||''''||l_sap_doc_type||''' as doc_type,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as start_dt,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as desp_dt,                   
                      cursor(select b.transporter_sap_code,                                 
                      atl_business_flow_pkg.get_sap_tt_code(b.shipment_id) as truck_type,                                 
                      b.truck_number                          
                      from shipment b where b.shipment_id=a.shipment_id) as shipment_details,                   
                      cursor(select c.line_no,                                 
                      c.item_id,                                 
                      c.qty as load_qty,                                 
                      c.batch_code,                                 
                      ''EA'' as meins                          
                      from loadslip_line_detail c where c.loadslip_id=a.loadslip_id) as loadslip_details                  
                      from loadslip a where a.loadslip_id='||''''||p_ls_id||'''';
    -- Create the XML as SQL
    l_xml := atl_util_pkg.sql2xml(l_sql_string);
    -- Transform XML using SAP XSL (Build SOAP envelope)
    l_so_xml := l_xml.transform(xmltype(atl_util_pkg.get_sap_so_stylesheet));
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_so_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'SO Create', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_so_create,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_so_xml.getclobval(), p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
    -- DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
    -- Pull out the specific value of interest.
    l_result := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//ns1:SalesOrder_Resp_In/DATA/ORDER_ID/text()', p_ns => 'xmlns:ns1="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM"');
    --DBMS_OUTPUT.put_line('l_result=' || l_result);
    
    
    if l_result is not null then
    update loadslip
    set sto_so_num    = l_result,
      update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'SUCCESS',
      int_message     = null,
      status          = 'SENT_SAP',
      confirm_date    = sysdate
    where loadslip_id = p_ls_id;
    update integration_log
    set status    ='PROCESSED',
      update_user = 'INTEGRATION',
      update_date = sysdate
    where id      = p_int_seq;
    commit;
    -- Return to client
    p_status := l_result;
    else
    l_int_error_seq := integration_error_seq.nextval;
    l_err_msg       := substr(l_xml.getStringVal(), 1, 4000);
    atl_util_pkg.insert_error('SO Create',l_err_msg,-1,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;  
    update loadslip
    set update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'ERROR',
      int_message     = l_err_msg,
      status          = 'LOADED',
      confirm_date    = null
    where loadslip_id = p_ls_id;
    commit;
    select atl_integration_pkg.upd_loadslip_error(p_ls_id) into l_err_msg 
    from loadslip where loadslip_id = p_ls_id;
    update loadslip
    set int_message     = l_err_msg
    where loadslip_id = p_ls_id;
    commit;
    -- Return to client
    p_status := 'ERROR';
    end if;
    --commit;
   
  exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('SO Create',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    update loadslip
    set update_user     = 'INTEGRATION',
      update_date     = sysdate,
      int_status      = 'ERROR',
      int_message     = l_err_msg,
      status          = 'LOADED',
      confirm_date    = null
    where loadslip_id = p_ls_id;
    commit;
    select atl_integration_pkg.upd_loadslip_error(p_ls_id) into l_err_msg 
    from loadslip where loadslip_id = p_ls_id;
    update loadslip
    set int_message     = l_err_msg
    where loadslip_id = p_ls_id;
    commit;
    raise;
  end;
  
  procedure send_barcode_data_to_sap(
      p_ls_id varchar2,
      p_int_seq in number)
  as
    l_sql_string varchar2(2000);
    l_xml xmltype;
    l_sto_xml xmltype;
    --l_int_num number := integration_seq.nextval;
    l_result        varchar2(100);
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
  begin
    -- Build data query
    l_sql_string := 'select a.loadslip_id,                    
                      a.source_loc,                   
                      a.dest_loc,
                      cursor(select cust_id,cust_name from mt_customer where cust_id=a.ship_to) as oe_details,
                      to_char(a.insert_Date,''YYYYMMDD'') as ship_date,                   
                      to_char(a.insert_Date,''YYYYMMDD'') as create_date,                   
                      cursor(select c.line_no,                                 
                      c.item_id,  
                      d.item_description,
                      c.load_qty,                                 
                      c.batch_code,
                      ''EA'' as UOM
                      from loadslip_detail c,mt_item d where c.loadslip_id=a.loadslip_id
                      and d.item_classification = ''TYRE'' 
                      and c.item_id=d.item_id and atl_business_flow_pkg.is_scannable(a.source_loc,d.item_category) = ''Y'') as loadslip_details                  
                      from loadslip a where a.loadslip_id='||''''||p_ls_id||'''';
    -- Create the XML as SQL
    l_xml := atl_util_pkg.sql2xml(l_sql_string);
    -- Transform XML using SAP XSL (Build SOAP envelope)
    l_sto_xml := l_xml.transform(xmltype(atl_util_pkg.get_sap_barcode_stylesheet));
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_sto_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'Barcode', p_status => 'PROCESSED', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_barcode_int,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_sto_xml.getclobval(), p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
     DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
    -- Pull out the specific value of interest.
    -- l_result := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//ns1:STO_Resp_In/DATA/ORDER_ID/text()', p_ns => 'xmlns:ns1="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM"');
    --DBMS_OUTPUT.put_line('l_result=' || l_result);
    exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('Barcode',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    commit;
    raise;
  end;
  
  procedure send_so_sto_del_req(
      p_ls_id varchar2,
      p_int_seq in number)
  as
    l_sql_string varchar2(2000);
    l_envelope clob;
    l_xml xmltype;
    --l_sto_xml xmltype;
    --l_int_num number := integration_seq.nextval;
    l_message_type  varchar2(10);
    l_message_desc  varchar2(400);
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
    l_loadslip_type loadslip.loadslip_type%type;
    l_so_sto_type order_type_lookup.sap_order_type%type;
    l_sto_so_num loadslip.sto_so_num%type;
  begin
    
    select nvl(loadslip_type,'NA'),nvl(sto_so_num,'1234')
    into l_loadslip_type, l_sto_so_num
    from loadslip
    where loadslip_id=p_ls_id;
    select nvl(
      (select sap_order_type
      from order_type_lookup
      where order_type=l_loadslip_type
      ),'NA')
    into l_so_sto_type
    from dual;
    
    -- Build SOAP envelope
    l_envelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                    <soapenv:Header/>
                    <soapenv:Body>
                      <OrderDeleteReq>
                         <OrderDetails>
                            <OrderType>'||l_so_sto_type||'</OrderType>
                            <OrderNumber>'||l_sto_so_num||'</OrderNumber>
                         </OrderDetails>
                      </OrderDeleteReq>
                     </soapenv:Body>
                   </soapenv:Envelope>';    
    
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_envelope, p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'SO-STO Delete', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_del_order,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_envelope, p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
     DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
    -- Pull out the specific value of interest.
    l_message_type := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//OrderDeleteResp/OrderDetails/Message[1]/MessageType/text()');
    DBMS_OUTPUT.put_line('MessageType=' || l_message_type);
    l_message_desc := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//OrderDeleteResp/OrderDetails/Message[1]/MessageText/text()');
    DBMS_OUTPUT.put_line('MessageText=' || l_message_desc);
    if l_message_type ='S' then
    
    update integration_log
    set status    ='PROCESSED',
      update_user = 'INTEGRATION',
      update_date = sysdate
    where id      = p_int_seq;
    
    update loadslip set sto_so_num = null,status = 'LOADED',confirm_date = null
    where loadslip_id=p_ls_id;
    
    else
    l_int_error_seq := integration_error_seq.nextval;
    l_err_msg       := substr(l_message_desc, 1, 4000);
    atl_util_pkg.insert_error('SO-STO Delete',l_err_msg,-1,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;    
    end if;
    
     commit;
    
  exception
  when no_data_found then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('SO-STO Delete',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    commit;
    raise;
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('SO-STO Delete',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    commit;
    raise;
    
  end;
  
  procedure send_so_sto_del_req(
      p_ls_id varchar2,
      p_int_seq in number,
      p_status out varchar2)
  as
    l_sql_string varchar2(2000);
    l_envelope clob;
    l_xml xmltype;
    --l_sto_xml xmltype;
    --l_int_num number := integration_seq.nextval;
    l_message_type  varchar2(10);
    l_message_desc  varchar2(400);
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
    l_loadslip_type loadslip.loadslip_type%type;
    l_so_sto_type order_type_lookup.sap_order_type%type;
    l_sto_so_num loadslip.sto_so_num%type;
  begin
    
    select nvl(loadslip_type,'NA'),nvl(sto_so_num,'1234')
    into l_loadslip_type, l_sto_so_num
    from loadslip
    where loadslip_id=p_ls_id;
    select nvl(
      (select sap_order_type
      from order_type_lookup
      where order_type=l_loadslip_type
      ),'NA')
    into l_so_sto_type
    from dual;
    
    -- Build SOAP envelope
    l_envelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                    <soapenv:Header/>
                    <soapenv:Body>
                      <OrderDeleteReq>
                         <OrderDetails>
                            <OrderType>'||l_so_sto_type||'</OrderType>
                            <OrderNumber>'||l_sto_so_num||'</OrderNumber>
                         </OrderDetails>
                      </OrderDeleteReq>
                     </soapenv:Body>
                   </soapenv:Envelope>';    
    
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_envelope, p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'SO-STO Delete', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_del_order,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_envelope, p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
     DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
    -- Pull out the specific value of interest.
    l_message_type := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//OrderDeleteResp/OrderDetails/Message[1]/MessageType/text()');
    DBMS_OUTPUT.put_line('MessageType=' || l_message_type);
    l_message_desc := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//OrderDeleteResp/OrderDetails/Message[1]/MessageText/text()');
    DBMS_OUTPUT.put_line('MessageText=' || l_message_desc);
    if l_message_type ='S' then
    
    update integration_log
    set status    ='PROCESSED',
      update_user = 'INTEGRATION',
      update_date = sysdate
    where id      = p_int_seq;
    
    update loadslip set sto_so_num = null,int_status = 'SUCCESS',int_message = null,status = 'LOADED',
    confirm_date = null
    where loadslip_id=p_ls_id;
    commit;
    p_status := 'SUCCESS';
    else
    l_int_error_seq := integration_error_seq.nextval;
    l_err_msg       := substr(l_message_desc, 1, 4000);
    atl_util_pkg.insert_error('SO-STO Delete',l_err_msg,-1,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;    
    commit;
     p_status := 'ERROR';
    end if;
    
     
    
  exception
  when no_data_found then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('SO-STO Delete',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    commit;
    raise;
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('SO-STO Delete',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    commit;
    raise;
    
  end;
  
 procedure insert_loadslip_lines(p_ls_id varchar2)
  as
    l_line_no pls_integer := 1;
    l_t_sku loadslip_detail_bom.tube_sku%type;
    l_t_sku_qty loadslip_detail_bom.tube_qty%type;
    l_f_sku loadslip_detail_bom.flap_sku%type;
    l_f_sku_qty loadslip_detail_bom.flap_qty%type;
    l_v_sku loadslip_detail_bom.valve_sku%type;
    l_v_sku_qty loadslip_detail_bom.valve_qty%type;
  begin
  delete from loadslip_line_detail where loadslip_id=p_ls_id;
  commit;
    for i in
    (select distinct a.item_id,
      b.line_no,
      b.batch_code,
      b.load_qty,
      round(b.gross_wt,3) as gross_wt,
      nvl(b.gross_wt_uom,'KG') as wt_uom,
      nvl(round(b.gross_vol,3),0) as gross_vol,
      nvl(b.gross_vol_uom,'CUMTR') as vol_uom
    from loadslip_detail_bom a,
      loadslip_detail b
    where a.loadslip_id=p_ls_id
    and a.loadslip_id  =b.loadslip_id
    and a.item_id      = b.item_id order by b.line_no
    )
    loop
    
    
      insert
      into loadslip_line_detail
        (
          loadslip_id,
          line_no,
          item_id,
          qty,
          batch_code,
          insert_date,
          weight,
          weight_uom,
          volume,
          volume_uom
        )
        values
        (
          p_ls_id,
          l_line_no,
          i.item_id,
          i.load_qty,
          i.batch_code,
          sysdate,
          i.gross_wt,
          i.wt_uom,
          i.gross_vol,
          i.vol_uom
        );
      select nvl(tube_sku,'NA'),
        nvl(tube_qty,0),
        nvl(flap_sku,'NA'),
        nvl(flap_qty,0),
        nvl(valve_sku,'NA'),
        nvl(valve_qty,0)
      into l_t_sku,
      l_t_sku_qty,
        l_f_sku,
        l_f_sku_qty,
        l_v_sku,
        l_v_sku_qty
      from loadslip_detail_bom
      where item_id=i.item_id and loadslip_id = p_ls_id and line_no = i.line_no;
      if l_t_sku  <> 'NA' and l_t_sku_qty <> 0 then
        l_line_no := l_line_no +1;
        insert into loadslip_line_detail
          (loadslip_id,line_no,item_id,qty,batch_code,insert_date,
          weight,
          weight_uom,
          volume,
          volume_uom
          )
        select loadslip_id,
          l_line_no,
          tube_sku,
          nvl(tube_qty,0),
          nvl(tube_batch,'BOAW'),
          --'BOAW',
          sysdate,
          0,
          'KG',
          0,
          'CUMTR'
        from loadslip_detail_bom
        where item_id=i.item_id and loadslip_id = p_ls_id and line_no = i.line_no;
      end if;
      if l_f_sku  <> 'NA' and l_f_sku_qty <> 0 then
        l_line_no := l_line_no +1;
        insert into loadslip_line_detail
          (loadslip_id,line_no,item_id,qty,batch_code,insert_date,
          weight,
          weight_uom,
          volume,
          volume_uom
          )
        select loadslip_id,
          l_line_no,
          flap_sku,
          nvl(flap_qty,0),
          nvl(flap_batch,'BOAW'),
          --'BOAW',
          sysdate,
          0,
          'KG',
          0,
          'CUMTR'
        from loadslip_detail_bom
        where item_id=i.item_id and loadslip_id = p_ls_id and line_no = i.line_no;
      end if;
      if l_v_sku  <> 'NA' and l_v_sku_qty <> 0 then 
        if l_v_sku_qty <> 0 then
        l_line_no := l_line_no +1;
        insert into loadslip_line_detail
          (loadslip_id,line_no,item_id,qty,batch_code,insert_date,
          weight,
          weight_uom,
          volume,
          volume_uom
          )
        select loadslip_id,
          l_line_no,
          valve_sku,
          nvl(valve_qty,0),
          nvl(valve_batch,'TRITON'),
          --'BOAW',
          sysdate,
          0,
          'KG',
          0,
          'CUMTR'
        from loadslip_detail_bom
        where item_id=i.item_id and loadslip_id = p_ls_id and line_no = i.line_no;
        end if;
      end if;
      commit;
      l_line_no := l_line_no +1;
    end loop;
  end;
  
  procedure get_eway_bill_details(
    p_loadslip_id varchar2,
    p_int_seq in number)
as
  l_sql_string varchar2(2000);
  l_xml xmltype;
  l_eb_xml xmltype;
  l_json_obj json_object_t;
  l_inv_line_obj json_object_t;
  l_inv_linedetail_arr json_array_t;
  l_inv_id varchar2(100);
  l_json_data clob;
  --l_int_num       number := integration_seq.nextval;
  l_result        varchar2(100);
  l_int_error_seq number;
  l_err_num       number;
  l_err_msg       varchar2(4000);
  l_cnt pls_integer;
  l_loadslip_type loadslip.loadslip_type%type;
  l_eb_no loadslip_inv_header.e_way_bill_no%type;
  l_eb_date loadslip_inv_header.e_way_bill_date%type;
  procedure invoke_eb_service
  as
  begin
    -- Create the XML as SQL
    l_xml := atl_util_pkg.sql2xml(l_sql_string);
    -- Transform XML using SAP XSL (Build SOAP envelope)
    l_eb_xml := l_xml.transform(xmltype(atl_util_pkg.get_sap_ewaybill_stylesheet));
    -- dbms_output.put_line('Request XML '||l_eb_xml.getClobVal());
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_eb_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'E-WayBill', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_ewaybill,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_eb_xml.getclobval(), p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
    -- dbms_output.put_line('Response XML ' || l_xml.getClobVal());
  
    
  end;
 procedure updt_details_on_ls
  as
  begin
    -- Convert XML CLOB to JSON CLOB
    l_json_data:= atl_util_pkg.xml_to_json(l_xml.getclobval());
    -- dbms_output.put_line('JSON Data :' || l_json_data);
    -- parsing json data
    l_json_obj              := json_object_t(l_json_data);
    l_json_obj              := l_json_obj.get_object('SOAP:Envelope');
    l_json_obj              := l_json_obj.get_object('SOAP:Body');
    l_json_obj              := l_json_obj.get_object('EwayBillResp');
    
    if l_json_obj is not null then
    l_inv_linedetail_arr    := l_json_obj.get_array('InvoiceDetails');
    if l_inv_linedetail_arr is not null then
      --dbms_output.put_line('Invoice line Details object Exists');
      for j in 0 .. l_inv_linedetail_arr.get_size - 1
      loop
        l_json_obj := treat(l_inv_linedetail_arr.get(j)
      as
        json_object_t);
        l_inv_id  := l_json_obj.get_string('InvoiceID');
        l_eb_no   := l_json_obj.get_string('EwayBillNumber');
        l_eb_date := l_json_obj.get_string('EwayBillDate');
        --dbms_output.put_line('Il_inv_id '||l_inv_id);
        if l_loadslip_type not in ('FGS_EXP','JIT_OEM') then
          update loadslip_inv_header
          set e_way_bill_no    = l_eb_no,
            e_way_bill_date    = l_eb_date,
            update_user        = 'INTEGRATION',
            update_date        = sysdate
          where invoice_number = l_inv_id;
        else
          update del_inv_header
          set e_way_bill_no    = l_eb_no,
            e_way_bill_date    = l_eb_date,
            update_user        = 'INTEGRATION',
            update_date        = sysdate
          where invoice_number = l_inv_id;
        end if;
      end loop;
    else
      --dbms_output.put_line('Invoice line Array not Exists');
      l_json_obj := l_json_obj.get_object('InvoiceDetails');
      l_inv_id   := l_json_obj.get_string('InvoiceID');
      l_eb_no    := l_json_obj.get_string('EwayBillNumber');
      l_eb_date  := l_json_obj.get_string('EwayBillDate');
      --dbms_output.put_line('Il_inv_id '||l_inv_id);
      if l_loadslip_type not in ('FGS_EXP','JIT_OEM') then
        update loadslip_inv_header
        set e_way_bill_no    = l_eb_no,
          e_way_bill_date    = l_eb_date,
          update_user        = 'INTEGRATION',
          update_date        = sysdate
        where invoice_number = l_inv_id;
      else
        update del_inv_header
        set e_way_bill_no    = l_eb_no,
          e_way_bill_date    = l_eb_date,
          update_user        = 'INTEGRATION',
          update_date        = sysdate
        where invoice_number = l_inv_id;
      end if;
    end if;
    
    end if;
    -- Details updated successfully
    commit;
    if l_loadslip_type not in ('FGS_EXP','JIT_OEM') then
      update loadslip a
      set a.e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from loadslip_inv_header
        where loadslip_id=a.loadslip_id
        ),
        a.e_way_bill_date =
        (select max(e_way_bill_date)
        from loadslip_inv_header
        where loadslip_id=a.loadslip_id
        )
      where a.loadslip_id = p_loadslip_id;
      update truck_reporting a
      set e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from loadslip_inv_header
        where loadslip_id=p_loadslip_id
        ),
        e_way_bill_date = (select max(e_way_bill_date)
        from loadslip_inv_header
        where loadslip_id=p_loadslip_id
        )
      where a.gate_control_code =
        (select gate_control_code
        from truck_reporting
        where shipment_id =
          (select shipment_id from loadslip where loadslip_id = p_loadslip_id
          )
        and truck_number       = a.truck_number
        and reporting_location =
          (select source_loc from loadslip where loadslip_id = p_loadslip_id
          )
        )
      and a.shipment_id =
        (select shipment_id from loadslip where loadslip_id = p_loadslip_id
        ) ;
    else
      update loadslip a
      set a.e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from del_inv_header
        where loadslip_id=a.loadslip_id
        ),
        a.e_way_bill_date =
        (select max(e_way_bill_date)
        from del_inv_header
        where loadslip_id=a.loadslip_id
        )
      where a.loadslip_id = p_loadslip_id;
      update truck_reporting a
      set e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from del_inv_header
        where loadslip_id=p_loadslip_id
        ),
        e_way_bill_date =
        (select max(e_way_bill_date)
        from del_inv_header
        where loadslip_id=p_loadslip_id
        )
      where a.gate_control_code =
        (select gate_control_code
        from truck_reporting
        where shipment_id =
          (select shipment_id from loadslip where loadslip_id = p_loadslip_id
          )
        and truck_number       = a.truck_number
        and reporting_location =
          (select source_loc from loadslip where loadslip_id = p_loadslip_id
          )
        )
      and a.shipment_id =
        (select shipment_id from loadslip where loadslip_id = p_loadslip_id
        ) ;
    end if;
    commit;
    
    -- Update integration table with status PROCESSED
    update integration_log
      set status    ='PROCESSED',
        update_user = 'INTEGRATION',
        update_date = sysdate
      where id      = p_int_seq;
    commit;
    
  end;
begin
  -- Check if loadslip is valid
  select count(1)
  into l_cnt
  from loadslip
  where loadslip_id = p_loadslip_id;
  if l_cnt         <> 0 then
    -- Check type of loadslip
    select nvl(loadslip_type,'NA')
    into l_loadslip_type
    from loadslip
    where loadslip_id =p_loadslip_id;
    -- Check if invoices linked to loadslip
    select count(1)
    into l_cnt
    from loadslip
    where loadslip_id = p_loadslip_id
    and sap_invoice  is not null;
    if l_cnt         <> 0 then
      if l_loadslip_type not in ('FGS_EXP','JIT_OEM') then
        -- Fetch all invoices of loadslip and send to SAP for quering E-Waybill details
        -- Build data query
        l_sql_string := 'select a.loadslip_id,                                          
                          cursor (select invoice_number                        
                          from loadslip_inv_header where loadslip_id = a.loadslip_id) as inv_details                       
                          from loadslip a where a.loadslip_id='||''''||p_loadslip_id||'''';
        -- Invoice E-WayBill Integration
        invoke_eb_service;
        -- Update details on Loadslip Invoice tables
        updt_details_on_ls;
      else
        -- dbms_output.put_line('Export or JIT Case');
        -- Fetch all invoices of loadslip and send to SAP for quering E-Waybill details
        -- Build data query
        l_sql_string := 'select a.loadslip_id,                                          
                          cursor (select invoice_number                        
                          from del_inv_header where loadslip_id = a.loadslip_id) as inv_details                       
                          from loadslip a where a.loadslip_id='||''''||p_loadslip_id||'''';
        -- Invoice E-WayBill Integration
        invoke_eb_service;
        -- Update details on Loadslip Invoice tables
        updt_details_on_ls;
      end if;
      -- else
      -- dbms_output.put_line('No invoices linked to loadslip to fetch details');
    end if;
    --else
    -- dbms_output.put_line('Invalid loadslip');
  end if;
  exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('E-WayBill',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    commit;
    raise;
end;

procedure send_ship_ls_details(
      p_shipment_id varchar2)
  as
    l_sql_string varchar2(2000);
    l_xml xmltype;
    l_ship_ls_xml xmltype;
    --l_int_num number := integration_seq.nextval;
    l_result        varchar2(100);
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
    l_int_num    NUMBER := integration_seq.nextval;
  begin
    -- Build data query
    l_sql_string := 'select a.shipment_id,
                      cursor(select loadslip_id,so_sto_num,invoice_number 
                      from del_inv_header where shipment_id = a.shipment_id) as passlsline
                      from shipment a where a.shipment_id='||''''||p_shipment_id||'''';
    -- Create the XML as SQL
    l_xml := atl_util_pkg.sql2xml(l_sql_string);
    -- Transform XML using SAP XSL (Build SOAP envelope)
    l_ship_ls_xml := l_xml.transform(xmltype(atl_util_pkg.get_sap_ship_ls_stylesheet));
    -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_ship_ls_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'ShipmentLoadslipUpdate', p_status => 'PROCESSED', p_insert_user => 'INTEGRATION', p_int_num => l_int_num);
    -- Get the XML response from the web service.
    l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_ship_ls_updt,
    --p_action            => 'http://sap.com/xi/WebService/soap1.1',
    p_envelope => l_ship_ls_xml.getclobval(), p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
    -- Display the whole SOAP document returned.
     DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
    -- Pull out the specific value of interest.
    -- l_result := apex_web_service.parse_xml( p_xml => l_xml, p_xpath => '//ns1:STO_Resp_In/DATA/ORDER_ID/text()', p_ns => 'xmlns:ns1="http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM"');
    --DBMS_OUTPUT.put_line('l_result=' || l_result);
    exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('ShipmentLoadslipUpdate',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = l_int_num;
    commit;
    raise;
  end;

procedure fetch_ewb_from_sap 
as
l_xml xmltype;
l_eb_xml xmltype;
l_int_num       number := integration_seq.nextval;
l_json_data clob;
l_ls_id loadslip.loadslip_id%type;
l_int_error_seq number;
l_err_num       number;
l_err_msg       varchar2(4000);
l_json_obj json_object_t;
l_inv_line_obj json_object_t;
l_inv_linedetail_arr json_array_t;
l_inv_id varchar2(100);
l_loadslip_type loadslip.loadslip_type%type;
l_eb_no loadslip_inv_header.e_way_bill_no%type;
l_eb_date loadslip_inv_header.e_way_bill_date%type;
begin
  
  -- Create the XML as SQL
  l_xml := atl_util_pkg.sql2xml('select a.invoice_number from loadslip_inv_header a where exists 
                                (select 1 from loadslip where loadslip_id = a.loadslip_id and e_way_bill_no is null) 
                                and trunc(a.insert_date) >= trunc(sysdate-2)
                                union all
                                select a.invoice_number from del_inv_header a where exists 
                                (select 1 from loadslip where loadslip_id = a.loadslip_id and e_way_bill_no is null) 
                                and trunc(a.insert_date) >= trunc(sysdate-2)');
  
  -- Transform XML using SAP XSL (Build SOAP envelope)
  l_eb_xml := l_xml.transform(xmltype(atl_util_pkg.get_sap_ewaybill_stylesheet_s));
  
  -- insert into integration log table
  atl_util_pkg.insert_integration_log(p_json_data => l_eb_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'SAP', p_api_name => 'E-WayBill', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => l_int_num);
  
  -- Get the XML response from the web service.
  l_xml := apex_web_service.make_request( p_url => atl_app_config.c_sap_ewaybill,
  --p_action            => 'http://sap.com/xi/WebService/soap1.1',
  p_envelope => l_eb_xml.getclobval(), p_username => atl_app_config.c_sap_pi_username, p_password => atl_app_config.c_sap_pi_password);
  -- Display the whole SOAP document returned.
  -- dbms_output.put_line('Response XML ' || l_xml.getClobVal());
  
  -- Convert XML CLOB to JSON CLOB
    l_json_data:= atl_util_pkg.xml_to_json(l_xml.getclobval());
    -- dbms_output.put_line('JSON Data :' || l_json_data);
    -- parsing json data
    l_json_obj              := json_object_t(l_json_data);
    l_json_obj              := l_json_obj.get_object('SOAP:Envelope');
    l_json_obj              := l_json_obj.get_object('SOAP:Body');
    l_json_obj              := l_json_obj.get_object('EwayBillResp');
    
    if l_json_obj is not null then   
    l_inv_linedetail_arr    := l_json_obj.get_array('InvoiceDetails');
    if l_inv_linedetail_arr is not null then
     -- dbms_output.put_line('Invoice line Details object Exists');
      for j in 0 .. l_inv_linedetail_arr.get_size - 1
      loop
        l_json_obj := treat(l_inv_linedetail_arr.get(j)
      as
        json_object_t);
        l_inv_id  := l_json_obj.get_string('InvoiceID');
        l_eb_no   := l_json_obj.get_string('EwayBillNumber');
        l_eb_date := l_json_obj.get_string('EwayBillDate');
        --dbms_output.put_line('Il_inv_id '||l_inv_id);
        
        select (select nvl(loadslip_type,'NA')
        from loadslip
        where loadslip_id = (select loadslip_id from 
        del_inv_header where invoice_number=l_inv_id and rownum=1)
        union 
        select nvl(loadslip_type,'NA')
        from loadslip
        where loadslip_id = (select loadslip_id from 
        loadslip_inv_header where invoice_number=l_inv_id and rownum=1))
        into l_loadslip_type
        from dual;
        
        
        if l_loadslip_type not in ('FGS_EXP','JIT_OEM') then
        
        select loadslip_id 
        into l_ls_id
        from loadslip_inv_header where invoice_number = l_inv_id and rownum=1;
        
          update loadslip_inv_header
          set e_way_bill_no    = l_eb_no,
            e_way_bill_date    = l_eb_date,
            update_user        = 'INTEGRATION',
            update_date        = sysdate
          where invoice_number = l_inv_id;
          commit;
          
          update loadslip a
          set a.e_way_bill_no =
            (select listagg(e_way_bill_no,'|') within group (
            order by e_way_bill_no)
            from loadslip_inv_header
            where loadslip_id=a.loadslip_id
            ),
            a.e_way_bill_date =
            (select max(e_way_bill_date)
            from loadslip_inv_header
            where loadslip_id=a.loadslip_id
            )
          where a.loadslip_id = l_ls_id;
          
          update truck_reporting a
      set e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from loadslip_inv_header
        where loadslip_id=l_ls_id
        ),
        e_way_bill_date =
            (select max(e_way_bill_date)
            from loadslip_inv_header
            where loadslip_id=l_ls_id
            )
      where a.gate_control_code =
        (select gate_control_code
        from truck_reporting
        where shipment_id =
          (select shipment_id from loadslip where loadslip_id = l_ls_id
          )
        and truck_number       = a.truck_number
        and reporting_location =
          (select source_loc from loadslip where loadslip_id = l_ls_id
          )
        )
      and a.shipment_id =
        (select shipment_id from loadslip where loadslip_id = l_ls_id
        ) ;
          
        else
        
        select loadslip_id 
        into l_ls_id
        from del_inv_header where invoice_number = l_inv_id and rownum=1;
        
          update del_inv_header
          set e_way_bill_no    = l_eb_no,
            e_way_bill_date    = l_eb_date,
            update_user        = 'INTEGRATION',
            update_date        = sysdate
          where invoice_number = l_inv_id;
          commit;
          
          update loadslip a
      set a.e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from del_inv_header
        where loadslip_id=a.loadslip_id
        ),
        a.e_way_bill_date =
        (select max(e_way_bill_date)
        from del_inv_header
        where loadslip_id=a.loadslip_id
        )
      where a.loadslip_id = l_ls_id;
      update truck_reporting a
      set e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from del_inv_header
        where loadslip_id=l_ls_id
        ),
        e_way_bill_date =
        (select max(e_way_bill_date)
        from del_inv_header
        where loadslip_id=l_ls_id
        )
      where a.gate_control_code =
        (select gate_control_code
        from truck_reporting
        where shipment_id =
          (select shipment_id from loadslip where loadslip_id = l_ls_id
          )
        and truck_number       = a.truck_number
        and reporting_location =
          (select source_loc from loadslip where loadslip_id = l_ls_id
          )
        )
      and a.shipment_id =
        (select shipment_id from loadslip where loadslip_id = l_ls_id
        ) ;
        
        end if;
      end loop;
    else
     -- dbms_output.put_line('Invoice line Array not Exists');
      l_json_obj := l_json_obj.get_object('InvoiceDetails');
      l_inv_id   := l_json_obj.get_string('InvoiceID');
      l_eb_no    := l_json_obj.get_string('EwayBillNumber');
      l_eb_date  := l_json_obj.get_string('EwayBillDate');
     -- dbms_output.put_line('l_eb_no '||l_eb_no);
      
      select (select nvl(loadslip_type,'NA')
        from loadslip
        where loadslip_id = (select loadslip_id from 
        del_inv_header where invoice_number=l_inv_id and rownum=1)
        union 
        select nvl(loadslip_type,'NA')
        from loadslip
        where loadslip_id = (select loadslip_id from 
        loadslip_inv_header where invoice_number=l_inv_id and rownum=1))
        into l_loadslip_type
        from dual;
      --dbms_output.put_line('l_loadslip_type '||l_loadslip_type);
      if l_loadslip_type not in ('FGS_EXP','JIT_OEM') then
      
       select loadslip_id 
        into l_ls_id
        from loadslip_inv_header where invoice_number = l_inv_id and rownum=1;
      
        update loadslip_inv_header
        set e_way_bill_no    = l_eb_no,
          e_way_bill_date    = l_eb_date,
          update_user        = 'INTEGRATION',
          update_date        = sysdate
        where invoice_number = l_inv_id;
        update loadslip a
          set a.e_way_bill_no =
            (select listagg(e_way_bill_no,'|') within group (
            order by e_way_bill_no)
            from loadslip_inv_header
            where loadslip_id=a.loadslip_id
            ),
            a.e_way_bill_date =
            (select max(e_way_bill_date)
            from loadslip_inv_header
            where loadslip_id=a.loadslip_id
            )
          where a.loadslip_id = l_ls_id;
          
          update truck_reporting a
      set e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from loadslip_inv_header
        where loadslip_id=l_ls_id
        ),
        e_way_bill_date =
            (select max(e_way_bill_date)
            from loadslip_inv_header
            where loadslip_id=l_ls_id
            )
      where a.gate_control_code =
        (select gate_control_code
        from truck_reporting
        where shipment_id =
          (select shipment_id from loadslip where loadslip_id = l_ls_id
          )
        and truck_number       = a.truck_number
        and reporting_location =
          (select source_loc from loadslip where loadslip_id = l_ls_id
          )
        )
      and a.shipment_id =
        (select shipment_id from loadslip where loadslip_id = l_ls_id
        ) ;
      else
      select loadslip_id 
        into l_ls_id
        from del_inv_header where invoice_number = l_inv_id and rownum=1;
        
        update del_inv_header
        set e_way_bill_no    = l_eb_no,
          e_way_bill_date    = l_eb_date,
          update_user        = 'INTEGRATION',
          update_date        = sysdate
        where invoice_number = l_inv_id;
        
        update loadslip a
      set a.e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from del_inv_header
        where loadslip_id=a.loadslip_id
        ),
        a.e_way_bill_date =
        (select max(e_way_bill_date)
        from del_inv_header
        where loadslip_id=a.loadslip_id
        )
      where a.loadslip_id = l_ls_id;
      update truck_reporting a
      set e_way_bill_no =
        (select listagg(e_way_bill_no,'|') within group (
        order by e_way_bill_no)
        from del_inv_header
        where loadslip_id=l_ls_id
        ),
        e_way_bill_date =
        (select max(e_way_bill_date)
        from del_inv_header
        where loadslip_id=l_ls_id
        )
      where a.gate_control_code =
        (select gate_control_code
        from truck_reporting
        where shipment_id =
          (select shipment_id from loadslip where loadslip_id = l_ls_id
          )
        and truck_number       = a.truck_number
        and reporting_location =
          (select source_loc from loadslip where loadslip_id = l_ls_id
          )
        )
      and a.shipment_id =
        (select shipment_id from loadslip where loadslip_id = l_ls_id
        ) ;
        
      end if;
    end if;
    -- Details updated successfully
    commit;
    
    end if;
   -- commit;
    
    -- Update integration table with status PROCESSED
    update integration_log
      set status    ='PROCESSED',
        update_user = 'INTEGRATION',
        update_date = sysdate
      where id      = l_int_num;
    commit;
 exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('E-WayBill',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = l_int_num;
    commit;
    raise;   
  
end;
  
  procedure make_request(
      p_att1 varchar2,
      p_att2 number,
      p_att3 varchar2)
  as
    l_job_id varchar2(100) := 'JOB'||to_char(sysdate,'ddmmyyhh24miss');
    l_loadslip_type loadslip.loadslip_type%type;
    l_so_sto_type order_type_lookup.sap_order_type%type;
    l_sap_doc_type order_type_lookup.sap_doc_type%type;
  begin
  if p_att3 = 'SO-STO' then
    select nvl(loadslip_type,'NA')
    into l_loadslip_type
    from loadslip
    where loadslip_id=p_att1;
    select nvl(
      (select sap_order_type
      from order_type_lookup
      where order_type=l_loadslip_type
      ),'NA')
    into l_so_sto_type
    from dual;
    if l_so_sto_type  <> 'NA' then
    
    --if l_sap_doc_type <> 'NA' then
    
      if l_so_sto_type = 'STO' then
      insert_loadslip_lines(p_att1);
        dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_sap_integration_pkg.send_loadslip_to_sap_sto('''||p_att1||''','||p_att2||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '5' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
      else
      insert_loadslip_lines(p_att1);
        dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_sap_integration_pkg.send_loadslip_to_sap_so('''||p_att1||''','||p_att2||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '5' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
      end if;
    -- end if; 
    else
      null;
    end if;
  
  elsif p_att3 = 'BARCODE' then
  insert_loadslip_lines(p_att1);
    dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_sap_integration_pkg.send_barcode_data_to_sap('''||p_att1||''','||p_att2||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '5' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
  elsif p_att3 = 'SO-STO-DEL' then
  
    dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_sap_integration_pkg.send_so_sto_del_req('''||p_att1||''','||p_att2||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '5' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
  elsif p_att3 = 'EWAY-BILL' then
  
    dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_sap_integration_pkg.get_eway_bill_details('''||p_att1||''','||p_att2||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '5' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
    elsif p_att3 = 'SHIP-LS-UPDT' then
    
    dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_sap_integration_pkg.send_ship_ls_details('''||p_att1||''');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '5' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
    
  end if;    
  end;
end atl_sap_integration_pkg;

/
