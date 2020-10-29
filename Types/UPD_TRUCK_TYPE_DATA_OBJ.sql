--------------------------------------------------------
--  DDL for Type UPD_TRUCK_TYPE_DATA_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."UPD_TRUCK_TYPE_DATA_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			tt_id				number,
			truck_type    		varchar2(50),
			load_factor			number,       
			truck_desc        	varchar2(50),
			tte_capacity       	number,       
			gross_wt           	number,       
			gross_wt_uom       	varchar2(5),  
			gross_vol         	number,       
			gross_vol_uom    	varchar2(5),  
			variant1        	varchar2(50), 
			variant2          	varchar2(50)
		);

/
