--------------------------------------------------------
--  DDL for Package ATL_ATOM_API
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_ATOM_API" authid definer as 

/* 
  Purpose:        PaaS Objects API 
  Remarks:       
  Who             Date            Description
  ------          ----------      ----------------------------------------------
  Akshay Thakur   21-MAR-2020     Initial 
  Akshay Thakur   02-APR-2020     New function added is_duplicate to check data
                                  uploaded from Macro is already exists.
                                  If yes then ignore else insert.

*/

  procedure create_paas_shipment(p_int_seq number);
  function get_item_wt_vol (p_item_id varchar2,p_source_loc varchar2,p_type varchar2) 
  return number;
  function get_ship_stop_type (p_shipment_id number) return varchar2;
  procedure process_request(p_att1 varchar2,p_att2 number);
  function is_duplicate(p_shipment_id varchar2) return boolean;
end atl_atom_api;

/
