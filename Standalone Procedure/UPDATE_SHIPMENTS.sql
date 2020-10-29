--------------------------------------------------------
--  DDL for Procedure UPDATE_SHIPMENTS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."UPDATE_SHIPMENTS" (p_data clob) 
as

l_count pls_integer;
l_loadslip_id loadslip.loadslip_id%type;
l_json_clob clob;
l_json_obj json_object_t;
l_shipments_obj json_object_t;
l_shipment_id shipment.shipment_id%type;
l_transporter_sap_code shipment.transporter_sap_code%type;
l_lr_num loadslip.lr_num%type;
l_truck_num shipment.truck_number%type;
l_rep_date loadslip.grn_reporting_date%type;
l_unload_date loadslip.grn_unloading_date%type;
l_source_go_date loadslip.grn_unloading_date%type;
begin

  --insert into json_clob (file_data) values (p_data);
  --commit;
  -- select file_data into l_json_clob from json_clob;
  -- parsing json data
    l_json_obj := json_object_t(p_data);
  -- get OEShipments object
    l_shipments_obj      := l_json_obj.get_object('ShipmentUpdate');
    l_shipment_id           := l_shipments_obj.get_string('ShipmentID');  
    l_transporter_sap_code  := l_shipments_obj.get_string('TransporterSAPCode'); 
    l_lr_num                := l_shipments_obj.get_string('LRNumber'); 
    l_truck_num             := l_shipments_obj.get_string('TruckNumber'); 
    l_rep_date              := to_date(l_shipments_obj.get_string('ReportingDate'),'YYYYMMDDHH24MISS'); 
    l_unload_date           := to_date(l_shipments_obj.get_string('UnloadingDate'),'YYYYMMDDHH24MISS');   
    l_source_go_date        := to_date(l_shipments_obj.get_string('SourceGateOutDate'),'YYYYMMDDHH24MISS');  
    --dbms_output.put_line('l_unload_date : '||l_unload_date);
    
    if l_shipment_id is not null then
    select count(1) into l_count from shipment where shipment_id = l_shipment_id;
    if l_count <> 0 then
    select loadslip_id into l_loadslip_id from loadslip 
    where shipment_id = l_shipment_id and rownum=1;
    
    update loadslip 
    set 
    grn_reporting_date = nvl(l_rep_date,grn_reporting_date),
    grn_unloading_date = nvl(l_unload_date,grn_unloading_date)
    where loadslip_id= l_loadslip_id;
    update shipment set is_sync_otm = 'T' where shipment_id=l_shipment_id;
    update truck_reporting set gateout_date = l_source_go_date 
    where shipment_id =l_shipment_id and gateout_date is null 
    and ref_code is null;
    commit;
    
    else
    
    select a.shipment_id into l_shipment_id 
    from shipment a, loadslip b 
    where a.shipment_id=b.shipment_id 
    and a.truck_number = l_truck_num
    and a.transporter_sap_code = (case when l_transporter_sap_code is null then a.transporter_sap_code else l_transporter_sap_code end)
    --and b.lr_num = l_lr_num;
    and l_lr_num in 
    (select regexp_substr(b.lr_num,'[^,]+', 1, level) from dual
    connect by regexp_substr(b.lr_num, '[^,]+', 1, level) is not null);
    
    update loadslip 
    set 
    grn_reporting_date = nvl(l_rep_date,grn_reporting_date),
    grn_unloading_date = nvl(l_unload_date,grn_unloading_date)
    where loadslip_id= (select loadslip_id from shipment where shipment_id=l_shipment_id);
    update shipment set is_sync_otm = 'T' where shipment_id=l_shipment_id;
    commit;
    
    end if;
    
    else
    
    select a.shipment_id into l_shipment_id 
    from shipment a, loadslip b 
    where a.shipment_id=b.shipment_id 
    and a.truck_number = l_truck_num
    and a.transporter_sap_code = (case when l_transporter_sap_code is null then a.transporter_sap_code else l_transporter_sap_code end)
    and l_lr_num in 
    (select regexp_substr(b.lr_num,'[^,]+', 1, level) from dual
    connect by regexp_substr(b.lr_num, '[^,]+', 1, level) is not null);
    
    update loadslip 
    set 
    grn_reporting_date = nvl(l_rep_date,grn_reporting_date),
    grn_unloading_date = nvl(l_unload_date,grn_unloading_date)
    where loadslip_id= (select loadslip_id from shipment where shipment_id=l_shipment_id);
    update shipment set is_sync_otm = 'T' where shipment_id=l_shipment_id;
    commit;
    
  end if;
    
    
    
end;

/
