--------------------------------------------------------
--  DDL for Type LOCATION_SCAN_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."LOCATION_SCAN_DATA_OBJ" AUTHID CURRENT_USER
AS
  OBJECT
  (
    location_id			VARCHAR2(20),
    scannable         	VARCHAR2(1),
    item_category      	VARCHAR2(20)
  );

/
