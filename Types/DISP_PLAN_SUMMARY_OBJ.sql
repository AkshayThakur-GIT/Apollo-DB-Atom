--------------------------------------------------------
--  DDL for Type DISP_PLAN_SUMMARY_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."DISP_PLAN_SUMMARY_OBJ" authid current_user
AS
  OBJECT
  ( p_tot_records       NUMBER,
    p_tot_error_records NUMBER,
    p_total_tyre_count  NUMBER,
    p_c1_count          NUMBER,
    p_c2_count          NUMBER,
    p_c3_count          NUMBER,
    p_c4_count          NUMBER,
    p_c5_count          NUMBER,
    p_c6_count          NUMBER,
    plan_status         VARCHAR2(20)
  );

/
