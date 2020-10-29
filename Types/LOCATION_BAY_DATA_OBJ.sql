--------------------------------------------------------
--  DDL for Type LOCATION_BAY_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."LOCATION_BAY_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			location_id 		varchar2(50),  
			bay_id              varchar2(20),
			bay_desc            varchar2(200),
			bay_status			varchar2(400),
			lb_id				number
		);

/
