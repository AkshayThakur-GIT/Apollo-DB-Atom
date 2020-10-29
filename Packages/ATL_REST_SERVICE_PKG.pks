--------------------------------------------------------
--  DDL for Package ATL_REST_SERVICE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_REST_SERVICE_PKG" authid current_user as 

/* 
  Purpose:        DBCS REST API Modules 
  Remarks:       
  Who             Date            Description
  ------          ----------      ----------------------------------------------
  Akshay Thakur   26-SEP-2018     Created 
  Akshay Thakur   03-OCT-2018     New funtion added: return_int_msg
*/ 
  
  procedure rest_service(p_data in blob,
                         p_api_auth in varchar2,
                         p_content_type in varchar2,
                         p_api_name in varchar2,
                         p_int_name in varchar2,
                         p_int_seq in number,
                         p_is_valid out nocopy varchar2,
                         p_resp_string out nocopy varchar2,
                         p_status out nocopy number);
  
  function return_int_msg(p_status in varchar2,
                          p_con_type in varchar2,
                          p_error_code in varchar2 default null,
                          p_error_msg in varchar2 default null,
                          p_int_no in number) return varchar2;
                                

end atl_rest_service_pkg;

/
