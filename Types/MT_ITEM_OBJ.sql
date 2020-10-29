--------------------------------------------------------
--  DDL for Type MT_ITEM_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."MT_ITEM_OBJ" authid current_user AS  OBJECT(
    item_id     varchar2(100),
    classification varchar2(100),
    description varchar2(200),
    type varchar2(100),
    tte varchar2(100),
    loadFactor varchar2(100),
    itemCategory varchar2(100));

/
