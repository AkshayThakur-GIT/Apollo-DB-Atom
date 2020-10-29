--------------------------------------------------------
--  DDL for Package ATL_APP_CONFIG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_APP_CONFIG" authid current_user as 

/* 
  Purpose:        Keeping all constants variables together 
  Remarks:       
  Who             Date            Description
  ------          ----------      ----------------------------------------------
  Akshay Thakur   26-SEP-2018     Created 
  Akshay Thakur   28-OCT-2020     Updated

*/
  c_loadfactor constant number := 122;
  c_otm_instance constant varchar2(20) := 'TEST';

  -- Integration API constants (autherization)
  c_int_username       constant varchar2(20)   := 'INTEGRATION';
  c_int_password       constant varchar2(20)   := 'Apollo@123';
  
  -- Below constant is Base64 encoded string for ATL.INTEGRATION_1:CHANGEME user
  -- We have changed this user from ATL.INTEGRATION To ATL.INTEGRATION_1 due to
  -- authentication issue at OTM side. After fixing it, need to revert it back
  c_otm_int_credential constant varchar2(100)  := 'QVRMLklOVEVHUkFUSU9OXzE6Q0hBTkdFTUU=';
  
  -- OTM Instance WMServlet API URL's
  c_otm_dev_api_url    constant varchar2(100)  := 'https://otmgtm-a563219-dev1.otm.em2.oraclecloud.com/GC3/glog.integration.servlet.WMServlet';
  c_otm_test_api_url   constant varchar2(100)  := 'https://otmgtm-test-a563219.otm.em2.oraclecloud.com/GC3/glog.integration.servlet.WMServlet';
  c_otm_prod_api_url   constant varchar2(100)  := 'https://otmgtm-a563219.otm.em2.oraclecloud.com/GC3/glog.integration.servlet.WMServlet';
  
  -- SAP Integration API URL's
  c_sap_sto_create constant varchar2(400)  := 'https://corpspis01.apollotyres.com:50001/XISOAPAdapter/MessageServlet?senderParty='||'&'||'senderService=BS_WSAPPS_Q'||'&'||'receiverParty='||'&'||'receiverService='||'&'||'interface=SI_PaaS_STO_Req'||'&'||'interfaceNamespace=http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM';
  c_sap_so_create constant varchar2(400)   := 'https://corpspis01.apollotyres.com:50001/XISOAPAdapter/MessageServlet?senderParty='||'&'||'senderService=BS_WSAPPS_Q'||'&'||'receiverParty='||'&'||'receiverService='||'&'||'interface=SI_PaaS_SalesOrder_Req'||'&'||'interfaceNamespace=http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM';
  c_sap_barcode_int constant varchar2(400) := 'https://corpspis01.apollotyres.com:50001/XISOAPAdapter/MessageServlet?senderParty='||'&'||'senderService=BS_OTM_Q'||'&'||'receiverParty='||'&'||'receiverService='||'&'||'interface=Barcode_Req_Out'||'&'||'interfaceNamespace=http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM';
  c_sap_del_order constant varchar2(400)   := 'https://corpspis01.apollotyres.com:50001/XISOAPAdapter/MessageServlet?senderParty='||'&'||'senderService=BS_OTM_Q'||'&'||'receiverParty='||'&'||'receiverService='||'&'||'interface=SI_PaaS_SO_STO_Delete_Out'||'&'||'interfaceNamespace=http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM';
  c_sap_ewaybill constant varchar2(400)    := 'https://corpspis01.apollotyres.com:50001/XISOAPAdapter/MessageServlet?senderParty='||'&'||'senderService=BS_OTM_Q'||'&'||'receiverParty='||'&'||'receiverService='||'&'||'interface=SI_PaaS_EWayBill_Out'||'&'||'interfaceNamespace=http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM';
  c_sap_ship_ls_updt constant varchar2(400):= 'https://corpspis01.apollotyres.com:50001/XISOAPAdapter/MessageServlet?senderParty='||'&'||'senderService=BS_OTM_Q'||'&'||'receiverParty='||'&'||'receiverService='||'&'||'interface=SI_PaaS_ShipmentUpdation_Out'||'&'||'interfaceNamespace=http://apollotyres.com.com/IF121/PaaS/Transaction_Data/I_OTM';

  -- SAP Integration credentials
  c_sap_pi_username constant varchar2(20)   := 'WS_PIQ';
  c_sap_pi_password constant varchar2(20)   := 'welcome16';

  -- other constants
  c_default_separator constant varchar2(1)  := ',';
  c_workspace_id      constant varchar2(20) := 'ATOMWS';
  c_atom_email_from   constant varchar2(100) := 'apollo.atom-test@apollotyres.com';
  
end atl_app_config;

/
