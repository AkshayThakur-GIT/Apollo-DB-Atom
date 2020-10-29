--------------------------------------------------------
--  DDL for Type ITEM_BOM_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."ITEM_BOM_OBJ" authid current_user
AS
  object
  (
    /* TODO enter attribute and method declarations here */
    
    item_id          VARCHAR2(20),    
    tube_code        VARCHAR2(20),
    tube_desc        VARCHAR2(200),
    tube_comp_qty    NUMBER,
    flap_code        VARCHAR2(20),
    flap_desc        VARCHAR2(200),
    flap_comp_qty    NUMBER,
    valve_code       VARCHAR2(20),
    valve_desc       VARCHAR2(200),
    valve_comp_qty   NUMBER,
    weight           NUMBER,
    weight_uom       VARCHAR2(5),
    volume           NUMBER,
    volume_uom       VARCHAR2(5));

/
