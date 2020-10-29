--------------------------------------------------------
--  DDL for Type SHIP_DETAILS_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."SHIP_DETAILS_OBJ" authid current_user
AS
  OBJECT
  (
    so_sto_num          VARCHAR2(400),
    invoice_num         VARCHAR2(400),
    invoice_date        DATE,
    delivery_num        VARCHAR2(400),
    lr_number           VARCHAR2(400),
    lr_date             DATE,
    mkt_segment         VARCHAR2(10),
    bay_number          NUMBER,
    tte_qty             NUMBER,
    truck_tte          NUMBER,
    actual_transit_days NUMBER,
    grn_number           VARCHAR2(400),
    grn_date             DATE);

/
