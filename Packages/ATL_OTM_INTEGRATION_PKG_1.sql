--------------------------------------------------------
--  DDL for Package Body ATL_OTM_INTEGRATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_OTM_INTEGRATION_PKG" 
AS
   /*
     Purpose:        OTM Integration API
     Remarks:
     Who             Date            Description
     ------          ----------      ----------------------------------------------
     Sameer Sahu   15-Feb-2019     Initial version

   */

   PROCEDURE add_audit(p_otm_ref_trans_no IN VARCHAR2,
                       p_otm_instance     IN VARCHAR2,
                       p_otm_instance_url IN VARCHAR2,
                       p_request_payload  IN CLOB,
                       p_response_payload IN CLOB)
  IS
  BEGIN
      INSERT INTO ATL_OTM_INTEGRATION_AUDIT(otm_ref_trans_no,
                                            otm_instance,
                                            otm_instance_url,
                                            otm_integration_type,
                                            otm_req_payload,
                                            otm_res_payload)
                                            VALUES
                                            (p_otm_ref_trans_no,
                                             p_otm_instance,
                                             p_otm_instance_url,
                                             'FREIGHT OUTBOUND',
                                             p_request_payload,
                                             p_response_payload
                                            );
      COMMIT;     
  EXCEPTION WHEN OTHERS
  THEN 
   DBMS_OUTPUT.put_line('Error in add_audit - '||SQLERRM);
   RAISE;
  END add_audit;

  PROCEDURE ins_err( p_mt_entity_name     IN VARCHAR2,
                   p_proc_func_name   IN VARCHAR2,
                   p_line_no          IN NUMBER DEFAULT NULL,
                   p_sql_code         IN NUMBER,
                   p_sql_errm         IN VARCHAR2,
                   p_user             IN VARCHAR2)
    IS
      p_package_name VARCHAR2(50) := 'ATL_OTM_INTEGRATION_PKG';
    BEGIN
      ATL_MASTER_ERROR_HANDLING_PKG.insert_error(p_mt_entity_name,
                                                p_package_name,
                                                p_proc_func_name,
                                                p_line_no,
                                                p_sql_code,
                                                p_sql_errm,
                                                p_user);
    EXCEPTION 
      WHEN OTHERS THEN 
        NULL;
    END ins_err;


   FUNCTION send_freight_csvs (p_instance    IN VARCHAR2,
                               p_user_name   IN VARCHAR2,
                               p_password    IN VARCHAR2,
                               p_type        IN VARCHAR2,
                               p_id          IN NUMBER)
      RETURN VARCHAR2
   IS

    l_result     VARCHAR2 (100);
    l_url        VARCHAR2 (1000);
    l_response   XMLTYPE;
    l_envelope   CLOB;
    l_dev_url    VARCHAR2 (300) := 'https://otmgtm-test-a563219.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call';
    l_operation  VARCHAR2 (300) := 'https://otmgtm-test-a563219.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call/publish';
   --l_dev_url    VARCHAR2 (300) := 'https://otmgtm-a563219-dev1.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call';
   --l_operation  VARCHAR2 (300) := 'https://otmgtm-a563219-dev1.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call/publish';
  --   l_dev_url    VARCHAR2 (300) := 'https://otmgtm-a563219.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call';
  --  l_operation  VARCHAR2 (300) := 'https://otmgtm-a563219.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call/publish';


    --Error Handling Variables
    l_proc_func_name    VARCHAR2(100) := 'send_freight_csvs';
    l_mt_entity_name    VARCHAR2(100) := 'FREIGHT OUTBOUND';

   BEGIN

    IF p_instance = 'DEV'
    THEN
      l_url := l_dev_url;
    END IF;

    IF p_type = 'FREIGHT' THEN
    l_envelope := prep_soap_env(p_user_name, p_password);
    

    ELSE
    l_envelope := ded_trucks_prep_soap_env(p_user_name, p_password, p_id);
   
    END IF;
    l_response :=
      APEX_WEB_SERVICE.make_request (
         p_url        => l_url,
         p_action     => l_operation,
         p_envelope   => l_envelope);

    --DBMS_OUTPUT.put_line ('Webservice response l_response=' || l_response.getClobVal ());

    l_result :=
      APEX_WEB_SERVICE.parse_xml (
         p_xml     => l_response,
         p_xpath   => '//otm:ReferenceTransmissionNo/text()',
         p_ns      => 'xmlns:otm="http://xmlns.oracle.com/apps/otm/transmission/v6.4"');
         
    
       add_audit(l_result,p_instance,l_url,l_envelope,l_response.getClobVal());
    
    RETURN l_result;
   EXCEPTION WHEN OTHERS 
   THEN
    DBMS_Output.put_line('Failed - '||sqlerrm);
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => null );        
    RAISE;
   END send_freight_csvs;

   FUNCTION prep_soap_env (p_user_name IN VARCHAR2, p_password IN VARCHAR2)
      RETURN CLOB
   IS
      l_xml_type        XMLTYPE;
      l_x_lane_xml_type XMLTYPE;
      l_rate_service_xml_type XMLTYPE;
      l_service_time_xml_type XMLTYPE;
      l_rate_offering_xml_type XMLTYPE;
      l_rate_geo_cc_xml_type  XMLTYPE;
      l_rate_geo_xml_type XMLTYPE;
      l_rate_geo_cost_xml_type  XMLTYPE;
      l_rg_spcl_serv_xml_type XMLTYPE;
      l_rate_offer_acc_xml_type XMLTYPE;
      --Added By Mangaiah Ramisetty on 10-04-2019--
      l_accessorial_cost_xml_type XMLTYPE;
      l_accessorial_cost_ul_xml_type XMLTYPE;
      l_accessorial_cost_others1_xml_type XMLTYPE;
      l_accessorial_cost_others2_xml_type XMLTYPE;
      l_accessorial_cost_others3_xml_type XMLTYPE;
      l_rate_geo_accessorial_xml_type XMLTYPE;
      l_rate_geo_accessorial_ul_xml_type XMLTYPE;
      l_rate_geo_accessorial_others1_xml_type XMLTYPE;
      l_rate_geo_accessorial_others2_xml_type XMLTYPE;
      l_rate_geo_accessorial_others3_xml_type XMLTYPE;
      --End of Code ---
      l_distance_lookup_xml_type XMLTYPE;
      l_otm_domain_name	VARCHAR2 (50) := 'ATL.';
      l_l2_approved     VARCHAR2 (100) := 'Level2 Approved-OTM';

      --Error Handling Variables
      l_proc_func_name    VARCHAR2(100) := 'prep_soap_env';
      l_mt_entity_name    VARCHAR2(100) := 'FREIGHT OUTBOUND';

   BEGIN

   -- X_LANE csv records.
      /*SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'X_LANE'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'X_LANE_GID,X_LANE_XID,SOURCE_LOCATION_GID,SOURCE_GEO_HIERARCHY_GID,DEST_LOCATION_GID,DEST_GEO_HIERARCHY_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            l_otm_domain_name
                         || f.source_loc
                         || '_'
                         || f.dest_loc
                         || ','
                         || f.source_loc
                         || '_'
                         || f.dest_loc
                         || ','
                         || l_otm_domain_name
                         || f.source_loc
                         || ','
                         || 'LOCATION'
                         || ','
                         || l_otm_domain_name
                         || f.dest_loc
                         || ','
                         || 'LOCATION'
                         || ','
                         || 'ATL'))))
        INTO l_x_lane_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;
         */
        
        /* SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'X_LANE'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'X_LANE_GID,X_LANE_XID,SOURCE_LOCATION_GID,SOURCE_GEO_HIERARCHY_GID,DEST_LOCATION_GID,DEST_GEO_HIERARCHY_GID,SOURCE_REGION_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            l_otm_domain_name
                         || f.source_loc
                         || '_'
                         || f.dest_loc
                         || ','
                         || f.source_loc
                         || '_'
                         || f.dest_loc
                         || ','
                         --|| l_otm_domain_name
                         --|| f.source_loc
                         || (case when upper(nvl(f.source_type,'L')) = 'L' then l_otm_domain_name||f.source_loc end)
                         || ','
                         --|| 'LOCATION'
                         || (case when upper(nvl(f.source_type,'L')) = 'L' then
                         (select source_geo_hierarchy_id from ct_lane_type_lookup where source_type = upper(nvl(f.source_type,'L')) and rownum=1) 
                         end)
                         || ','
                         || l_otm_domain_name
                         || f.dest_loc
                         || ','
                         || 'LOCATION'
                         || ','
                         ||(case when upper(nvl(f.source_type,'L')) = 'R' then l_otm_domain_name||f.source_loc end)
                         ||','
                         || 'ATL'))))
        INTO l_x_lane_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;
         */
         
         SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'X_LANE'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'X_LANE_GID,X_LANE_XID,SOURCE_LOCATION_GID,SOURCE_GEO_HIERARCHY_GID,SOURCE_REGION_GID,DEST_LOCATION_GID,DEST_GEO_HIERARCHY_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            l_otm_domain_name
                         || f.source_loc
                         || '_'
                         || f.dest_loc
                         || ','
                         || f.source_loc
                         || '_'
                         || f.dest_loc
                         || ','
                         --|| 'ATL.'
                         --|| f.source_loc
                         || (case when upper(nvl(f.source_type,'L')) = 'L' then l_otm_domain_name||f.source_loc end)
                         || ','
                         --|| 'LOCATION'
                         || (case when upper(nvl(f.source_type,'L')) = 'L' then
                         (select source_geo_hierarchy_id from ct_lane_type_lookup where source_type = upper(nvl(f.source_type,'L')) and rownum=1) 
                         else Null  --Raghava 25-June
                       -- else 'REGION'
                         end)
                         || ','
                         ||(case when upper(nvl(f.source_type,'L')) = 'R' then l_otm_domain_name||f.source_loc end)
                         || ','
                         || l_otm_domain_name
                         || f.dest_loc
                         || ','
                         || 'LOCATION'                         
                         ||','
                         || 'ATL'))))
     INTO l_x_lane_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;
         

     -- RATE_SERVICE csv records. 
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_SERVICE'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'RATE_SERVICE_GID,RATE_SERVICE_XID,RATE_SERVICE_NAME,RATE_SERVICE_TYPE,CALENDAR_GID,MAX_WORK_TIME_USAGE_TYPE,IS_IGNORE_DELV_LOC_CALENDAR,IS_USE_RUSH_HOUR,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1
                         || ','
                         || f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1
                         || ','
                         || 'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1
                         || ','
                         || 'DAYDURATION'
                         || ','
                         || 'ATL.ATL_CALENDAR'
                         || ','
                         || 'REST WHEN TIME EXCEEDED'
                         || ','
                         || 'N'
                         || ','
                         || 'N'
                         || ','
                         || 'ATL'))))
        INTO l_rate_service_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;

      -- SERVICE_TIME csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'SERVICE_TIME'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'X_LANE_GID,RATE_SERVICE_GID,SERVICE_DAYS,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.source_loc||'_'||f.dest_loc
                         || ','
                         || 'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1
                         || ','
                         --|| f.tt_days*24*60*60 -- days to seconds
                         --|| ','
                         --|| 'S'
                         --|| ','
                         --|| f.tt_days*24*60*60 -- days to seconds
                         || f.tt_days
                         || ','
                         || 'ATL'))))
        INTO l_service_time_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;

     -- RATE_OFFERING csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_OFFERING'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'RATE_OFFERING_GID,RATE_OFFERING_XID,RATE_OFFERING_TYPE_GID,SERVPROV_GID,CURRENCY_GID,TRANSPORT_MODE_GID,RATE_SERVICE_GID,RATE_VERSION_GID,RATE_DISTANCE_GID,EXCHANGE_RATE_GID,COMMODITY_USAGE,FAK_RATE_AS,PERSPECTIVE,ALLOW_UNCOSTED_LINE_ITEMS,IS_ACTIVE,HANDLES_UNKNOWN_SHIPPER,USES_TIME_BASED_RATES,IS_DEPOT_APPLICABLE,RECALCULATE_COST,IS_CONTRACT_RATE,USE_TACT_AS_DISPLAY_RATE_1,IS_DIRECT_ONLY_RATE,HAZARDOUS_RATE_TYPE,USE_TACT_AS_DISPLAY_RATE_2,USE_TACT_AS_DISPLAY_RATE_3,IS_ROUTE_EXECUTION_RATE,PACKAGE_COUNT_METHOD,IS_TEMPLATE,IS_SOURCING_RATE,RATE_OFFERING_DESC,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||'TL'
                         || ','
                         || f.servprov||'_'||'TL'
                         || ','
                         || 'TL'
                         || ','
                         || 'ATL.'||f.servprov
                         || ','
                         || f.base_freight_uom
                         || ','
                         || 'TL'
                         || ','
                         || 'ATL.'||'ATL_LOOKUP'
                         || ','
                         || 'ATL.'||'ATL_VERSION'
                         || ','
                         || 'LOOKUP ONLY'
                         || ','
                         || 'DEFAULT'
                         || ','
                         || 'F,N,B,N,Y,Y,N,N,N,N,Y,Y,A,Y,Y,N,L,N,N'
                         || ','
                         || f.servprov
                         || ','
                         || 'ATL'))))
        INTO l_rate_offering_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;


      -- RATE_GEO csv records.
     /* SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'RATE_GEO_GID,RATE_GEO_XID,RATE_OFFERING_GID,X_LANE_GID,RATE_SERVICE_GID,EFFECTIVE_DATE,EXPIRATION_DATE,ALLOW_UNCOSTED_LINE_ITEMS,MULTI_BASE_GROUPS_RULE,IS_MASTER_OVERRIDES_BASE,HAZARDOUS_RATE_TYPE,IS_QUOTE,IS_ACTIVE,IS_FOR_BEYOND,IS_FROM_BEYOND,IS_SOURCING_RATE,RATE_GEO_DESC,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || 'ATL.'||f.servprov||'_'||f.transport_mode
                         || ','
                         || 'ATL.'||f.source_loc||'_'||f.dest_loc
                         || ','
                         || 'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1
                         || ','
                         || to_char(f.EFFECTIVE_DATE,'DD-MON-RR')
                         || ','
                         || to_char(f.EXPIRY_DATE,'DD-MON-RR')
                         || ','
                         || 'N,A,N,A,N,Y,Y,Y,N'
                         || ','
                         || f.servprov
                         || ','
                         || f.approval1_user
                         || ','
                         || f.approval2_user
                         || ','
                         || to_char(f.approval1_date,'DD-MON-RR')
                         || ','
                         || to_char(f.approval2_date,'DD-MON-RR')
                         || ','
                         || 'ATL'))))
        INTO l_rate_geo_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;
         */
         
         SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'RATE_GEO_GID,RATE_GEO_XID,RATE_OFFERING_GID,X_LANE_GID,RATE_SERVICE_GID,EFFECTIVE_DATE,EXPIRATION_DATE,ALLOW_UNCOSTED_LINE_ITEMS,MULTI_BASE_GROUPS_RULE,IS_MASTER_OVERRIDES_BASE,HAZARDOUS_RATE_TYPE,IS_QUOTE,IS_ACTIVE,IS_FOR_BEYOND,IS_FROM_BEYOND,IS_SOURCING_RATE,RATE_GEO_DESC,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || 'ATL.'||f.servprov||'_'||'TL'
                         || ','
                         || 'ATL.'||f.source_loc||'_'||f.dest_loc
                         || ','
                         || 'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1
                         || ','
                         || to_char(f.EFFECTIVE_DATE,'DD-MON-RR')
                         || ','
                         || to_char(f.EXPIRY_DATE,'DD-MON-RR')
                         || ','
                         || 'N,A,N,A,N,Y,Y,Y,N'
                         || ','
                         || f.servprov
                         || ','
                         || f.approval1_user
                         || ','
                         || f.approval2_user
                         || ','
                         || f.otm_rr_id
                         || ','
                         || to_char(f.approval1_date,'DD-MON-RR')
                         || ','
                         || to_char(f.approval2_date,'DD-MON-RR')
                         || ','
                         || 'ATL'))))
        INTO l_rate_geo_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;

      -- RATE_GEO_COST_GROUP csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_COST_GROUP'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'RATE_GEO_COST_GROUP_GID,RATE_GEO_COST_GROUP_XID,RATE_GEO_GID,RATE_GEO_COST_GROUP_SEQ,MULTI_RATES_RULE,RATE_GROUP_TYPE,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || 'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || '1,A,M,'
                         || 'ATL'))))
        INTO l_rate_geo_cc_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;


      -- RATE_GEO_COST csv records.
    /*  SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_COST'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'RATE_GEO_COST_GROUP_GID,RATE_GEO_COST_SEQ,OPER1_GID,LEFT_OPERAND1,LOW_VALUE1,AND_OR1,OPER2_GID,LEFT_OPERAND2,LOW_VALUE2,CHARGE_AMOUNT,CHARGE_CURRENCY_GID,CHARGE_AMOUNT_BASE,CHARGE_UNIT_UOM_CODE,CHARGE_UNIT_COUNT,CHARGE_MULTIPLIER,CHARGE_ACTION,CHARGE_TYPE,CHARGE_MULTIPLIER_OPTION,EFFECTIVE_DATE,EXPIRATION_DATE,IS_FILED_AS_TARIFF,COST_TYPE,COST_CODE_GID,ALLOW_ZERO_RBI_VALUE,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE8,ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || '1'
                         || ','
                         || 'EQ'
                         || ','
                         || 'SHIPMENT.EQUIPMENT.EQUIPMENT_GROUP_GID'
                         || ','
                         || 'ATL.'||f.truck_type
                         || ','
                         || decode(f.condition1,null,'','A')
                         || ','
                         || decode(f.condition1,null,'','EQ')
                         || ','
                         || decode(f.condition1,null,'','SHIPMENT.SPECIAL_SERVICES.SPECIAL_SERVICE_GID')
                         || ','
                         || decode(f.condition1,null,'','ATL.'||f.condition1)
                         || ','
                         || f.base_freight
                         || ','
                         || f.base_freight_uom
                         || ','
                         || f.base_freight * 0.022931
                         || ','
                         || decode(f.basis,'PER_KG','KG','PER_KM','KM','')
                         || ','
                         || '1'
                         || ','
                         || bs.otm_basis--decode(f.truck_type,'PER_TRUCK','SHIPMENT','')
                         || ','
                         || 'A,B,A'
                         ||','
                         ||to_char(f.EFFECTIVE_DATE,'DD-MON-RR')
                         ||','
                         || to_char(f.EXPIRY_DATE,'DD-MON-RR')
                         ||','
                         ||'N,C,ATL.FREIGHT,N'
                         || ','
                         || f.servprov
                         || ','
                         || f.servprov
                         || ','
                         || f.source_loc
                         || ','
                         || chr(34)||f.source_desc||chr(34)
                         || ','
                         || f.dest_loc
                         || ','
                         || chr(34)||f.dest_desc||chr(34)
                         || ','
                         || f.APPROVAL1_USER 
                         || ','
                         || f.APPROVAL2_USER
                         || ','
                         || to_char(f.APPROVAL1_DATE,'DD-MON-RR')
                         || ','
                         || to_char(f.APPROVAL2_DATE,'DD-MON-RR')
                         || ','
                         || 'ATL'
                         ))))
        INTO l_rate_geo_cost_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;
        */
        
        SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_COST'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                    --  'RATE_GEO_COST_GROUP_GID,RATE_GEO_COST_SEQ,OPER1_GID,LEFT_OPERAND1,LOW_VALUE1,AND_OR1,OPER2_GID,LEFT_OPERAND2,LOW_VALUE2,CHARGE_AMOUNT,CHARGE_CURRENCY_GID,CHARGE_AMOUNT_BASE,CHARGE_UNIT_UOM_CODE,CHARGE_UNIT_COUNT,CHARGE_MULTIPLIER,CHARGE_ACTION,CHARGE_TYPE,CHARGE_MULTIPLIER_OPTION,EFFECTIVE_DATE,EXPIRATION_DATE,IS_FILED_AS_TARIFF,COST_TYPE,COST_CODE_GID,ALLOW_ZERO_RBI_VALUE,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE8,ATTRIBUTE_NUMBER1,ATTRIBUTE_NUMBER2,ATTRIBUTE_NUMBER3,ATTRIBUTE_NUMBER4,ATTRIBUTE_NUMBER5,ATTRIBUTE_NUMBER6,ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,ATTRIBUTE9,ATTRIBUTE10,ATTRIBUTE_NUMBER7,ATTRIBUTE_NUMBER8,DOMAIN_NAME'),
                   'RATE_GEO_COST_GROUP_GID,RATE_GEO_COST_SEQ,OPER1_GID,LEFT_OPERAND1,LOW_VALUE1,AND_OR1,OPER2_GID,LEFT_OPERAND2,LOW_VALUE2,CHARGE_AMOUNT,CHARGE_CURRENCY_GID,CHARGE_AMOUNT_BASE,CHARGE_UNIT_UOM_CODE,CHARGE_UNIT_COUNT,CHARGE_MULTIPLIER,CHARGE_ACTION,CHARGE_TYPE,CHARGE_MULTIPLIER_OPTION,EFFECTIVE_DATE,EXPIRATION_DATE,IS_FILED_AS_TARIFF,COST_TYPE,COST_CODE_GID,ALLOW_ZERO_RBI_VALUE,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE8,ATTRIBUTE_NUMBER1,ATTRIBUTE_NUMBER2,ATTRIBUTE_NUMBER3,ATTRIBUTE_NUMBER4,ATTRIBUTE_NUMBER5,ATTRIBUTE_NUMBER6,ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,ATTRIBUTE9,ATTRIBUTE10,ATTRIBUTE11,ATTRIBUTE_NUMBER7,ATTRIBUTE_NUMBER8,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || '1'
                         || ','
                         || 'EQ'
                         || ','
                         || 'SHIPMENT.EQUIPMENT.EQUIPMENT_GROUP_GID'
                         || ','
                         || 'ATL.'||f.truck_type
                         || ','
                         || decode(f.condition1,null,'','A')
                         || ','
                         || decode(f.condition1,null,'','EQ')
                         || ','
                         || decode(f.condition1,null,'','SHIPMENT.SPECIAL_SERVICES.SPECIAL_SERVICE_GID')
                         || ','
                         || decode(f.condition1,null,'','ATL.'||f.condition1)
                         || ','
                         || f.base_freight
                         || ','
                         || f.base_freight_uom
                         || ','
                         || f.base_freight * 0.022931
                         || ','
                         || decode(f.basis,'PER_KG','KG','PER_KM','KM','')
                         || ','
                         || '1'
                         || ','
                         || bs.otm_basis--decode(f.truck_type,'PER_TRUCK','SHIPMENT','')
                         || ','
                         || 'A,B,A'
                         ||','
                         ||to_char(f.EFFECTIVE_DATE,'DD-MON-RR')
                         ||','
                         || to_char(f.EXPIRY_DATE,'DD-MON-RR')
                         ||','
                         ||'N,C,ATL.FREIGHT,N'
                         || ','
                         || f.transporter_sap_code
                         || ','
                         || f.servprov
                         || ','
                         || f.source_loc
                         || ','
                         || chr(34)||f.source_desc||chr(34)
                         || ','
                         || f.dest_loc
                         || ','
                         || chr(34)||f.dest_desc||chr(34)
                         || ','
                         || f.APPROVAL1_USER 
                         || ','
                         || f.APPROVAL2_USER
                         || ','
						 || f.base_freight
                         || ','
						 || f.loading
                         || ','
						 || f.unloading
                         || ','
						 || (case when f.others1_code like '%PENALTY%' then f.others1 
								  when f.others2_code like '%PENALTY%' then f.others2 
								  when f.others3_code like '%PENALTY%' then f.others3 
								  else null end)
                         || ','
						 || (case when f.others1_code like '%DETENTION%' then f.others1 
								  when f.others2_code like '%DETENTION%' then f.others2 
								  when f.others3_code like '%DETENTION%' then f.others3 
								  else null end)
                         || ','
						 || get_other_charges(f.id)
                         || ','
                         || to_char(f.APPROVAL1_DATE,'DD-MON-RR')
                         || ','
                         || to_char(f.APPROVAL2_DATE,'DD-MON-RR')
                         || ','
                         --|| chr(34)||f.condition2||chr(34)
                         || translate((chr(34)||substr(f.condition2,1,140)||chr(34)),chr(10) || chr(13) || chr(09), ' ')
                         || ','
                         || f.rate_type
                         || ','
                     --    || SUBSTR(f.remarks,1,149)  --Added on 6 Mar
                     -- Raghava 25-Jun-20 added regular exp to remove special characters from Remarks
                         || regexp_replace(regexp_replace(SUBSTR(f.remarks,1,149), '[^a-z_A-Z0-9 ]', ''),' {2,}', ' ')
                         || ','
                         || f.total_expense
                         || ','
                         || f.payable_transporter
                         || ','
                         || 'ATL'
                         ))))
        INTO l_rate_geo_cost_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis;
        
       -- RG_SPECIAL_SERVICE csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RG_SPECIAL_SERVICE'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'RATE_GEO_GID,SPECIAL_SERVICE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                         decode(f.condition1,null,null,'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
                         || decode(f.condition1,null,'','ATL.'||f.condition1)
                         || ','
                         || 'ATL'
                         )))))
        INTO l_rg_spcl_serv_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;
     -- Commentd by Mangaiah Ramisetty on 10-04-2019--
     /*  
     -- RATE_OFFERING_ACCESSORIAL csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_OFFERING_ACCESSORIAL'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,RATE_OFFERING_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||'ATL_DETENTION_CHARGES'
                         || ','
                         || 'ATL.'||f.servprov||'_'||f.transport_mode
                         || ','
                         || 'ATL.'||'DETENTION'
                         || ','
                         || 'ATL'
                         )),
                  XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||'ATL_TT_PENALTY_CHARGES'
                         || ','
                         || 'ATL.'||f.servprov||'_'||f.transport_mode
                         || ','
                         || 'ATL.'||'TRANSIT_PENALTY'
                         || ','
                         || 'ATL'
                         ))
                         ))
        INTO l_rate_offer_acc_xml_type
        from freight f, 
             CT_OTM_FREIGHT_BASIS bs
       where lower(f.status) = lower(l_l2_approved)
         and lower(bs.in_otm) = lower('YES')
         and f.basis = bs.basis ;
         */
    --- End of Comment ----

    -- Added by Mangaiah Ramisetty on 10-04-2019--
    	 -- RATE_OFFERING_ACCESSORIAL csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_OFFERING_ACCESSORIAL'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,RATE_OFFERING_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            rtl.detention_code
                         || ','
                         || 'ATL.'||f.servprov||'_'||'TL'
                         || ','
                         || 'ATL.DETENTION'
                         || ','
                         || 'ATL'
                         )),
                  XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            rtl.penalty_code
                         || ','
                         || 'ATL.'||f.servprov||'_'||'TL'
                         || ','
                         || 'ATL.TRANSIT_PENALTY'
                         || ','
                         || 'ATL'
                         ))
                         ))
        INTO l_rate_offer_acc_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
      where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved);

      ---- ACCESSORIAL_COST for Loading and Unloading csv records.
     /* SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'ACCESSORIAL_COST'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,ACCESSORIAL_COST_XID,CHARGE_MULTIPLIER,CHARGE_AMOUNT,CHARGE_AMOUNT_GID,CHARGE_AMOUNT_BASE,CHARGE_ACTION,CHARGE_TYPE,USE_DEFAULTS,CHARGE_MULTIPLIER_OPTION,IS_FILED_AS_TARIFF,COST_TYPE,IS_ACTIVE,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_LOAD_'||f.loading
                         || ','
						 ||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_LOAD_'||f.loading
						 ||','
						 ||'SHIPMENT'
						 ||','
						 ||f.loading
						 ||','
						 ||'INR'
						 ||','
						 ||f.loading
						 ||','
						 ||rtl.loading
						 || ','
						 ||'B,N,A,N,C,Y'
						 ||','
						 || 'ATL'
                         )),
					XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                           'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_UNLOAD_'||f.unloading
                         || ','
						 ||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_UNLOAD_'||f.unloading
						 ||','
						 ||'SHIPMENT'
						 ||','
						 ||f.unloading
						 ||','
						 ||'INR'
						 ||','
						 ||f.unloading
						 ||','
						 ||rtl.unloading
						 || ','
						 ||'B,N,A,N,C,Y'
						 ||','
						 || 'ATL'
                         ))
						 ))
        INTO l_accessorial_cost_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved);
     */
     
     ---- ACCESSORIAL_COST for Loading csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'ACCESSORIAL_COST'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,ACCESSORIAL_COST_XID,CHARGE_MULTIPLIER,CHARGE_AMOUNT,CHARGE_AMOUNT_GID,CHARGE_AMOUNT_BASE,CHARGE_ACTION,CHARGE_TYPE,USE_DEFAULTS,CHARGE_MULTIPLIER_OPTION,IS_FILED_AS_TARIFF,COST_TYPE,IS_ACTIVE,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                         --   'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_LOAD_'||f.loading
                    --     || ','
						-- ||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_LOAD_'||f.loading
           -- 'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_LOAD'
             'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_L'||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 --||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_LOAD_'||f.loading
             -- ||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_LOAD'
                  ||SUBSTR(f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_L'||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY'),1,50)
						 ||','
						 ||'SHIPMENT'
						 ||','
						 ||f.loading
						 ||','
						 ||'INR'
						 ||','
						 ||f.loading
						 ||','
						 ||rtl.loading
						 || ','
						 ||'B,N,A,N,C,Y'
						 ||','
						 || 'ATL'
                         ))
						 ))
        INTO l_accessorial_cost_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
     and f.loading is not null;
     
     ---- ACCESSORIAL_COST for Unloading csv records recorss
     
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'ACCESSORIAL_COST'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,ACCESSORIAL_COST_XID,CHARGE_MULTIPLIER,CHARGE_AMOUNT,CHARGE_AMOUNT_GID,CHARGE_AMOUNT_BASE,CHARGE_ACTION,CHARGE_TYPE,USE_DEFAULTS,CHARGE_MULTIPLIER_OPTION,IS_FILED_AS_TARIFF,COST_TYPE,IS_ACTIVE,DOMAIN_NAME'),                   
					XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                       --    'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_UNLOAD_'||f.unloading
                       --  || ','
						-- ||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_UNLOAD_'||f.unloading
            --'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_UNLOAD'
                 'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_U'||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 --||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_UNLOAD_'||f.unloading
            -- ||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_UNLOAD'
                    ||SUBSTR(f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_U'||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY'),1,50)
						 ||','
						 ||'SHIPMENT'
						 ||','
						 ||f.unloading
						 ||','
						 ||'INR'
						 ||','
						 ||f.unloading
						 ||','
						 ||rtl.unloading
						 || ','
						 ||'B,N,A,N,C,Y'
						 ||','
						 || 'ATL'
                         ))
						 ))
        INTO l_accessorial_cost_ul_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
     and f.unloading is not null;

       ---- ACCESSORIAL_COST for Others1 csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'ACCESSORIAL_COST'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,ACCESSORIAL_COST_XID,CHARGE_MULTIPLIER,CHARGE_AMOUNT,CHARGE_AMOUNT_GID,CHARGE_AMOUNT_BASE,CHARGE_ACTION,CHARGE_TYPE,USE_DEFAULTS,CHARGE_MULTIPLIER_OPTION,IS_FILED_AS_TARIFF,COST_TYPE,IS_ACTIVE,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                       --    'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others1_code||'_'||f.others1
                    --     || ','
					--	 ||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others1_code||'_'||f.others1
        --  'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others1_code
         'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others1_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 --||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others1_code||'_'||f.others1
           --  ||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others1_code
           ||SUBSTR(f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others1_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY'),1,50)

						 ||','
						 ||'SHIPMENT'
						 ||','
						 ||f.others1
						 ||','
						 ||'INR'
						 ||','
						 ||f.others1
						 ||','
						 ||rtl.others1
						 || ','
						 ||'B,N,A,N,C,Y'
						 ||','
						 || 'ATL'
                         ))
						 ))
        INTO l_accessorial_cost_others1_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
	   and 	f.others1 is not null
     and f.others1_code is not null;

       ---- ACCESSORIAL_COST for Others2 csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'ACCESSORIAL_COST'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,ACCESSORIAL_COST_XID,CHARGE_MULTIPLIER,CHARGE_AMOUNT,CHARGE_AMOUNT_GID,CHARGE_AMOUNT_BASE,CHARGE_ACTION,CHARGE_TYPE,USE_DEFAULTS,CHARGE_MULTIPLIER_OPTION,IS_FILED_AS_TARIFF,COST_TYPE,IS_ACTIVE,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                      --     'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others2_code||'_'||f.others2
                      --   || ','
						-- ||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others2_code||'_'||f.others2
            --'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others2_code
            'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others2_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 --||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others2_code||'_'||f.others2
            -- ||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others2_code
           ||SUBSTR(f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others2_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY'),1,50)
						 ||','
						 ||'SHIPMENT'
						 ||','
						 ||f.others2
						 ||','
						 ||'INR'
						 ||','
						 ||f.others2
						 ||','
						 ||rtl.others2
						 || ','
						 ||'B,N,A,N,C,Y'
						 ||','
						 || 'ATL'
                         ))
						 ))
        INTO l_accessorial_cost_others2_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
	   and 	f.others2 is not null
     and f.others2_code is not null;

       ---- ACCESSORIAL_COST for Others3 csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'ACCESSORIAL_COST'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,ACCESSORIAL_COST_XID,CHARGE_MULTIPLIER,CHARGE_AMOUNT,CHARGE_AMOUNT_GID,CHARGE_AMOUNT_BASE,CHARGE_ACTION,CHARGE_TYPE,USE_DEFAULTS,CHARGE_MULTIPLIER_OPTION,IS_FILED_AS_TARIFF,COST_TYPE,IS_ACTIVE,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                      --     'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others3_code||'_'||f.others3
                      --   || ','
						 --||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others3_code||'_'||f.others3
            -- 'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others3_code
             'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others3_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 --||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others3_code||'_'||f.others3
            --||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others3_code
           ||SUBSTR(f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others3_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY'),1,50)
						 ||','
						 ||'SHIPMENT'
						 ||','
						 ||f.others3
						 ||','
						 ||'INR'
						 ||','
						 ||f.others3
						 ||','
						 ||rtl.others3
						 || ','
						 ||'B,N,A,N,C,Y'
						 ||','
						 || 'ATL'
                         ))
						 ))
        INTO l_accessorial_cost_others3_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
	   and 	f.others3 is not null
     and f.others3_code is not null;

	---- RATE_GEO_ACCESSORIAL for Loading and Unloading csv records.
    /*  SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_ACCESSORIAL'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,RATE_GEO_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_LOAD_'||f.loading
                         || ','
						 ||'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
						 ||','
						 ||'ATL.LOADING'
						 ||','
						 ||'ATL'
						 )),
					XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_UNLOAD_'||f.unloading
                         || ','
						 ||'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
						 ||','
						 ||'ATL.UNLOADING'
						 ||','
						 ||'ATL'
						 ))
                         ))
	 INTO l_rate_geo_accessorial_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved);
     */
     
     -- RATE_GEO_ACCESSORIAL for Loading csv records.
     
     SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_ACCESSORIAL'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,RATE_GEO_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                          --  'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_LOAD_'||f.loading
                        --  'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_LOAD'
                        'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_L'||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 ||'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
						 ||','
						 ||'ATL.LOADING'
						 ||','
						 ||'ATL'
						 ))))
	 INTO l_rate_geo_accessorial_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
     and f.loading is not null;
     
     -- RATE_GEO_ACCESSORIAL for Unloading csv records.
       
       SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_ACCESSORIAL'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,RATE_GEO_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         
                         "v6:CsvRow",
                          --  'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_UNLOAD_'||f.unloading
                        --  'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_UNLOAD'
                        'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_U'||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 ||'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
						 ||','
						 ||'ATL.UNLOADING'
						 ||','
						 ||'ATL'						 
						 ))))
	 INTO l_rate_geo_accessorial_ul_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
     and f.unloading is not null;

       ---- RATE_GEO_ACCESSORIAL for others1 csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_ACCESSORIAL'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,RATE_GEO_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                         --  'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others1_code||'_'||f.others1
                        -- 'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others1_code
                         'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others1_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 ||'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
						 ||','
						 ||'ATL.'||f.others1_code
						 ||','
						 ||'ATL'
                         ))
						 ))
	 INTO l_rate_geo_accessorial_others1_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
	   and  f.others1 is not null
     and f.others1_code is not null;

       ---- RATE_GEO_ACCESSORIAL for others2 csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_ACCESSORIAL'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,RATE_GEO_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                          -- 'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others2_code||'_'||f.others2
                    --'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others2_code
                    'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others2_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 ||'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
						 ||','
						 ||'ATL.'||f.others2_code
						 ||','
						 ||'ATL'
                         ))
						 ))
	 INTO l_rate_geo_accessorial_others2_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
	   and  f.others2 is not null
     and f.others2_code is not null;

       ---- RATE_GEO_ACCESSORIAL for others3 csv records.
      SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO_ACCESSORIAL'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'ACCESSORIAL_COST_GID,RATE_GEO_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                         --  'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.truck_type||'_'||f.others3_code||'_'||f.others3
                     -- 'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||f.others3_code
                     'ATL.'||f.servprov||'_'||f.source_loc||'_'||ltrim(f.dest_loc,'0')||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||f.rate_type||'_'||SUBSTR(f.others3_code,1,2)||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
                         || ','
						 ||'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1||'_'||to_char(to_date(f.effective_date,'DD-MM-RR'),'DDMMYY')
						 ||','
						 ||'ATL.'||f.others3_code
						 ||','
						 ||'ATL'
                         ))
						 ))
	 INTO l_rate_geo_accessorial_others3_xml_type
        from freight f, 
             ct_rate_type_lookup rtl
       where f.rate_type = rtl.rate_type
	   and	lower(f.status) = lower(l_l2_approved)
	   and  f.others3 is not null
     and f.others3_code is not null;

    ---- End of the Code  ----
    
    ---- DISTANCE_LOOKUP for distance csv records.
     SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'DISTANCE_LOOKUP'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'X_LANE_GID,RATE_DISTANCE_GID,DISTANCE_VALUE,DISTANCE_VALUE_UOM_CODE,DISTANCE_VALUE_BASE,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'
                         || f.source_loc
                         || '_'
                         || f.dest_loc
                         || ','                         
                         || 'LOOKUP ONLY'                         
                         || ','                         
                         || f.distance
                         || ','
                         || 'KM'
                         || ','
                         || f.distance
                         ||','
                         || 'ATL'))))
        INTO l_distance_lookup_xml_type
        from freight f
       where lower(f.status) = lower(l_l2_approved) 
       and f.distance is not null;

      --FINAL SOAP Envelope 
      SELECT XMLELEMENT (
                "soapenv:Envelope",
                xmlattributes (
                   'http://schemas.xmlsoap.org/soap/envelope/' AS "xmlns:soapenv",
                   'http://xmlns.oracle.com/apps/otm/TransmissionService' AS "xmlns:tran",
                   'http://xmlns.oracle.com/apps/otm/transmission/v6.4' AS "xmlns:v6"),
                XMLELEMENT (
                   "soapenv:Header",
                   XMLELEMENT (
                      "wsse:Security",
                      xmlattributes (
                         '1' AS "soapenv:mustUnderstand",
                         'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' AS "xmlns:wsse",
                         'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd' AS "xmlns:wsu"),
                      XMLELEMENT (
                         "wsse:UsernameToken",
                         xmlattributes (
                            'UsernameToken-721E1D6E9FA18A17D615502218927725' AS "wsu:Id"),
                         XMLELEMENT ("wsse:Username", p_user_name --'ATL.INTEGRATION'
                                                                 ),
                         XMLELEMENT (
                            "wsse:Password",
                            xmlattributes (
                               'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText' AS "Type"),
                            --'CHANGEME'
                            p_password)))),
                XMLELEMENT (
                   "soapenv:Body",
                   XMLELEMENT (
                      "tran:publish",
                      XMLELEMENT (
                         "v6:Transmission",
                         XMLELEMENT ("v6:TransmissionHeader"),
                         XMLELEMENT ("v6:TransmissionBody",
                                     l_x_lane_xml_type,
                                     l_rate_service_xml_type,
                                     l_service_time_xml_type,
                                     l_rate_offering_xml_type,
                                     l_rate_geo_xml_type,
                                     l_rate_geo_cc_xml_type,
                                     l_rate_geo_cost_xml_type,
                                     l_rg_spcl_serv_xml_type,
                                     l_rate_offer_acc_xml_type,
                                     --Added by Mangaiah Ramisetty on 10-04-2019--
                                     l_accessorial_cost_xml_type,
                                     l_accessorial_cost_ul_xml_type,
                                     l_accessorial_cost_others1_xml_type,
                                    l_accessorial_cost_others2_xml_type,
                                    l_accessorial_cost_others3_xml_type,
                                    l_rate_geo_accessorial_xml_type,
                                    l_rate_geo_accessorial_ul_xml_type,
                                    l_rate_geo_accessorial_others1_xml_type,
                                    l_rate_geo_accessorial_others2_xml_type,
                                    l_rate_geo_accessorial_others3_xml_type,
                                     --End of the Code--
                                     l_distance_lookup_xml_type
                                     )))))
        INTO l_xml_type
        FROM DUAL;

--      DBMS_OUTPUT.put_line ('Webservice Request l_xml_type = ' || dbms_xmlgen.convert(l_xml_type.getClobVal(),dbms_xmlgen.ENTITY_DECODE));

      return replace(dbms_xmlgen.convert(l_xml_type.getClobVal(),dbms_xmlgen.ENTITY_DECODE),'&',';'); 
   EXCEPTION WHEN OTHERS
   THEN
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => null );
    RAISE;
   END prep_soap_env;
   
   FUNCTION ded_trucks_prep_soap_env (p_user_name IN VARCHAR2, p_password IN VARCHAR2,p_id IN NUMBER)
   return clob
   as
   l_xml_type        XMLTYPE;      
   l_rate_geo_xml_type XMLTYPE;
   l_proc_func_name    VARCHAR2(100) := 'ded_trucks_prep_soap_env';
   l_mt_entity_name    VARCHAR2(100) := 'TRUCK DEDICATED OUTBOUND';
   begin
   
    SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'iu'),
                   XMLELEMENT ("v6:CsvTableName", 'RATE_GEO'),
                   XMLELEMENT (
                      "v6:CsvColumnList",
                      'RATE_GEO_GID,RATE_GEO_XID,RATE_OFFERING_GID,IS_ACTIVE,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE_DATE1,DOMAIN_NAME'),
                   XMLAGG (
                      XMLELEMENT (
                         "v6:CsvRow",
                            'ATL.'||f.id
                         || ','
                         || f.id
                         || ','
                         || 'ATL.TRIGGER_RETROSPECTIVE_RO'
                         || ','
                         || 'N'
                         || ','
                         || f.serpvorv
                         || ','
                         || f.source_loc
                         || ','
                         || chr(34)||f.source_desc||chr(34)
                         || ','
                         || f.dest_loc
                         || ','
                         || chr(34)||f.dest_desc||chr(34)
                         || ','
                         || f.truck_type
                         || ','
                         || f.truck_number
                         || ','
                         || to_char(f.expiry_date,'DD-MON-RR')
                         || ','
                         || 'ATL'))))
        INTO l_rate_geo_xml_type
        from mt_truck_dedicated_audit f
        where id = p_id;

      --FINAL SOAP Envelope 
      SELECT XMLELEMENT (
                "soapenv:Envelope",
                xmlattributes (
                   'http://schemas.xmlsoap.org/soap/envelope/' AS "xmlns:soapenv",
                   'http://xmlns.oracle.com/apps/otm/TransmissionService' AS "xmlns:tran",
                   'http://xmlns.oracle.com/apps/otm/transmission/v6.4' AS "xmlns:v6"),
                XMLELEMENT (
                   "soapenv:Header",
                   XMLELEMENT (
                      "wsse:Security",
                      xmlattributes (
                         '1' AS "soapenv:mustUnderstand",
                         'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' AS "xmlns:wsse",
                         'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd' AS "xmlns:wsu"),
                      XMLELEMENT (
                         "wsse:UsernameToken",
                         xmlattributes (
                            'UsernameToken-721E1D6E9FA18A17D615502218927725' AS "wsu:Id"),
                         XMLELEMENT ("wsse:Username", p_user_name --'ATL.INTEGRATION'
                                                                 ),
                         XMLELEMENT (
                            "wsse:Password",
                            xmlattributes (
                               'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText' AS "Type"),
                            --'CHANGEME'
                            p_password
                            )))),
                XMLELEMENT (
                   "soapenv:Body",
                   XMLELEMENT (
                      "tran:publish",
                      XMLELEMENT (
                         "v6:Transmission",
                         XMLELEMENT ("v6:TransmissionHeader"),
                         XMLELEMENT ("v6:TransmissionBody",
                                     l_rate_geo_xml_type)))))
        INTO l_xml_type
        FROM DUAL;


   return replace(dbms_xmlgen.convert(l_xml_type.getClobVal(),dbms_xmlgen.ENTITY_DECODE),'&',';'); 
    EXCEPTION WHEN OTHERS
   THEN
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => null );
    RAISE;
   
   end;
   
function get_other_charges(
    p_id number)
  return number
as
  l_c1 freight.others1_code%type;
  l_c2 freight.others1_code%type;
  l_c3 freight.others1_code%type;
  l_c1_cost  number := 0;
  l_c2_cost  number := 0;
  l_c3_cost  number := 0;
  l_tot_cost number;
begin
  select others1_code,
    others2_code,
    others3_code
  into l_c1,
    l_c2,
    l_c3
  from freight
  where id = p_id;
  if l_c1 is null and l_c2 is null and l_c3 is null then
    return null;
  else
    if l_c1 not like '%DETENTION%' and l_c1 not like '%PENALTY%' then
      select others1 into l_c1_cost from freight where id= p_id;
    end if;
    if l_c2 not like '%DETENTION%' and l_c2 not like '%PENALTY%' then
      select others2 into l_c2_cost from freight where id= p_id;
    end if;
    if l_c3 not like '%DETENTION%' and l_c3 not like '%PENALTY%' then
      select others3 into l_c3_cost from freight where id= p_id;
    end if;
    l_tot_cost   := l_c1_cost + l_c2_cost + l_c3_cost;
    if l_tot_cost = 0 then
      return null;
    else
      return l_tot_cost;
    end if;
  end if;
end; 

procedure clear_otm_rate_cache
  as
    l_otm_clob clob;
    l_resp_clob clob;    
   
  begin
    
            
            l_otm_clob := '<?xml version="1.0" encoding="utf-8"?>
                            <Transmission>
							<TransmissionBody>
							<GLogXMLElement>
							<Topic>
							<TopicAliasName>glog.server.workflow.adhoc.ClearCaches</TopicAliasName>
							<TopicArg>
							<TopicArgName>cache</TopicArgName>
							<TopicArgValue>RateGeoCache</TopicArgValue>
							</TopicArg>
							</Topic>
							</GLogXMLElement>
							<GLogXMLElement>
							<Topic>
							<TopicAliasName>glog.server.workflow.adhoc.ClearCaches</TopicAliasName>
							<TopicArg>
							<TopicArgName>cache</TopicArgName>
							<TopicArgValue>TRateGeoCache</TopicArgValue>
							</TopicArg>
							</Topic>
							</GLogXMLElement>
							</TransmissionBody>
							</Transmission>';
           
            
    -- Sets character set of the body
    utl_http.set_body_charset('UTF-8');
    
    -- Clear headers before setting up
    apex_web_service.g_request_headers.delete();
    
    -- Build request header with content type and authorization
    apex_web_service.g_request_headers(1).name  := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/xml';
    apex_web_service.g_request_headers(2).name  := 'Authorization';
    apex_web_service.g_request_headers(2).value := 'Basic QVRMLklOVEVHUkFUSU9OX1YxOkNIQU5HRU1F';
    
    -- Call OTM Integration API for XML processing
    --if p_instance    = 'DEV' then
      l_resp_clob   := apex_web_service.make_rest_request(
	  p_url => 'https://otmgtm-test-a563219.otm.em2.oraclecloud.com/GC3/glog.integration.servlet.WMServlet',--'atl_app_config.c_otm_dev_api_url, 
	  p_http_method => 'POST', 
	  p_body => l_otm_clob);
         
    
  end;


   
END atl_otm_integration_pkg;

/
