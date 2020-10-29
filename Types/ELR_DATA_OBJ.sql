--------------------------------------------------------
--  DDL for Type ELR_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."ELR_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			location_id 			varchar2(20),  
			servprov              	varchar2(20), 
			elr_flag              	varchar2(1)
		);

/
