--------------------------------------------------------
--  DDL for Type UPD_MATERIAL_GROUP_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."UPD_MATERIAL_GROUP_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			mg_id						number,
			material_group_id    		varchar2(20),
			description_2				varchar2(100),      
			description_1        		varchar2(100),
			scm_group       			varchar2(20)
		);

/
