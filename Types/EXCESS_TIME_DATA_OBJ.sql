--------------------------------------------------------
--  DDL for Type EXCESS_TIME_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."EXCESS_TIME_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			reporting_loc 			varchar2(20),  
			excess_time              	varchar2(20)
		);

/
