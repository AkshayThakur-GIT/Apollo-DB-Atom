--------------------------------------------------------
--  DDL for Type ITEM_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."ITEM_OBJ" authid current_user AS  OBJECT(
    item_id     varchar2(20),
    description varchar2(200),
    tte number,
    is_item_exists varchar2(1),
    is_tte_exists varchar2(1));

/
