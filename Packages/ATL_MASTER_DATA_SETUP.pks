--------------------------------------------------------
--  DDL for Package ATL_MASTER_DATA_SETUP
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_MASTER_DATA_SETUP" 
AS
   PROCEDURE create_user (payload       VARCHAR2,
                          MESSAGE   OUT VARCHAR2,
                          success   OUT VARCHAR2);

   PROCEDURE change_password (payload       VARCHAR2,
                              MESSAGE   OUT VARCHAR2,
                              success   OUT VARCHAR2);
END atl_master_data_setup;

/
