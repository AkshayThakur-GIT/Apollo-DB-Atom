--------------------------------------------------------
--  DDL for Type TRANSPORTER_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."TRANSPORTER_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			transporter_id 			varchar2(50),  
			servprov              	varchar2(50)
		);

/
