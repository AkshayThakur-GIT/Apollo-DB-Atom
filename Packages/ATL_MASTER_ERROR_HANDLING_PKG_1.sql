--------------------------------------------------------
--  DDL for Package Body ATL_MASTER_ERROR_HANDLING_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_MASTER_ERROR_HANDLING_PKG" AS
    PROCEDURE insert_error (
        p_mt_entity_name   IN VARCHAR2,
        p_package_name     IN VARCHAR2,
        p_proc_func_name   IN VARCHAR2,
        p_line_no          IN NUMBER,
        p_sql_code         IN NUMBER,
        p_sql_errm         IN VARCHAR2,
        p_user             IN VARCHAR2
    ) AS
        PRAGMA autonomous_transaction;
    BEGIN
        INSERT INTO atl_master_error_details (
            master_entity_name,
            package_name,
            proc_func_name,
            line_no,
            SQL_ERROR_CODE,
            SQL_ERROR_MESSAGE,
            CREATED_BY,
            LAST_UPDATED_BY
        ) VALUES (
            p_mt_entity_name,
            p_package_name,
            p_proc_func_name,
            p_line_no,
            p_sql_code,
            p_sql_errm,
            p_user,
            p_user
        );

        COMMIT;
    EXCEPTION
        WHEN others THEN
            ROLLBACK;
    END insert_error;

END ATL_MASTER_ERROR_HANDLING_PKG;

/
