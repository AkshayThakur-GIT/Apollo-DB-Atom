--------------------------------------------------------
--  DDL for Type UPD_SAP_TRUCK_TYPE_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."UPD_SAP_TRUCK_TYPE_DATA_OBJ" AUTHID CURRENT_USER
AS
  OBJECT
  (
    stt_id 					NUMBER,
	sap_truck_type			VARCHAR2(20),
    sap_truck_type_desc     VARCHAR2(100),
    ops_truck_type      	VARCHAR2(20),
	ops_variant_1			VARCHAR2(20)
  );

/
