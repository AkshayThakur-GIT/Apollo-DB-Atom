--------------------------------------------------------
--  DDL for Trigger TRG_MT_TRUCK_DEDICATED_BIUD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "ATOM"."TRG_MT_TRUCK_DEDICATED_BIUD" after
  insert or
  update or 
  delete
  on mt_truck_dedicated for each row 
  declare
  l_otm_trans_no VARCHAR2(100);
  pragma autonomous_transaction;
  l_xml_type        XMLTYPE;      
  l_rate_geo_xml_type XMLTYPE;
  l_result     VARCHAR2 (100);
  --l_url        VARCHAR2 (1000);
  l_response   XMLTYPE;
  l_envelope   CLOB;
  l_dev_url    VARCHAR2 (300) := 'https://otmgtm-test-a563219.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call';
  l_operation  VARCHAR2 (300) := 'https://otmgtm-test-a563219.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call/publish';
  begin
  
  case when INSERTING THEN
  delete from mt_truck_dedicated_audit where id = :new.id;
  insert
  into mt_truck_dedicated_audit
    (
      id,
      serpvorv,
      source_loc,
      source_desc,
      dest_loc,
      dest_desc,
      truck_type,
      truck_number,
      expiry_date,
      insert_date,
      insert_user,
      update_date,
      update_user
    )
    values
    (
      :new.id,
      :new.serpvorv,
      :new.source_loc,
      :new.source_desc,
      :new.dest_loc,
      :new.dest_desc,
      :new.truck_type,
      :new.truck_number,
      :new.expiry_date,
      :new.insert_date,
      :new.insert_user,
      :new.update_date,
      :new.update_user
    );
    
    l_otm_trans_no := atl_otm_integration_pkg.send_freight_csvs('DEV','ATL.INTEGRATION','CHANGEME','DED_TRUCKS',:new.id);
    
    WHEN UPDATING THEN
    delete from mt_truck_dedicated_audit where id = :new.id;
    insert
  into mt_truck_dedicated_audit
    (
      id,
      serpvorv,
      source_loc,
      source_desc,
      dest_loc,
      dest_desc,
      truck_type,
      truck_number,
      expiry_date,
      insert_date,
      insert_user,
      update_date,
      update_user
    )
    values
    (
      :new.id,
      :new.serpvorv,
      :new.source_loc,
      :new.source_desc,
      :new.dest_loc,
      :new.dest_desc,
      :new.truck_type,
      :new.truck_number,
      :new.expiry_date,
      :new.insert_date,
      :new.insert_user,
      :new.update_date,
      :new.update_user
    );
    
    l_otm_trans_no := atl_otm_integration_pkg.send_freight_csvs('DEV','ATL.INTEGRATION','CHANGEME','DED_TRUCKS',:new.id);
    WHEN DELETING THEN
   
   SELECT XMLELEMENT (
                "v6:GLogXMLElement",
                XMLELEMENT (
                   "v6:CSVDataLoad",
                   XMLELEMENT ("v6:CsvCommand", 'd'),
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
        from mt_truck_dedicated_audit f where id = :old.id;
        
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
                         XMLELEMENT ("wsse:Username", 'ATL.INTEGRATION' --p_user_name --'ATL.INTEGRATION'
                                                                 ),
                         XMLELEMENT (
                            "wsse:Password",
                            xmlattributes (
                               'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText' AS "Type"),
                            'CHANGEME'
                            --p_password
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
        
        l_envelope :=  replace(dbms_xmlgen.convert(l_xml_type.getClobVal(),dbms_xmlgen.ENTITY_DECODE),'&',';'); 
   
      l_response :=
      APEX_WEB_SERVICE.make_request (
         p_url        => l_dev_url,
         p_action     => l_operation,
         p_envelope   => l_envelope);

    --DBMS_OUTPUT.put_line ('Webservice response l_response=' || l_response.getClobVal ());

    l_result :=
      APEX_WEB_SERVICE.parse_xml (
         p_xml     => l_response,
         p_xpath   => '//otm:ReferenceTransmissionNo/text()',
         p_ns      => 'xmlns:otm="http://xmlns.oracle.com/apps/otm/transmission/v6.4"');
    
    END CASE;
    
end;
/
ALTER TRIGGER "ATOM"."TRG_MT_TRUCK_DEDICATED_BIUD" ENABLE;
