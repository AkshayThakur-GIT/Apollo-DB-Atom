--------------------------------------------------------
--  DDL for Package ATL_UTIL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_UTIL_PKG" authid current_user  as

/* 
  Purpose:      Common Utilities 
  Remarks:
  Who             Date            Description
  ------          ----------      ----------------------------------------------
  Akshay Thakur   26-AUG-2018     Created
  Akshay Thakur   15-SEP-2018     Updated with new utilities for API integration
  Akshay Thakur   14-OCT-2018     New function added for business number generation
*/
  -- Constants
  --g_default_separator constant varchar2(1) := ',';
  --c_int_username constant varchar2(20) := 'INTEGRATION';
  --c_int_password constant varchar2(20) := 'Apollo@123';
  --c_workspace_id constant varchar2(20) := 'ATOMWS';
 
  -- convert CSV line to array of values
  function csv_to_array (p_csv_line in varchar2,
                         p_separator in varchar2 := atl_app_config.c_default_separator) return t_str_array;
 
  -- convert array of values to CSV
  function array_to_csv (p_values in t_str_array,
                         p_separator in varchar2 := atl_app_config.c_default_separator) return varchar2;
 
  -- get value from array by position
  function get_array_value (p_values in t_str_array,
                            p_position in number,
                            p_column_name in varchar2 := null) return varchar2;

  -- convert clob to CSV
  function clob_to_csv (p_csv_clob in clob,
                        p_separator in varchar2 := atl_app_config.c_default_separator,
                        p_skip_rows in number := 0) return t_csv_tab pipelined;
  
  -- convert clob to CSV
  function clob_to_csv (p_csv_clob in clob,
                        p_skip_rows in number := 0) return exp_ship_csv_tab pipelined;
                        
  function blob_to_csv (p_csv_blob in blob,
                        p_separator in varchar2 := atl_app_config.c_default_separator,
                        p_skip_rows in number := 0) return exp_ship_csv_tab pipelined;
  
  -- function to convert date into epoch value (required for IoT)
  -- Example : ATL_UTIL_PKG.date_to_epoch(TO_DATE(to_char(sysdate,'DD-MON-YY HH24:MI:SS'),'DD-MON-YY HH24:MI:SS'))
  function date_to_epoch(p_date date) return number;
  
  -- insert into integration error table
  procedure insert_error(p_api_name in varchar2 default null,
                         p_err_msg in varchar2,
                         p_err_code in number,
                         p_user in varchar2,
                         p_int_seq number);
  
  -- insert into integration error table
  procedure insert_error(p_api_name in varchar2 default null,
                         p_err_msg in varchar2,
                         p_err_code in number,
                         p_user in varchar2,
                         p_int_err_seq number,
                         p_int_seq number);                       
  
  -- convert blob to clob (Used for DBCS API integration)
  function blob_to_clob (blob_in in blob) return clob;
  
  -- function to decode API username/password encoded in base64 string
  function decode_base64(p_data in varchar2) return varchar2;
  
  -- function to encode API username/password encoded in base64 string
  function encode_base64(p_data in varchar2) return varchar2;
  
  -- function to validate user used for integration
  function is_valid_auth(p_data in varchar2) return varchar2;
  
  -- procedure to send email (Standard by Oracle APEX)
  -- Doc Ref#: https://docs.oracle.com/cd/E37097_01/doc.42/e35127/GUID-EFA503A4-783B-48C3-832C-A7FE5B74C8E2.htm#AEAPI512
  procedure send_email(p_email_to in varchar2,
                       p_email_from in varchar2,
                       p_email_body in varchar2,
                       p_email_body_html in varchar2 default null,
                       p_email_subj in varchar2 default null,
                       p_email_cc in varchar2 default null,
                       p_email_bcc in varchar2 default null,
                       p_is_attachment in varchar2 default 'N',
                       p_attachment in blob default null,
                       p_filename varchar2 default null,
                       p_mime_type varchar2 default null);
                       
  -- function to convert xml input to json
  function xml_to_json(p_xml_data in clob) return clob;
  function xmltojson(xmldata clob) return varchar2;
  
  function xmltype2clob(i_xml in xmltype) return clob;
  function xml2json(i_xml in xmltype) return xmltype;
  function sql2xml(i_sql_string in varchar2) return xmltype;
  
  -- Stylesheet functions
  function get_xml_to_json_stylesheet return varchar2;
  function get_servprov_stylesheet return varchar2;
  function get_sap_sto_stylesheet return varchar2;
  function get_sap_so_stylesheet return varchar2;
  function get_sap_barcode_stylesheet return varchar2;
  function get_sap_ewaybill_stylesheet return varchar2;
  function get_sap_ewaybill_stylesheet_s return varchar2;
  function get_sap_ship_ls_stylesheet return varchar2;
  
  -- insert to integration log table
  procedure insert_integration_log(p_json_data in clob,
                                   p_int_in_out in varchar2,
                                   p_interface_name in varchar2,
                                   p_api_name in varchar2,
                                   p_status in varchar2,
                                   p_insert_user in varchar2,
                                   p_int_num in number);
  
  -- recompile invalid obejcts in database
  procedure recompile_invalid_objects;
  
  -- function to generate business number
  function generate_business_number(p_type varchar2,
                                    p_attribute1 varchar2,
                                    p_attribute2 varchar2) return varchar2;
                                    
  function is_number (p_string in varchar2) return int;

END ATL_UTIL_PKG;

/
