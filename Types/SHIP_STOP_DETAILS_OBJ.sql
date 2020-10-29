--------------------------------------------------------
--  DDL for Type SHIP_STOP_DETAILS_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."SHIP_STOP_DETAILS_OBJ" authid current_user
AS
  object
  (
    /* TODO enter attribute and method declarations here */
    grn_remark       VARCHAR2(200),
    gate_in_date     VARCHAR2(20),
    gate_out_date    VARCHAR2(20),
    reporting_date   VARCHAR2(20),
    ls_date          VARCHAR2(20),
    le_date          VARCHAR2(20),
    sap_rep_date     VARCHAR2(20),
    sap_ul_date      VARCHAR2(20));

/
