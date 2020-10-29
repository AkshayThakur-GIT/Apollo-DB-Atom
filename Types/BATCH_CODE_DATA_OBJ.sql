--------------------------------------------------------
--  DDL for Type BATCH_CODE_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."BATCH_CODE_DATA_OBJ" AUTHID CURRENT_USER
AS
  OBJECT
  (
    batch_code			VARCHAR2(100),
    category         	VARCHAR2(20),
    plant_code      	VARCHAR2(20),
	batch_description	VARCHAR2(50),
	bc_id				number
  );

/
