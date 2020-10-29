--------------------------------------------------------
--  DDL for Package ATL_MASTER_DATA_FLOW_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_MASTER_DATA_FLOW_PKG" AUTHID CURRENT_USER AS 

/* 
  Purpose:        Business flow logic 
  Remarks:        API for handling Master data flows 
  Who                   Date            Description
  ------                ----------      -------------------------- 
  Inspirage		        05-Feb-2019 	    Created 
  Mangaiah Ramisetty    16-Apr-2019         Added New fields (RATE_TYPE, LOADING, UNLOADING, OTHERS1, OTHERS2, OTHERS3, OTHERS1_CODE, OTHERS2_CODE, OTHERS3_CODE 
                                            to Procedure upload_freight_data and update_freight_status.
  Mangaiah Ramisetty    23-04-2019          Added upload_location_scan_data Procedure
  Mangaiah Ramisetty    24-04-2019          Added update_location_scan Procedure
  Mangaiah Ramisetty    24-04-2019          Added upload_batch_code_data Procedure
  Mangaiah Ramisetty    24-04-2019          Added upload_sap_truck_type_data
  Mangaiah Ramisetty    26-04-2019          Added insert_truck_type_data
  Mangaiah Ramisetty    26-04-2019          Added update_truck_type_data
  Mangaiah Ramisetty    27-04-2019          Added update_batch_code_data Procedure
  Mangaiah Ramisetty    27-04-2019          Added update_sap_truck_type_data
  Mangaiah Ramisetty    27-04-2019          Added upload_material_group_data
  Mangaiah Ramisetty    27-04-2019          Added update_material_group_data
  Mangaiah Ramisetty    27-04-2019          Added update_transporter_data
  Mangaiah Ramisetty    27-04-2019          Added insert_mt_valve_data
  Mangaiah Ramisetty    27-04-2019          Added update_mt_valve_data
  Mangaiah Ramisetty    27-04-2019          Added insert_order_type_lookup_data
  Mangaiah Ramisetty    27-04-2019          Added update_order_type_lookup_data
  Mangaiah Ramisetty    29-05-2019          Added upload_elr_data
  Mangaiah Ramisetty    29-05-2019          Added update_elr_data
  Mangaiah Ramisetty    29-05-2019          Added insert_excess_waiting_loc_limit_data
  Mangaiah Ramisetty    29-05-2019          Added update_excess_waiting_loc_limit_data
  Mangaiah Ramisetty    29-05-2019          Added insert_excess_waiting_rep_limit_data
  Mangaiah Ramisetty    29-05-2019          Added update_excess_waiting_rep_limit_data
  Mangaiah Ramisetty    29-05-2019          Added upload_location_bay_data
  Mangaiah Ramisetty    29-05-2019          Added delete_location_bay_data
  Mangaiah Ramisetty    29-05-2019          Added update_location_data
  Mangaiah Ramisetty    29-05-2019          Added insert_user_data
  Mangaiah Ramisetty    29-05-2019          Added update_user_data
  Mangaiah Ramisetty    29-05-2019          Added insert_user_role_data
  Mangaiah Ramisetty    29-05-2019          Added update_user_role_data
  Mangaiah Ramisetty    29-05-2019          Added insert_user_association_data
  Mangaiah Ramisetty    29-05-2019          Added update_user_association_data
*/

--==============================================================================
-- This procedure allows to update item details in MT_ITEM table
-- Name: update_item_line
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records 
--==============================================================================

  procedure update_item_line(p_json_data clob,
                       p_root_element varchar2,
                       p_user         varchar2,
                       p_tot_records out number
                      );

--==============================================================================
-- This procedure allows to insert data into FREIGHT table after
-- Name: upload_freight_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records 
--    p_tot_error_records = Return total error records from uploaded file
--==============================================================================
PROCEDURE upload_freight_data(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER--,
	  --p_tot_error_records OUT NUMBER--,
	  --p_error_out OUT CLOB
	  ); 

--==============================================================================
-- This procedure allows to update approval status in FREIGHT table after
-- Name: update_freight_status
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records 
--    p_tot_error_records = Return total error records from uploaded file
--==============================================================================
PROCEDURE update_freight_status(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );

--==============================================================================
-- This procedure allows to createtrip in FreightTiger by invoking webservice
-- Name: call_ft_createtrip
-- Arguments:
--    p_shipment_id         = shipment , gets invoked from atl_otm_package
--==============================================================================

PROCEDURE call_ft_createtrip ( p_shipment_id VARCHAR2) ; 

--==============================================================================
-- This procedure allows to closetrip in FreightTiger by invoking webservice
-- Name: call_ft_closetrip
-- Arguments:
--    p_shipment_id         = shipment , gets invoked from atl_otm_package
--==============================================================================

PROCEDURE call_ft_closetrip( p_shipment_id VARCHAR2);

--==============================================================================
-- This procedure allows to insert data into LOCATION_SCAN table after
-- Name: upload_location_scan_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--==============================================================================
PROCEDURE upload_location_scan_data(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );
      
--==============================================================================
-- This procedure allows to update data into LOCATION_SCAN table after
-- Name: upload_batch_code_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--==============================================================================
PROCEDURE update_location_scan(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );
       
--==============================================================================
-- This procedure allows to insert data into MT_BATCH_CODES table after
-- Name: upload_batch_code_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--==============================================================================
 PROCEDURE upload_batch_code_data(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );

--==============================================================================
-- This procedure allows to Update data into MT_BATCH_CODES table after
-- Name: upload_batch_code_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--==============================================================================
PROCEDURE update_batch_code_data(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );
      
--==============================================================================
-- This procedure allows to insert data into MT_SAP_TRUCK_TYPE table after
-- Name: upload_batch_code_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--==============================================================================
PROCEDURE upload_sap_truck_type_data(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );

--==============================================================================
-- This procedure allows to Update data into MT_SAP_TRUCK_TYPE table after
-- Name: upload_batch_code_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--==============================================================================
PROCEDURE update_sap_truck_type_data(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );
      
--==============================================================================
-- This procedure allows to Insert data into MT_TRUCK_TYPE table after
-- Name: insert_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--==============================================================================
PROCEDURE insert_truck_type_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);

--==============================================================================
-- This procedure allows to update data into MT_TRUCK_TYPE table after
-- Name: update_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--==============================================================================
 PROCEDURE update_truck_type_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to Insert data into MT_MATERIAL_GROUP table after
-- Name: update_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE upload_material_group_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into MT_MATERIAL_GROUP table after
-- Name: update_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
 PROCEDURE update_material_group_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to Insert data into MT_VALVE table after
-- Name: update_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE insert_mt_valve_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
--==============================================================================
-- This procedure allows to update data into MT_VALVE table after
-- Name: update_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_mt_valve_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to Insert data into ORDER_TYPE_LOOKUP table after
-- Name: update_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE insert_order_type_lookup_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into ORDER_TYPE_LOOKUP table after
-- Name: update_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_order_type_lookup_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into MT_TRANSPORTER table after
-- Name: update_truck_type_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_transporter_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into MT_ELR table after
-- Name: update_elr_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_elr_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into MT_ELR table after
-- Name: upload_elr_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE upload_elr_data(
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into mt_excess_waiting_loc_limit table after
-- Name: insert_excess_waiting_loc_limit_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE insert_excess_waiting_loc_limit_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into mt_excess_waiting_loc_limit table after
-- Name: update_excess_waiting_loc_limit_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_excess_waiting_loc_limit_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into mt_excess_waiting_rep_limit table after
-- Name: update_excess_waiting_rep_limit_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_excess_waiting_rep_limit_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into mt_excess_waiting_rep_limit table after
-- Name: insert_excess_waiting_rep_limit_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE insert_excess_waiting_rep_limit_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into MT_LOCATION_BAY table after
-- Name: upload_location_bay_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE upload_location_bay_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into MT_LOCATION_BAY table after
-- Name: delete_location_bay_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE delete_location_bay_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into MT_LOCATION table after
-- Name: update_location_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_location_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);

--==============================================================================
-- This procedure allows to update data into UM_USER table after
-- Name: insert_user_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE insert_user_data (
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );
    
--==============================================================================
-- This procedure allows to update data into UM_USER table after
-- Name: update_user_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_user_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
    
--==============================================================================
-- This procedure allows to update data into UM_USER_ROLE table after
-- Name: insert_user_role_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE insert_user_role_data (
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );
    
--==============================================================================
-- This procedure allows to update data into UM_USER_ROLE table after
-- Name: update_user_role_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_user_role_data (
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );
    
--==============================================================================
-- This procedure allows to update data into UM_USER_ASSOCIATION table after
-- Name: insert_user_association_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE insert_user_association_data (
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  );
    
--==============================================================================
-- This procedure allows to update data into UM_USER_ASSOCIATION table after
-- Name: update_user_association_data
-- Arguments:
--    p_json_data         = JSON object passed from UI (converted data from excel)
--    p_root_element      = Name of root element in JSON document
--    p_user              = UI logged in USER ID
--    p_tot_records       = Return total records
--=============================================================================
PROCEDURE update_user_association_data (
	p_json_data 		CLOB,
	p_root_element 		VARCHAR2,
	p_user         		VARCHAR2,
	p_tot_records OUT 	NUMBER
	);
  
PROCEDURE change_password (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	);
  
PROCEDURE insert_servprov (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	);

 END ATL_MASTER_DATA_FLOW_PKG;

/
