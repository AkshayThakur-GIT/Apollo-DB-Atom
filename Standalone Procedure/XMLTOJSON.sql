--------------------------------------------------------
--  DDL for Function XMLTOJSON
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ATOM"."XMLTOJSON" (xmldata varchar2) return varchar2
	as
	  language java name 'XmlToJson.transform (java.lang.String)                          
	return java.lang.String';

/
