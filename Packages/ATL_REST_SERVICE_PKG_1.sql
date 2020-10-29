--------------------------------------------------------
--  DDL for Package Body ATL_REST_SERVICE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_REST_SERVICE_PKG" 
as
  procedure rest_service(
      p_data         in blob,
      p_api_auth     in varchar2,
      p_content_type in varchar2,
      p_api_name     in varchar2,
      p_int_name     in varchar2,
      p_int_seq      in number,
      p_is_valid out nocopy    varchar2,
      p_resp_string out nocopy varchar2,
      p_status out nocopy      number)
  as
    l_api_name varchar2(50) := p_api_name;
    l_clob clob;
    l_json_data clob;
    l_err_num       number;
    l_err_msg       varchar2(100);
    l_int_error_seq number;
  begin
    if p_content_type not in ('application/xml','application/json','text/xml') then
      p_status      := 400;
      p_resp_string := '<Response>Wrong Content Type</Response>';
      p_is_valid    := 'N';
      return;
    end if;
    if atl_util_pkg.is_valid_auth(p_api_auth) = 'VALID' then
      -- Convert BLOB to CLOB
      l_clob := atl_util_pkg.blob_to_clob(p_data);
      -- insert into integration log table
      atl_util_pkg.insert_integration_log(p_json_data => l_clob, p_int_in_out => 'Y', p_interface_name => p_int_name, p_api_name => l_api_name, p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
      -- Convert XML CLOB to JSON CLOB
        l_json_data:= atl_util_pkg.xml_to_json(l_clob);
      --l_json_data:= to_clob(atl_util_pkg.xmltojson(l_clob));
      -- Actual Interface calling API
      -- Start
      if p_int_name = 'ItemMaster' then
        /* API Name:
        Item Master : /apollo/api/syncItemMaster
        */
        atl_integration_pkg.sync_item_master(l_json_data);
      elsif p_int_name = 'WTMasterPW' then
        /* API Name:
        Item Master (Plant Wise) : /apollo/api/syncWTMasterPW
        */
        atl_integration_pkg.sync_item_master(l_json_data,'P');
      elsif p_int_name = 'LocationMaster' then
        /* API Name:
        Location Master : /apollo/api/syncLocationMaster
        */
        atl_integration_pkg.sync_location_master(l_json_data);
      elsif p_int_name = 'TransporterMaster' then
        /* API Name:
        Transporter Master : /apollo/api/syncTransportermaster
        */
        atl_integration_pkg.sync_transporter_master(l_json_data);
      elsif p_int_name = 'InvoiceResponse' then
        /* API Name:
        Invoice Response : /apollo/api/updateInvResp
        */
        atl_integration_pkg.updt_inv_response(l_json_data);
      elsif p_int_name = 'GRNResponse' then
        /* API Name:
        GRN Response : /apollo/api/updateGRNResp
        */
        atl_integration_pkg.updt_grn_response(l_json_data);
       elsif p_int_name = 'SOGRNResponse' then
        /* API Name:
        SOGRN Response : /apollo/api/updateSOGRNResp
        */
        atl_integration_pkg.updt_so_grn_response(l_json_data);
      elsif p_int_name = 'DSResp' then
        /* API Name:
        DIT/Shortage Response : /apollo/api/updateDSResp
        */
        atl_integration_pkg.updt_ds_response(l_json_data);
      elsif p_int_name = 'BarcodeResponse' then
        /* API Name:
        Barcode Response : /apollo/api/updateBarcodeResp
        */
        atl_integration_pkg.updt_barcode_response(l_json_data);
      elsif p_int_name = 'UpdateShipments' then
        /* API Name:
        OE Shipments Response : /apollo/api/uploadShipmentsData
        */
        update_shipments(l_json_data);
      elsif p_int_name = 'UploadPaaSShipment' then
        /* API Name:
        Upload Shipments : /apollo/api/uploadPaaSShipment
        */
        insert into xx_json_document (id,json_data) values (p_int_seq,l_json_data);
        commit;
        atl_atom_api.process_request('Shipment',p_int_seq);
      end if;      
      -- End
      p_status      := 200;
      p_is_valid    := 'Y';
      p_resp_string := return_int_msg('SUCCESS',p_content_type,null,null,p_int_seq) ;
      update integration_log
      set status    ='PROCESSED',
        update_user = 'INTEGRATION',
        update_date = sysdate
      where id      = p_int_seq;
    else
      p_status      := 401;
      p_is_valid    := 'N';
      p_resp_string := return_int_msg('ERROR',p_content_type,null,null,0) ;
      return;
    end if;
    commit;
  exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error(p_api_name,l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    commit;
    raise;
  end;
  function return_int_msg(
      p_status     in varchar2,
      p_con_type   in varchar2,
      p_error_code in varchar2 default null,
      p_error_msg  in varchar2 default null,
      p_int_no     in number)
    return varchar2
  as
    l_string varchar2(2000);
  begin
    if p_con_type in ('application/json') then    
      if p_status = 'SUCCESS' then
        l_string := '{
              "IntegrationResponse": {
                "ResponseNumber": "'||p_int_no||'",
                "ReponseStatus": "'||p_status||'",
                "ErrorDetails": {
                  "ErrorCode": "",
                  "ErrorMessage": ""
                    }
                  }
                }';
     
     else
     l_string := '{
              "IntegrationResponse": {
                "ResponseNumber": "'||p_int_no||'",
                "ReponseStatus": "'||p_status||'",
                "ErrorDetails": {
                  "ErrorCode": "'||p_error_code||'",
                  "ErrorMessage": "'||p_error_msg||'"
                    }
                  }
                }';
      end if;    
    elsif p_con_type in ('application/xml','text/xml') then    
    if p_status = 'SUCCESS' then
        l_string := '<IntegrationResponse>
                      <ResponseNumber>'||p_int_no||'</ResponseNumber>
                      <ReponseStatus>'||p_status||'</ReponseStatus>
                      <ErrorDetails>
                        <ErrorCode></ErrorCode>
                        <ErrorMessage></ErrorMessage>
                      </ErrorDetails>
                    </IntegrationResponse>';
     
     else
     l_string := '<IntegrationResponse>
                      <ResponseNumber>'||p_int_no||'</ResponseNumber>
                      <ReponseStatus>'||p_status||'</ReponseStatus>
                      <ErrorDetails>
                        <ErrorCode>'||p_error_code||'</ErrorCode>
                        <ErrorMessage>'||p_error_msg||'</ErrorMessage>
                      </ErrorDetails>
                    </IntegrationResponse>';
      end if;      
    end if;
    return l_string;
  end;
end atl_rest_service_pkg;

/
