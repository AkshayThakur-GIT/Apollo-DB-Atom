--------------------------------------------------------
--  DDL for Type USER_ASSOCIATION_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."USER_ASSOCIATION_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
				user_id						varchar2(20),
				association_identifier		varchar2(20),
				association_value			varchar2(50),
				ua_id						number
		);

/
