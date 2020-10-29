--------------------------------------------------------
--  DDL for Package ATL_SAP_INTEGRATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_SAP_INTEGRATION_PKG" authid current_user as 

/* 
  Purpose:        SAP Integration API 
  Remarks:        
  Who             Date            Description
  ------          ----------      ----------------------------------------------
  Akshay Thakur   21-OCT-2018     Created
 
*/

  procedure send_loadslip_to_sap_sto(p_ls_id varchar2,p_int_seq in number);
  procedure send_loadslip_to_sap_sto(p_ls_id varchar2,p_int_seq in number,p_status out varchar2);
  procedure send_loadslip_to_sap_so(p_ls_id varchar2,p_int_seq in number);
  procedure send_loadslip_to_sap_so(p_ls_id varchar2,p_int_seq in number,p_status out varchar2);
  procedure insert_loadslip_lines(p_ls_id varchar2);
  procedure send_barcode_data_to_sap(p_ls_id varchar2,p_int_seq in number);
  procedure send_so_sto_del_req(p_ls_id varchar2,p_int_seq in number);
  procedure send_so_sto_del_req(p_ls_id varchar2,p_int_seq in number,p_status out varchar2);
  procedure get_eway_bill_details(p_loadslip_id varchar2,p_int_seq in number);
  procedure send_ship_ls_details(p_shipment_id varchar2);
  procedure fetch_ewb_from_sap;
  procedure make_request(p_att1 varchar2,p_att2 number,p_att3 varchar2);

end atl_sap_integration_pkg;

/
