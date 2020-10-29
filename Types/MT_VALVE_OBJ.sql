--------------------------------------------------------
--  DDL for Type MT_VALVE_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."MT_VALVE_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			item_id     				varchar2(20),
			item_description           	varchar2(200),
			item_category          		varchar2(20),
			batch_code         	 		varchar2(20),
			valve_id					number
		);

/
