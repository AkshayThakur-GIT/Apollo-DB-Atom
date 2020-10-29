--------------------------------------------------------
--  DDL for Package GET_LOADSLIP_LR_NUM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."GET_LOADSLIP_LR_NUM" AS
    g_sequence_length CONSTANT NUMBER := 5;
    FUNCTION get_lr_num (
        p_loadslip_id VARCHAR2
    ) RETURN VARCHAR2;

END;

/
