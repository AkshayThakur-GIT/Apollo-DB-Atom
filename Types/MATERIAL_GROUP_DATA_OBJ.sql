--------------------------------------------------------
--  DDL for Type MATERIAL_GROUP_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."MATERIAL_GROUP_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			material_group_id 			varchar2(20),  
			description_1              	varchar2(200), 
			description_2              	varchar2(200), 
			scm_group                  	varchar2(20)
		);

/
