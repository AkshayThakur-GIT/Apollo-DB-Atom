--------------------------------------------------------
--  DDL for Package ATL_ACTUAL_SHIP_INT_API
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_ACTUAL_SHIP_INT_API" as 

/* 
  Purpose:        OTM Actual Shipment API 
  Remarks:        
  Who             Date            Description
  ------          -----------      ----------------------------------------------
  Akshay Thakur   31-JAN-2019     Created  
  
*/
--==============================================================================
  
  function get_as_stylesheet(p_type varchar2) return clob;  
  function build_exp_sql(p_ship_id varchar2) return clob;
  function build_jit_sql(p_ship_id varchar2) return clob;
  function build_sql(p_ship_id varchar2) return clob;
  
  function get_shipment_details(p_shipment_id varchar2) return ship_details pipelined;
  procedure process_shipment(p_shipment_id in varchar2,
                             p_loadslip_type in varchar2,
                             p_instance varchar2, 
                             p_int_seq in number);
  function get_ship_stop_details(
    p_shipment_id  varchar2,
    p_truck_number varchar2,
    p_stop_num     number,
    p_stop_type    varchar2,
    p_loadslip_id  varchar2,
    p_type         varchar2)
  return ship_stop_details_list pipelined;
  
  function get_exp_ship_details(
    p_shipment_id varchar2)
  return exp_ship_tab pipelined;
  
  function get_tyre_id(
    p_loadslip_id varchar2,
    p_item_id varchar2)
  return varchar2;
                             
  procedure make_request(p_att1 varchar2,p_att2 number);
  
end atl_actual_ship_int_api;

/
