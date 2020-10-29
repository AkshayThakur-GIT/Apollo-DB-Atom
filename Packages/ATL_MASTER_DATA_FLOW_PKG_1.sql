--------------------------------------------------------
--  DDL for Package Body ATL_MASTER_DATA_FLOW_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_MASTER_DATA_FLOW_PKG" 
AS

	g_err_exist_yes    VARCHAR2 (1) := 'Y'; --Constant to check if error exists
	g_valid_err_flag  VARCHAR2 (3)  := 'VE'; --Global variable for Error record during Validation('VE')
	g_valid_suc_flag  VARCHAR2 (3) := 'V';  --Global variable for Valid Record('V')

/**********************************************************************/

PROCEDURE ins_err( p_mt_entity_name     IN VARCHAR2,
                   p_proc_func_name   IN VARCHAR2,
                   p_line_no          IN NUMBER DEFAULT NULL,
                   p_sql_code         IN NUMBER,
                   p_sql_errm         IN VARCHAR2,
                   p_user             IN VARCHAR2)
IS
  p_package_name VARCHAR2(50) := 'ATL_MASTER_DATA_FLOW_PKG';
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

PROCEDURE call_ft_closetrip(
    p_shipment_id VARCHAR2)
AS
  --DECLARE
  l_clob CLOB;
  var_payload   VARCHAR2(32767);
  var_accesskey VARCHAR2(100);
  l_parm_names apex_application_global.vc_arr2;
  l_parm_values apex_application_global.vc_arr2;
  l_status      VARCHAR2(10);
  l_id          VARCHAR2(100);
  l_message     VARCHAR2(500);
  l_shipment_id VARCHAR2(500);

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'call_ft_closetrip';
  l_mt_entity_name    VARCHAR2(100) := 'FREIGHT';

BEGIN

  l_shipment_id := p_shipment_id; --'SH1001080219006'; --p_shipment_id ; --'SH1001080219006';

  SELECT ft_access_key
  INTO var_accesskey
  FROM mt_location
  WHERE location_id IN
    (SELECT location_id
    FROM shipment_stop
    WHERE shipment_id = l_shipment_id -- 'SH1001080219006'
    AND stop_num      = 1
    ) ;

  SELECT json_object ( 'closedate' value --sysdate
    TO_CHAR(sysdate , 'YYYY-MM-DD HH24:MI:SS') ,'lrid' value ft_trip_id , 'index' value 0 ,'closeTripComment' value 'Trip closed after talking to the driver' )
  INTO var_payload
  FROM shipment
  WHERE shipment_id = l_shipment_id;

  dbms_output.put_line('var_payload:'||var_payload);
  dbms_output.put_line('var_accessKey:'||var_accesskey);

  apex_web_service.g_request_headers.delete();
  utl_http.set_body_charset('UTF-8');
  apex_web_service.g_request_headers(1).name  := 'Content-Type';
  apex_web_service.g_request_headers(1).value := 'application/json';

  l_parm_names(1)                             := 'accessKey';
  l_parm_values(1)                            := var_accesskey;
  l_parm_names(2)                             := 'payload';
  l_parm_values(2)                            := var_payload;

  l_clob                                      := APEX_WEB_SERVICE.make_rest_request
            ( p_url => 'https://integration.freighttiger.com/api/closeTrip',
              p_http_method => 'GET' ,
              p_parm_name => l_parm_names, 
              p_parm_value => l_parm_values ) ;

  dbms_output.put_line(l_clob);

  SELECT jt.status
  INTO l_status
  FROM dual,
    JSON_TABLE (l_clob, '$' COLUMNS (status VARCHAR2(50) PATH '$.status' )) AS jt;

  dbms_output.put_line( 'l_status:'|| l_status );

  /* update shipment
  set ft_closetrip_status = l_status
  where shipment_id = l_shipment_id ;
  commit; */
  /*EXCEPTION
  WHEN OTHERS THEN
  NULL;
  --SELECT utl_http.get_detailed_sqlerrm FROM dual;
  */
EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => null );
END ;

/*********************************************************************/

PROCEDURE call_ft_createtrip ( p_shipment_id VARCHAR2)
AS
--DECLARE
  l_clob CLOB;
  var_payload VARCHAR2(32767);
  var_accesskey VARCHAR2(100);

  l_parm_names  apex_application_global.vc_arr2;  
  l_parm_values apex_application_global.vc_arr2;  

  l_status varchar2(10);
  l_id      varchar2(100); 
  l_message  varchar2(500);

  l_shipment_id VARCHAR2(500);

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'call_ft_createtrip';
  l_mt_entity_name    VARCHAR2(100) := 'FREIGHT';

BEGIN

l_shipment_id :=  p_shipment_id ; --'SH1001080219006';

SELECT distinct mls.ft_access_key,  json_object('driverNumbers' VALUE json_array(sh.driver_mobile),
                    'driverName' VALUE sh.driver_name,
                    'locationSource' VALUE 'sim',
                    'vehicleNumber' VALUE sh.truck_number,
                    'lrNumber' VALUE (select listagg(lr_num, ',')
                                    within group (order by shipment_id) 
                                    from loadslip WHERE  shipment_id = sh.shipment_id ) ,
                    'loading' VALUE json_object (
                                              'uniqueID' VALUE ss.location_id,
                                              'city' VALUE mls.city,
                                              'area' VALUE mls.city,
                                              'latitude' VALUE mls.lat ,
                                              'longitude' VALUE mls.lon  ),
                    'unloading' VALUE json_object (
                                              'uniqueID' VALUE sd.location_id,
                                              'city' VALUE mld.city,
                                              'area' VALUE mld.city,
                                              'latitude' VALUE mld.lat,
                                              'longitude' VALUE mld.lon  ),
                    'transporter' VALUE json_object (
                                              'uniqueID' VALUE sh.transporter_sap_code||'-'||ss.location_id, --sh.servprov,
                                              'name' VALUE sh.servprov 
                                             --, 'name' VALUE mt.transporter_desc
                                              ),
                    'extraContext' VALUE json_object (
                                              'invoiceNumber' VALUE (select listagg(sap_invoice, ',')
                                                                      within group (order by shipment_id) 
                                                            from loadslip WHERE  shipment_id = sh.shipment_id ) ,
                                              'shipmentNumber' VALUE sh.shipment_id,
											  'ewbNumber' VALUE NULL,
											  'customValues' VALUE json_array(NULL)),

                    'share_trip' VALUE 'false'

                  )  aa
				  into var_accesskey, var_payload
from  shipment sh, shipment_stop ss, shipment_stop sd , mt_location mls,
(select location_id, city, lat, lon from mt_location
union all
select cust_id location_id, city, lat, lon from MT_CUSTOMER)
 mld 
where  1=1 --ls.loadslip_id='LSGJJ1INNSA080219005'
and sh.shipment_id = l_shipment_id --'SH1001080219006'
--and ls.shipment_id = sh.shipment_id
and sd.shipment_id = sh.shipment_id
and sd.stop_num = ( select max(stop_num) from shipment_stop where shipment_id = sh.shipment_id) 
and sd.location_id = mld.location_id 
and ss.shipment_id = sh.shipment_id
and ss.stop_num = 1
and ss.location_id = mls.location_id 
; 

 dbms_output.put_line('var_payload:'||var_payload);

  dbms_output.put_line('var_accesskey:'||var_accesskey);

    apex_web_service.g_request_headers.delete();
    utl_http.set_body_charset('UTF-8');
	apex_web_service.g_request_headers(1).name := 'Content-Type';  
	apex_web_service.g_request_headers(1).value := 'application/json';  

  l_parm_names(1) := 'payload';  
  l_parm_values(1) :=var_payload;  
  l_parm_names(2) := 'accessKey';  
  l_parm_values(2) := var_accesskey;  

  l_clob := APEX_WEB_SERVICE.make_rest_request(
		--  p_url => 'test.freighttiger.com/api/feed/addTripAuth', 
      p_url => 'https://integration.freighttiger.com/api/feed/addTripAuth', 
		  p_http_method => 'GET' ,
		  p_parm_name => l_parm_names,  
		  p_parm_value => l_parm_values  
 ) ;

  dbms_output.put_line(l_clob);

  SELECT jt.status , jt.id, jt.message
    into l_status, l_id, l_message
    FROM dual,
    JSON_TABLE (l_clob, '$'
    COLUMNS (status            VARCHAR2(50) PATH '$.status',
             id          VARCHAR2(50) PATH '$.result.id',
             message VARCHAR2(500) PATH '$.message'
     ))
     as jt;

  dbms_output.put_line( 'l_status:'|| l_status || ' l_id:'|| l_id 
                       ||' l_message:'||l_message
   );

  update shipment
  set ft_trip_id = l_id 
  where shipment_id = l_shipment_id ;
 -- AND l_status  =1 ;

   commit; 

/*EXCEPTION 
	WHEN OTHERS THEN
		NULL;
			--SELECT utl_http.get_detailed_sqlerrm FROM dual;
*/

EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => null );

END ;



/******/	


--Procedure to update data into MT_ITEM table
  PROCEDURE update_item_line(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER)
  AS

    l_item_id        VARCHAR2(100) ;
    l_tte            VARCHAR2(100);
    l_load_factor    VARCHAR2(100);
    l_item_category  VARCHAR2(100);
    l_classification VARCHAR2(100);
    l_description    VARCHAR2(200);
    l_type           VARCHAR2(100);

    -- Collection variables
    l_item_data mt_item_list;
    l_item_record mt_item_obj;

    -- Common variables
    l_record INT := 1;
    l_count pls_integer;

    -- Variables for JSON processing
    l_json_obj json_object_t;
    l_item_obj json_object_t;
    l_item_arr json_array_t;

    -- Output variables
    --l_tot_records pls_integer;
    l_tot_error_records pls_integer;
    l_total_tyre_count NUMBER;

	-- dbms_output.put_line('Inside Procedure ');

    --Error Handling Variables
    l_proc_func_name    VARCHAR2(100) := 'update_item_line';
    l_mt_entity_name    VARCHAR2(100) := 'ITEM';

    PROCEDURE parse_item_data
    AS
    BEGIN
      -- parsing json data
      l_json_obj := json_object_t.parse(p_json_data);
      l_item_arr := l_json_obj.get_array(p_root_element);
      l_count    := l_item_arr.get_size;
    --  dbms_output.put_line('Data Count '||l_count);
      p_tot_records := l_count;
    END;

  PROCEDURE fill_item_collection
  AS
  BEGIN
    -- initialize list for dispatch plan
    l_item_data := mt_item_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_item_obj := treat(l_item_arr.get(i)
    AS
      json_object_t);
      l_item_id     := l_item_obj.get_string('id');
      l_tte         := l_item_obj.get_string('tte');
      l_load_factor := l_item_obj.get_string('loadFactor');
      l_item_category := l_item_obj.get_string('category');
      l_classification := l_item_obj.get_string('classification');
      l_description    := l_item_obj.get_string('description');
      l_type           := l_item_obj.get_string('type');

	--  dbms_output.put_line('itemId '||l_item_id);

      l_item_record    := mt_item_obj(item_id => l_item_id, classification => l_classification, description => l_description, type => l_type, tte => l_tte, loadFactor => l_load_factor, itemCategory => l_item_category );
      l_item_data.extend;
      l_item_data(l_record) := l_item_record;
      l_record              := l_record + 1;
    END LOOP;
  END;

  PROCEDURE update_item_tbl
  AS
  BEGIN
    -- update Item table.
    forall i IN l_item_data.first .. l_item_data.last
    UPDATE mt_item
    SET  
      tte           	= l_item_data(i).tte ,
      load_factor   	= l_item_data(i).loadfactor ,
      item_category 	= l_item_data(i).itemCategory ,
	  item_classification = l_item_data(i).classification ,
      update_date   	= sysdate,
      update_user   	= p_user
    WHERE item_id   	= l_item_data(i).item_id;
    COMMIT;
  END;

BEGIN
  parse_item_data ;
  fill_item_collection ;
  update_item_tbl ;
/*EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => p_user );
*/
END;


--Procedure to insert data into FREIGHT table
PROCEDURE upload_freight_data(
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER--,
    --p_tot_error_records OUT NUMBER--,
	--p_error_out OUT CLOB 
  )
AS

  l_transporter_sap_code VARCHAR2(50);
  l_servprov             VARCHAR2(50);
  l_source_loc           VARCHAR2(50);
  l_dest_loc             VARCHAR2(50);
  l_lane_code            VARCHAR2(50);
  l_truck_type           VARCHAR2(50);
  l_condition1           VARCHAR2(200);
  l_condition2           VARCHAR2(800);
  l_effective_date       VARCHAR2(100);
  l_expiry_date          VARCHAR2(100);
  l_tt_days              NUMBER;
  l_base_freight         NUMBER;
  l_base_freight_uom     VARCHAR2(10);
  l_basis                VARCHAR2(50);
  l_min_value            NUMBER;
  l_min_value_uom        VARCHAR2(10);
  l_transportMode        VARCHAR2(50);
  l_eff_date				date;
  l_exp_date				date;
  l_status          VARCHAR2(50);
  l_affected_rows number;
  
  --Added by Mangaiah Ramisetty on 16-04-2019 ---
  l_rate_type       VARCHAR2(20);
  l_loading         NUMBER;
  l_unloading       NUMBER;
  l_others1         NUMBER;
  l_others1_code    VARCHAR2(100);
  l_others2         NUMBER;
  l_others2_code    VARCHAR2(100);
  l_others3         NUMBER;
  l_others3_code    VARCHAR2(100);
  --End of the Code ---
  
  --Added by Akshay Thakur 21-06-2019 ---
  l_distance			      NUMBER;
	l_total_expense		    NUMBER;
	l_payable_transporter	NUMBER;
	l_source_type			    VARCHAR2(20);
  --End of the Code ---
  
  --Added by Raghava 3-Mar-2020
    l_remarks    VARCHAR2(4000);
 --End of the Code ---
 
  -- Collection variables
  l_freight_data freight_data_list;
  l_freight_record freight_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_freight_obj json_object_t;
  l_freight_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'upload_freight_data';
  l_mt_entity_name    VARCHAR2(100) := 'FREIGHT';

  --purge freight_temp table
  PROCEDURE purge_freight_temp_tab
AS
  BEGIN
  -- truncate table freight_temp; 
   delete from FREIGHT_TEMP; 
	commit; 

  END;

  PROCEDURE parse_freight_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    := json_object_t.parse(p_json_data);
    l_freight_arr := l_json_obj.get_array(p_root_element);
    l_count       := l_freight_arr.get_size;
    --  dbms_output.put_line('Data Count '||l_count);
    p_tot_records := l_count;
  END;

  PROCEDURE fill_freight_collection
  AS
  BEGIN
    -- initialize list for dispatch plan
    l_freight_data := freight_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_freight_obj := treat(l_freight_arr.get(i)
    AS
      json_object_t);
      l_transporter_sap_code:= trim(l_freight_obj.get_string('transporterSapCode'));
      l_servprov            := trim(l_freight_obj.get_string('servprov'));
      l_source_loc          := trim(l_freight_obj.get_string('sourceLoc'));
	  l_dest_loc          	:= trim(l_freight_obj.get_string('destLoc'));
      --l_lane_code           := l_freight_obj.get_string('truckType');
      l_truck_type          := trim(l_freight_obj.get_string('truckType'));
      l_condition1          := trim(l_freight_obj.get_string('condition1'));
      l_condition2          := trim(l_freight_obj.get_string('condition2'));
      l_effective_date      := l_freight_obj.get_string('effectiveDate');
	 -- select to_char(to_date('Dec 30, 2019 11:59:50 PM','Mon dd, yyyy HH:MI:SS AM'),'dd-MON-yy') from dual;
--Jan 1, 2019 5:30:00 AM
		  l_eff_date            := to_date( to_char(to_date(l_effective_date,'Mon dd, yyyy HH:MI:SS AM'),'dd-MON-yy hh:mi:ss AM'),'dd-MON-yy hh:mi:ss AM') ;

--	  l_eff_date            := to_char(to_date( l_effective_date,'yyyy-mm-dd'),'dd-MON-yy') ;


   l_expiry_date         := l_freight_obj.get_string('expiryDate');
	 -- l_exp_date			:= to_char(to_date(l_expiry_date,'Mon dd, yyyy HH:MI:SS AM'),'dd-MON-yy');
    l_exp_date            := to_date( to_char(to_date(l_expiry_date,'Mon dd, yyyy HH:MI:SS AM'),'dd-MON-yy hh:mi:ss AM'),'dd-MON-yy hh:mi:ss AM') ;

      --l_exp_date			:= l_expiry_date ; 
	l_tt_days             := l_freight_obj.get_string('ttDays');
      l_base_freight        := l_freight_obj.get_string('baseFreight');
      l_base_freight_uom    := l_freight_obj.get_string('baseFreightUom');
      l_basis               := l_freight_obj.get_string('basis');
      l_min_value           := l_freight_obj.get_string('minValue');
      l_min_value_uom       := l_freight_obj.get_string('minValueUom');
	    l_transportMode       := trim(l_freight_obj.get_string('transportMode'));
      l_status       := l_freight_obj.get_string('status');
     --dbms_output.put_line('itemId '||l_item_id);
     
     --Added by Mangaiah Ramisetty on 16-04-2019 ---
      l_rate_type           := l_freight_obj.get_string('rateType'); 
      l_loading             := l_freight_obj.get_string('loading'); 
      l_unloading           := l_freight_obj.get_string('unloading'); 
      l_others1             := l_freight_obj.get_string('others1'); 
      l_others1_code        := l_freight_obj.get_string('others1Code'); 
      l_others2             := l_freight_obj.get_string('others2'); 
      l_others2_code        := l_freight_obj.get_string('others2Code'); 
      l_others3             := l_freight_obj.get_string('others3'); 
      l_others3_code        := l_freight_obj.get_string('others3Code'); 
      -- End of the Code ---
      
      --Added by Akshay Thakur 21-06-2019 ---
      l_distance                  := l_freight_obj.get_string('distance'); 
      l_total_expense             := l_freight_obj.get_string('totExpense'); 
      l_payable_transporter       := l_freight_obj.get_string('payTransporter'); 
      l_source_type               := l_freight_obj.get_string('sourceType');
      -- End of the Code ---
      
      --Added by Raghava 3-Mar-2020
            l_remarks  := l_freight_obj.get_string('remarks');
      -- End of the Code ---
      
       l_freight_record := freight_data_obj(transporter_sap_code => l_transporter_sap_code, servprov => l_servprov, source_loc => l_source_loc, dest_loc=> l_dest_loc, truck_type => l_truck_type, condition1 => l_condition1, condition2 => l_condition2, 
       effective_date => to_char(l_eff_date,'dd-MON-yy hh:mi:ss AM') , 
       expiry_date => to_char(l_exp_date,'dd-MON-yy hh:mi:ss AM'),--to_date(to_char(l_exp_date,'dd-MON-yy'),'dd-MON-yy')+interval '330' minute,
            tt_days => l_tt_days, base_freight => l_base_freight, 
            base_freight_uom => l_base_freight_uom, basis => l_basis, min_value => l_min_value, 
            min_value_uom => l_min_value_uom, transport_mode => l_transportMode, 
            status => l_status, rate_type => l_rate_type, 
            loading => l_loading, unloading => l_unloading, others1 => l_others1, 
            others1_code => l_others1_code, others2 => l_others2, others2_code => l_others2_code, 
            others3 => l_others3, others3_code => l_others3_code, 
            distance => l_distance,total_expense => l_total_expense, payable_transporter => l_payable_transporter,
            source_type => l_source_type,remarks => l_remarks);
            
            
      l_freight_data.extend;
      l_freight_data(l_record) := l_freight_record;
      l_record                 := l_record + 1;
    END LOOP;
  END;


PROCEDURE insert_freight_temp_tbl
AS

l_line_num NUMBER :=0;

BEGIN
  -- Populate FREIGHT_TEMP table.
  --forall i IN l_freight_data.first .. l_freight_data.last
  for i IN l_freight_data.first .. l_freight_data.last
  loop 

  l_line_num := l_line_num +1;

  INSERT
  INTO freight_temp
    ( id, 
      transporter_sap_code ,
      servprov ,
      source_loc ,
      dest_loc
      -- ,lane_code
      ,
      truck_type ,
      condition1 ,
      condition2,
      effective_date ,
      expiry_date ,
      tt_days ,
      base_freight ,
      base_freight_uom ,
      basis ,
      min_value ,
      min_value_uom ,
      transport_mode ,
      status ,
       -- Added By Mangaiah Ramisetty on 16-04-2019 --
      rate_type,
      loading,
      unloading,
      others1,
      others1_code,
      others2,
      others2_code,
      others3,
      others3_code,
      -- End of the Code --
      insert_user ,
      insert_date,
      distance,
      total_expense,
      payable_transporter,
      source_type,
      remarks
    )
    VALUES
    ( l_line_num,
      l_freight_data(i).transporter_sap_code,
      l_freight_data(i).servprov,
      l_freight_data(i).source_loc,
      l_freight_data(i).dest_loc,
      --  l_freight_data(i).lane_code,
      l_freight_data(i).truck_type,
      l_freight_data(i).condition1,
      l_freight_data(i).condition2,
     to_date(l_freight_data(i).effective_date,'dd-MON-yy hh:mi:ss AM'),
	 -- l_freight_data(i).effective_date,
   to_date(l_freight_data(i).expiry_date,'dd-MON-yy hh:mi:ss AM'),
     -- l_freight_data(i).expiry_date,
      l_freight_data(i).tt_days,
      l_freight_data(i).base_freight,
      l_freight_data(i).base_freight_uom,
      l_freight_data(i).basis,
      l_freight_data(i).min_value,
      l_freight_data(i).min_value_uom,
      l_freight_data(i).transport_mode,
      'N' ,
      -- Added by Mangaiah Ramisetty on 16-04-2019 ---
      l_freight_data(i).rate_type,
      l_freight_data(i).loading,
      l_freight_data(i).unloading,
      l_freight_data(i).others1,
      l_freight_data(i).others1_code,
      l_freight_data(i).others2,
      l_freight_data(i).others2_code,
      l_freight_data(i).others3,
      l_freight_data(i).others3_code,
      -- End of the Code ---
      p_user,
      sysdate,
      l_freight_data(i).distance,
      l_freight_data(i).total_expense,
      l_freight_data(i).payable_transporter,
      l_freight_data(i).source_type,
      l_freight_data(i).remarks
    );
    end loop; 
  COMMIT;
END;

--Performing Freight Validations
PROCEDURE perform_freight_validation
AS
  v_err_flag VARCHAR2 (1)  := 'N';
  l_error_message VARCHAR2 (2400);
  l_transporter   VARCHAR2 (50);
  l_servprov	  VARCHAR2 (50);
  l_source_loc	  VARCHAR2 (50);
  l_dest_loc  	  VARCHAR2 (50);
  l_truck_type	  VARCHAR2 (50); 
  l_condition1    VARCHAR2 (200); 
  l_condition2    VARCHAR2 (800); 
l_base_freight_uom   VARCHAR2 (50);
l_source_loc_desc 	VARCHAR2 (240);	
l_dest_loc_desc 	VARCHAR2 (240);	

  CURSOR cr_freight
  IS
    SELECT id ,
      transporter_sap_code ,
      servprov ,
      source_loc ,
      dest_loc ,
      lane_code ,
      truck_type ,
      condition1 ,
      condition2,
      effective_date ,
      expiry_date ,
      tt_days ,
      base_freight ,
      base_freight_uom ,
      basis ,
      min_value ,
      min_value_uom,
      transport_mode
    FROM freight_temp ;

BEGIN

  FOR l_freight IN cr_freight
  LOOP
    v_err_flag      := 'N';
    l_error_message := NULL;
    l_transporter   := NULL;
	l_servprov		:= NULL;
	l_source_loc	:= NULL;
	l_dest_loc		:= NULL;
	l_truck_type	:= NULL;
	l_base_freight_uom	:= NULL; 
	l_source_loc_desc  := NULL;
	l_dest_loc_desc  := NULL;

    --transporterSapCode validation
	BEGIN
      SELECT distinct transporter_id
      INTO l_transporter
      FROM MT_TRANSPORTER
      WHERE transporter_id =l_freight.transporter_sap_code ;

    EXCEPTION WHEN OTHERS THEN
      v_err_flag      := g_err_exist_yes;
      l_error_message := l_error_message||','||'Invalid Transporter SAP Code';
    END;

	--servprov Validation
	BEGIN
      SELECT distinct servprov
      INTO l_servprov
      FROM MT_TRANSPORTER
      WHERE servprov =l_freight.servprov ;
    EXCEPTION WHEN OTHERS THEN
      v_err_flag      := g_err_exist_yes;
      l_error_message := l_error_message||','||'Invalid Service Provider';
    END;

	--source_loc Validation
	BEGIN
      SELECT distinct LOCATION_ID, LOCATION_DESC
      INTO l_source_loc, l_source_loc_desc
      FROM MT_LOCATION
      WHERE LOCATION_ID = l_freight.source_loc ;
    EXCEPTION WHEN OTHERS THEN
      v_err_flag      := g_err_exist_yes;
      l_error_message := l_error_message||','||'Invalid Source Location';
    END;

	--dest_loc Validation
	BEGIN
      SELECT distinct LOCATION_ID, LOCATION_DESC
      INTO l_dest_loc, l_dest_loc_desc
      FROM MT_LOCATION
      WHERE LOCATION_ID = l_freight.dest_loc ;
    EXCEPTION WHEN NO_DATA_FOUND THEN

			BEGIN
				SELECT distinct CUST_ID, CUST_NAME
			     INTO l_dest_loc, l_dest_loc_desc
				  FROM MT_CUSTOMER
				  WHERE CUST_ID = l_freight.dest_loc
				  AND ROWNUM = 1;
			EXCEPTION 
			 WHEN OTHERS THEN
			  v_err_flag      := g_err_exist_yes;
			  l_error_message := l_error_message||','||'Invalid Destination Location';
			END;

     WHEN OTHERS THEN
      v_err_flag      := g_err_exist_yes;
      l_error_message := l_error_message||','||'Invalid Destination Location';
    END;

	--truck_type Validation
	BEGIN
      SELECT distinct truck_type
      INTO l_truck_type
      FROM MT_TRUCK_TYPE
      WHERE truck_type = l_freight.truck_type ;
    EXCEPTION WHEN OTHERS THEN
      v_err_flag      := g_err_exist_yes;
      l_error_message := l_error_message||','||'Invalid Truck Type';
    END;

	--truck_type Validation
	BEGIN

		IF l_freight.condition1 IS NOT NULL THEN 

		  SELECT distinct variant1
		  INTO l_condition1
		  FROM MT_TRUCK_TYPE
		  WHERE truck_type = l_truck_type
		  AND variant1 = l_freight.condition1  ;

		END IF;  

	EXCEPTION WHEN OTHERS THEN
      v_err_flag      := g_err_exist_yes;
      l_error_message := l_error_message||','||'Invalid Condition1';
    END;


	--base_freight_uom validation
	BEGIN
      SELECT distinct UOM_CODE
      INTO l_base_freight_uom
      FROM CT_UOM
      WHERE UOM_CODE = l_freight.base_freight_uom ;
    EXCEPTION WHEN OTHERS THEN
      v_err_flag      := g_err_exist_yes;
      l_error_message := l_error_message||','||'Invalid Base freight uom';
    END;

	--base_freight validation
    --IF l_freight.base_freight <=0 THEN  -- Commented by Mangaiah Ramisetty on 06-05-2019
    IF l_freight.base_freight < 0 THEN
      v_err_flag              := g_err_exist_yes;
      l_error_message         :=l_error_message||','|| 'Base Freight is always >0';
    END IF;

	--tt_days validation
    IF l_freight.tt_days <0 THEN
      v_err_flag        := g_err_exist_yes;
      l_error_message   := l_error_message||','||'TTDays Always >=0';
    END IF;

	--Updating the freight_temp with validation status
    BEGIN
      UPDATE freight_temp
      SET  source_desc = l_source_loc_desc, dest_desc = l_dest_loc_desc,
		   status      = DECODE (v_err_flag, 'N', g_valid_suc_flag, g_valid_err_flag) ,
        error_message = l_error_message
      WHERE id        = l_freight.id;

      COMMIT;
    END;
  END LOOP;
END;

/*
--Fetching all Freight validation Errors
PROCEDURE fetch_freight_errors
AS
  BEGIN
  SELECT JSON_ARRAYAGG( JSON_OBJECT
				('recordID' VALUE id, 
				'transporterSapCode' VALUE transporter_sap_code, 
				'servprov' VALUE servprov, 
				'sourceLoc' VALUE source_loc, 
				'destLoc' VALUE dest_loc, 
				'truckType' VALUE truck_type, 
				--'condition1' VALUE condition1, 
				--'effectiveDate' VALUE effective_date,
				--'expiryDate' VALUE expiry_date, 
				--'ttDays' VALUE tt_days, 
				--'baseFreight' VALUE base_freight, 
				--'baseFreightUom' VALUE base_freight_uom, 
				--'basis' VALUE basis, 
				--'minValue' VALUE min_value,
				--'minValueUom' VALUE min_value_uom,
				'transportMode' VALUE transport_mode,
				'errorMessage' VALUE error_message
				)) INTO p_error_out
  FROM freight_temp
  WHERE status = g_valid_err_flag;
  END;
*/
  --Inserting into FREIGHT Table and archiving data from FREIGHT_TEMP table
  PROCEDURE insert_freight_tbl
  AS
  BEGIN

  MERGE INTO freight f
  USING freight_temp ft
   ON (f.TRANSPORTER_SAP_CODE = ft.TRANSPORTER_SAP_CODE
		and f.servprov= ft.servprov
		and f.source_loc = ft.source_loc
		and f.dest_loc = ft.dest_loc
		and f.truck_type = ft.truck_type
		and nvl(f.condition1,'-') = nvl(ft.condition1,'-')
		and nvl(f.effective_date,sysdate) = nvl(ft.effective_date,sysdate)
		--and nvl(f.expiry_date, sysdate) = nvl(ft.expiry_date, sysdate)
		--and f.transport_mode = ft.transport_mode
		and ft.status = g_valid_suc_flag
    )
	WHEN MATCHED THEN
	--NULL
		/*UPDATE SET f.TRANSPORTER_SAP_CODE = ft.TRANSPORTER_SAP_CODE,
		 f.servprov= ft.servprov,
		 f.source_loc = ft.source_loc,
		 f.source_desc = ft.source_desc,
		 f.dest_loc = ft.dest_loc,
		 f.truck_type = ft.truck_type,
		 f.condition1 = ft.condition1,
		 f.effective_date = ft.effective_date,
		 f.expiry_date = ft. expiry_date,*/
		 UPDATE SET 
		 f.tt_days = ft.tt_days,
		 f.base_freight = ft.base_freight,
         f.base_freight_uom = ft.base_freight_uom,
         f.basis =ft.basis,
         f.min_value = ft.min_value,
         f.min_value_uom  =ft.min_value_uom,
          --Added By Mangaiah Ramisetty on 16-04-2019 --
         f.rate_type = ft.rate_type,
         f.loading = ft.loading,
         f.unloading = ft.unloading,
         f.others1 = ft.others1,
         f.others1_code = ft.others1_code,
         f.others2 = ft.others2,
         f.others2_code = ft.others2_code,
         f.others3 = ft.others3,
         f.others3_code = ft.others3_code,
         -- End of Code --
         f.update_user = p_user,
         f.update_date = sysdate,
         f.distance = ft.distance,
         f.total_expense = (nvl(ft.base_freight,0) + nvl(ft.loading,0) + nvl(ft.unloading,0) + 
                                    nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0)),--ft.total_expense,
         f.payable_transporter = 
         (case 
           when ft.rate_type = 'B' then nvl(ft.base_freight,0)
           when ft.rate_type = 'BLUO' then nvl(ft.base_freight,0) + nvl(ft.loading,0) + nvl(ft.unloading,0) + 
                                          nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0)
           when ft.rate_type = 'BLU' then nvl(ft.base_freight,0) + nvl(ft.loading,0) + nvl(ft.unloading,0)
           when ft.rate_type = 'BUO' then nvl(ft.base_freight,0) +  nvl(ft.unloading,0) + 
                                          nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0)        
           when ft.rate_type = 'BLO' then nvl(ft.base_freight,0) + nvl(ft.loading,0) + 
                                            nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0) 
           when ft.rate_type = 'BL' then nvl(ft.base_freight,0) + nvl(ft.loading,0)  
           when ft.rate_type = 'BU' then nvl(ft.base_freight,0) + nvl(ft.unloading,0)
           when ft.rate_type = 'BO' then nvl(ft.base_freight,0) + nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0) 
          end),
            --ft.payable_transporter,
         f.source_type = ft.source_type,
         f.expiry_date = ft. expiry_date+interval '330' minute,
         f.status = null,
		 --f.transport_mode = ft.transport_mode
         f.remarks = ft.remarks
	WHEN NOT MATCHED THEN
		INSERT
      (
        f.transporter_sap_code ,
        f.servprov ,
        f.source_loc ,
        f.source_desc, 
        f.dest_loc ,
        f.dest_desc ,
        f.lane_code ,
        f.truck_type ,
        f.condition1 ,
        f.condition2,
        f.effective_date ,
        f.expiry_date ,
        f.tt_days ,
        f.base_freight ,
        f.base_freight_uom ,
        f.basis ,
        f.min_value ,
        f.min_value_uom ,
        f.insert_user ,
        f.insert_date,
		f.transport_mode ,
		f.previous_rate
        --Added By Mangaiah Ramisetty on 16-04-2019 --
        ,f.rate_type,
        f.loading,
        f.unloading,
        f.others1,
        f.others1_code,
        f.others2,
        f.others2_code,
        f.others3,
        f.others3_code,
        -- End of Code --
        f.distance,
        f.total_expense,
        f.payable_transporter,
        f.source_type,
        f.remarks
      )
    VALUES (ft.transporter_sap_code ,
      ft.servprov ,
      ft.source_loc ,
	  ft.source_desc,
      ft.dest_loc ,
      ft.dest_desc ,
      ft.lane_code ,
      ft.truck_type ,
      ft.condition1 ,
      ft.condition2,
      ft.effective_date ,
      nvl(ft.expiry_date +interval '330' minute,ft.expiry_date),
      ft.tt_days ,
      ft.base_freight ,
      ft.base_freight_uom ,
      ft.basis ,
      ft.min_value ,
      ft.min_value_uom ,
      p_user ,
      sysdate,
	  ft.transport_mode,
	  -1
      --Added By Mangaiah Ramisetty on 16-04-2019 --
      ,ft.rate_type,
        ft.loading,
        ft.unloading,
        ft.others1,
        ft.others1_code,
        ft.others2,
        ft.others2_code,
        ft.others3,
        ft.others3_code,
        -- End of Code --
        ft.distance,
        --ft.total_expense,
        (nvl(ft.base_freight,0) + nvl(ft.loading,0) + nvl(ft.unloading,0) + 
                                    nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0)),
        --ft.payable_transporter,
        (case 
           when ft.rate_type = 'B' then nvl(ft.base_freight,0)
           when ft.rate_type = 'BLUO' then nvl(ft.base_freight,0) + nvl(ft.loading,0) + nvl(ft.unloading,0) + 
                                          nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0)
           when ft.rate_type = 'BLU' then nvl(ft.base_freight,0) + nvl(ft.loading,0) + nvl(ft.unloading,0)
           when ft.rate_type = 'BUO' then nvl(ft.base_freight,0) +  nvl(ft.unloading,0) + 
                                          nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0)        
           when ft.rate_type = 'BLO' then nvl(ft.base_freight,0) + nvl(ft.loading,0) + 
                                            nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0) 
           when ft.rate_type = 'BL' then nvl(ft.base_freight,0) + nvl(ft.loading,0)  
           when ft.rate_type = 'BU' then nvl(ft.base_freight,0) + nvl(ft.unloading,0)
           when ft.rate_type = 'BO' then nvl(ft.base_freight,0) + nvl(ft.others1,0) + nvl(ft.others2,0) + nvl(ft.others3,0) 
          end),
        ft.source_type,
        ft.remarks
      )
    WHERE ft.status <> g_valid_err_flag;

     --dbms_output.put_line('After Merge = '||sql%rowcount);
    l_affected_rows := sql%rowcount;

    /*SELECT COUNT(*)
    INTO p_tot_error_records
    FROM FREIGHT_TEMP
    WHERE status = g_valid_err_flag;*/
    --Deleting data from FREIGHT_TEMP table
    --DELETE FROM FREIGHT_TEMP ;
    COMMIT;


  END;


  PROCEDURE update_freight_tbl
  AS
  BEGIN

		 UPDATE freight zz
		SET previous_rate =
		  ( WITH T AS
		  (SELECT distinct base_freight , TRANSPORTER_SAP_CODE , servprov, SOURCE_LOC , DEST_LOC, TRUCK_TYPE, NVL(CONDITION1, 'XX') CONDITION1
		  FROM
			(SELECT DENSE_RANK() OVER (PARTITION BY TRANSPORTER_SAP_CODE , SOURCE_LOC , DEST_LOC, TRUCK_TYPE, NVL(CONDITION1, 'XX') ORDER BY effective_date DESC ) RN ,
			  ZZ.*
			FROM freight ZZ
			)
		  WHERE RN = 2 
		  )
		SELECT max(base_freight)
		FROM t
		WHERE t.TRANSPORTER_SAP_CODE = zz.TRANSPORTER_SAP_CODE
		AND t.servprov = zz.servprov
		AND t.SOURCE_LOC             = zz.SOURCE_LOC
		AND t.DEST_LOC               = zz.DEST_LOC
		AND t.TRUCK_TYPE             = zz.TRUCK_TYPE
		AND NVL(t.CONDITION1, 'XX')  = NVL(zz.CONDITION1,'XX')
		--and trunc(T.EFFECTIVE_DATE) = trunc(ZZ.EFFECTIVE_DATE)
		  )
		WHERE NVL(zz.previous_rate, 0) = -1 ; 

		update freight
		set diff = base_freight - previous_rate 
		where diff is null ; 
    begin
		update freight
		set percentile = -(round(100- ((base_freight/previous_rate) * 100), 2))
		where percentile is null ; 
    exception when others then
    null;
    end;

   update freight f
  --  set rate_record_id = 'ATL.'||f.transporter_sap_code||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1
    set rate_record_id = 'ATL.'||f.servprov||'_'||f.source_loc||'_'||f.dest_loc||'_'||f.truck_type||decode(f.condition1,null,'','_')||f.condition1

    where rate_record_id is null;



  END;   


  BEGIN
  purge_freight_temp_tab; 
  parse_freight_data ;
  fill_freight_collection ;
  insert_freight_temp_tbl;
  perform_freight_validation;
  --fetch_freight_errors;
  insert_freight_tbl; 
  update_freight_tbl ;  
  
  atl_business_flow_pkg.freight_approve_notify(p_tot_records,p_user);
  --freight_notify_accounts('UPLOAD',p_user);

  EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => p_user );
  END;


PROCEDURE update_freight_status(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  )
AS
  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_freight_obj json_object_t;
  l_freight_arr json_array_t;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;
  l_old_record_id pls_integer;


  l_id        NUMBER;   --Added by Mangaiah Ramisetty on 18-04-2019
  l_transporter_sap_code VARCHAR2(50);
  l_servprov             VARCHAR2(50);
  l_source_loc           VARCHAR2(50);
  l_dest_loc             VARCHAR2(50);
  l_lane_code            VARCHAR2(50);
  l_truck_type           VARCHAR2(50);
  l_condition1           VARCHAR2(200);
  l_condition2           VARCHAR2(800);
  l_effective_date       VARCHAR2(100);
  l_expiry_date          VARCHAR2(100);
  l_tt_days              NUMBER;
  l_base_freight         NUMBER;
  l_base_freight_uom     VARCHAR2(10);
  l_basis                VARCHAR2(50);
  l_min_value            NUMBER;
  l_min_value_uom        VARCHAR2(10);
  l_transportMode        VARCHAR2(50);
  l_eff_date				date;
  l_exp_date				date;
  l_status        		 VARCHAR2(50);
  
  --- Added by Mangaiah Ramisetty on 16-04-2019 ----
  l_rate_type            VARCHAR2(20);
  l_loading              NUMBER;
  l_unloading            NUMBER;
  l_others1              NUMBER;
  l_others1_code         VARCHAR2(100);
  l_others2              NUMBER;
  l_others2_code         VARCHAR2(100);
  l_others3              NUMBER;
  l_others3_code         VARCHAR2(100);
  --- End of the Code ------
  
  --Added by Akshay Thakur 21-06-2019 ---
  l_distance			      NUMBER;
  l_total_expense		    NUMBER;
  l_payable_transporter	NUMBER;
  l_source_type			    VARCHAR2(20);
  --End of the Code ---

  --Added by Raghava 7-jun-2020
  l_remarks    VARCHAR2(4000);
    
  -- Collection variables
  -- l_freight_data freight_data_list; ---- Commented by Mangaiah Ramisetty on 18-04-2019
  -- l_freight_record freight_data_obj;  ---- Commented by Mangaiah Ramisetty on 18-04-2019
 
  l_freight_data freight_data_upd_list;   -- Added by Mangaiah Ramisetty on 18-04-2019
  l_freight_record freight_data_upd_obj;  --- Added by Mangaiah Ramisetty on 18-04-2019

  -- status
  l_level1_approved  VARCHAR2(20) := 'Level1 Approved';
  l_level2_approved  VARCHAR2(20) := 'Level2 Approved';

  -- Otm reference no from CSV Outbound
  l_otm_reference_no  varchar2(100);

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'update_freight_status';
  l_mt_entity_name    VARCHAR2(100) := 'FREIGHT OUTBOUND';


  PROCEDURE parse_freight_data
  AS
  BEGIN

    -- parsing json data
    l_json_obj    := json_object_t.parse(p_json_data);
    l_freight_arr := l_json_obj.get_array(p_root_element);
    l_count       := l_freight_arr.get_size;
    --  dbms_output.put_line('Data Count '||l_count);
    p_tot_records := l_count;
  END;

  PROCEDURE fill_freight_collection
  AS
  BEGIN
    -- initialize list for dispatch plan
   -- l_freight_data := freight_data_list();  --- Commented by Mangaiah Ramisetty on 18-04-2019
    l_freight_data := freight_data_upd_list(); --- Added by Mangaiah Ramisetty on 18-04-2019
    FOR i IN 0 .. l_count - 1
    LOOP
      l_freight_obj := treat(l_freight_arr.get(i)
                             AS
                             json_object_t);
       l_id                 := l_freight_obj.get_string('id');        --- Added by Mangaiah Ramisetty on 18-04-2019
      l_transporter_sap_code:= trim(l_freight_obj.get_string('transporterSapCode'));
      l_servprov            := trim(l_freight_obj.get_string('servprov'));
      l_source_loc          := trim(l_freight_obj.get_string('sourceLoc'));
	    l_dest_loc          	:= trim(l_freight_obj.get_string('destLoc'));
      --l_lane_code           := l_freight_obj.get_string('truckType');
      l_truck_type          := trim(l_freight_obj.get_string('truckType'));
      l_condition1          := trim(l_freight_obj.get_string('condition1'));
      l_condition2          := trim(l_freight_obj.get_string('condition2'));
      l_effective_date      := l_freight_obj.get_string('effectiveDate');
	 -- select to_char(to_date('Dec 30, 2019 11:59:50 PM','Mon dd, yyyy HH:MI:SS AM'),'dd-MON-yy') from dual;
	    l_eff_date            := to_date(to_char(to_date(l_effective_date,'Mon dd, yyyy HH:MI:SS AM'),'dd-MON-yy hh:mi:ss AM'),'dd-MON-yy hh:mi:ss AM') ;
      l_expiry_date         := l_freight_obj.get_string('expiryDate');
	    l_exp_date			     := to_char(to_date(l_expiry_date,'Mon dd, yyyy HH:MI:SS AM'),'dd-MON-yy');
	    l_tt_days             := l_freight_obj.get_string('ttDays');
      l_base_freight        := l_freight_obj.get_string('baseFreight');
      l_base_freight_uom    := l_freight_obj.get_string('baseFreightUom');
      l_basis               := l_freight_obj.get_string('basis');
      l_min_value           := l_freight_obj.get_string('minValue');
      l_min_value_uom       := l_freight_obj.get_string('minValueUom');
	    l_transportMode       := trim(l_freight_obj.get_string('transportMode'));
      l_status              := l_freight_obj.get_string('status');
      -- Added By Mangaiah Ramisetty on 16-04-2019 ----
        l_rate_type           := l_freight_obj.get_string('rateType');
        l_loading             := l_freight_obj.get_string('loading');
        l_unloading           := l_freight_obj.get_string('unloading');
        l_others1             := l_freight_obj.get_string('others1');
        l_others1_code        := l_freight_obj.get_string('others1Code');
        l_others2             := l_freight_obj.get_string('others2');
        l_others2_code        := l_freight_obj.get_string('others2Code');
        l_others3             := l_freight_obj.get_string('others3');
        l_others3_code        := l_freight_obj.get_string('others3Code');
        
        
  -- End of the Code ----
  
      --Added by Akshay Thakur 21-06-2019 ---
      l_distance                  := l_freight_obj.get_string('distance'); 
      l_total_expense             := l_freight_obj.get_string('totExpense'); 
      l_payable_transporter       := l_freight_obj.get_string('payTransporter'); 
      l_source_type               := l_freight_obj.get_string('sourceType');
      -- End of the Code ---
      
   --Added by Raghava 7-Jun-2020
    l_remarks  := l_freight_obj.get_string('remarks');
  
     --dbms_output.put_line('itemId '||l_item_id);
     /* Commented by Mangaiah on 16-04-2019---
      l_freight_record := freight_data_obj(transporter_sap_code => l_transporter_sap_code, servprov => l_servprov, source_loc => l_source_loc, dest_loc=> l_dest_loc,
											truck_type => l_truck_type, condition1 => l_condition1, effective_date => l_eff_date, 
											expiry_date => l_exp_date, tt_days => l_tt_days, base_freight => l_base_freight, base_freight_uom => l_base_freight_uom,
											basis => l_basis, min_value => l_min_value, min_value_uom => l_min_value_uom,transport_mode => l_transportMode, status=>l_status ); */
                                            
    -- Added by Mangaiah Ramisetty on 16-04-2019 ---
    l_freight_record := freight_data_upd_obj(id => l_id, transporter_sap_code => l_transporter_sap_code, servprov => l_servprov, source_loc => l_source_loc, dest_loc=> l_dest_loc, truck_type => l_truck_type, condition1 => l_condition1, condition2 => l_condition2, effective_date => to_char(l_eff_date,'dd-MON-yy hh:mi:ss AM') , 
                         expiry_date => l_exp_date, tt_days => l_tt_days, base_freight => l_base_freight, base_freight_uom => l_base_freight_uom, basis => l_basis, min_value => l_min_value, min_value_uom => l_min_value_uom, transport_mode => l_transportMode, status => l_status, 
                         rate_type => l_rate_type, loading => l_loading, unloading => l_unloading, others1 => l_others1, others1_code => l_others1_code, others2 => l_others2, others2_code => l_others2_code, others3 => l_others3, 
                         others3_code => l_others3_code,
                         distance => l_distance,total_expense => l_total_expense, payable_transporter => l_payable_transporter,
                         source_type => l_source_type,remarks => l_remarks);
    --End of the code --
      l_freight_data.extend;
      l_freight_data(l_record) := l_freight_record;
      l_record                 := l_record + 1;
      
    END LOOP;
  END;

  PROCEDURE upd_freight_status
  AS
    l_sts VARCHAR2(50);
	l_errm VARCHAR2(5000); 
	l_upd_cnt NUMBER ; 
    l_upd_l1_cnt NUMBER ;  --added to track l1 approval
  l_old_rr_id freight.rate_record_id%type;
  l_id freight.id%type;
  BEGIN
    dbms_output.put_line('l_freight_data count = '||l_freight_data.count);


  BEGIN    
    for i IN l_freight_data.first .. l_freight_data.last
    LOOP
      l_sts := l_freight_data(i).status;
      /*dbms_output.put_line('Status = '||l_sts);
      dbms_output.put_line('l_freight_data(i).TRANSPORTER_SAP_CODE - '||l_freight_data(i).TRANSPORTER_SAP_CODE);
      dbms_output.put_line('l_freight_data(i).servprov - '||l_freight_data(i).servprov);
      dbms_output.put_line('l_freight_data(i).source_loc - '||l_freight_data(i).source_loc);
      dbms_output.put_line('l_freight_data(i).dest_loc - '||l_freight_data(i).dest_loc);
      dbms_output.put_line('l_freight_data(i).truck_type - '||l_freight_data(i).truck_type);
      dbms_output.put_line('l_freight_data(i).condition1 - '||l_freight_data(i).condition1);
      dbms_output.put_line('l_freight_data(i).transport_mode - '||l_freight_data(i).transport_mode);
	  dbms_output.put_line('l_freight_data(i).effective_date:'||l_freight_data(i).effective_date); 
      */
	  --dbms_output.put_line('l_freight_data(i).effective_date - --'||to_date(l_freight_data(i).effective_date,'DD-MON-YY'));
      --dbms_output.put_line('l_freight_data(i).expiry_date - '||to_date(l_freight_data(i).expiry_date,'DD-MON-YY'));

	  
   /* ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => p_user || ':'||l_freight_data(i).effective_date  );  */
	  

      IF l_sts = l_level1_approved
          THEN

            UPDATE freight f
               SET status = l_level1_approved,approval1_user = p_user, approval1_date = sysdate
        /* Commented by Mangaiah Ramisetty on 18-04-2019 ----
             WHERE f.TRANSPORTER_SAP_CODE = l_freight_data(i).transporter_sap_code
               and f.servprov= l_freight_data(i).servprov
               and f.source_loc = l_freight_data(i).source_loc
               and f.dest_loc = l_freight_data(i).dest_loc
               and f.truck_type = l_freight_data(i).truck_type
               and nvl(f.condition1,'-') = nvl(l_freight_data(i).condition1,'-')
               and nvl(to_char(f.effective_date,'DD-MON-YY'),sysdate) = nvl(to_char(to_date(l_freight_data(i).effective_date,'DD-MON-YY')),sysdate)
               and nvl(to_char(f.expiry_date,'DD-MON-YY'),sysdate)= nvl(to_char(to_date(l_freight_data(i).expiry_date,'DD-MON-YY')),sysdate)
               --and nvl(to_char(f.effective_date,'dd-MON-yy'), to_char(sysdate,'dd-MON-yy')) = nvl(l_freight_data(i).effective_date,to_char(sysdate,'dd-MON-yy'))
               and nvl(f.transport_mode,'-') = nvl(l_freight_data(i).transport_mode,'-')
               ---End of Comment ----------------*/
               where f.id = l_freight_data(i).id -- Added by Mangaiah Ramisetty on 18-04-2019
               AND status is null ; 
          
          /*     
           -- added  on 12/20 to send L1 approval mail  
          l_upd_l1_cnt := sql%rowcount;
          if  l_upd_l1_cnt > 0 then
          
          atl_business_flow_pkg.freight_approve_notify(l_upd_l1_cnt,p_user);
          
          end if;
            ---End L1 approval Mail on 12/20 
          */
          END IF;

          IF l_sts = l_level2_approved
          THEN

	-- below records are new records which will get inserted in OTM	  
            UPDATE freight f
               SET status = l_level2_approved||'-OTM'
        /* Commented by Mangaiah Ramisetty on 18-04-2019 ----
             WHERE f.TRANSPORTER_SAP_CODE = l_freight_data(i).TRANSPORTER_SAP_CODE
               and f.servprov= l_freight_data(i).servprov
               and f.source_loc = l_freight_data(i).source_loc
               and f.dest_loc = l_freight_data(i).dest_loc
               and f.truck_type = l_freight_data(i).truck_type
               and nvl(f.condition1,'-') = nvl(l_freight_data(i).condition1,'-')
               and nvl(to_char(f.effective_date,'DD-MON-YY'),sysdate) = nvl(to_char(to_date(l_freight_data(i).effective_date,'DD-MON-YY')),sysdate)
               and nvl(to_char(f.expiry_date,'DD-MON-YY'),sysdate)= nvl(to_char(to_date(l_freight_data(i).expiry_date,'DD-MON-YY')),sysdate)
               and nvl(f.transport_mode,'-') = nvl(l_freight_data(i).transport_mode,'-')
         ---End of Comment ----------------*/
               where f.id = l_freight_data(i).id -- Added by Mangaiah Ramisetty on 18-04-2019
			   and f.status = l_level1_approved;
         
         update freight 
         set  approval2_user = p_user, approval2_date = sysdate
         where id = l_freight_data(i).id ;

			--l_upd_cnt := sql%rowcount  ;   


    ----Below are records updated with expiry date and will get updated in OTM
		/*UPDATE FREIGHT ZZ
		SET 
		status = l_level2_approved||'-OTM',
		EXPIRY_DATE = 
			(SELECT (EFFECTIVE_DATE -1 )  EFFECTIVE_DATE 
			FROM freight ft 
			WHERE LOWER (ft.status) = LOWER (l_level2_approved||'-OTM')
			AND ft.TRANSPORTER_SAP_CODE = zz.TRANSPORTER_SAP_CODE
			AND ft.servprov = zz.servprov
			AND ft.SOURCE_LOC             = zz.SOURCE_LOC
			AND ft.DEST_LOC               = zz.DEST_LOC
			AND ft.TRUCK_TYPE             = zz.TRUCK_TYPE
			AND NVL(ft.CONDITION1, 'XX')  = NVL(zz.CONDITION1,'XX'))
		WHERE status = l_level2_approved and expiry_date is null
             and zz.TRANSPORTER_SAP_CODE = l_freight_data(i).TRANSPORTER_SAP_CODE
               and zz.servprov= l_freight_data(i).servprov
               and zz.source_loc = l_freight_data(i).source_loc
               and zz.dest_loc = l_freight_data(i).dest_loc
               and zz.truck_type = l_freight_data(i).truck_type
               and nvl(zz.condition1,'-') = nvl(l_freight_data(i).condition1,'-')
               and nvl(zz.transport_mode,'-') = nvl(l_freight_data(i).transport_mode,'-');
			*/   
			
	-- To update expiry of older record and then send to OTM for expiring the same RR in OTM		
	begin
	select id 
	into  l_old_record_id
	from (select id from freight a 
					where 
          --a.status = l_level2_approved 
          a.expiry_date is null 
					and a.effective_date < (select effective_date from freight where id = l_freight_data(i).id)
					and a.TRANSPORTER_SAP_CODE = l_freight_data(i).TRANSPORTER_SAP_CODE
				    and a.servprov= l_freight_data(i).servprov
				    and a.source_loc = l_freight_data(i).source_loc
				    and a.dest_loc = l_freight_data(i).dest_loc
				    and a.truck_type = l_freight_data(i).truck_type
				    and nvl(a.condition1,'-') = nvl(l_freight_data(i).condition1,'-')
				    --and nvl(a.transport_mode,'-') = nvl(l_freight_data(i).transport_mode,'-')
					order by a.effective_date desc) where rownum=1;
					
	exception when others then
	l_old_record_id := 0;
	end;

	
	 UPDATE FREIGHT
		SET 
		status = l_level2_approved||'-OTM',
		EXPIRY_DATE = 
			(SELECT (EFFECTIVE_DATE -1 )  EFFECTIVE_DATE 
			FROM freight ft 
			WHERE ft.id = l_freight_data(i).id)
		WHERE id = l_old_record_id;			
		

    
    begin
    /*select zz.rate_record_id,zz.id   
    into l_old_rr_id,l_id
    from freight zz
    where zz.expiry_date is not null 
    and zz.rate_record_id is not null 
    and zz.status = l_level2_approved||'-OTM'
             and zz.TRANSPORTER_SAP_CODE = l_freight_data(i).TRANSPORTER_SAP_CODE
               and zz.servprov= l_freight_data(i).servprov
               and zz.source_loc = l_freight_data(i).source_loc
               and zz.dest_loc = l_freight_data(i).dest_loc
               and zz.truck_type = l_freight_data(i).truck_type
               and nvl(zz.condition1,'-') = nvl(l_freight_data(i).condition1,'-')
               and nvl(zz.transport_mode,'-') = nvl(l_freight_data(i).transport_mode,'-');
    */
	 select zz.rate_record_id,zz.id   
     into l_old_rr_id,l_id
     from freight zz 
	 where zz.id = l_old_record_id;
	
    exception when others then
    l_old_rr_id := 'NO_RATE';
    l_id := 0;
    end;
    
    if l_old_rr_id <> 'NO_RATE' then
    
    UPDATE freight f
               SET otm_rr_id =  l_old_rr_id||'_'||(select to_char(effective_date,'ddmmyy') 
               from freight where id=l_id)
               where f.id = l_freight_data(i).id ;
			 --  and status = l_level1_approved  ;
    
    end if;


	END IF; 

     dbms_output.put_line('Freight count updated :- '||sql%rowcount);

    END LOOP;

    COMMIT;
    END;

  --  IF l_sts = l_level2_approved||'-OTM'
   -- IF l_upd_cnt > 0   THEN
    
    select count(1)
    into l_upd_cnt
    from freight
    where status = l_level2_approved||'-OTM';
    
    if l_upd_cnt > 0 then
    
        --dbms_output.put_line('Before invoking Integration...');
        -- Send the level 2 approved records in CSVs to OTM.
        begin
          l_otm_reference_no := ATL_OTM_INTEGRATION_PKG.send_freight_csvs('DEV','ATL.INTEGRATION','CHANGEME','FREIGHT',null);
          atl_otm_integration_pkg.clear_otm_rate_cache;
          exception when others then
          l_otm_reference_no :='0';
          end;
        --dbms_output.put_line('After invoking Integration...');


         UPDATE FREIGHT f
            SET f.otm_ref_trans_no = l_otm_reference_no, f.status = l_level2_approved--, f.approval2_date = sysdate
          WHERE f.id IN
                    (SELECT id
                       FROM freight ft, CT_OTM_FREIGHT_BASIS bs
                      WHERE     LOWER (ft.status) = LOWER (l_level2_approved||'-OTM')
                            AND LOWER (bs.in_otm) = LOWER ('YES')
                            AND ft.basis = bs.basis);

		UPDATE FREIGHT 
		 set status = l_level2_approved
		WHERE  LOWER (status) = LOWER (l_level2_approved||'-OTM');



        COMMIT;
        
    END IF;
    
     -- This is for Rates notification in Release 24-Nov-2019
     atl_business_flow_pkg.freight_approve_notify(p_tot_records,p_user);


  END;
  
/*PROCEDURE insert_freight_temp_tbl
AS

l_line_num NUMBER :=0;

BEGIN
  delete from freight_temp_notify;
  commit;
  -- Populate FREIGHT_TEMP table.
  --forall i IN l_freight_data.first .. l_freight_data.last
  for i IN l_freight_data.first .. l_freight_data.last
  loop 

  l_line_num := l_line_num +1;

  INSERT
  INTO freight_temp_notify
    ( id, 
      transporter_sap_code ,
      servprov ,
      source_loc ,
      dest_loc
      -- ,lane_code
      ,
      truck_type ,
      condition1 ,
      condition2,
      effective_date ,
      expiry_date ,
      tt_days ,
      base_freight ,
      base_freight_uom ,
      basis ,
      min_value ,
      min_value_uom ,
      transport_mode ,
      status ,
       -- Added By Mangaiah Ramisetty on 16-04-2019 --
      rate_type,
      loading,
      unloading,
      others1,
      others1_code,
      others2,
      others2_code,
      others3,
      others3_code,
      -- End of the Code --
      insert_user ,
      insert_date,
      distance,
      total_expense,
      payable_transporter,
      source_type
    )
    VALUES
    ( l_line_num,
      l_freight_data(i).transporter_sap_code,
      l_freight_data(i).servprov,
      l_freight_data(i).source_loc,
      l_freight_data(i).dest_loc,
      --  l_freight_data(i).lane_code,
      l_freight_data(i).truck_type,
      l_freight_data(i).condition1,
      l_freight_data(i).condition2,
     to_date(l_freight_data(i).effective_date,'dd-MON-yy hh:mi:ss AM'),
	 -- l_freight_data(i).effective_date,
   to_date(l_freight_data(i).expiry_date,'dd-MON-yy hh:mi:ss AM'),
     -- l_freight_data(i).expiry_date,
      l_freight_data(i).tt_days,
      l_freight_data(i).base_freight,
      l_freight_data(i).base_freight_uom,
      l_freight_data(i).basis,
      l_freight_data(i).min_value,
      l_freight_data(i).min_value_uom,
      l_freight_data(i).transport_mode,
      'N' ,
      -- Added by Mangaiah Ramisetty on 16-04-2019 ---
      l_freight_data(i).rate_type,
      l_freight_data(i).loading,
      l_freight_data(i).unloading,
      l_freight_data(i).others1,
      l_freight_data(i).others1_code,
      l_freight_data(i).others2,
      l_freight_data(i).others2_code,
      l_freight_data(i).others3,
      l_freight_data(i).others3_code,
      -- End of the Code ---
      p_user,
      sysdate,
      l_freight_data(i).distance,
      l_freight_data(i).total_expense,
      l_freight_data(i).payable_transporter,
      l_freight_data(i).source_type
    );
    end loop; 
  COMMIT;
END;*/
  

BEGIN

  parse_freight_data;
  fill_freight_collection;
  upd_freight_status;  
  
  -- for notification
  --insert_freight_temp_tbl;
  --freight_notify_accounts('APPROVE',p_user);
  

EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => p_user );  
END;

---Added by Mangaiah Ramisetty on 23-04-2019

PROCEDURE upload_location_scan_data(
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_location_id VARCHAR2(20);
  l_scannable             VARCHAR2(1);
  l_item_category           VARCHAR2(20);
  
  -- Collection variables
  l_location_scan_data location_scan_data_list;
  l_location_scan_record location_scan_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_location_scan_obj json_object_t;
  l_location_scan_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'upload_location_scan_data';
  l_mt_entity_name    VARCHAR2(100) := 'LOCATION_SCAN';

  
  PROCEDURE parse_location_scan_data
  AS
  BEGIN
  --dbms_output.put_line ( 'From Insert location from parse_location_scan_data');
    -- parsing json data
    l_json_obj    		:= json_object_t.parse(p_json_data);
    l_location_scan_arr := l_json_obj.get_array(p_root_element);
    l_count       		:= l_location_scan_arr.get_size;
    p_tot_records 		:= l_count;
  END;

  PROCEDURE fill_location_scan_collection
  AS
  BEGIN
  --dbms_output.put_line ( 'From Insert location from fill_location_scan_collection');
    l_location_scan_data := location_scan_data_list();
   -- dbms_output.put_line ( 'From Insert location from fill_location_scan_collection ');
    FOR i IN 0 .. l_count - 1
    LOOP
      l_location_scan_obj 	:= treat(l_location_scan_arr.get(i) AS json_object_t);
      l_location_id			:= trim(l_location_scan_obj.get_string('locationId'));
      l_scannable       	:= trim(l_location_scan_obj.get_string('scannable'));
      l_item_category     	:= trim(l_location_scan_obj.get_string('itemCategory'));
	  
      l_location_scan_record 			:= location_scan_data_obj(location_id => l_location_id, scannable => l_scannable, item_category => l_item_category);
      l_location_scan_data.extend;
      l_location_scan_data(l_record) 	:= l_location_scan_record;
      l_record                 			:= l_record + 1;
    END LOOP;
  END;


PROCEDURE insert_location_scan
AS
BEGIN
  -- Populate LOCATION_SCAN table.
  --dbms_output.put_line ( 'From Insert location from before loop');
  for i IN l_location_scan_data.first .. l_location_scan_data.last
  
  loop 
 --dbms_output.put_line ( 'From Insert location from for loop');
 
 --dbms_output.put_line ( 'From Insert location from for loop:' || l_location_scan_data(i).location_id);
  INSERT
  INTO location_scan
    ( location_id, 
      scannable,
      item_category,
      insert_user,
      insert_date
    )
    VALUES
    ( l_location_scan_data(i).location_id,
      l_location_scan_data(i).scannable,
      l_location_scan_data(i).item_category,
      p_user,
      sysdate
    );
    end loop; 
  COMMIT;
END;

  BEGIN
  
  parse_location_scan_data ;
  fill_location_scan_collection ;
  insert_location_scan;
 

/*  EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
--End of the Code ---

--Added by Mangaiah Ramisetty on 24-04-2019---
PROCEDURE update_location_scan(
      p_json_data CLOB,
      p_root_element VARCHAR2,
      p_user         VARCHAR2,
      p_tot_records OUT NUMBER
	  )
AS
	-- Variables for JSON processing
	l_json_obj json_object_t;
	l_location_scan_obj json_object_t;
	l_location_scan_arr json_array_t;

	-- Common variables
	l_record INT := 1;
	l_count pls_integer;


	l_location_id        		VARCHAR2(20); 
	l_scannable 				VARCHAR2(1);
	l_item_category           VARCHAR2(20);
  

	-- Collection variables
	l_location_scan_data location_scan_data_list;   
	l_location_scan_record location_scan_data_obj; 

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) := 'update_location_scan';
	l_mt_entity_name    VARCHAR2(100) := 'LOCATION_SCAN';


  PROCEDURE parse_location_scan_data
  AS
  BEGIN

    -- parsing json data
    l_json_obj    := json_object_t.parse(p_json_data);
    l_location_scan_arr := l_json_obj.get_array(p_root_element);
    l_count       := l_location_scan_arr.get_size;
	
    --  dbms_output.put_line('Data Count '||l_count);
    p_tot_records := l_count;
	
  END;

  PROCEDURE fill_location_scan_collection
  AS
  BEGIN
    -- initialize list for dispatch plan
	l_location_scan_data := location_scan_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
		l_location_scan_obj := treat(l_location_scan_arr.get(i) AS json_object_t);
		l_location_id                 := l_location_scan_obj.get_string('locationId');       
		l_scannable:= trim(l_location_scan_obj.get_string('scannable'));
		l_item_category            := trim(l_location_scan_obj.get_string('itemCategory'));
      
		l_location_scan_record := location_scan_data_obj(location_id => l_location_id, scannable => l_scannable, item_category => l_item_category);
		l_location_scan_data.extend;
		l_location_scan_data(l_record) := l_location_scan_record;
		l_record                 := l_record + 1;
    END LOOP;
  END;

  PROCEDURE upd_location_scan
  AS
    l_errm VARCHAR2(5000); 
	l_upd_cnt NUMBER ; 

  BEGIN    
    for i IN l_location_scan_data.first .. l_location_scan_data.last
    LOOP
      
        UPDATE location_scan SET scannable = l_scannable, update_user = p_user, update_date = sysdate
        where location_id = l_location_scan_data(i).location_id 
		and	item_category = l_location_scan_data(i).item_category;
         
		l_upd_cnt := sql%rowcount  ;   
		dbms_output.put_line('Freight count updated :- '||sql%rowcount);
    END LOOP;
	COMMIT;
  END;

BEGIN

  parse_location_scan_data;
  fill_location_scan_collection;
  upd_location_scan;  

/*EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode ,p_sql_errm => sqlerrm,p_user => p_user );  
*/
END;
--End of the Code--

---Added by Mangaiah Ramisetty on 24-04-2019---

PROCEDURE upload_batch_code_data(
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_batch_code 				VARCHAR2(100);
  l_category             	VARCHAR2(20);
  l_plant_code           	VARCHAR2(20);
  l_batch_description		VARCHAR2(50);
  l_bc_id                 	NUMBER;
  -- Collection variables
  l_batch_code_data batch_code_data_list;
  l_batch_code_record batch_code_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_batch_code_obj json_object_t;
  l_batch_code_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'upload_batch_code_data';
  l_mt_entity_name    VARCHAR2(100) := 'MT_BATCH_CODES';

  
  PROCEDURE parse_batch_codes_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    		:= json_object_t.parse(p_json_data);
    l_batch_code_arr := l_json_obj.get_array(p_root_element);
    l_count       		:= l_batch_code_arr.get_size;
    p_tot_records 		:= l_count;
  END;

  PROCEDURE fill_batch_code_collection
  AS
  BEGIN
    l_batch_code_data := batch_code_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_batch_code_obj 	:= treat(l_batch_code_arr.get(i) AS json_object_t);
	  
      l_batch_code		:= trim(l_batch_code_obj.get_string('batchCode'));
      l_category       	:= trim(l_batch_code_obj.get_string('category'));
      l_plant_code     	:= trim(l_batch_code_obj.get_string('plantCode'));
	  l_batch_description := trim(l_batch_code_obj.get_string('batchDescription'));
      l_bc_id           := null;
	  
      l_batch_code_record 			:= batch_code_data_obj(bc_id => l_bc_id, batch_code => l_batch_code, category => l_category, plant_code => l_plant_code, batch_description => l_batch_description);
      l_batch_code_data.extend;
      l_batch_code_data(l_record) 	:= l_batch_code_record;
      l_record                 			:= l_record + 1;
    END LOOP;
  END;


PROCEDURE insert_batch_codes
AS
l_count number;
BEGIN
  -- Populate MT_BATCH_CODES table.
  for i IN l_batch_code_data.first .. l_batch_code_data.last
  loop 
    --dbms_output.put_line(l_batch_code_data(i).batch_code);
    --dbms_output.put_line(l_batch_code_data(i).category);
    --dbms_output.put_line(l_batch_code_data(i).plant_code);
    --dbms_output.put_line(l_batch_code_data(i).batch_description);
    
  INSERT
  INTO MT_BATCH_CODES
    ( batch_code, 
      category,
      plant_code,
	  batch_description,
      insert_user,
      insert_date
    )
    VALUES
    ( l_batch_code_data(i).batch_code,
      l_batch_code_data(i).category,
      l_batch_code_data(i).plant_code,
	  l_batch_code_data(i).batch_description,
      p_user,
      sysdate
    );
    
    -- CODE ADDED BY : AMAN GUMASTA (11-SEP-2020)
    if l_batch_code_data(i).category in ('Tyre','TYRE','tyre') then
    
       select count(1)
       into l_count
       from MT_PLANT_BATCH
       where PLANT_ID=l_batch_code_data(i).plant_code;
       
          if l_count=0 then
          
             INSERT
             INTO MT_PLANT_BATCH
             ( plant_id,
               batch_code,
               item_classification
             )
             VALUES
             ( l_batch_code_data(i).plant_code,
               substr(l_batch_code_data(i).batch_code,1,2),
               'TYRE'
             );
          end if;
          l_count := 0;
      end if;
   end loop; 
  COMMIT;
END;

  BEGIN
  
  parse_batch_codes_data ;
  fill_batch_code_collection ;
  insert_batch_codes;
 

 /* EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
  
--End of the Code--

--Added by Mangaiah Ramisetty on 24-04-2019---
PROCEDURE update_batch_code_data(
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_batch_code 				VARCHAR2(100);
  l_category             	VARCHAR2(20);
  l_plant_code           	VARCHAR2(20);
  l_batch_description		VARCHAR2(50);
  l_bc_id                   NUMBER;
  
  -- Collection variables
  l_batch_code_data batch_code_data_list;
  l_batch_code_record batch_code_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_batch_code_obj json_object_t;
  l_batch_code_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'upload_batch_code_data';
  l_mt_entity_name    VARCHAR2(100) := 'MT_BATCH_CODES';

  
  PROCEDURE parse_batch_codes_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    		:= json_object_t.parse(p_json_data);
    l_batch_code_arr := l_json_obj.get_array(p_root_element);
    l_count       		:= l_batch_code_arr.get_size;
    p_tot_records 		:= l_count;
  END;

  PROCEDURE fill_batch_code_collection
  AS
  BEGIN
    l_batch_code_data := batch_code_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_batch_code_obj 	:= treat(l_batch_code_arr.get(i) AS json_object_t);
      l_batch_code			:= trim(l_batch_code_obj.get_string('batchCode'));
      l_category       	:= trim(l_batch_code_obj.get_string('category'));
      l_plant_code     	:= trim(l_batch_code_obj.get_string('plantCode'));
	  l_batch_description := trim(l_batch_code_obj.get_string('batchDescription'));
	  l_bc_id           := l_batch_code_obj.get_string('bcId');
      l_batch_code_record 			:= batch_code_data_obj(bc_id => l_bc_id, batch_code => l_batch_code, category => l_category, plant_code => l_plant_code, batch_description => l_batch_description);
      l_batch_code_data.extend;
      l_batch_code_data(l_record) 	:= l_batch_code_record;
      l_record                 			:= l_record + 1;
    END LOOP;
  END;


PROCEDURE update_batch_codes
AS
l_count number;
BEGIN
  for i IN l_batch_code_data.first .. l_batch_code_data.last
  loop 

	UPDATE 	MT_BATCH_CODES SET	batch_code =  l_batch_code_data(i).batch_code,
                                category = l_batch_code_data(i).category,
                                plant_code = l_batch_code_data(i).plant_code,
                                batch_description = l_batch_code_data(i).batch_description, 
								update_user = p_user,
								update_date = sysdate
	WHERE 	bc_id =  l_batch_code_data(i).bc_id;
    
    -- CODE ADDED BY : AMAN GUMASTA (11-SEP-2020)
    if l_batch_code_data(i).category in ('Tyre','TYRE','tyre') then
    
       select count(1)
       into l_count
       from MT_PLANT_BATCH
       where PLANT_ID=l_batch_code_data(i).plant_code;
       
          if l_count=0 then
             INSERT
             INTO MT_PLANT_BATCH
             ( plant_id,
               batch_code,
               item_classification
             )
             VALUES
             ( l_batch_code_data(i).plant_code,
               substr(l_batch_code_data(i).batch_code,1,2),
               'TYRE'
             );
          end if;
          l_count := 0;
     end if;
    
  end loop; 
  COMMIT;
END;

  BEGIN
  
	parse_batch_codes_data ;
	fill_batch_code_collection ;
	update_batch_codes;
 

	/*EXCEPTION 
	WHEN OTHERS THEN 
		ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
--End of the Code--

--Added by Mangaiah Ramisetty on 24-04-2019---
PROCEDURE upload_sap_truck_type_data(
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_sap_truck_type					VARCHAR2(20);
  l_sap_truck_type_desc            	VARCHAR2(100);
  l_ops_truck_type           		VARCHAR2(20);
  l_ops_variant_1					VARCHAR2(20);
  
  -- Collection variables
  l_sap_truck_type_data sap_truck_type_data_list;
  l_sap_truck_type_record sap_truck_type_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_sap_truck_type_obj json_object_t;
  l_sap_truck_type_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'upload_sap_truck_type_data';
  l_mt_entity_name    VARCHAR2(100) := 'MT_SAP_TRUCK_TYPE';

  
  PROCEDURE parse_sap_truck_type_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    		:= json_object_t.parse(p_json_data);
    l_sap_truck_type_arr := l_json_obj.get_array(p_root_element);
    l_count       		:= l_sap_truck_type_arr.get_size;
    p_tot_records 		:= l_count;
  END;

  PROCEDURE fill_sap_truck_type_collection
  AS
  BEGIN
    l_sap_truck_type_data := sap_truck_type_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_sap_truck_type_obj 	:= treat(l_sap_truck_type_arr.get(i) AS json_object_t);
      l_sap_truck_type			:= trim(l_sap_truck_type_obj.get_string('sapTruckType'));
      l_sap_truck_type_desc       	:= trim(l_sap_truck_type_obj.get_string('sapTruckTypeDesc'));
      l_ops_truck_type     	:= trim(l_sap_truck_type_obj.get_string('opsTruckType'));
	  l_ops_variant_1 := trim(l_sap_truck_type_obj.get_string('opsVariant1'));
	  
      l_sap_truck_type_record 			:= sap_truck_type_data_obj(sap_truck_type => l_sap_truck_type, sap_truck_type_desc => l_sap_truck_type_desc, ops_truck_type => l_ops_truck_type, ops_variant_1 => l_ops_variant_1);
      l_sap_truck_type_data.extend;
      l_sap_truck_type_data(l_record) 	:= l_sap_truck_type_record;
      l_record                 			:= l_record + 1;
    END LOOP;
  END;


PROCEDURE insert_sap_truck_type
AS
BEGIN
  -- Populate MT_SAP_TRUCK_TYPE table.
  for i IN l_sap_truck_type_data.first .. l_sap_truck_type_data.last
  loop 

  INSERT
  INTO 	MT_SAP_TRUCK_TYPE
		( 	--stt_id,
			sap_truck_type, 
			sap_truck_type_desc,
			ops_truck_type,
			ops_variant_1,
			insert_user,
			insert_date
		)
    VALUES
		( 	--paas_master_data_seq.nextval,
			l_sap_truck_type_data(i).sap_truck_type,
			l_sap_truck_type_data(i).sap_truck_type_desc,
			l_sap_truck_type_data(i).ops_truck_type,
			l_sap_truck_type_data(i).ops_variant_1,
			p_user,
			sysdate
		);
    end loop; 
  COMMIT;
END;

  BEGIN
  
	parse_sap_truck_type_data ;
	fill_sap_truck_type_collection ;
	insert_sap_truck_type;
 

 /* EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
--End of the Code--

--Added by Mangaiah Ramisetty on 27-04-2019---
PROCEDURE update_sap_truck_type_data(
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_sap_truck_type					VARCHAR2(20);
  l_sap_truck_type_desc            	VARCHAR2(100);
  l_ops_truck_type           		VARCHAR2(20);
  l_ops_variant_1					VARCHAR2(20);
  l_stt_id							NUMBER;
  
  -- Collection variables
  l_sap_truck_type_data upd_sap_truck_type_data_list;
  l_sap_truck_type_record upd_sap_truck_type_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_sap_truck_type_obj json_object_t;
  l_sap_truck_type_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'upload_sap_truck_type_data';
  l_mt_entity_name    VARCHAR2(100) := 'MT_SAP_TRUCK_TYPE';

  
  PROCEDURE parse_sap_truck_type_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    		:= json_object_t.parse(p_json_data);
    l_sap_truck_type_arr := l_json_obj.get_array(p_root_element);
    l_count       		:= l_sap_truck_type_arr.get_size;
    p_tot_records 		:= l_count;
  END;

  PROCEDURE fill_sap_truck_type_collection
  AS
  BEGIN
    l_sap_truck_type_data := upd_sap_truck_type_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_sap_truck_type_obj 	:= treat(l_sap_truck_type_arr.get(i) AS json_object_t);
	  
      l_sap_truck_type			:= trim(l_sap_truck_type_obj.get_string('sapTruckType'));
      l_sap_truck_type_desc       	:= trim(l_sap_truck_type_obj.get_string('sapTruckTypeDesc'));
      l_ops_truck_type     	:= trim(l_sap_truck_type_obj.get_string('opsTruckType'));
	  l_ops_variant_1 := trim(l_sap_truck_type_obj.get_string('opsVariant1'));
	  l_stt_id			:= l_sap_truck_type_obj.get_string('sttId');
	  
      l_sap_truck_type_record 			:= upd_sap_truck_type_data_obj(stt_id => l_stt_id, sap_truck_type => l_sap_truck_type, sap_truck_type_desc => l_sap_truck_type_desc, ops_truck_type => l_ops_truck_type, ops_variant_1 => l_ops_variant_1);
      l_sap_truck_type_data.extend;
      l_sap_truck_type_data(l_record) 	:= l_sap_truck_type_record;
      l_record                 			:= l_record + 1;
    END LOOP;
  END;


PROCEDURE update_sap_truck_type
AS
BEGIN
  -- Populate MT_SAP_TRUCK_TYPE table.
  for i IN l_sap_truck_type_data.first .. l_sap_truck_type_data.last
  loop 

	UPDATE MT_SAP_TRUCK_TYPE SET 
			sap_truck_type = l_sap_truck_type_data(i).sap_truck_type, 
			sap_truck_type_desc = l_sap_truck_type_data(i).sap_truck_type_desc,
			ops_truck_type = l_sap_truck_type_data(i).ops_truck_type,
			ops_variant_1 = l_sap_truck_type_data(i).ops_variant_1,
			update_user = p_user,
			update_date = sysdate
	WHERE	stt_id = l_sap_truck_type_data(i).stt_id;
  end loop; 
  COMMIT;
END;

  BEGIN
  
	parse_sap_truck_type_data ;
	fill_sap_truck_type_collection ;
	update_sap_truck_type;
 

  /*EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
--End of the Code--



--Added by Mangaiah Ramisetty on 26-04-2019---
PROCEDURE insert_truck_type_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS

	l_truck_type					VARCHAR2(50);
	l_truck_desc            		VARCHAR2(50);
	l_variant1           			VARCHAR2(50);
	l_variant2						VARCHAR2(50);
	l_load_factor					number;  
	l_tte_capacity       			number;       
	l_gross_wt           			number;      
	l_gross_wt_uom       			varchar2(5);  
	l_gross_vol         			number;       
	l_gross_vol_uom    				varchar2(5);
  
	-- Collection variables
	l_truck_type_data 		truck_type_data_list;
	l_truck_type_record 	truck_type_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_truck_type_obj 	json_object_t;
	l_truck_type_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'insert_truck_type_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_TRUCK_TYPE';

  
	PROCEDURE parse_truck_type_data
	AS
	BEGIN
        --DBMS_OUTPUT.PUT_LINE (' FROM parse_truck_type_data');
		-- parsing json data
		l_json_obj    		:= json_object_t.parse(p_json_data);
		l_truck_type_arr 	:= l_json_obj.get_array(p_root_element);
		l_count       		:= l_truck_type_arr.get_size;
		p_tot_records 		:= l_count;
	END;

	PROCEDURE fill_truck_type_collection
	AS
	BEGIN
    --DBMS_OUTPUT.PUT_LINE (' FROM fill_truck_type_collection');
		l_truck_type_data := truck_type_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_truck_type_obj 		:= treat(l_truck_type_arr.get(i) AS json_object_t);
			l_truck_type			:= trim(l_truck_type_obj.get_string('truckType'));
			l_truck_desc       		:= trim(l_truck_type_obj.get_string('truckDesc'));
			l_variant1     			:= trim(l_truck_type_obj.get_string('variant1'));
			l_variant2 				:= trim(l_truck_type_obj.get_string('variant2'));
			l_load_factor			:= trim(l_truck_type_obj.get_string('loadFactor'));
			l_tte_capacity       	:= trim(l_truck_type_obj.get_string('tteCapacity'));  
			l_gross_wt           	:= trim(l_truck_type_obj.get_string('grossWt')); 
			l_gross_wt_uom       	:= trim(l_truck_type_obj.get_string('grossWtUom'));
			l_gross_vol         	:= trim(l_truck_type_obj.get_string('grossVol')); 
			l_gross_vol_uom    		:= trim(l_truck_type_obj.get_string('grossVolUom'));
	  
			l_truck_type_record 			:= truck_type_data_obj(	truck_type => l_truck_type, truck_desc => l_truck_desc, variant1 => l_variant1, variant2 => l_variant2,
																	load_factor => l_load_factor, tte_capacity => l_tte_capacity, gross_wt => l_gross_wt, gross_wt_uom => l_gross_wt_uom,
																	gross_vol => l_gross_vol, gross_vol_uom => l_gross_vol_uom);
			l_truck_type_data.extend;
			l_truck_type_data(l_record) 	:= l_truck_type_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE insert_truck_type
	AS
	BEGIN
        --DBMS_OUTPUT.PUT_LINE (' FROM insert_truck_type');
		-- Populate mt_truck_type table.
		FOR i IN l_truck_type_data.first .. l_truck_type_data.last LOOP 
        --DBMS_OUTPUT.PUT_LINE (' FROM insert_truck_type LOOP');
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).truck_type);
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).truck_desc);
       -- DBMS_OUTPUT.PUT_LINE (paas_master_data_seq.nextval);
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).variant1);
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).variant2);
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).load_factor);
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).tte_capacity);
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).gross_wt);
      --  DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).gross_wt_uom);
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).gross_vol);
       -- DBMS_OUTPUT.PUT_LINE (l_truck_type_data(i).gross_vol_uom);
       -- DBMS_OUTPUT.PUT_LINE (p_user);
       -- DBMS_OUTPUT.PUT_LINE (sysdate);
			INSERT INTO mt_truck_type	
				(--tt_id,
					truck_type, 
					truck_desc,
					variant1,
					variant2,
					load_factor,
					tte_capacity,
					gross_wt,
					gross_wt_uom,
					gross_vol,
					gross_vol_uom,
					insert_user,
					insert_date)
			VALUES	
				(--paas_master_data_seq.nextval,
					l_truck_type_data(i).truck_type,
					l_truck_type_data(i).truck_desc,
					l_truck_type_data(i).variant1,
					l_truck_type_data(i).variant2,
					l_truck_type_data(i).load_factor,
					l_truck_type_data(i).tte_capacity,
					l_truck_type_data(i).gross_wt,
					l_truck_type_data(i).gross_wt_uom,
					l_truck_type_data(i).gross_vol,
					l_truck_type_data(i).gross_vol_uom,
					p_user,
					sysdate);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_truck_type_data ;
	fill_truck_type_collection ;
	insert_truck_type;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 26-04-2019---
PROCEDURE update_truck_type_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_tt_id							number;
	l_truck_type					VARCHAR2(50);
	l_truck_desc            		VARCHAR2(50);
	l_variant1           			VARCHAR2(50);
	l_variant2						VARCHAR2(50);
	l_load_factor					number;  
	l_tte_capacity       			number;       
	l_gross_wt           			number;      
	l_gross_wt_uom       			varchar2(5);  
	l_gross_vol         			number;       
	l_gross_vol_uom    				varchar2(5);
  
	-- Collection variables
	l_truck_type_data 		upd_truck_type_data_list;
	l_truck_type_record 	upd_truck_type_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_truck_type_obj 	json_object_t;
	l_truck_type_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'update_truck_type_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_TRUCK_TYPE';

  
	PROCEDURE parse_truck_type_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    		:= json_object_t.parse(p_json_data);
		l_truck_type_arr 	:= l_json_obj.get_array(p_root_element);
		l_count       		:= l_truck_type_arr.get_size;
		p_tot_records 		:= l_count;
	END;

	PROCEDURE fill_truck_type_collection
	AS
	BEGIN
		l_truck_type_data := upd_truck_type_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_truck_type_obj 		:= treat(l_truck_type_arr.get(i) AS json_object_t);
			
			l_tt_id					:= trim(l_truck_type_obj.get_string('ttId'));
			l_truck_type			:= trim(l_truck_type_obj.get_string('truckType'));
			l_truck_desc       		:= trim(l_truck_type_obj.get_string('truckDesc'));
			l_variant1     			:= trim(l_truck_type_obj.get_string('variant1'));
			l_variant2 				:= trim(l_truck_type_obj.get_string('variant2'));
			l_load_factor			:= trim(l_truck_type_obj.get_string('loadFactor'));
			l_tte_capacity       	:= trim(l_truck_type_obj.get_string('tteCapacity'));  
			l_gross_wt           	:= trim(l_truck_type_obj.get_string('grossWt')); 
			l_gross_wt_uom       	:= trim(l_truck_type_obj.get_string('grossWtUom'));
			l_gross_vol         	:= trim(l_truck_type_obj.get_string('grossVol')); 
			l_gross_vol_uom    		:= trim(l_truck_type_obj.get_string('grossVolUom'));
	  
			l_truck_type_record 			:= upd_truck_type_data_obj(	tt_id => l_tt_id, truck_type => l_truck_type, truck_desc => l_truck_desc, variant1 => l_variant1, 
																		variant2 => l_variant2, load_factor => l_load_factor, tte_capacity => l_tte_capacity, gross_wt => l_gross_wt, 
																		gross_wt_uom => l_gross_wt_uom, gross_vol => l_gross_vol, gross_vol_uom => l_gross_vol_uom);
			l_truck_type_data.extend;
			l_truck_type_data(l_record) 	:= l_truck_type_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_truck_type
	AS
	BEGIN
		FOR i IN l_truck_type_data.first .. l_truck_type_data.last LOOP 
			UPDATE mt_truck_type set 	
					truck_type = l_truck_type_data(i).truck_type,
					truck_desc = l_truck_type_data(i).truck_desc,
					variant1 = l_truck_type_data(i).variant1,
					variant2 = l_truck_type_data(i).variant2,
					load_factor = l_truck_type_data(i).load_factor,
					tte_capacity = l_truck_type_data(i).tte_capacity,
					gross_wt = l_truck_type_data(i).gross_wt,
					gross_wt_uom = l_truck_type_data(i).gross_wt_uom,
					gross_vol = l_truck_type_data(i).gross_vol,
					gross_vol_uom = l_truck_type_data(i).gross_vol_uom,
					update_user = p_user,
					update_date = sysdate
			WHERE	tt_id = l_truck_type_data(i).tt_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_truck_type_data ;
	fill_truck_type_collection ;
	update_truck_type;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 27-04-2019---
PROCEDURE upload_material_group_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS

	l_material_group_id					VARCHAR2(20);
	l_description_1            			VARCHAR2(100);
	l_description_2						VARCHAR2(100); 
	l_scm_group       					VARCHAR2(20);       
	
	-- Collection variables
	l_material_group_data 		material_group_data_list;
	l_material_group_record 	material_group_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_material_group_obj 	json_object_t;
	l_material_group_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'upload_material_group_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_MATERIAL_GROUP';

  
	PROCEDURE parse_material_group_data
	AS
	BEGIN
        dbms_output.put_line ( 'From Insert location from parse_material_group_data');
		-- parsing json data
		l_json_obj    			:= json_object_t.parse(p_json_data);
		l_material_group_arr 	:= l_json_obj.get_array(p_root_element);
		l_count       			:= l_material_group_arr.get_size;
		p_tot_records 			:= l_count;
	END;

	PROCEDURE fill_material_group_collection
	AS
	BEGIN
    dbms_output.put_line ( 'From fill_material_group_collection');
		l_material_group_data := material_group_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_material_group_obj 		:= treat(l_material_group_arr.get(i) AS json_object_t);
			
			l_material_group_id			:= trim(l_material_group_obj.get_string('materialGroupId'));
			l_description_1       		:= trim(l_material_group_obj.get_string('description_1'));
			l_description_2				:= trim(l_material_group_obj.get_string('description_2'));
			l_scm_group       			:= trim(l_material_group_obj.get_string('scmGroup'));  
			
			l_material_group_record 			:= material_group_data_obj(	material_group_id => l_material_group_id, description_1 => l_description_1, description_2 => l_description_2, scm_group => l_scm_group);
			l_material_group_data.extend;
			l_material_group_data(l_record) 	:= l_material_group_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE insert_material_group
	AS
	BEGIN
    dbms_output.put_line ( 'insert_material_group from before loop');
		-- Populate mt_material_group table.
		FOR i IN l_material_group_data.first .. l_material_group_data.last LOOP 
        
        dbms_output.put_line ( 'insert_material_group from for loop');
        dbms_output.put_line ( 'insert_material_group from for loop:' ||l_material_group_data(i).material_group_id);
			INSERT INTO mt_material_group	
				( 	--mg_id,
					material_group_id, 
					description_1,
					description_2,
					scm_group,
					insert_user,
					insert_date
				)
			VALUES	
				( 	--paas_master_data_seq.nextval,
					l_material_group_data(i).material_group_id,
					l_material_group_data(i).description_1,
					l_material_group_data(i).description_2,
					l_material_group_data(i).scm_group,
					p_user,
					sysdate
				);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_material_group_data ;
	fill_material_group_collection ;
	insert_material_group;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 27-04-2019---
PROCEDURE update_material_group_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_mg_id							number;
	l_material_group_id				VARCHAR2(20);
	l_description_1            		VARCHAR2(100);
	l_description_2					VARCHAR2(100);  
	l_scm_group       				VARCHAR2(20);      
	
	-- Collection variables
	l_material_group_data 		upd_material_group_data_list;
	l_material_group_record 	upd_material_group_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_material_group_obj 	json_object_t;
	l_material_group_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'update_material_group_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_MATERIAL_GROUP';

  
	PROCEDURE parse_material_group_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    			:= json_object_t.parse(p_json_data);
		l_material_group_arr 	:= l_json_obj.get_array(p_root_element);
		l_count       			:= l_material_group_arr.get_size;
		p_tot_records 			:= l_count;
	END;

	PROCEDURE fill_material_group_collection
	AS
	BEGIN
		l_material_group_data := upd_material_group_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_material_group_obj 		:= treat(l_material_group_arr.get(i) AS json_object_t);
			
			l_mg_id						:= trim(l_material_group_obj.get_string('mgId'));
			l_material_group_id			:= trim(l_material_group_obj.get_string('materialGroupId'));
			l_description_1       		:= trim(l_material_group_obj.get_string('description_1'));
			l_description_2				:= trim(l_material_group_obj.get_string('description_2'));
			l_scm_group       			:= trim(l_material_group_obj.get_string('scmGroup'));  
			
			l_material_group_record 			:= upd_material_group_data_obj(	mg_id => l_mg_id, material_group_id => l_material_group_id, description_1 => l_description_1, description_2 => l_description_2, scm_group => l_scm_group);
			l_material_group_data.extend;
			l_material_group_data(l_record) 	:= l_material_group_record;
			l_record                 			:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_material_group
	AS
	BEGIN
		FOR i IN l_material_group_data.first .. l_material_group_data.last LOOP 
			UPDATE 	mt_material_group set 	
					material_group_id = l_material_group_data(i).material_group_id,
					description_1 = l_material_group_data(i).description_1,
					description_2 = l_material_group_data(i).description_2,
					scm_group = l_material_group_data(i).scm_group,
					update_user = p_user,
					update_date = sysdate
			WHERE	mg_id = l_material_group_data(i).mg_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_material_group_data ;
	fill_material_group_collection ;
	update_material_group;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 27-04-2019---
PROCEDURE insert_mt_valve_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS

	l_item_id						VARCHAR2(20);
	l_item_description           	VARCHAR2(200);
	l_item_category           		VARCHAR2(20);
	l_batch_code					VARCHAR2(20);
    l_valve_id                      NUMBER;
	
	-- Collection variables
	l_mt_valve_data 		mt_valve_list;
	l_mt_valve_record 		mt_valve_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_mt_valve_obj 		json_object_t;
	l_mt_valve_arr 		json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 		NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'insert_mt_valve_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_VALVE';

  
	PROCEDURE parse_mt_valve
	AS
	BEGIN
		-- parsing json data
		l_json_obj    		:= json_object_t.parse(p_json_data);
		l_mt_valve_arr 		:= l_json_obj.get_array(p_root_element);
		l_count       		:= l_mt_valve_arr.get_size;
		p_tot_records 		:= l_count;
	END;

	PROCEDURE fill_mt_valve_collection
	AS
	BEGIN
		l_mt_valve_data := mt_valve_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_mt_valve_obj 				:= treat(l_mt_valve_arr.get(i) AS json_object_t);
			
			l_item_id					:= trim(l_mt_valve_obj.get_string('itemId'));
			l_item_description       	:= trim(l_mt_valve_obj.get_string('itemDescription'));
			l_item_category     		:= trim(l_mt_valve_obj.get_string('itemCategory'));
			l_batch_code 				:= trim(l_mt_valve_obj.get_string('batchCode'));
            l_valve_id                  := null;
			
			l_mt_valve_record 			:= mt_valve_obj(valve_id => l_valve_id, item_id => l_item_id, item_description => l_item_description, item_category => l_item_category, batch_code => l_batch_code);
			l_mt_valve_data.extend;
			l_mt_valve_data(l_record) 	:= l_mt_valve_record;
			l_record                 	:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE insert_mt_valve
	AS
	BEGIN
		-- Populate mt_valve table.
		FOR i IN l_mt_valve_data.first .. l_mt_valve_data.last LOOP 
			INSERT INTO mt_valve	
				( 	item_id,
					item_description, 
					item_category,
					batch_code,
					insert_user,
					insert_date
				)
			VALUES	
				( 	l_mt_valve_data(i).item_id,
					l_mt_valve_data(i).item_description,
					l_mt_valve_data(i).item_category,
					l_mt_valve_data(i).batch_code,
					p_user,
					sysdate
				);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_mt_valve ;
	fill_mt_valve_collection ;
	insert_mt_valve;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 27-04-2019---
PROCEDURE update_mt_valve_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_item_id						VARCHAR2(20);
	l_item_description           	VARCHAR2(200);
	l_item_category           		VARCHAR2(20);
	l_batch_code					VARCHAR2(20);
	l_valve_id                      NUMBER;
	-- Collection variables
	l_mt_valve_data 		mt_valve_list;
	l_mt_valve_record 		mt_valve_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_mt_valve_obj 		json_object_t;
	l_mt_valve_arr 		json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 		NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'insert_mt_valve_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_VALVE';

  
	PROCEDURE parse_mt_valve
	AS
	BEGIN
		-- parsing json data
		l_json_obj    		:= json_object_t.parse(p_json_data);
		l_mt_valve_arr 		:= l_json_obj.get_array(p_root_element);
		l_count       		:= l_mt_valve_arr.get_size;
		p_tot_records 		:= l_count;
	END;

	PROCEDURE fill_mt_valve_collection
	AS
	BEGIN
		l_mt_valve_data := mt_valve_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_mt_valve_obj 				:= treat(l_mt_valve_arr.get(i) AS json_object_t);
			
			l_item_id					:= trim(l_mt_valve_obj.get_string('itemId'));
			l_item_description       	:= trim(l_mt_valve_obj.get_string('itemDescription'));
			l_item_category     		:= trim(l_mt_valve_obj.get_string('itemCategory'));
			l_batch_code 				:= trim(l_mt_valve_obj.get_string('batchCode'));
            l_valve_id                  := l_mt_valve_obj.get_string('valveId');
			
			l_mt_valve_record 			:= mt_valve_obj(valve_id => l_valve_id, item_id => l_item_id, item_description => l_item_description, item_category => l_item_category, batch_code => l_batch_code);
			l_mt_valve_data.extend;
			l_mt_valve_data(l_record) 	:= l_mt_valve_record;
			l_record                 	:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_mt_valve
	AS
	BEGIN
		FOR i IN l_mt_valve_data.first .. l_mt_valve_data.last LOOP 
		
			UPDATE mt_valve set 	
					item_id = l_mt_valve_data(i).item_id,
                    item_description = l_mt_valve_data(i).item_description,
					item_category = l_mt_valve_data(i).item_category,
					batch_code = l_mt_valve_data(i).batch_code,
					update_user = p_user,
					update_date = sysdate
			WHERE	valve_id = l_mt_valve_data(i).valve_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_mt_valve ;
	fill_mt_valve_collection ;
	update_mt_valve;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 27-04-2019---
PROCEDURE insert_order_type_lookup_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS

	l_order_type					VARCHAR2(50);
	l_movement_type            		VARCHAR2(30);
	l_market_segment           		VARCHAR2(20);
	l_sap_order_type				VARCHAR2(20);
	l_sap_doc_type					VARCHAR2(20);
	
	-- Collection variables
	l_order_type_data 		order_type_lookup_list;
	l_order_type_record 	order_type_lookup_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_order_type_obj 	json_object_t;
	l_order_type_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'insert_order_type_lookup_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'ORDER_TYPE_LOOKUP';

  
	PROCEDURE parse_order_type_lookup
	AS
	BEGIN
		-- parsing json data
		l_json_obj    		:= json_object_t.parse(p_json_data);
		l_order_type_arr 	:= l_json_obj.get_array(p_root_element);
		l_count       		:= l_order_type_arr.get_size;
		p_tot_records 		:= l_count;
	END;

	PROCEDURE fill_order_type_collection
	AS
	BEGIN
		l_order_type_data := order_type_lookup_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_order_type_obj 		:= treat(l_order_type_arr.get(i) AS json_object_t);
			
			l_order_type					:= trim(l_order_type_obj.get_string('orderType'));
			l_movement_type       			:= trim(l_order_type_obj.get_string('movementType'));
			l_market_segment     			:= trim(l_order_type_obj.get_string('marketSegment'));
			l_sap_order_type 				:= trim(l_order_type_obj.get_string('sapOrderType'));
			l_sap_doc_type					:= trim(l_order_type_obj.get_string('sapDocType'));
			
			l_order_type_record 			:= order_type_lookup_obj(order_type => l_order_type, movement_type => l_movement_type, market_segment => l_market_segment, sap_order_type => l_sap_order_type, sap_doc_type => l_sap_doc_type);
			l_order_type_data.extend;
			l_order_type_data(l_record) 	:= l_order_type_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE insert_order_type_lookup
	AS
	BEGIN
		-- Populate ORDER_TYPE_LOOKUP table.
		FOR i IN l_order_type_data.first .. l_order_type_data.last LOOP 
			INSERT INTO ORDER_TYPE_LOOKUP	
				( 	order_type,
					movement_type, 
					market_segment,
					sap_order_type,
					sap_doc_type,
					insert_user,
					insert_date
				)
			VALUES	
				( 	l_order_type_data(i).order_type,
					l_order_type_data(i).movement_type,
					l_order_type_data(i).market_segment,
					l_order_type_data(i).sap_order_type,
					l_order_type_data(i).sap_doc_type,
					p_user,
					sysdate
				);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_order_type_lookup ;
	fill_order_type_collection ;
	insert_order_type_lookup;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 27-04-2019---
PROCEDURE update_order_type_lookup_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_order_type					VARCHAR2(50);
	l_movement_type            		VARCHAR2(30);
	l_market_segment           		VARCHAR2(20);
	l_sap_order_type				VARCHAR2(20);
	l_sap_doc_type					VARCHAR2(20);
	
	-- Collection variables
	l_order_type_data 		order_type_lookup_list;
	l_order_type_record 	order_type_lookup_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_order_type_obj 	json_object_t;
	l_order_type_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'insert_order_type_lookup_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'ORDER_TYPE_LOOKUP';

  
	PROCEDURE parse_order_type_lookup
	AS
	BEGIN
		-- parsing json data
		l_json_obj    		:= json_object_t.parse(p_json_data);
		l_order_type_arr 	:= l_json_obj.get_array(p_root_element);
		l_count       		:= l_order_type_arr.get_size;
		p_tot_records 		:= l_count;
	END;

	PROCEDURE fill_order_type_collection
	AS
	BEGIN
		l_order_type_data := order_type_lookup_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_order_type_obj 		:= treat(l_order_type_arr.get(i) AS json_object_t);
			
			l_order_type					:= trim(l_order_type_obj.get_string('orderType'));
			l_movement_type       			:= trim(l_order_type_obj.get_string('movementType'));
			l_market_segment     			:= trim(l_order_type_obj.get_string('marketSegment'));
			l_sap_order_type 				:= trim(l_order_type_obj.get_string('sapOrderType'));
			l_sap_doc_type					:= trim(l_order_type_obj.get_string('sapDocType'));
			
			l_order_type_record 			:= order_type_lookup_obj(order_type => l_order_type, movement_type => l_movement_type, market_segment => l_market_segment, sap_order_type => l_sap_order_type, sap_doc_type => l_sap_doc_type);
			l_order_type_data.extend;
			l_order_type_data(l_record) 	:= l_order_type_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_order_type_lookup
	AS
	BEGIN
		FOR i IN l_order_type_data.first .. l_order_type_data.last LOOP 
		
			UPDATE ORDER_TYPE_LOOKUP set 	
					movement_type = l_order_type_data(i).movement_type,
					market_segment = l_order_type_data(i).market_segment,
					sap_order_type = l_order_type_data(i).sap_order_type,
					sap_doc_type = l_order_type_data(i).sap_doc_type,
					update_user = p_user,
					update_date = sysdate
			WHERE	order_type = l_order_type_data(i).order_type;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_order_type_lookup ;
	fill_order_type_collection ;
	update_order_type_lookup;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 27-04-2019---
PROCEDURE update_transporter_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_transporter_id		VARCHAR2(50);
	l_servprov				VARCHAR2(50);
	
	-- Collection variables
	l_transporter_data 		transporter_data_list;
	l_transporter_record 	transporter_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_transporter_obj 	json_object_t;
	l_transporter_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'update_transporter_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_TRANSPORTER';

  
	PROCEDURE parse_transporter_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    			:= json_object_t.parse(p_json_data);
		l_transporter_arr 		:= l_json_obj.get_array(p_root_element);
		l_count       			:= l_transporter_arr.get_size;
		p_tot_records 			:= l_count;
	END;

	PROCEDURE fill_transporter_collection
	AS
	BEGIN
		l_transporter_data := transporter_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_transporter_obj 		:= treat(l_transporter_arr.get(i) AS json_object_t);
			
			l_transporter_id			:= trim(l_transporter_obj.get_string('id'));
			l_servprov					:= trim(l_transporter_obj.get_string('servprov'));
			
			l_transporter_record 			:= transporter_data_obj(transporter_id => l_transporter_id, servprov => l_servprov);
			l_transporter_data.extend;
			l_transporter_data(l_record) 	:= l_transporter_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_transporter
	AS
	BEGIN
		FOR i IN l_transporter_data.first .. l_transporter_data.last LOOP 
			UPDATE 	MT_TRANSPORTER set 	
					servprov = l_transporter_data(i).servprov,
					update_user = p_user,
					update_date = sysdate
			WHERE	transporter_id = l_transporter_data(i).transporter_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_transporter_data ;
	fill_transporter_collection ;
	update_transporter;
 
	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
END;
--End of the Code--

--Added by Mangaiah Ramisetty on 29-05-2019---

PROCEDURE upload_elr_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS

	l_location_id					VARCHAR2(20);
	l_servprov            			VARCHAR2(20);
	l_elr_flag						VARCHAR2(1);
	
	-- Collection variables
	l_elr_data 		elr_data_list;
	l_elr_record 	elr_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_elr_obj 			json_object_t;
	l_elr_arr 			json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 		NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'upload_elr_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_ELR';

  
	PROCEDURE parse_elr_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    			:= json_object_t.parse(p_json_data);
		l_elr_arr 				:= l_json_obj.get_array(p_root_element);
		l_count       			:= l_elr_arr.get_size;
		p_tot_records 			:= l_count;
	END;

	PROCEDURE fill_elr_collection
	AS
	BEGIN
		l_elr_data := elr_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_elr_obj 				:= treat(l_elr_arr.get(i) AS json_object_t);
			
			l_location_id			:= trim(l_elr_obj.get_string('locationId'));
			l_servprov       		:= trim(l_elr_obj.get_string('servprov'));
			l_elr_flag				:= trim(l_elr_obj.get_string('elrFlag'));
			
			l_elr_record 			:= elr_data_obj(location_id => l_location_id, servprov => l_servprov, elr_flag => l_elr_flag);
			l_elr_data.extend;
			l_elr_data(l_record) 	:= l_elr_record;
			l_record                := l_record + 1;
		END LOOP;
	END;


	PROCEDURE insert_elr
	AS
	BEGIN
		-- Populate mt_material_group table.
		FOR i IN l_elr_data.first .. l_elr_data.last LOOP 
			INSERT INTO mt_elr	
				( 	location_id,
					servprov, 
					elr_flag,
					insert_user,
					insert_date
				)
			VALUES	
				( 	l_elr_data(i).location_id,
					l_elr_data(i).servprov,
					l_elr_data(i).elr_flag,
					p_user,
					sysdate
				);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_elr_data ;
	fill_elr_collection ;
	insert_elr;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE update_elr_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_location_id				VARCHAR2(20);
	l_servprov            		VARCHAR2(20);
	l_elr_flag					VARCHAR2(1);  
	
	-- Collection variables
	l_elr_data 		elr_data_list;
	l_elr_record 	elr_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 	json_object_t;
	l_elr_obj 	json_object_t;
	l_elr_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'update_elr_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_ELR';

  
	PROCEDURE parse_elr_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    			:= json_object_t.parse(p_json_data);
		l_elr_arr 				:= l_json_obj.get_array(p_root_element);
		l_count       			:= l_elr_arr.get_size;
		p_tot_records 			:= l_count;
	END;

	PROCEDURE fill_elr_collection
	AS
	BEGIN
		l_elr_data := elr_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_elr_obj 		:= treat(l_elr_arr.get(i) AS json_object_t);
			
			l_location_id			:= trim(l_elr_obj.get_string('locationId'));
			l_servprov       		:= trim(l_elr_obj.get_string('servprov'));
			l_elr_flag				:= trim(l_elr_obj.get_string('elrFlag'));
			
			l_elr_record 			:= elr_data_obj(location_id => l_location_id, servprov => l_servprov, elr_flag => l_elr_flag);
			l_elr_data.extend;
			l_elr_data(l_record) 	:= l_elr_record;
			l_record                := l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_elr
	AS
	BEGIN
		FOR i IN l_elr_data.first .. l_elr_data.last LOOP 
			UPDATE 	mt_elr set 	
					elr_flag = l_elr_data(i).elr_flag,
					update_user = p_user,
					update_date = sysdate
			WHERE	location_id = l_elr_data(i).location_id
			AND		servprov = l_elr_data(i).servprov;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_elr_data ;
	fill_elr_collection ;
	update_elr;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE insert_excess_waiting_loc_limit_data (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS

	l_reporting_loc					VARCHAR2(20);
	l_excess_time            			VARCHAR2(20);
	
	-- Collection variables
	l_excess_waiting_limit_data 		excess_time_data_list;
	l_excess_waiting_limit_record 		excess_time_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 							json_object_t;
	l_excess_waiting_limit_obj 			json_object_t;
	l_excess_waiting_limit_arr 			json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 		NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'insert_excess_waiting_loc_limit_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_EXCESS_WAITING_LOC_LIMIT';

  
	PROCEDURE parse_excess_waiting_loc_limit_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    							:= json_object_t.parse(p_json_data);
		l_excess_waiting_limit_arr 				:= l_json_obj.get_array(p_root_element);
		l_count       							:= l_excess_waiting_limit_arr.get_size;
		p_tot_records 							:= l_count;
	END;

	PROCEDURE fill_excess_waiting_loc_limit_collection
	AS
	BEGIN
		l_excess_waiting_limit_data := excess_time_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_excess_waiting_limit_obj 				:= treat(l_excess_waiting_limit_arr.get(i) AS json_object_t);
			
			l_reporting_loc							:= trim(l_excess_waiting_limit_obj.get_string('reportingLoc'));
			l_excess_time       					:= trim(l_excess_waiting_limit_obj.get_string('excessTime'));
			
			l_excess_waiting_limit_record 			:= excess_time_data_obj(reporting_loc => l_reporting_loc, excess_time => l_excess_time);
			l_excess_waiting_limit_data.extend;
			l_excess_waiting_limit_data(l_record) 	:= l_excess_waiting_limit_record;
			l_record                				:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE insert_excess_waiting_loc_limit
	AS
	BEGIN
		
		FOR i IN l_excess_waiting_limit_data.first .. l_excess_waiting_limit_data.last LOOP 
			INSERT INTO mt_excess_waiting_loc_limit
				( 	reporting_loc,
					excess_time, 
					insert_user,
					insert_date
				)
			VALUES	
				( 	l_excess_waiting_limit_data(i).reporting_loc,
					l_excess_waiting_limit_data(i).excess_time,
					p_user,
					sysdate
				);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_excess_waiting_loc_limit_data ;
	fill_excess_waiting_loc_limit_collection ;
	insert_excess_waiting_loc_limit;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE update_excess_waiting_loc_limit_data(
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_reporting_loc				VARCHAR2(20);
	l_excess_time            	VARCHAR2(20);
	
	-- Collection variables
	l_excess_waiting_limit_data 		excess_time_data_list;
	l_excess_waiting_limit_record 		excess_time_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 	json_object_t;
	l_excess_waiting_limit_obj 	json_object_t;
	l_excess_waiting_limit_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'update_excess_waiting_loc_limit_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_EXCESS_WAITING_LOC_LIMIT';

  
	PROCEDURE parse_excess_waiting_loc_limit_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    					:= json_object_t.parse(p_json_data);
		l_excess_waiting_limit_arr 		:= l_json_obj.get_array(p_root_element);
		l_count       					:= l_excess_waiting_limit_arr.get_size;
		p_tot_records 					:= l_count;
	END;

	PROCEDURE fill_excess_waiting_loc_limit_collection
	AS
	BEGIN
		l_excess_waiting_limit_data := excess_time_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_excess_waiting_limit_obj 		:= treat(l_excess_waiting_limit_arr.get(i) AS json_object_t);
			
			l_reporting_loc			:= trim(l_excess_waiting_limit_obj.get_string('reportingLoc'));
			l_excess_time       		:= trim(l_excess_waiting_limit_obj.get_string('excessTime'));
			
			l_excess_waiting_limit_record 			:= excess_time_data_obj(reporting_loc => l_reporting_loc, excess_time => l_excess_time);
			l_excess_waiting_limit_data.extend;
			l_excess_waiting_limit_data(l_record) 	:= l_excess_waiting_limit_record;
			l_record                				:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_excess_waiting_loc_limit
	AS
	BEGIN
		FOR i IN l_excess_waiting_limit_data.first .. l_excess_waiting_limit_data.last LOOP 
			UPDATE 	mt_excess_waiting_loc_limit set 	
					excess_time = l_excess_waiting_limit_data(i).excess_time,
					update_user = p_user,
					update_date = sysdate
			WHERE	reporting_loc = l_excess_waiting_limit_data(i).reporting_loc;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_excess_waiting_loc_limit_data ;
	fill_excess_waiting_loc_limit_collection ;
	update_excess_waiting_loc_limit;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE insert_excess_waiting_rep_limit_data (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS

	l_reporting_loc					VARCHAR2(20);
	l_excess_time            			VARCHAR2(20);
	
	-- Collection variables
	l_excess_waiting_limit_data 		excess_time_data_list;
	l_excess_waiting_limit_record 		excess_time_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 							json_object_t;
	l_excess_waiting_limit_obj 			json_object_t;
	l_excess_waiting_limit_arr 			json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 		NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'insert_excess_waiting_rep_limit_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_EXCESS_WAITING_REP_LIMIT';

  
	PROCEDURE parse_excess_waiting_rep_limit_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    							:= json_object_t.parse(p_json_data);
		l_excess_waiting_limit_arr 				:= l_json_obj.get_array(p_root_element);
		l_count       							:= l_excess_waiting_limit_arr.get_size;
		p_tot_records 							:= l_count;
	END;

	PROCEDURE fill_excess_waiting_rep_limit_collection
	AS
	BEGIN
		l_excess_waiting_limit_data := excess_time_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_excess_waiting_limit_obj 				:= treat(l_excess_waiting_limit_arr.get(i) AS json_object_t);
			
			l_reporting_loc							:= trim(l_excess_waiting_limit_obj.get_string('reportingLoc'));
			l_excess_time       					:= trim(l_excess_waiting_limit_obj.get_string('excessTime'));
			
			l_excess_waiting_limit_record 			:= excess_time_data_obj(reporting_loc => l_reporting_loc, excess_time => l_excess_time);
			l_excess_waiting_limit_data.extend;
			l_excess_waiting_limit_data(l_record) 	:= l_excess_waiting_limit_record;
			l_record                				:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE insert_excess_waiting_rep_limit
	AS
	BEGIN
		
		FOR i IN l_excess_waiting_limit_data.first .. l_excess_waiting_limit_data.last LOOP 
			INSERT INTO mt_excess_waiting_rep_limit
				( 	reporting_loc,
					excess_time, 
					insert_user,
					insert_date
				)
			VALUES	
				( 	l_excess_waiting_limit_data(i).reporting_loc,
					l_excess_waiting_limit_data(i).excess_time,
					p_user,
					sysdate
				);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_excess_waiting_rep_limit_data ;
	fill_excess_waiting_rep_limit_collection ;
	insert_excess_waiting_rep_limit;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE update_excess_waiting_rep_limit_data (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_reporting_loc				VARCHAR2(20);
	l_excess_time            	VARCHAR2(20);
	
	-- Collection variables
	l_excess_waiting_limit_data 		excess_time_data_list;
	l_excess_waiting_limit_record 		excess_time_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 	json_object_t;
	l_excess_waiting_limit_obj 	json_object_t;
	l_excess_waiting_limit_arr 	json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'update_excess_waiting_rep_limit_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_EXCESS_WAITING_REP_LIMIT';

  
	PROCEDURE parse_excess_waiting_rep_limit_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    					:= json_object_t.parse(p_json_data);
		l_excess_waiting_limit_arr 		:= l_json_obj.get_array(p_root_element);
		l_count       					:= l_excess_waiting_limit_arr.get_size;
		p_tot_records 					:= l_count;
	END;

	PROCEDURE fill_excess_waiting_rep_limit_collection
	AS
	BEGIN
		l_excess_waiting_limit_data := excess_time_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_excess_waiting_limit_obj 		:= treat(l_excess_waiting_limit_arr.get(i) AS json_object_t);
			
			l_reporting_loc			:= trim(l_excess_waiting_limit_obj.get_string('reportingLoc'));
			l_excess_time       		:= trim(l_excess_waiting_limit_obj.get_string('excessTime'));
			
			l_excess_waiting_limit_record 			:= excess_time_data_obj(reporting_loc => l_reporting_loc, excess_time => l_excess_time);
			l_excess_waiting_limit_data.extend;
			l_excess_waiting_limit_data(l_record) 	:= l_excess_waiting_limit_record;
			l_record                				:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_excess_waiting_rep_limit
	AS
	BEGIN
		FOR i IN l_excess_waiting_limit_data.first .. l_excess_waiting_limit_data.last LOOP 
			UPDATE 	mt_excess_waiting_rep_limit set 	
					excess_time = l_excess_waiting_limit_data(i).excess_time,
					update_user = p_user,
					update_date = sysdate
			WHERE	reporting_loc = l_excess_waiting_limit_data(i).reporting_loc;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_excess_waiting_rep_limit_data ;
	fill_excess_waiting_rep_limit_collection ;
	update_excess_waiting_rep_limit;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE upload_location_bay_data (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_location_id		    VARCHAR2(50);
	l_bay_id              	varchar2(20);
	l_bay_desc              varchar2(200);
	l_bay_status			varchar2(400);
    l_lb_id                 number;
	
	-- Collection variables
	l_location_bay_data 		location_bay_data_list;
	l_location_bay_record 		location_bay_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_location_bay_obj 		json_object_t;
	l_location_bay_arr 		json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'upload_location_bay_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_LOCATION_BAY';

  
	PROCEDURE parse_location_bay_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    			:= json_object_t.parse(p_json_data);
		l_location_bay_arr 			:= l_json_obj.get_array(p_root_element);
		l_count       			:= l_location_bay_arr.get_size;
		p_tot_records 			:= l_count;
	END;

	PROCEDURE fill_location_bay_collection
	AS
	BEGIN
		l_location_bay_data := location_bay_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_location_bay_obj 		:= treat(l_location_bay_arr.get(i) AS json_object_t);
			
			l_location_id			:= trim(l_location_bay_obj.get_string('locationId'));
			l_bay_id					:= trim(l_location_bay_obj.get_string('bayId'));
			l_bay_desc					:= trim(l_location_bay_obj.get_string('bayDesc'));
			l_bay_status			:= trim(l_location_bay_obj.get_string('bayStatus'));
            l_lb_id			        := trim(l_location_bay_obj.get_string('lbId'));
			
			l_location_bay_record 			:= 	location_bay_data_obj(location_id => l_location_id, bay_id => l_bay_id, bay_desc => l_bay_desc, bay_status => l_bay_status, lb_id => l_lb_id);
			l_location_bay_data.extend;
			l_location_bay_data(l_record) 	:= l_location_bay_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE upload_location_bay
	AS
	BEGIN
		FOR i IN l_location_bay_data.first .. l_location_bay_data.last LOOP 
			INSERT INTO MT_LOCATION_BAY
					(location_id,
					bay_id,
					bay_desc,
					bay_status,
					insert_user,
					insert_date)
			VALUES	
					(l_location_bay_data(i).location_id,
					l_location_bay_data(i).bay_id,
					l_location_bay_data(i).bay_desc,
					l_location_bay_data(i).bay_status,
					p_user,
					sysdate);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_location_bay_data ;
	fill_location_bay_collection ;
	upload_location_bay;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE delete_location_bay_data (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_location_id		    VARCHAR2(50);
	l_bay_id              	varchar2(20);
	l_bay_desc              varchar2(200);
	l_bay_status			varchar2(400);
    l_lb_id                 number;
	
	-- Collection variables
	l_location_bay_data 		location_bay_data_list;
	l_location_bay_record 		location_bay_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_location_bay_obj 		json_object_t;
	l_location_bay_arr 		json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'delete_location_bay_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_LOCATION_BAY';

  
	PROCEDURE parse_location_bay_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    			:= json_object_t.parse(p_json_data);
		l_location_bay_arr 			:= l_json_obj.get_array(p_root_element);
		l_count       			:= l_location_bay_arr.get_size;
		p_tot_records 			:= l_count;
	END;

	PROCEDURE fill_location_bay_collection
	AS
	BEGIN
		l_location_bay_data := location_bay_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_location_bay_obj 		:= treat(l_location_bay_arr.get(i) AS json_object_t);
			
			l_location_id			:= trim(l_location_bay_obj.get_string('locationId'));
			l_bay_id					:= trim(l_location_bay_obj.get_string('bayId'));
			l_bay_desc					:= trim(l_location_bay_obj.get_string('bayDesc'));
			l_bay_status			:= trim(l_location_bay_obj.get_string('bayStatus'));
            l_lb_id			        := trim(l_location_bay_obj.get_string('lbId'));
			
			l_location_bay_record 			:= 	location_bay_data_obj(location_id => l_location_id, bay_id => l_bay_id, bay_desc => l_bay_desc, bay_status => l_bay_status, lb_id => l_lb_id);
			l_location_bay_data.extend;
			l_location_bay_data(l_record) 	:= l_location_bay_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE delete_location_bay
	AS
	BEGIN
		FOR i IN l_location_bay_data.first .. l_location_bay_data.last LOOP 
			DELETE 	FROM MT_LOCATION_BAY
			WHERE	lb_id = l_location_bay_data(i).lb_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_location_bay_data ;
	fill_location_bay_collection ;
	delete_location_bay;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE update_location_data (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_location_id		    VARCHAR2(50);
	l_lat              		number(11,8);
	l_lon              		number(11,8);
	l_ft_access_key			varchar2(2000);
	l_location_class		varchar2(20);
	l_linked_plant			varchar2(50);
  l_email_id varchar2(4000);
	
	-- Collection variables
	l_location_data 		location_data_list;
	l_location_record 		location_data_obj;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 			json_object_t;
	l_location_obj 		json_object_t;
	l_location_arr 		json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 	NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'update_location_data';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_LOCATION';

  
	PROCEDURE parse_location_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    			:= json_object_t.parse(p_json_data);
		l_location_arr 			:= l_json_obj.get_array(p_root_element);
		l_count       			:= l_location_arr.get_size;
		p_tot_records 			:= l_count;
	END;

	PROCEDURE fill_location_collection
	AS
	BEGIN
		l_location_data := location_data_list();
		FOR i IN 0 .. l_count - 1	LOOP
			l_location_obj 		:= treat(l_location_arr.get(i) AS json_object_t);
			
			l_location_id			:= trim(l_location_obj.get_string('locationId'));
			l_lat					:= trim(l_location_obj.get_string('lat'));
			l_lon					:= trim(l_location_obj.get_string('long'));
			l_ft_access_key			:= trim(l_location_obj.get_string('ftAccessKey'));
			l_location_class		:= trim(l_location_obj.get_string('locationClass'));
			l_linked_plant			:= trim(l_location_obj.get_string('linkedPlant'));
      l_email_id			:= trim(l_location_obj.get_string('emailID'));
			
			l_location_record 			:= 	location_data_obj(location_id => l_location_id, lat => l_lat, lon => l_lon, ft_access_key => l_ft_access_key, 
											location_class => l_location_class, linked_plant => l_linked_plant, email_id => l_email_id);
			l_location_data.extend;
			l_location_data(l_record) 	:= l_location_record;
			l_record                 		:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE update_location
	AS
	BEGIN
		FOR i IN l_location_data.first .. l_location_data.last LOOP 
			UPDATE 	MT_LOCATION set 	
					lat = l_location_data(i).lat,
					lon = l_location_data(i).lon,
					ft_access_key = l_location_data(i).ft_access_key,
					location_class = l_location_data(i).location_class,
					linked_plant = l_location_data(i).linked_plant,
          email_id = l_location_data(i).email_id,
					update_user = p_user,
					update_date = sysdate
			WHERE	location_id = l_location_data(i).location_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_location_data ;
	fill_location_collection ;
	update_location;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE insert_user_data (
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_user_id 				varchar2(20);
  l_status             		varchar2(20);
  l_plant_code           	varchar2(20);
  l_user_role_id			varchar2(20);
  l_password				varchar2(400);
  l_first_name				varchar2(20);
  l_last_name				varchar2(20);
  l_email_id				varchar2(100);
  
  -- Collection variables
  l_user_data user_data_list;
  l_user_data_record user_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_user_obj json_object_t;
  l_user_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'insert_user_data';
  l_mt_entity_name    VARCHAR2(100) := 'UM_USER';

  
  PROCEDURE parse_user_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    		:= json_object_t.parse(p_json_data);
    l_user_arr 			:= l_json_obj.get_array(p_root_element);
    l_count       		:= l_user_arr.get_size;
    p_tot_records 		:= l_count;
  END;

  PROCEDURE fill_user_collection
  AS
  BEGIN
    l_user_data := user_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_user_obj 	:= treat(l_user_arr.get(i) AS json_object_t);
	  
      l_user_id			:= trim(l_user_obj.get_string('userId'));
      l_status       	:= trim(l_user_obj.get_string('status'));
      l_plant_code     	:= trim(l_user_obj.get_string('plantCode'));
	  l_user_role_id 	:= trim(l_user_obj.get_string('userRoleId'));
	  l_password 		:= trim(l_user_obj.get_string('password'));
	  l_first_name 		:= trim(l_user_obj.get_string('firstName'));
	  l_last_name 		:= trim(l_user_obj.get_string('lastName'));
	  l_email_id 		:= trim(l_user_obj.get_string('emailId'));
	  
      l_user_data_record 			:= user_data_obj(user_id => l_user_id, status => l_status, plant_code => l_plant_code, user_role_id => l_user_role_id, password => l_password, 									first_name => l_first_name, last_name => l_last_name, email_id => l_email_id);
      l_user_data.extend;
      l_user_data(l_record) 		:= l_user_data_record;
      l_record                 		:= l_record + 1;
    END LOOP;
  END;


PROCEDURE insert_um_user
AS
BEGIN
  
  for i IN l_user_data.first .. l_user_data.last
  loop 

  INSERT
  INTO UM_USER
    ( user_id, 
      status,
      plant_code,
	  user_role_id,
	  password,
	  first_name,
	  last_name,
      email_id,
      insert_user,
      insert_date
    )
    VALUES
    ( l_user_data(i).user_id,
      l_user_data(i).status,
      l_user_data(i).plant_code,
	  l_user_data(i).user_role_id,
	  l_user_data(i).password,
	  l_user_data(i).first_name,
	  l_user_data(i).last_name,
	  l_user_data(i).email_id,
      p_user,
      sysdate
    );
    end loop; 
  COMMIT;
END;

  BEGIN
  
  parse_user_data ;
  fill_user_collection ;
  insert_um_user;
 

 /* EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
  
  PROCEDURE update_user_data (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_user_id 				varchar2(20);
	l_status             		varchar2(20);
	l_plant_code           	varchar2(20);
	l_user_role_id			varchar2(20);
	l_first_name				varchar2(20);
	l_last_name				varchar2(20);
	l_email_id				varchar2(100);
    l_password              varchar2(400);
	
	 -- Collection variables
  l_user_data user_data_list;
  l_user_data_record user_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_user_obj json_object_t;
  l_user_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'update_user_data';
  l_mt_entity_name    VARCHAR2(100) := 'UM_USER';

  
  PROCEDURE parse_user_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    		:= json_object_t.parse(p_json_data);
    l_user_arr 			:= l_json_obj.get_array(p_root_element);
    l_count       		:= l_user_arr.get_size;
    p_tot_records 		:= l_count;
  END;

  PROCEDURE fill_user_collection
  AS
  BEGIN
    l_user_data := user_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_user_obj 	:= treat(l_user_arr.get(i) AS json_object_t);
	  
      l_user_id			:= trim(l_user_obj.get_string('userId'));
      l_status       	:= trim(l_user_obj.get_string('status'));
      l_plant_code     	:= trim(l_user_obj.get_string('plantCode'));
	  l_user_role_id 	:= trim(l_user_obj.get_string('userRoleId'));
	  l_password 		:= trim(l_user_obj.get_string('password'));
	  l_first_name 		:= trim(l_user_obj.get_string('firstName'));
	  l_last_name 		:= trim(l_user_obj.get_string('lastName'));
	  l_email_id 		:= trim(l_user_obj.get_string('emailId'));
	  
      l_user_data_record 			:= user_data_obj(user_id => l_user_id, status => l_status, plant_code => l_plant_code, user_role_id => l_user_role_id, password => l_password, 									first_name => l_first_name, last_name => l_last_name, email_id => l_email_id);
      l_user_data.extend;
      l_user_data(l_record) 		:= l_user_data_record;
      l_record                 		:= l_record + 1;
    END LOOP;
  END;



	PROCEDURE update_um_user
	AS
	BEGIN
		FOR i IN l_user_data.first .. l_user_data.last LOOP 
			UPDATE 	UM_USER set
					status = l_user_data(i).status,
					user_role_id = l_user_data(i).user_role_id,
					plant_code = l_user_data(i).plant_code,
					first_name = l_user_data(i).first_name,
					last_name = l_user_data(i).last_name,
					email_id = l_user_data(i).email_id,
					update_user = p_user,
					update_date = sysdate
			WHERE	user_id = l_user_data(i).user_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_user_data ;
	fill_user_collection ;
	update_um_user;
 
	/*EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE insert_user_role_data (
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_user_role_id 		varchar2(20);
  l_description      	varchar2(20);
  
  -- Collection variables
  l_user_role_data 		user_role_data_list;
  l_user_role_record 	user_role_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj 				json_object_t;
  l_user_role_obj 	json_object_t;
  l_user_role_arr 	json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records 	pls_integer;
  l_total_tyre_count 	NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'insert_user_role_data';
  l_mt_entity_name    VARCHAR2(100) := 'UM_USER_ROLE';

  
  PROCEDURE parse_user_role_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    					:= json_object_t.parse(p_json_data);
    l_user_role_arr 				:= l_json_obj.get_array(p_root_element);
    l_count       					:= l_user_role_arr.get_size;
    p_tot_records 					:= l_count;
  END;

  PROCEDURE fill_user_role_collection
  AS
  BEGIN
    l_user_role_data := user_role_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_user_role_obj 		:= treat(l_user_role_arr.get(i) AS json_object_t);
	  
      l_user_role_id			:= trim(l_user_role_obj.get_string('userRoleId'));
      l_description     		:= trim(l_user_role_obj.get_string('description'));
     
      l_user_role_record 			:= user_role_data_obj(user_role_id => l_user_role_id, description => l_description);
      l_user_role_data.extend;
      l_user_role_data(l_record) 	:= l_user_role_record;
      l_record                 		:= l_record + 1;
    END LOOP;
  END;


PROCEDURE insert_user_role
AS
BEGIN
  
  for i IN l_user_role_data.first .. l_user_role_data.last
  loop 

  INSERT
  INTO UM_USER_ROLE
    ( user_role_id, 
      description,
      insert_user,
      insert_date
    )
    VALUES
    ( l_user_role_data(i).user_role_id,
      l_user_role_data(i).description,
      p_user,
      sysdate
    );
    end loop; 
  COMMIT;
END;

  BEGIN
  
  parse_user_role_data ;
  fill_user_role_collection ;
  insert_user_role;
 

/*  EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
  
  PROCEDURE update_user_role_data (
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_user_role_id 		varchar2(20);
  l_description      	varchar2(20);
  
  -- Collection variables
  l_user_role_data 		user_role_data_list;
  l_user_role_record 	user_role_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj 				json_object_t;
  l_user_role_obj 	json_object_t;
  l_user_role_arr 	json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records 	pls_integer;
  l_total_tyre_count 	NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'insert_user_role_data';
  l_mt_entity_name    VARCHAR2(100) := 'UM_USER_ROLE';

  
  PROCEDURE parse_user_role_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    					:= json_object_t.parse(p_json_data);
    l_user_role_arr 				:= l_json_obj.get_array(p_root_element);
    l_count       					:= l_user_role_arr.get_size;
    p_tot_records 					:= l_count;
  END;

  PROCEDURE fill_user_role_collection
  AS
  BEGIN
    l_user_role_data := user_role_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_user_role_obj 		:= treat(l_user_role_arr.get(i) AS json_object_t);
	  
      l_user_role_id			:= trim(l_user_role_obj.get_string('userRoleId'));
      l_description     		:= trim(l_user_role_obj.get_string('description'));
     
      l_user_role_record 			:= user_role_data_obj(user_role_id => l_user_role_id, description => l_description);
      l_user_role_data.extend;
      l_user_role_data(l_record) 	:= l_user_role_record;
      l_record                 		:= l_record + 1;
    END LOOP;
  END;


PROCEDURE update_user_role
AS
BEGIN
  
  for i IN l_user_role_data.first .. l_user_role_data.last
  loop 

  update UM_USER_ROLE set 
    description = l_user_role_data(i).description,
      update_user = p_user,
      update_date = sysdate
    where user_role_id = l_user_role_data(i).user_role_id;
      
    end loop; 
  COMMIT;
END;

  BEGIN
  
  parse_user_role_data ;
  fill_user_role_collection ;
  update_user_role;
 

 /* EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
  
  PROCEDURE insert_user_association_data (
    p_json_data CLOB,
    p_root_element VARCHAR2,
    p_user         VARCHAR2,
    p_tot_records OUT NUMBER
  )
AS

  l_user_id 					varchar2(20);
  l_association_identifier      varchar2(20);
  l_association_value          	varchar2(50);
  l_ua_id						number;
 
  -- Collection variables
  l_user_association_data 		user_association_data_list;
  l_user_association_record 	user_association_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj 				json_object_t;
  l_user_association_obj 	json_object_t;
  l_user_association_arr 	json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records 	pls_integer;
  l_total_tyre_count 	NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'insert_user_association_data';
  l_mt_entity_name    VARCHAR2(100) := 'UM_USER_ASSOCIATION';

  
  PROCEDURE parse_user_association_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    					:= json_object_t.parse(p_json_data);
    l_user_association_arr 			:= l_json_obj.get_array(p_root_element);
    l_count       					:= l_user_association_arr.get_size;
    p_tot_records 					:= l_count;
  END;

  PROCEDURE fill_user_association_collection
  AS
  BEGIN
    l_user_association_data := user_association_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_user_association_obj 		:= treat(l_user_association_arr.get(i) AS json_object_t);
	  
      l_user_id						:= trim(l_user_association_obj.get_string('userId'));
      l_association_identifier      := trim(l_user_association_obj.get_string('associationIdentifier'));
      l_association_value     		:= trim(l_user_association_obj.get_string('associationValue'));
	  l_ua_id 						:= null;
	  
      l_user_association_record 				:= user_association_data_obj(user_id => l_user_id, association_identifier => l_association_identifier, association_value => l_association_value, ua_id => l_ua_id);
      l_user_association_data.extend;
      l_user_association_data(l_record) 		:= l_user_association_record;
      l_record                 					:= l_record + 1;
    END LOOP;
  END;


PROCEDURE insert_user_association
AS
BEGIN
  
  for i IN l_user_association_data.first .. l_user_association_data.last
  loop 

  INSERT
  INTO UM_USER_ASSOCIATION
    ( user_id, 
      association_identifier,
      association_value,
	  insert_user,
      insert_date
    )
    VALUES
    ( l_user_association_data(i).user_id,
      l_user_association_data(i).association_identifier,
      l_user_association_data(i).association_value,
	  p_user,
      sysdate
    );
    end loop; 
  COMMIT;
END;

  BEGIN
  
  parse_user_association_data ;
  fill_user_association_collection ;
  insert_user_association;
 

 /* EXCEPTION 
  WHEN OTHERS THEN 
    ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
  */
  END;
  
  PROCEDURE update_user_association_data (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_user_id 						varchar2(20);
	l_association_identifier        varchar2(20);
	l_association_value           	varchar2(50);
	l_ua_id						number;
	
	
	 -- Collection variables
  l_user_association_data 		user_association_data_list;
  l_user_association_record 	user_association_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_user_association_obj json_object_t;
  l_user_association_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'update_user_association_data';
  l_mt_entity_name    VARCHAR2(100) := 'UM_USER_ASSOCIATION';

  
  PROCEDURE parse_user_association_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    					:= json_object_t.parse(p_json_data);
    l_user_association_arr 			:= l_json_obj.get_array(p_root_element);
    l_count       					:= l_user_association_arr.get_size;
    p_tot_records 					:= l_count;
  END;

  PROCEDURE fill_user_association_collection
  AS
  BEGIN
    l_user_association_data := user_association_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_user_association_obj 			:= treat(l_user_association_arr.get(i) AS json_object_t);
	  
      l_user_id							:= trim(l_user_association_obj.get_string('userId'));
      l_association_identifier       	:= trim(l_user_association_obj.get_string('associationIdentifier'));
      l_association_value     			:= trim(l_user_association_obj.get_string('associationValue'));
	  l_ua_id 							:= trim(l_user_association_obj.get_string('uaId'));
	  
      l_user_association_record 				:= user_association_data_obj(user_id => l_user_id, association_identifier => l_association_identifier, association_value => l_association_value, ua_id => l_ua_id);
      l_user_association_data.extend;
      l_user_association_data(l_record) 		:= l_user_association_record;
      l_record                 					:= l_record + 1;
    END LOOP;
  END;



	PROCEDURE update_user_association
	AS
	BEGIN
		FOR i IN l_user_association_data.first .. l_user_association_data.last LOOP 
			UPDATE 	UM_USER_ASSOCIATION set
					user_id = l_user_association_data(i).user_id,
					association_identifier = l_user_association_data(i).association_identifier,
					association_value = l_user_association_data(i).association_value,
					update_user = p_user,
					update_date = sysdate
			WHERE	ua_id = l_user_association_data(i).ua_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_user_association_data ;
	fill_user_association_collection ;
	update_user_association;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

--End of the Code--

PROCEDURE change_password (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS
	l_user_id 				varchar2(20);	
    l_password              varchar2(400);
	
	 -- Collection variables
  l_user_data user_data_list;
  l_user_data_record user_data_obj;

  -- Common variables
  l_record INT := 1;
  l_count pls_integer;

  -- Variables for JSON processing
  l_json_obj json_object_t;
  l_user_obj json_object_t;
  l_user_arr json_array_t;

  -- Output variables
  --l_tot_records pls_integer;
  l_tot_error_records pls_integer;
  l_total_tyre_count NUMBER;

  --Error Handling Variables
  l_proc_func_name    VARCHAR2(100) := 'change_password';
  l_mt_entity_name    VARCHAR2(100) := 'UM_USER';

  
  PROCEDURE parse_user_data
  AS
  BEGIN
    -- parsing json data
    l_json_obj    		:= json_object_t.parse(p_json_data);
    l_user_arr 			:= l_json_obj.get_array(p_root_element);
    l_count       		:= l_user_arr.get_size;
    p_tot_records 		:= l_count;
  END;

  PROCEDURE fill_user_collection
  AS
  BEGIN
    l_user_data := user_data_list();
    FOR i IN 0 .. l_count - 1
    LOOP
      l_user_obj 	:= treat(l_user_arr.get(i) AS json_object_t);
	  
      l_user_id			:= trim(l_user_obj.get_string('userId'));      
	  l_password 		:= trim(l_user_obj.get_string('password'));
	  
	  
      l_user_data_record 			:= user_data_obj(user_id => l_user_id, status => null, plant_code => null, user_role_id => null, password => l_password, 									first_name => null, last_name => null, email_id => null);
      l_user_data.extend;
      l_user_data(l_record) 		:= l_user_data_record;
      l_record                 		:= l_record + 1;
    END LOOP;
  END;
  
  PROCEDURE update_um_user
	AS
	BEGIN
		FOR i IN l_user_data.first .. l_user_data.last LOOP 
			UPDATE 	UM_USER set
					
					password = l_user_data(i).password,
					update_user = p_user,
					update_date = sysdate
			WHERE	user_id = l_user_data(i).user_id;
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_user_data ;
	fill_user_collection ;
	update_um_user;
 
/*	EXCEPTION 
		WHEN OTHERS THEN 
			ins_err( p_mt_entity_name => l_mt_entity_name, p_proc_func_name => l_proc_func_name, p_sql_code => sqlcode, p_sql_errm => sqlerrm, p_user => p_user);
*/
END;

PROCEDURE insert_servprov (
    p_json_data 		CLOB,
    p_root_element		VARCHAR2,
    p_user         		VARCHAR2,
    p_tot_records OUT 	NUMBER
	)
AS

	l_scac_id					VARCHAR2(50);
	l_name            			VARCHAR2(200);
	
	-- Collection variables
	l_servprov_data 		SERVPROV_DATA_LIST;
	l_servprov_record 		SERVPROV_DATA_OBJ;

	-- Common variables
	l_record INT 	:= 1;
	l_count 		pls_integer;

	-- Variables for JSON processing
	l_json_obj 							json_object_t;
	l_servprov_obj 			json_object_t;
	l_servprov_arr 			json_array_t;

	-- Output variables
	l_tot_error_records 	pls_integer;
	l_total_tyre_count 		NUMBER;

	--Error Handling Variables
	l_proc_func_name    VARCHAR2(100) 	:= 'insert_servprov';
	l_mt_entity_name    VARCHAR2(100) 	:= 'MT_SCAC';

  
	PROCEDURE parse_servprov_data
	AS
	BEGIN
		-- parsing json data
		l_json_obj    							:= json_object_t.parse(p_json_data);
		l_servprov_arr 				      := l_json_obj.get_array(p_root_element);
		l_count       							:= l_servprov_arr.get_size;
		p_tot_records 							:= l_count;
	END;

	PROCEDURE fill_servprov_collection
	AS
	BEGIN
		l_servprov_data := SERVPROV_DATA_LIST();
		FOR i IN 0 .. l_count - 1	LOOP
			l_servprov_obj 				:= treat(l_servprov_arr.get(i) AS json_object_t);
			
			l_scac_id							:= trim(l_servprov_obj.get_string('ID'));
			l_name       					:= trim(l_servprov_obj.get_string('Name'));
			
			l_servprov_record 			:= SERVPROV_DATA_OBJ(scac => l_scac_id, name => l_name);
			l_servprov_data.extend;
			l_servprov_data(l_record) 	:= l_servprov_record;
			l_record                				:= l_record + 1;
		END LOOP;
	END;


	PROCEDURE insert_servprov_data
	AS
	BEGIN
		
		FOR i IN l_servprov_data.first .. l_servprov_data.last LOOP 
			INSERT INTO mt_scac
				( 	scac,
					company_name)
			VALUES	
				( 	l_servprov_data(i).scac,
					l_servprov_data(i).name);
		END LOOP; 
		COMMIT;
	END;

BEGIN
	parse_servprov_data ;
	fill_servprov_collection ;
	insert_servprov_data;
 
END;

END ATL_MASTER_DATA_FLOW_PKG ;

/
