--------------------------------------------------------
--  DDL for Package Body GET_LOADSLIP_LR_NUM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."GET_LOADSLIP_LR_NUM" AS

    FUNCTION new_lr_sequence (
        p_lr_nbr_pattern VARCHAR2
    ) RETURN VARCHAR2 AS
        lr_max_seq   NUMBER;
    BEGIN
        BEGIN
            SELECT
                MAX(substr(lr_num,instr(lr_num,'/',-1) + 1,length(lr_num) - instr(lr_num,'/',-1) ) )
            INTO lr_max_seq
            FROM
                loadslip
            WHERE
                status != 'CANCELLED'
                AND lr_num LIKE p_lr_nbr_pattern || '%';

        EXCEPTION
            WHEN OTHERS THEN
                lr_max_seq := 0;
        END;

        IF
            ( lr_max_seq IS NULL )
        THEN
            lr_max_seq := 0;
        END IF;
        RETURN lr_max_seq + 1;
    END new_lr_sequence;

    FUNCTION reuse_lr_sequence (
        p_lr_nbr_pattern VARCHAR2
    ) RETURN VARCHAR2 AS
        l_lr_num    VARCHAR2(100);
        l_min_seq   VARCHAR2(100);
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        SELECT
            MIN(substr(lr_num,instr(lr_num,'/',-1) + 1,length(lr_num) - length('_REUSE') - instr(lr_num,'/',-1) ) )
        INTO l_min_seq
        FROM
            loadslip
        WHERE
            lr_num LIKE p_lr_nbr_pattern || '%_REUSE'
            AND status = 'CANCELLED';

        IF
            ( l_min_seq IS NOT NULL )
        THEN
            dbms_output.put_line('Pattern--'
                                   || p_lr_nbr_pattern
                                   || l_min_seq
                                   || '_REUSE');

            UPDATE loadslip
            SET
                lr_num = p_lr_nbr_pattern
                         || l_min_seq
                         || '_DELETE'
            WHERE
                lr_num = p_lr_nbr_pattern
                         || l_min_seq
                         || '_REUSE';

        END IF;
        COMMIT;
        RETURN l_min_seq;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END reuse_lr_sequence;

    PROCEDURE update_cancelled_loadslip
        AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE loadslip
        SET
            lr_num = lr_num || '_REUSE'
        WHERE
            status = 'CANCELLED'
            AND lr_num NOT LIKE '%_REUSE'
            AND lr_num NOT LIKE '%_DELETE';
        
        COMMIT;

    END update_cancelled_loadslip;

    FUNCTION get_lr_num (
        p_loadslip_id VARCHAR2
    ) RETURN VARCHAR2 AS

        l_cancelled_loadslip   NUMBER;
        l_lr_num               VARCHAR2(100);
        l_status               VARCHAR2(50);
        l_lr_reuse_seq         VARCHAR2(100);
        l_lr_new_seq           VARCHAR2(100);
        l_shipment_id          VARCHAR2(100);
        l_source_loc           VARCHAR2(100);
        l_servprov             VARCHAR2(100);
        l_financial_year       VARCHAR2(100);
        l_reuse_seq_count      NUMBER;
        l_sequence             VARCHAR2(20);
        l_lr_nbr_pattern       VARCHAR2(200);
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        SELECT
            COUNT(*)
        INTO l_cancelled_loadslip
        FROM
            loadslip
        WHERE
            status = 'CANCELLED'
            AND lr_num NOT LIKE '%_REUSE'
            AND lr_num NOT LIKE '%_DELETE';

        IF
            ( l_cancelled_loadslip > 0 )
        THEN
            update_cancelled_loadslip ();
        END IF;
        SELECT
            lr_num,
            shipment_id,
            source_loc,
            status
        INTO
            l_lr_num,
            l_shipment_id,
            l_source_loc,
            l_status
        FROM
            loadslip
        WHERE
            loadslip_id = p_loadslip_id;

        SELECT
            servprov
        INTO l_servprov
        FROM
            shipment
        WHERE
            shipment_id = l_shipment_id;

        SELECT
            EXTRACT(YEAR FROM add_months(SYSDATE,-3) )
            || '-'
            || EXTRACT(YEAR FROM add_months(SYSDATE,9) )
        INTO l_financial_year
        FROM
            dual;

        IF
            l_status = 'CANCELLED'
        THEN
            RETURN NULL;
        ELSE
            IF
                l_lr_num IS NOT NULL
            THEN
                RETURN l_lr_num;
            ELSE
                l_lr_nbr_pattern := l_source_loc
                                    || '/'
                                    || l_servprov
                                    || '/'
                                    || l_financial_year
                                    || '/';

                SELECT
                    COUNT(*)
                INTO l_reuse_seq_count
                FROM
                    loadslip
                WHERE
                    status = 'CANCELLED'
                    AND lr_num LIKE l_lr_nbr_pattern || '%_REUSE';

                IF
                    ( l_reuse_seq_count > 0 )
                THEN
                    l_lr_reuse_seq := reuse_lr_sequence(l_lr_nbr_pattern);
                    l_sequence := lpad(l_lr_reuse_seq,g_sequence_length,'0');
                ELSE
                    l_lr_new_seq := new_lr_sequence(l_lr_nbr_pattern);
                    l_sequence := lpad(l_lr_new_seq,g_sequence_length,'0');
                END IF;

                l_lr_num := l_source_loc
                            || '/'
                            || l_servprov
                            || '/'
                            || l_financial_year
                            || '/'
                            || l_sequence;

                UPDATE loadslip
                SET
                    lr_num = l_lr_num,
                    lr_date = sysdate
                WHERE
                    loadslip_id = p_loadslip_id;
                COMMIT;
                RETURN l_lr_num;
            END IF;
        END IF;
        
        

    END get_lr_num;

END get_loadslip_lr_num;

/
