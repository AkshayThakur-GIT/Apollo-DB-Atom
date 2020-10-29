--------------------------------------------------------
--  DDL for Type USER_ROLE_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."USER_ROLE_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
				user_role_id		varchar2(20),
				description			varchar2(50)
		);

/
