--------------------------------------------------------
--  DDL for Type USER_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."USER_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
				user_id			varchar2(20),
				status			varchar2(20),
				user_role_id	varchar2(20),
				password		varchar2(400),
				plant_code		varchar2(20),
				first_name		varchar2(20),
				last_name		varchar2(20),
				email_id		varchar2(100)
		);

/
