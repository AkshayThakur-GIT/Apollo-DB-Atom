--------------------------------------------------------
--  DDL for Package ATL_BUSINESS_FLOW_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_BUSINESS_FLOW_PKG" authid current_user as 

/* 
  Purpose:        Business flow logic 
  Remarks:        API for handling business flows 
  Who             Date            Description
  ------          ----------      -------------------------------------------------------------------
  Akshay Thakur   25-SEP-2018     Created 
  Akshay Thakur   27-SEP-2018     Added new function get_market_segment for deriving market segment
  Akshay Thakur   29-SEP-2018     Improvements added in upload_dispatch_plan by removing 
                                  APEX_JSON functionality for parsing and used native 
                                  support of PL/SQL Object Types for JSON parsing in Oracle 12c.
                                  Performance improvement gain is 50% more as comapared to APEX_JSON.
  Akshay Thakur   04-OCT-2018     Added new procedure for manual dispatch plan creation.
                                  procedure name: create_dispatch_plan_manual                                  
  Akshay Thakur   14-OCT-2018     Added new function for getting dispatch plan BOM details
                                  function name: get_disp_plan_bom_details   
                                  
  Aman Gumasta    27-JUN-2020     Used for calcultating the loadslip weight and volume                           
*/

--==============================================================================
-- This procedure allows for auto dispatch plan creation
-- Name: upload_dispatch_plan
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records 
--    p_tot_error_records = Return total error records from uploaded file
--    p_total_tyre_count  = Return sum of total quantity loaded in uploaded file 
--    p_XX_count          = Return count of various error checks as mentioned 
--                          below.
--                          -- C1: Check Locations Codes
--                          -- C2: Check for material code
--                          -- C3  Check for material TTE
--                          -- C4: Check for Item Category
--                          -- C5: Check for Batch Code
--                          -- C6: Check for duplicate records
--
-- Example:
-- set serveroutput on 
--      declare 
--          l_tot_records pls_integer;
--          l_tot_error_records pls_integer;
--          l_total_tyre_count pls_integer;
--          l_c1_count pls_integer;
--          l_c2_count pls_integer;
--          l_c3_count pls_integer;
--          l_c4_count pls_integer;
--          l_c5_count pls_integer;
--          l_c6_count pls_integer;
--          l_plan_id number;
--          l_plan_status varchar2(100);
--      begin
--      atl_business_flow_pkg.upload_dispatch_plan('1','planItems','SYSTEM',l_tot_records,l_tot_error_records,l_total_tyre_count,l_c1_count,
--                           l_c2_count,l_c3_count,l_c4_count,l_c5_count,l_c6_count,l_plan_id,l_plan_status);
--                           
--      dbms_output.put_line('-----Plan Summary------');
--      dbms_output.put_line('Status '||l_plan_status);
--      dbms_output.put_line('Plan ID '||l_plan_id);
--      dbms_output.put_line('Total records '||l_tot_records);
--      dbms_output.put_line('Total Tyre Count '||l_total_tyre_count);
--      dbms_output.put_line('Total error records '||l_tot_error_records);
--      dbms_output.put_line('Location Code missing '||l_c1_count);
--      dbms_output.put_line('No SKU in master '||l_c2_count);
--      dbms_output.put_line('TTE not available '||l_c3_count);
--      dbms_output.put_line('No Material Group '||l_c4_count);
--      dbms_output.put_line('Wrong Batch Code '||l_c5_count);
--      dbms_output.put_line('Duplicate Records '||l_c6_count);
--      end; 
--==============================================================================  
 procedure upload_dispatch_plan(p_json_data clob,
                       p_root_element varchar2,
                       p_user         varchar2,
                       p_tot_records out number,
                       p_tot_error_records out number,
                       p_total_tyre_count out number,
                       p_c1_count out number,
                       p_c2_count out number,
                       p_c3_count out number,
                       p_c4_count out number,
                       p_c5_count out number,
                       p_c6_count out number,
                       p_plan_id out number,
                       p_plan_status out nocopy varchar2);
                       
--==============================================================================
-- This procedure allows for manual dispatch plan creation
-- Name: create_dispatch_plan_manual
-- Arguments:
--    p_disp_plan_id      = Valid Dispatch plan ID
--    p_user              = UI logged in USER ID
--
-- Example: 
-- begin atl_business_flow_pkg.create_dispatch_plan_manual(34588,'SYSTEM'); end;
--==============================================================================
  procedure create_dispatch_plan_manual(p_disp_plan_id in number, 
                                        p_user varchar2, 
                                        p_status out nocopy varchar2);  
  
--==============================================================================
-- This procedure allows for populating dispatch plan BOM
-- Name: insert_disp_plan_bom
-- Arguments:
--    p_disp_plan_id      = Valid Dispatch plan ID
--
-- Example: 
-- begin atl_business_flow_pkg.insert_disp_plan_bom(34588); end;
--==============================================================================
  procedure insert_disp_plan_bom(p_disp_plan_id in number);
                                       
  procedure cal_truck_summary;
  
--==============================================================================
-- This function returns uploaded dispatch plan summary
-- Name: get_disp_plan_summary
-- Arguments:
--    p_disp_plan_id      = Valid Dispatch plan ID
 
-- Example: 
-- select * from table (atl_business_flow_pkg.get_disp_plan_summary(34588)) 
--==============================================================================
  function get_disp_plan_summary(p_disp_plan_id in number)return disp_plan_summary_list pipelined;
   
--==============================================================================
-- This function returns marketing segment based on source and destination
-- Name: get_market_segment
-- Arguments:
--    p_source_loc_id      = Source location ID
--    p_dest_loc_id        = Destination location ID
--
-- Example: 
-- select atl_business_flow_pkg.get_market_segment ('1002','222') from dual
--==============================================================================  
  function get_market_segment(p_source_loc_id in varchar2,p_dest_loc_id in varchar2) return varchar2;

--==============================================================================
-- This function returns Dispatch plan BOM details
-- Name: get_disp_plan_summary
-- Arguments:
--    p_disp_plan_id      = Valid Dispatch plan ID
 
-- Example: 
-- select * from table (atl_business_flow_pkg.get_disp_plan_bom_details(39395)) 
--==============================================================================
  function get_disp_plan_bom_details(p_disp_plan_id in number)return disp_plan_bom_list pipelined;

  function get_order_type(p_source_loc varchar2,p_dest_loc   varchar2,p_item_id varchar2) return varchar2;
  
  function is_scannable (p_loc_id varchar2,p_item_category varchar2) return varchar2;
  
  function get_item_bom(p_item_id varchar2,p_source_loc varchar2,p_dest_loc varchar2) return item_bom_list;
  
  function get_sap_tt_code(p_shipment_id varchar2) return varchar2;
  
  procedure insert_shipment_stops(p_shipment_id varchar2,p_user_id varchar2);
  
  function get_truck_type_details(p_truck_type_id varchar2,p_variant_1 varchar2) return truck_type_list pipelined;
  
  function loadslip_dashboard(p_loadslip_id in varchar2) return ls_dashboard_list pipelined;
  
  function loadslip_dashboard_ui(p_loadslip_id in varchar2) return ls_dashboard_ui_list pipelined;
  
  procedure calc_truck_summary_delay;
  
  procedure upload_exp_shipments_data(p_file_data blob,p_user varchar2,p_result out nocopy varchar2);
  
  procedure process_data(p_file_id number);
  
  procedure sync_export_sh_to_otm;
  
  function get_item_wt_vol(p_item_id varchar2,p_mkt_segment varchar2,
                           p_source_loc varchar2,p_dest_loc varchar2,p_type varchar2) return number;
                           
  procedure dispatch_plan_notify (p_disp_plan_id number);
  
  procedure indent_notify(p_login_user varchar2,
                          p_indent_id varchar2,
                          p_eb clob,
                          p_att blob default null,
                          p_fn varchar2,
                          p_mimt varchar2,
                          p_status out nocopy varchar2);
  
  function get_valid_batch_location(p_location_id varchar2) return varchar2;
  
  procedure freight_approve_notify (p_tot_records number,p_approve_user varchar2);
  
--==============================================================================
-- This procedure allows for manual dispatch plan creation
-- Name: update_item_line
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records 
--    p_tot_error_records = Return total error records from uploaded file
--    p_total_tyre_count  = Return sum of total quantity loaded in uploaded file 
--    p_XX_count          = Return count of various error checks as mentioned 
--                          below.
--                          -- C1: Check Locations Codes
--                          -- C2: Check for material code
--                          -- C3  Check for material TTE
--                          -- C4: Check for Item Category
--                          -- C5: Check for Batch Code
--                          -- C6: Check for duplicate records
--==============================================================================

  /*procedure update_item_line(p_json_data clob,
                       p_root_element varchar2,
                       p_user         varchar2,
                       p_tot_records out number
                      );
  */
  
  procedure loadslip_wt_vol_cal (p_loadslip_id varchar2);
  
  
end atl_business_flow_pkg;

/
