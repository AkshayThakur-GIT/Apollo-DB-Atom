--------------------------------------------------------
--  DDL for Type DISPATCH_PLAN_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."DISPATCH_PLAN_OBJ" authid current_user
AS
  object
  (
    /* TODO enter attribute and method declarations here */
    dispatch_plan_id NUMBER,
    line_num         NUMBER,
    dispatch_date    DATE,
    dest_loc         VARCHAR2(20),
    source_loc       VARCHAR2(20),
    item_id          VARCHAR2(20),
    item_description VARCHAR2(200),
    item_category    VARCHAR2(20),
    tte              NUMBER,
    batch_code       VARCHAR2(10),
    quantity         NUMBER,
    priority         NUMBER,
    market_segment   VARCHAR2(10),
    dest_desc        VARCHAR2(200),
    comments         VARCHAR2(200));

/
