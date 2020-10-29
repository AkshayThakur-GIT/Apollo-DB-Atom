--------------------------------------------------------
--  DDL for Package ATL_MASTER_ERROR_HANDLING_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_MASTER_ERROR_HANDLING_PKG" AS
    PROCEDURE insert_error (
        p_mt_entity_name   IN VARCHAR2,
        p_package_name     IN VARCHAR2,
        p_proc_func_name   IN VARCHAR2,
        p_line_no          IN NUMBER,
        p_sql_code         IN NUMBER,
        p_sql_errm         IN VARCHAR2,
        p_user             IN VARCHAR2
    );

END ATL_MASTER_ERROR_HANDLING_PKG;

/
