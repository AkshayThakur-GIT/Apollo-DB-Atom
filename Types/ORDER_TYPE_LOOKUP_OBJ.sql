--------------------------------------------------------
--  DDL for Type ORDER_TYPE_LOOKUP_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."ORDER_TYPE_LOOKUP_OBJ" AUTHID CURRENT_USER
AS
	OBJECT
		(
			order_type     			varchar2(50),
			movement_type           varchar2(30),
			market_segment          varchar2(20),
			sap_order_type          varchar2(20), 
			sap_doc_type            varchar2(20)
		);

/
