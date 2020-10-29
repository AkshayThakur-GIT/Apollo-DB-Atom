--------------------------------------------------------
--  DDL for Type LS_DASHBOARD_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."LS_DASHBOARD_OBJ" authid current_user
AS
  object
  (
    /* TODO enter attribute and method declarations here */
    loadslip_id       VARCHAR2(200),
    sto_so_num        VARCHAR2(400),
    item_id           VARCHAR2(200),
    item_description  VARCHAR2(200),
    source_location   VARCHAR2(20),
    dest_location     VARCHAR2(20),
    loadslip_quantity NUMBER,
    invoice_quantity  NUMBER,
    grn_quantity      NUMBER,
    dit_quantity      NUMBER,
    short_quantity    NUMBER);

/
