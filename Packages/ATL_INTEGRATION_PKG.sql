--------------------------------------------------------
--  DDL for Package ATL_INTEGRATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_INTEGRATION_PKG" authid current_user as  

/* 
  Purpose:        Integration API 
  Remarks:        
  Who             Date            Description
  ------          ----------      ----------------------------------------------
  Akshay Thakur   15-SEP-2018     Created
  Akshay Thakur   16-SEP-2018     New API added for plant wise item integration
  Akshay Thakur   05-OCT-2018     New API added for sending data to OTM
                                  Name: post_to_otm
  Akshay Thakur   16-OCT-2018     New API added for Invoice response integration
                                  Name: updt_inv_response
  Akshay Thakur   17-OCT-2018     Support of JSON_TABLE added for reading data
                                  from json document
  
*/

--==============================================================================
-- This procedure allows for integrating Item Master data
-- Name: sync_item_master
-- Arguments:
--    p_data      = Valid CLOB data in XML format
--
-- Example: 
-- begin atl_integration_pkg.sync_item_master(p_data); end;
--==============================================================================
  procedure sync_item_master(p_data in clob);
  
--==============================================================================
-- This procedure allows for integrating Weight Master data Plant wise
-- Name: sync_item_master
-- Arguments:
--    p_data      = Valid CLOB data in JSON format
--    p_type      = Identifier to overload this function, 'P' to indicate it is
--                  weight master integration plant wise
--
-- Example: 
-- begin atl_integration_pkg.sync_item_master(p_data,'P'); end;
--==============================================================================  
  procedure sync_item_master(p_data in clob,p_type in varchar2);
  
--==============================================================================
-- This procedure allows for integrating location Master data
-- Name: sync_location_master
-- Arguments:
--    p_data      = Valid CLOB data in JSON format
--
-- Example: 
-- begin atl_integration_pkg.sync_location_master(p_data); end;
--==============================================================================  
  procedure sync_location_master(p_data in clob);
  
--==============================================================================
-- This procedure allows for integrating Transporter Master data
-- Name: sync_location_master
-- Arguments:
--    p_data      = Valid CLOB data in JSON format
--
-- Example: 
-- begin atl_integration_pkg.sync_transporter_master(p_data); end;
--==============================================================================  
  procedure sync_transporter_master(p_data in clob);

--==============================================================================
-- This procedure allows for integrating invoice details from SAP to PaaS
-- Name: updt_inv_response
-- Arguments:
--    p_data      = Valid CLOB data in XML format
--
-- Example: 
-- begin atl_integration_pkg.updt_inv_response(p_data); end;
--==============================================================================
  procedure updt_inv_response(p_data in clob);
  
  procedure updt_barcode_response(p_data in clob);
  
  procedure updt_grn_response(p_data in clob);
  
  procedure updt_so_grn_response(p_data in clob);
  
  procedure updt_ds_response(p_data in clob);
  
  procedure close_pass_shipment(p_shipment_id varchar2, p_loadslip_id varchar2);
  
  function is_grn_complete(p_loadslip_id varchar2) return varchar2;

--==============================================================================
-- This procedure allows for data integration with OTM application
-- Name: post_to_otm
-- Arguments:
--    p_data          = Valid CLOB data in XML format
--    p_instance      = Valid Instance Type. DEV/TEST/PROD
--    p_response_code = Returns OTM Response code
--
-- Example:
--   declare
--      l_xml_resp number; 
--      l_clob clob := '<?xml version="1.0" encoding="utf-8"?>
--    <Transmission>
--      <TransmissionHeader></TransmissionHeader>
--      <TransmissionBody>
--        <GLogXMLElement>
--          <ItemMaster>
--            <Item>
--              <TransactionCode>NP</TransactionCode>
--              <ItemGid>
--                <Gid>
--                  <DomainName>ATL</DomainName>
--                  <Xid>RLGIK0APT9AS1</Xid>
--                </Gid>
--              </ItemGid>
--              <ItemName>RLGIK0APT9AS1</ItemName>
--              <Description>235/65 R17 104S APTERRA AT TL-D</Description>                  
--            </Item>        
--          </ItemMaster>
--        </GLogXMLElement>
--      </TransmissionBody>
--    </Transmission>';
--    begin
--        atl_integration_pkg.post_to_otm(p_data =>l_clob,
--                                        p_instance => 'DEV',
--                                        p_response_code => l_xml_resp);
--         
--        dbms_output.put_line('Response ID '||l_xml_resp);
--    end;
--==============================================================================  
  procedure post_to_otm(p_data in clob, 
                        p_instance varchar2, 
                        p_response_code out number);
  
--==============================================================================
-- This procedure allows for data integration with OTM application
-- Name: post_to_otm
-- Arguments:
--    p_data          = Valid CLOB data in XML format
--    p_stylesheet    = Valid Styleshet (fully compiled with no errors)--    
--    p_instance      = Valid Instance Type, DEV/TEST/PROD
--    p_response_code = Returns OTM Response code
--
-- Example:
--    declare
--      l_sql_string varchar2(2000);  
--      l_xml_resp number;
--      l_id number := 3000464;
--    begin
--      -- This SQL is for pushing transporter data to OTM
--      l_sql_string := 'select a.scac as sevprov_id,       
--                        a.transporter_desc as servprov_name,       
--                        a.transporter_address as servprov_add,       
--                        a.city as city,       
--                        a.state as state,       
--                        a.postal_code as postal_code,       
--                        a.country as country,       
--                        a.state_code as state_code,       
--                        a.industry_key as industry_key,       
--                        cursor(select b.contact_id,c.first_name,c.last_name,c.email,c.mobile       
--                        from mt_transporter_contact b, mt_contact c where        
--                        b.contact_id=c.contact_id and b.transporter_id=a.transporter_id) as contact_details
--                        from mt_transporter a where a.transporter_id='||l_id;      
--      atl_integration_pkg.post_to_otm(p_sql_string => l_sql_string,
--                                      p_stylesheet => atl_util_pkg.get_servprov_stylesheet,
--                                      p_instance => 'DEV', 
--                                      p_response_code => l_xml_resp);
--      dbms_output.put_line('Response ID '||l_xml_resp);
--    end;
--==============================================================================  
  procedure post_to_otm(p_sql_string in varchar2,
                        p_stylesheet in varchar2,
                        p_instance varchar2, 
                        p_response_code out number);
  
  procedure post_to_atom(p_loadslip_id varchar2,
                         p_inv_can_flag varchar2 default 'N',
                         p_invoice_number varchar2);
  
  function upd_loadslip_error (p_loadslip IN loadslip.loadslip_id%type) return varchar2;
  
end atl_integration_pkg;

/
