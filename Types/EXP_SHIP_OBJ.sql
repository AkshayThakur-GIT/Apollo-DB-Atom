--------------------------------------------------------
--  DDL for Type EXP_SHIP_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."EXP_SHIP_OBJ" authid current_user
AS
  object
  (
    pi_no                  VARCHAR2(400),
    customer_name          VARCHAR2(500),
    pre_inv_no             VARCHAR2(400),
    inco_term              VARCHAR2(100),
    payment_terms          VARCHAR2(100),
    pol                    VARCHAR2(100),
    pod                    VARCHAR2(100),
    cofd                   VARCHAR2(100),
    forwarder              VARCHAR2(100),
    billing_party          VARCHAR2(200),
    shipping_line          VARCHAR2(200),
    container_num          VARCHAR2(50),
    cont_pick_date         DATE,
    stuffing_date          DATE,
    booking_num            VARCHAR2(100),
    post_inv_no            VARCHAR2(400),
    sap_invoice            VARCHAR2(400),
    inv_amount             VARCHAR2(400),
    cha                    VARCHAR2(100),
    planned_vessel         VARCHAR2(400),
    vessel_depart_pol_date DATE,
    shipping_bill          VARCHAR2(400),
    shipping_bill_date     DATE,
    gatein_date_cfs        DATE,
    customs_exam_date      DATE,
    leo_date               DATE,
    gateout_date_cfs       DATE,
    gatein_date_port       DATE,
    actual_vessel          VARCHAR2(400),
    shipped_onboard_date   DATE,
    eta_pod                DATE,
    export_remarks         VARCHAR2(500));

/
