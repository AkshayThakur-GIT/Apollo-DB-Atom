--------------------------------------------------------
--  DDL for Function TEST_OTM_FREIGHT_OUTBOUND
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ATOM"."TEST_OTM_FREIGHT_OUTBOUND" 
   RETURN VARCHAR2
AS
   v_user       VARCHAR2 (200) := 'ATL.INTEGRATION';
   v_password   VARCHAR2 (200) := 'CHANGEME';
   l_envelope   CLOB
      := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tran="http://xmlns.oracle.com/apps/otm/TransmissionService" xmlns:v6="http://xmlns.oracle.com/apps/otm/transmission/v6.4">
   <soapenv:Header>
      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
         <wsse:UsernameToken wsu:Id="UsernameToken-721E1D6E9FA18A17D615502218927725">
            <wsse:Username>ATL.INTEGRATION</wsse:Username>
            <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">CHANGEME</wsse:Password>
         </wsse:UsernameToken>
      </wsse:Security>
   </soapenv:Header>
   <soapenv:Body>
      <tran:publish>
         <v6:Transmission>
            <v6:TransmissionHeader/>
            <v6:TransmissionBody>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>X_LANE</v6:CsvTableName>
                     <v6:CsvColumnList>X_LANE_GID,X_LANE_XID,SOURCE_LOCATION_GID,SOURCE_GEO_HIERARCHY_GID,DEST_LOCATION_GID,DEST_GEO_HIERARCHY_GID,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.1002_0000033169,1002_0000033169,ATL.1002,LOCATION,ATL.0000033169,LOCATION,ATL</v6:CsvRow>
                     <v6:CsvRow>ATL.1002_0000033169,1002_0000033169,ATL.1002,LOCATION,ATL.0000033169,LOCATION,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>RATE_SERVICE</v6:CsvTableName>
                     <v6:CsvColumnList>RATE_SERVICE_GID,RATE_SERVICE_XID,RATE_SERVICE_NAME,RATE_SERVICE_TYPE,MAX_WORK_TIME_USAGE_TYPE,IS_IGNORE_DELV_LOC_CALENDAR,IS_USE_RUSH_HOUR,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_MA_CONT_DED,0003009202_1002_0000033169_32FT_MA_CONT_DED,0003009202_1002_0000033169_32FT_MA_CONT_DED,LOOKUP,REST WHEN TIME EXCEEDED,Y,N,ATL</v6:CsvRow>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_SA_CONT_DED,0003009202_1002_0000033169_32FT_SA_CONT_DED,0003009202_1002_0000033169_32FT_SA_CONT_DED,LOOKUP,REST WHEN TIME EXCEEDED,Y,N,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>SERVICE_TIME</v6:CsvTableName>
                     <v6:CsvColumnList>X_LANE_GID,RATE_SERVICE_GID,SERVICE_TIME_VALUE,SERVICE_TIME_VALUE_UOM_CODE,SERVICE_TIME_VALUE_BASE,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.1002_0000033169,ATL.0003009202_1002_0000033169_32FT_MA_CONT_DED,86400,S,86400,ATL</v6:CsvRow>
                     <v6:CsvRow>ATL.1002_0000033169,ATL.0003009202_1002_0000033169_32FT_SA_CONT_DED,86400,S,86400,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>RATE_OFFERING</v6:CsvTableName>
                     <v6:CsvColumnList>RATE_OFFERING_GID,RATE_OFFERING_XID,RATE_OFFERING_TYPE_GID,SERVPROV_GID,CURRENCY_GID,TRANSPORT_MODE_GID,RATE_SERVICE_GID,RATE_VERSION_GID,RATE_DISTANCE_GID,EXCHANGE_RATE_GID,COMMODITY_USAGE,FAK_RATE_AS,PERSPECTIVE,ALLOW_UNCOSTED_LINE_ITEMS,IS_ACTIVE,HANDLES_UNKNOWN_SHIPPER,USES_TIME_BASED_RATES,IS_DEPOT_APPLICABLE,RECALCULATE_COST,IS_CONTRACT_RATE,USE_TACT_AS_DISPLAY_RATE_1,IS_DIRECT_ONLY_RATE,HAZARDOUS_RATE_TYPE,USE_TACT_AS_DISPLAY_RATE_2,USE_TACT_AS_DISPLAY_RATE_3,IS_ROUTE_EXECUTION_RATE,PACKAGE_COUNT_METHOD,IS_TEMPLATE,IS_SOURCING_RATE,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.0003009202_TL,0003009202_TL,TL,ATL.0003009202,INR,TL,TL-SIM,ATL.ATL_VERSION,LOOKUP ONLY,DEFAULT,F,N,B,N,Y,Y,N,N,N,N,Y,Y,A,Y,Y,N,L,N,N,ATL</v6:CsvRow>
                     <v6:CsvRow>ATL.0003009202_TL,0003009202_TL,TL,ATL.0003009202,INR,TL,TL-SIM,ATL.ATL_VERSION,LOOKUP ONLY,DEFAULT,F,N,B,N,Y,Y,N,N,N,N,Y,Y,A,Y,Y,N,L,N,N,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>RATE_GEO</v6:CsvTableName>
                     <v6:CsvColumnList>RATE_GEO_GID,RATE_GEO_XID,RATE_OFFERING_GID,X_LANE_GID,EFFECTIVE_DATE,EXPIRATION_DATE,ALLOW_UNCOSTED_LINE_ITEMS,MULTI_BASE_GROUPS_RULE,IS_MASTER_OVERRIDES_BASE,HAZARDOUS_RATE_TYPE,IS_QUOTE,IS_ACTIVE,IS_FOR_BEYOND,IS_FROM_BEYOND,IS_SOURCING_RATE,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_MA_CONT_DED_010119,0003009202_1002_0000033169_32FT_MA_CONT_DED_010119,ATL.0003009202_TL,ATL.1002_0000033169,2.02E+13,2.02E+13,N,A,N,A,N,Y,Y,Y,N,ATL</v6:CsvRow>
                     <v6:CsvRow>00033169_32FT_SA_CONT_DED_010119,0003009202_1002_0000033169_32FT_SA_CONT_DED_010119,ATL.0003009202_TL,ATL.1002_0000033169,2.02E+13,2.02E+13,N,A,N,A,N,Y,Y,Y,N,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>RATE_GEO_COST_GROUP</v6:CsvTableName>
                     <v6:CsvColumnList>RATE_GEO_COST_GROUP_GID,RATE_GEO_COST_GROUP_XID,RATE_GEO_GID,RATE_GEO_COST_GROUP_SEQ,MULTI_RATES_RULE,RATE_GROUP_TYPE,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_MA_CONT_DED_010119,0003009202_1002_0000033169_32FT_MA_CONT_DED_010119,ATL.0003009202_1002_0000033169_32FT_MA_CONT_DED_010119,1,A,M,ATL</v6:CsvRow>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_SA_CONT_DED_010119,0003009202_1002_0000033169_32FT_SA_CONT_DED_010119,ATL.0003009202_1002_0000033169_32FT_SA_CONT_DED_010119,1,A,M,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>RATE_GEO_COST</v6:CsvTableName>
                     <v6:CsvColumnList>RATE_GEO_COST_GROUP_GID,OPER1_GID,LEFT_OPERAND1,LOW_VALUE1,CHARGE_AMOUNT,CHARGE_CURRENCY_GID,CHARGE_AMOUNT_BASE,CHARGE_UNIT_COUNT,CHARGE_MULTIPLIER,CHARGE_ACTION,CHARGE_TYPE,CHARGE_MULTIPLIER_OPTION,IS_FILED_AS_TARIFF,TIER,COST_TYPE,ALLOW_ZERO_RBI_VALUE,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_MA_CONT_DED_010119,EQ,SHIPMENT.EQUIPMENT.EQUIPMENT_GROUP_GID,ATL.32FT_MA_CONT,20952,INR,480.450312,1,SHIPMENT,A,B,A,N,,C,N,ATL</v6:CsvRow>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_SA_CONT_DED_010119,EQ,SHIPMENT.EQUIPMENT.EQUIPMENT_GROUP_GID,ATL.32FT_SA_CONT,15708,INR,360.200148,1,SHIPMENT,A,B,A,N,,C,N,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>RG_SPECIAL_SERVICE</v6:CsvTableName>
                     <v6:CsvColumnList>RATE_GEO_GID,SPECIAL_SERVICE_GID,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_MA_CONT_DED_010119,ATL.DED,ATL</v6:CsvRow>
                     <v6:CsvRow>ATL.0003009202_1002_0000033169_32FT_SA_CONT_DED_010119,ATL.DED,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
               <v6:GLogXMLElement>
                  <v6:CSVDataLoad>
                     <v6:CsvCommand>iu</v6:CsvCommand>
                     <v6:CsvTableName>RATE_OFFERING_ACCESSORIAL</v6:CsvTableName>
                     <v6:CsvColumnList>ACCESSORIAL_COST_GID,RATE_OFFERING_GID,ACCESSORIAL_CODE_GID,DOMAIN_NAME</v6:CsvColumnList>
                     <v6:CsvRow>ATL.ATL_TT_PENALTY_CHARGES,ATL.0003009202_TL,ATL.TRANSIT_PENALTY,ATL</v6:CsvRow>
                     <v6:CsvRow>ATL.ATL_DETENTION_CHARGES,ATL.0003009202_TL,ATL.DETENTION,ATL</v6:CsvRow>
                  </v6:CSVDataLoad>
               </v6:GLogXMLElement>
            </v6:TransmissionBody>
         </v6:Transmission>
      </tran:publish>
   </soapenv:Body>
</soapenv:Envelope>';
   l_result     VARCHAR2 (100);
   l_xml        XMLTYPE;
BEGIN
   -- Get the XML response from the web service.
   l_xml :=
      APEX_WEB_SERVICE.make_request (
         p_url        => 'https://otmgtm-a563219-dev1.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call',
         p_action     => 'https://otmgtm-a563219-dev1.otm.em2.oraclecloud.com:443/GC3Services/TransmissionService/call/publish',
         p_envelope   => l_envelope);

   -- Display the whole SOAP document returned.
   DBMS_OUTPUT.put_line ('l_xml=' || l_xml.getClobVal ());

   -- Pull out the specific value of interest.
   l_result :=
      APEX_WEB_SERVICE.parse_xml (
         p_xml     => l_xml,
         p_xpath   => '//otm:ReferenceTransmissionNo/text()',
         p_ns      => 'xmlns:otm="http://xmlns.oracle.com/apps/otm/transmission/v6.4"');

   DBMS_OUTPUT.put_line ('l_result=' || l_result);
   RETURN l_result;
END test_otm_freight_outbound;

/
