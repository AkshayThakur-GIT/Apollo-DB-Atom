--------------------------------------------------------
--  DDL for Package ATL_OTM_INTEGRATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOM"."ATL_OTM_INTEGRATION_PKG" 
   AUTHID CURRENT_USER
AS
   /*
     Purpose:        OTM Integration API
     Remarks:
     Who             Date            Description
     ------          ----------      ----------------------------------------------
     Sameer Sahu   15-Feb-2019     Initial version

   */

   FUNCTION send_freight_csvs (p_instance    IN VARCHAR2,
                               p_user_name   IN VARCHAR2,
                               p_password    IN VARCHAR2,
                               p_type        IN VARCHAR2,
                               p_id          IN NUMBER DEFAULT NULL)
      RETURN VARCHAR2;

   FUNCTION prep_soap_env (p_user_name IN VARCHAR2, p_password IN VARCHAR2)
      RETURN CLOB;
   FUNCTION ded_trucks_prep_soap_env (p_user_name IN VARCHAR2, p_password IN VARCHAR2, p_id NUMBER)
      RETURN CLOB;
   FUNCTION get_other_charges(p_id IN NUMBER) RETURN NUMBER ;
   procedure clear_otm_rate_cache;
END atl_otm_integration_pkg;

/
