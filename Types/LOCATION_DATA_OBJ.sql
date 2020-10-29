--------------------------------------------------------
--  DDL for Type LOCATION_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."LOCATION_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			location_id 		varchar2(50),  
			lat              	number(11,8),
			lon              	number(11,8),
			ft_access_key		varchar2(2000),
			location_class		varchar2(20),
			linked_plant		varchar2(50),
      email_id varchar2(4000)
		);

/
