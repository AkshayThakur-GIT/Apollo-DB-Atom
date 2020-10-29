--------------------------------------------------------
--  DDL for Package Body ATL_ACTUAL_SHIP_INT_API
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_ACTUAL_SHIP_INT_API" as

 -- Use this function to transform PaaS XML into OTM standard XML
  function get_as_stylesheet(p_type varchar2) return clob is
  l_xslt_string clob;
  begin
 
    select xsl_clob into l_xslt_string 
    from xsl_stylesheet where type='OTM_ACTUAL_SHIPMENT_V5';
    
    return l_xslt_string;
    end;
    
  function get_shipment_details(
    p_shipment_id varchar2)
  return ship_details pipelined
as
  l_so_sto_num loadslip.sto_so_num%type;
  l_sap_invoice loadslip.sap_invoice%type;
  l_invoice_date loadslip.sap_invoice_date%type;
  l_delivery_num loadslip.delivery%type;
  l_lr_num loadslip.lr_num%type;
  l_lr_date loadslip.lr_date%type;
  l_mkt_seg varchar2(10);
  l_bay_num loadslip.bay%type;
  l_tte_qty loadslip.tte_qty%type;
  l_truck_tte mt_truck_type.tte_capacity%type;
  l_at_days number;
  l_grn_num loadslip.grn%type;
  l_grn_date loadslip.grn_date%type;
begin
  begin
    select listagg(sto_so_num,'|') within group (
    order by sto_so_num)
    into l_so_sto_num
    from loadslip
    where shipment_id=p_shipment_id;
  exception
  when no_data_found then
    l_so_sto_num := null;
  end;
  begin
    select listagg(sap_invoice,'|') within group (
    order by sap_invoice)
    into l_sap_invoice
    from loadslip
    where shipment_id=p_shipment_id;
  exception
  when no_data_found then
    l_sap_invoice := null;
  end;
  begin
    select max(sap_invoice_date)
    into l_invoice_date
    from loadslip
    where shipment_id=p_shipment_id;
  exception
  when no_data_found then
    l_invoice_date := null;
  end;
  begin
    select listagg(delivery,'|') within group (
    order by delivery)
    into l_delivery_num
    from loadslip
    where shipment_id=p_shipment_id;
  exception
  when no_data_found then
    l_delivery_num := null;
  end;
  begin
    select listagg(lr_num,'|') within group (
    order by lr_num)
    into l_lr_num
    from loadslip
    where shipment_id=p_shipment_id and lr_num <> 'null';
  exception
  when no_data_found then
    l_lr_num := null;
  end;
  begin
    select max(lr_date)
    into l_lr_date
    from loadslip
    where shipment_id=p_shipment_id;
  exception
  when no_data_found then
    l_lr_date := null;
  end;
  begin
    /*select atl_business_flow_pkg.get_market_segment (
      (select location_id
      from shipment_stop a
      where a.shipment_id=p_shipment_id
      and a.stop_num     =
        (select min(stop_num) from shipment_stop where shipment_id = a.shipment_id
        )
      and rownum=1
      ),
      (select location_id
      from shipment_stop a
      where a.shipment_id=p_shipment_id
      and a.stop_num     =
        (select max(stop_num) from shipment_stop where shipment_id = a.shipment_id
        )
      and rownum=1
      ))
    into l_mkt_seg
    from dual;
    */
    
    select nvl((select b.market_segment
    from loadslip a, order_type_lookup b where a.loadslip_type=b.order_type 
    and a.shipment_id=p_shipment_id and rownum=1),'NA') 
    into l_mkt_seg
    from dual;
    
  exception
  when no_data_found then
    l_mkt_seg := null;
  end;
  begin
    select bay
    into l_bay_num
    from loadslip
    where shipment_id = p_shipment_id
    and bay          is not null
    and rownum        =1;
  exception
  when no_data_found then
    l_bay_num := null;
  end;
  begin
    select round(sum(tte_qty),2)
    into l_tte_qty
    from loadslip
    where shipment_id = p_shipment_id;
  exception
  when no_data_found then
    l_tte_qty := null;
  end;
  begin
    select tte_capacity
    into l_truck_tte
    from mt_truck_type
    where truck_type =
      (select truck_type
      from shipment
      where shipment_id=p_shipment_id
      )
    and nvl(variant1,'NO VARIANT') = nvl(
      (select variant_1 from shipment where shipment_id=p_shipment_id
      ),'NO VARIANT')
    and rownum=1;
  exception
  when no_data_found then
    l_truck_tte := null;
  end;
  
  /*begin
    select round(
      (select reporting_date
      from truck_reporting
      where truck_number=a1.truck_number
      and dest_loc      =
        (select location_id
        from shipment_stop b
        where b.shipment_id = a1.shipment_id
        and b.stop_num      =
          (select max(stop_num) from shipment_stop where shipment_id = b.shipment_id
          )
        )
      and shipment_id = a1.shipment_id
      and ref_code   is not null
      and rownum      =1
      ) -
      (select gateout_date
      from truck_reporting
      where truck_number=a1.truck_number
      and source_loc    =
        (select location_id
        from shipment_stop b
        where b.shipment_id = a1.shipment_id
        and b.stop_num      =
          (select min(stop_num) from shipment_stop where shipment_id = b.shipment_id
          )
        and rownum=1
        )
      and shipment_id = a1.shipment_id
      and ref_code   is null
      and rownum      =1
      ))
    into l_at_days
    from shipment a1
    where a1.shipment_id=p_shipment_id;
  exception
  when no_data_found then
    l_at_days := null;
  end;
  */
  l_at_days := null;
  
  begin
    select listagg(grn,'|') within group (
    order by grn)
    into l_grn_num
    from loadslip
    where shipment_id=p_shipment_id;
  exception
  when no_data_found then
    l_grn_num := null;
  end;
  begin
    select max(grn_date)
    into l_grn_date
    from loadslip
    where shipment_id=p_shipment_id;
  exception
  when no_data_found then
    l_grn_date := null;
  end;
  
  pipe row (ship_details_obj (so_sto_num => l_so_sto_num, invoice_num => l_sap_invoice, invoice_date => l_invoice_date, delivery_num => l_delivery_num, lr_number => l_lr_num, lr_date => l_lr_date, mkt_segment => l_mkt_seg, bay_number => l_bay_num, tte_qty => l_tte_qty, truck_tte => l_truck_tte, actual_transit_days => l_at_days, grn_number => l_grn_num, grn_date => l_grn_date));
  return;
end;
  
   function build_exp_sql(p_ship_id varchar2) return clob is
   l_sql_string clob;
   begin
   -- commented on 23-apr-2019
   /*l_sql_string := 
   'select 
      a1.shipment_id,round(a1.tte_util,2) as tte_util,round(a1.weight_util,2) as weight_util,round(a1.volume_util,2) as volume_util,a1.driver_name as driver_name,a1.driver_mobile as driver_mobile, a1.driver_license as driver_license,
      a1.shipment_name,a1.shipment_type,a1.status,a1.container_num,
      to_char(a1.shipped_onboard_date,''YYYYMMDDHH24MISS'') as shipped_onboard_date,
      a1.servprov as servprov_gid,a1.transporter_sap_code,
      nvl(a1.actual_truck_type,a1.truck_type) as equipment_group_gid,
      a1.truck_number as equipment_number,
      a1.shipment_id||''-1'' as shipment_equipment,
      a1.truck_type as pl_tt,a1.variant_1 as special_service,
      a1.variant_2,a1.transport_mode,(tab.so_sto_num) as so_sto_num,
      (tab.invoice_num) as sap_invoice,to_char(tab.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,
      (tab.grn_number) as grn_num,to_char(tab.grn_date,''YYYYMMDDHH24MISS'') as grn_date,
      (tab.delivery_num) as delivery,(tab.lr_number) as lr_num,
      to_char(tab.lr_date,''YYYYMMDDHH24MISS'') as lr_date,
      (tab.mkt_segment) as mk_seg,(tab.bay_number)as bay,
      cursor (select shipment_id,location_id,stop_num,loadslip_id,activity,
      (select to_char(gatein_date,''YYYYMMDDHH24MISS'') from truck_reporting where 
      truck_number=a1.truck_number and reporting_location = (select location_id from shipment_stop b 
      where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) 
      and shipment_id = a.shipment_id) as gate_in_date,
      (select to_char(gateout_date,''YYYYMMDDHH24MISS'') from truck_reporting where 
      truck_number=a1.truck_number and reporting_location = (select location_id from shipment_stop b 
      where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) 
      and shipment_id = a.shipment_id) as gate_out_date
      from shipment_stop a where a.shipment_id=a1.shipment_id
      order by stop_num,location_id) as shipment_stops,
      (tab.tte_qty) as TTE_QTY,(tab.truck_tte) as TRUCK_TTE,
      (tab.actual_transit_days) as AT_DAYS,
      cursor(select  a.loadslip_id,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,
      a.lr_num,a.status,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date,
      a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,
      a.delivery,a1.truck_type,(tab.mkt_segment) as mk_seg,
      a.item_category,a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,
      nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,
      a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,
      a.weight as wt,a.volume as vol,
      cursor(select ld.loadslip_id,ld.line_no,ld.item_id,ld.load_qty as qty,ld.batch_code,
      nvl(ld.gross_wt,0) * ld.load_qty as weight,nvl(ld.gross_wt_uom,''KG'') as weight_uom,nvl(ld.gross_vol,0) as volume,nvl(ld.gross_vol_uom,''CUMTR'') as volume_uom,dil.invoice_number,
      to_char(dih.invoice_date,''YYYYMMDDHH24MISS'') as invoice_date,dih.so_sto_num as so_sto_num,dih.delivery_number as delivery,mi.load_factor,mi.tte,(mi.tte * ld.load_qty) as tte_qty
      from loadslip_detail ld,del_inv_header dih, del_inv_line dil, mt_item mi
      where ld.loadslip_id=a.loadslip_id
      and ld.item_id = mi.item_id
      and ld.loadslip_id=dih.loadslip_id
      and dih.invoice_number = dil.invoice_number
      and ld.invoice_number=dil.invoice_number 
      and ld.item_id=dil.item_id) as LS_ITM_D
      from loadslip a where a.shipment_id= a1.shipment_id and a.status <> ''CANCELLED'') as S_LS
      from shipment a1,TABLE(atl_actual_ship_int_api.get_shipment_details(a1.shipment_id)) 
      tab where a1.shipment_id='||''''||p_ship_id||'''';*/
      
      l_sql_string := 'select a1.shipment_id,(select listagg(custom_inv_number,''|'') within group (order by loadslip_id) from del_inv_header where shipment_id=a1.shipment_id) as cus_inv,a1.stop_type,(select listagg(comments,'','') within group (order by loadslip_id) from loadslip where shipment_id=a1.shipment_id) as ls_com,(select listagg(comments,'','') within group (order by gate_control_code) from truck_reporting where (truck_number,shipment_id) = (select truck_number,shipment_id from shipment where shipment_id=a1.shipment_id)) as tr_com,round(a1.tte_util,2) as tte_util,round(a1.weight_util,2) as weight_util,round(a1.volume_util,2) as volume_util,a1.driver_name as driver_name,a1.driver_mobile as driver_mobile, a1.driver_license as driver_license,a1.shipment_name,a1.shipment_type,a1.status,a1.container_num,to_char(a1.shipped_onboard_date,''YYYYMMDDHH24MISS'') as shipped_onboard_date,a1.servprov as servprov_gid,a1.transporter_sap_code,nvl(a1.actual_truck_type,a1.truck_type) as equipment_group_gid,a1.truck_number as equipment_number,a1.shipment_id||''-1'' as shipment_equipment,a1.truck_type as pl_tt,a1.variant_1 as special_service,a1.variant_2,a1.transport_mode,(tab.so_sto_num) as so_sto_num,(tab.invoice_num) as sap_invoice,to_char(tab.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,(tab.grn_number) as grn_num,to_char(tab.grn_date,''YYYYMMDDHH24MISS'') as grn_date,(tab.delivery_num) as delivery,(tab.lr_number) as lr_num,to_char(tab.lr_date,''YYYYMMDDHH24MISS'') as lr_date,(tab.mkt_segment) as mk_seg,(tab.bay_number)as bay,cursor (SELECT shipment_id,location_id,stop_num,loadslip_id,activity,t.grn_remark,t.gate_in_date,t.gate_out_date,t.reporting_date,t.ls_date,t.le_date,t.sap_rep_date,t.sap_ul_date FROM shipment_stop a,table(atl_actual_ship_int_api.get_ship_stop_details(a.shipment_id,a1.truck_number,a.stop_num,a.activity,a.loadslip_id,''EXP''))t WHERE a.shipment_id=a1.shipment_id ORDER BY stop_num,location_id) as shipment_stops,(tab.tte_qty) as TTE_QTY,(tab.truck_tte) as TRUCK_TTE,(tab.actual_transit_days) as AT_DAYS,cursor(select  a.loadslip_id,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,a.lr_num,a.status,to_char(a.arrived_date,''YYYYMMDDHH24MISS'') as arr_date,to_char(a.ls_date,''YYYYMMDDHH24MISS'') as ls_date,to_char(a.le_date,''YYYYMMDDHH24MISS'') as le_date,to_char(a.release_date,''YYYYMMDDHH24MISS'') as r_date,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as c_date,to_char(a.grn_reporting_date,''YYYYMMDDHH24MISS'') as g_r_date,to_char(a.grn_unloading_date,''YYYYMMDDHH24MISS'') as g_u_date,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date,a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,a.delivery,a1.truck_type,(tab.mkt_segment) as mk_seg,a.item_category,a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,a.weight as wt,a.volume as vol,cursor(select ld.loadslip_id,ld.line_no,ld.item_id,ld.load_qty as qty,ld.batch_code,atl_actual_ship_int_api.get_tyre_id(ld.loadslip_id,ld.item_id) as tyre_id,nvl(ld.gross_wt,0) as weight,nvl(ld.gross_wt_uom,''KG'') as weight_uom,nvl(ld.gross_vol,0) as volume,nvl(ld.gross_vol_uom,''CUMTR'') as volume_uom,dil.invoice_number,to_char(dih.invoice_date,''YYYYMMDDHH24MISS'') as invoice_date,dih.so_sto_num as so_sto_num,dih.delivery_number as delivery,mi.load_factor,mi.tte,(mi.tte * ld.load_qty) as tte_qty from loadslip_detail ld,del_inv_header dih, del_inv_line dil, mt_item mi where ld.loadslip_id=a.loadslip_id and ld.item_id = mi.item_id and ld.loadslip_id=dih.loadslip_id and dih.invoice_number = dil.invoice_number and ld.invoice_number=dil.invoice_number and ld.item_id=dil.item_id) as LS_ITM_D from loadslip a where a.shipment_id= a1.shipment_id and a.status <> ''CANCELLED'') as S_LS,';
      l_sql_string := l_sql_string ||' cursor(select pi_no,customer_name,pre_inv_no,inco_term,payment_terms,pol,pod,cofd,forwarder,billing_party,shipping_line,container_num,to_char(cont_pick_date,''YYYYMMDDHH24MISS'') as cont_pick_date,to_char(stuffing_date,''YYYYMMDDHH24MISS'') as stuffing_date,booking_num,post_inv_no,sap_invoice,inv_amount,cha,planned_vessel,to_char(vessel_depart_pol_date,''YYYYMMDDHH24MISS'') as vessel_depart_pol_date,shipping_bill,to_char(shipping_bill_date,''YYYYMMDDHH24MISS'') as shipping_bill_date,to_char(gatein_date_cfs,''YYYYMMDDHH24MISS'') as gatein_date_cfs,to_char(customs_exam_date,''YYYYMMDDHH24MISS'') as customs_exam_date,to_char(leo_date,''YYYYMMDDHH24MISS'') as leo_date,to_char(gateout_date_cfs,''YYYYMMDDHH24MISS'') as gateout_date_cfs,to_char(gatein_date_port,''YYYYMMDDHH24MISS'') as gatein_date_port,actual_vessel,to_char(shipped_onboard_date,''YYYYMMDDHH24MISS'') as shipped_onboard_date,to_char(eta_pod,''YYYYMMDDHH24MISS'') as eta_pod,export_remarks from table(atl_actual_ship_int_api.get_exp_ship_details (a1.shipment_id))) as exp_data from shipment a1,TABLE(atl_actual_ship_int_api.get_shipment_details(a1.shipment_id)) tab where a1.status <> ''CANCELLED'' and a1.shipment_id='||''''||p_ship_id||'''';
      
      return l_sql_string;
   end;
   
   function build_jit_sql(p_ship_id varchar2) return clob is
   l_sql_string clob;
   begin
   -- commented on 23-apr-2019
   /*l_sql_string := 
   'select 
      a1.shipment_id,round(a1.tte_util,2) as tte_util,round(a1.weight_util,2) as weight_util,round(a1.volume_util,2) as volume_util,a1.driver_name as driver_name,a1.driver_mobile as driver_mobile, a1.driver_license as driver_license,a1.shipment_name,a1.shipment_type,a1.status,a1.servprov as servprov_gid,to_char((select max(receiving_date) from grn_detail_so where shipment_id =a1.shipment_id),''YYYYMMDDHH24MISS'') as grn_date,
      a1.transporter_sap_code,nvl(a1.actual_truck_type,a1.truck_type) as equipment_group_gid,
      a1.truck_number as equipment_number,a1.shipment_id||''-1'' as shipment_equipment,
      a1.truck_type as pl_tt,a1.variant_1 as special_service,a1.variant_2,
      a1.transport_mode,(tab.so_sto_num) as so_sto_num,(tab.invoice_num) as sap_invoice,
      to_char(tab.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,
      (tab.grn_number) as grn_num,to_char(tab.grn_date,''YYYYMMDDHH24MISS'') as grn_date,
      (tab.delivery_num) as delivery,(tab.lr_number) as lr_num,to_char(tab.lr_date,''YYYYMMDDHH24MISS'') as lr_date,
      (tab.mkt_segment) as mk_seg,(tab.bay_number)as bay,cursor (select shipment_id,location_id,stop_num,loadslip_id,activity,(select to_char(gatein_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=a1.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) 
      and shipment_id = a.shipment_id) as gate_in_date,(select to_char(gateout_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=a1.truck_number and reporting_location = (select location_id from shipment_stop b 
      where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) 
      and shipment_id = a.shipment_id) as gate_out_date from shipment_stop a where a.shipment_id=a1.shipment_id
      order by stop_num,location_id) as shipment_stops,
      (tab.tte_qty) as TTE_QTY,(tab.truck_tte) as TRUCK_TTE,
      cursor(select a.loadslip_id,a.ship_to,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,a.lr_num,
      a.status,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date,
      a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,
      a.delivery,a1.truck_type,(tab.mkt_segment) as mk_seg,a.item_category,
      a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,
      nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,
      a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,
      a.weight as wt,a.volume as vol,cursor(select ld.loadslip_id,ld.line_no,ld.item_id,ld.load_qty as qty,ld.batch_code,
      nvl(ld.gross_wt,0) * ld.load_qty as weight,nvl(ld.gross_wt_uom,''KG'') as weight_uom,nvl(ld.gross_vol,0) as volume,nvl(ld.gross_vol_uom,''CUMTR'') as volume_uom,dil.invoice_number,cursor(select sap_doc_number as grn_num,to_char(receiving_date,''YYYYMMDDHH24MISS'') as grn_date from grn_detail_so where invoice_number=dil.invoice_number and rownum=1)as grn_details ,
      to_char(dih.invoice_date,''YYYYMMDDHH24MISS'') as invoice_date,dih.so_sto_num as so_sto_num,dih.delivery_number as delivery,mi.load_factor,mi.tte,(mi.tte * ld.load_qty) as tte_qty
      from loadslip_detail ld,del_inv_header dih, del_inv_line dil, mt_item mi
      where ld.loadslip_id=a.loadslip_id
      and ld.item_id = mi.item_id
      and ld.loadslip_id=dih.loadslip_id
      and dih.invoice_number = dil.invoice_number
      and ld.invoice_number=dil.invoice_number 
      and ld.item_id=dil.item_id) as LS_ITM_D
      from loadslip a where a.shipment_id= a1.shipment_id and a.status <> ''CANCELLED'') as S_LS
      from shipment a1,TABLE(atl_actual_ship_int_api.get_shipment_details(a1.shipment_id)) 
      tab where a1.shipment_id='||''''||p_ship_id||'''';*/
      
      l_sql_string := 'select a1.shipment_id,a1.stop_type,(select listagg(comments,'','') within group (order by loadslip_id) from loadslip where shipment_id=a1.shipment_id) as ls_com,(select listagg(comments,'','') within group (order by gate_control_code) from truck_reporting where (truck_number,shipment_id) = (select truck_number,shipment_id from shipment where shipment_id=a1.shipment_id)) as tr_com,round(a1.tte_util,2) as tte_util,round(a1.weight_util,2) as weight_util,round(a1.volume_util,2) as volume_util,a1.driver_name as driver_name,a1.driver_mobile as driver_mobile, a1.driver_license as driver_license,a1.shipment_name,a1.shipment_type,a1.status,a1.servprov as servprov_gid,to_char((select max(receiving_date) from grn_detail_so where shipment_id =a1.shipment_id),''YYYYMMDDHH24MISS'') as grn_date,a1.transporter_sap_code,nvl(a1.actual_truck_type,a1.truck_type) as equipment_group_gid,a1.truck_number as equipment_number,a1.shipment_id||''-1'' as shipment_equipment,a1.truck_type as pl_tt,a1.variant_1 as special_service,a1.variant_2,a1.transport_mode,(tab.so_sto_num) as so_sto_num,(tab.invoice_num) as sap_invoice,to_char(tab.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,(tab.grn_number) as grn_num,to_char(tab.grn_date,''YYYYMMDDHH24MISS'') as grn_date,(tab.delivery_num) as delivery,(tab.lr_number) as lr_num,to_char(tab.lr_date,''YYYYMMDDHH24MISS'') as lr_date,(tab.mkt_segment) as mk_seg,(tab.bay_number)as bay,cursor (SELECT shipment_id,location_id,stop_num,loadslip_id,activity,t.grn_remark,t.gate_in_date,t.gate_out_date,t.reporting_date,t.ls_date,t.le_date,t.sap_rep_date,t.sap_ul_date FROM shipment_stop a,table(atl_actual_ship_int_api.get_ship_stop_details(a.shipment_id,a1.truck_number,a.stop_num,a.activity,a.loadslip_id,''OE''))t WHERE a.shipment_id=a1.shipment_id ORDER BY stop_num,location_id) as shipment_stops,(tab.tte_qty) as TTE_QTY,(tab.truck_tte) as TRUCK_TTE,';
      l_sql_string := l_sql_string ||' cursor(select a.loadslip_id,a.ship_to,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,a.lr_num,a.status,to_char(a.arrived_date,''YYYYMMDDHH24MISS'') as arr_date,to_char(a.ls_date,''YYYYMMDDHH24MISS'') as ls_date,to_char(a.le_date,''YYYYMMDDHH24MISS'') as le_date,to_char(a.release_date,''YYYYMMDDHH24MISS'') as r_date,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as c_date,to_char(a.grn_reporting_date,''YYYYMMDDHH24MISS'') as g_r_date,to_char(a.grn_unloading_date,''YYYYMMDDHH24MISS'') as g_u_date,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date,a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,a.delivery,a1.truck_type,(tab.mkt_segment) as mk_seg,a.item_category,a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,a.weight as wt,a.volume as vol,cursor(select ld.loadslip_id,ld.line_no,ld.item_id,ld.load_qty as qty,ld.batch_code,atl_actual_ship_int_api.get_tyre_id(ld.loadslip_id,ld.item_id) as tyre_id,nvl(ld.gross_wt,0) * ld.load_qty as weight,nvl(ld.gross_wt_uom,''KG'') as weight_uom,nvl(ld.gross_vol,0) as volume,nvl(ld.gross_vol_uom,''CUMTR'') as volume_uom,dil.invoice_number,cursor(select sap_doc_number as grn_num,to_char(receiving_date,''YYYYMMDDHH24MISS'') as grn_date from grn_detail_so where invoice_number=dil.invoice_number and rownum=1)as grn_details,to_char(dih.invoice_date,''YYYYMMDDHH24MISS'') as invoice_date,dih.so_sto_num as so_sto_num,dih.delivery_number as delivery,mi.load_factor,mi.tte,(mi.tte * ld.load_qty) as tte_qty from loadslip_detail ld,del_inv_header dih, del_inv_line dil, mt_item mi where ld.loadslip_id=a.loadslip_id and ld.item_id = mi.item_id and ld.loadslip_id=dih.loadslip_id and dih.invoice_number = dil.invoice_number and ld.invoice_number=dil.invoice_number and ld.item_id=dil.item_id) as LS_ITM_D from loadslip a where a.shipment_id= a1.shipment_id and a.status <> ''CANCELLED'') as S_LS from shipment a1,TABLE(atl_actual_ship_int_api.get_shipment_details(a1.shipment_id)) tab where a1.status <> ''CANCELLED'' and a1.shipment_id='||''''||p_ship_id||'''';
      return l_sql_string;
   end;
   
   function build_sql(p_ship_id varchar2) return clob is
   l_sql_string clob;
   begin
   l_sql_string := 
   --'select v.shipment_id,round(v.tte_util,2) as tte_util,round(v.weight_util,2) as weight_util,round(v.volume_util,2) as volume_util,v.driver_name as driver_name,v.driver_mobile as driver_mobile, v.driver_license as driver_license,v.shipment_name,v.shipment_type,v.status,v.servprov as servprov_gid,v.transporter_sap_code,nvl(v.actual_truck_type,v.truck_type) as equipment_group_gid,v.truck_number as equipment_number,v.shipment_id||''-1'' as shipment_equipment,v.truck_type as pl_tt,v.variant_1 as special_service,v.variant_2,v.transport_mode,(x.so_sto_num) as so_sto_num,(x.invoice_num) as sap_invoice,to_char(x.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,(x.grn_number) as grn_num,to_char(x.grn_date,''YYYYMMDDHH24MISS'') as grn_date,(x.delivery_num) as delivery,(x.lr_number) as lr_num,to_char(x.lr_date,''YYYYMMDDHH24MISS'') as lr_date,(x.mkt_segment) as mk_seg,(x.bay_number)as bay,cursor(select shipment_id,location_id,stop_num,loadslip_id,activity,nvl((select to_char(reporting_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=v.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) and shipment_id = a.shipment_id),(select to_char(v.grn_reporting_date,''YYYYMMDDHH24MISS'') from loadslip v where v.loadslip_id = a.loadslip_id and v.shipment_id=a.shipment_id)) as gate_in_date,nvl((select to_char(gateout_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=v.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) and shipment_id = a.shipment_id),(select to_char(v.grn_unloading_date,''YYYYMMDDHH24MISS'') from loadslip v where v.loadslip_id = a.loadslip_id and v.shipment_id=a.shipment_id)) as gate_out_date from shipment_stop a where a.shipment_id=v.shipment_id order by stop_num,location_id) as shipment_stops,(x.tte_qty) as TTE_QTY,(x.truck_tte) as TRUCK_TTE,cursor(select a.loadslip_id,a.ship_to,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,a.lr_num,a.status,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date, a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,a.delivery,v.truck_type,(x.mkt_segment) as mk_seg,a.item_category,a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,a.weight as wt,a.volume as vol,cursor(select p.loadslip_id,p.line_no,p.item_id,p.qty as qty,p.batch_code,nvl(p.weight,0)*p.qty as weight,nvl(p.weight_uom,''KG'') as weight_uom,nvl(p.volume,0) as volume,nvl(p.volume_uom,''CUMTR'') as volume_uom,(select listagg(invoice_number,'','') within group (order by invoice_number) from loadslip_inv_line where loadslip_id=p.loadslip_id and item_id=y.item_id) as invoice_number,cursor(select grn as grn_num,to_char(grn_date,''YYYYMMDDHH24MISS'') as grn_date from loadslip where loadslip_id = p.loadslip_id and rownum=1)as grn_details,to_char(h.invoice_date,''YYYYMMDDHH24MISS'') as invoice_date,h.so_sto_num as so_sto_num,h.delivery_number as delivery,g.load_factor,g.tte,(g.tte * p.qty) as tte_qty from loadslip_line_detail p,loadslip_inv_header h, loadslip_inv_line y, mt_item g where p.loadslip_id=a.loadslip_id and p.item_id = g.item_id and p.loadslip_id=h.loadslip_id and h.invoice_number = y.invoice_number and p.invoice_number=y.invoice_number and p.item_id=y.item_id and p.line_no = y.line_no order by p.line_no asc) as LS_ITM_D from loadslip a where a.shipment_id= v.shipment_id and a.status <> ''CANCELLED'') as S_LS from shipment v,TABLE(atl_actual_ship_int_api.get_shipment_details(v.shipment_id)) x where v.shipment_id='||''''||p_ship_id||'''';
   --'select v.shipment_id,round(v.tte_util,2) as tte_util,round(v.weight_util,2) as weight_util,round(v.volume_util,2) as volume_util,v.driver_name as driver_name,v.driver_mobile as driver_mobile, v.driver_license as driver_license,v.shipment_name,v.shipment_type,v.status,v.servprov as servprov_gid,v.transporter_sap_code,nvl(v.actual_truck_type,v.truck_type) as equipment_group_gid,v.truck_number as equipment_number,v.shipment_id||''-1'' as shipment_equipment,v.truck_type as pl_tt,v.variant_1 as special_service,v.variant_2,v.transport_mode,(x.so_sto_num) as so_sto_num,(x.invoice_num) as sap_invoice,to_char(x.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,(x.grn_number) as grn_num,to_char(x.grn_date,''YYYYMMDDHH24MISS'') as grn_date,(x.delivery_num) as delivery,(x.lr_number) as lr_num,to_char(x.lr_date,''YYYYMMDDHH24MISS'') as lr_date,(x.mkt_segment) as mk_seg,(x.bay_number)as bay,cursor(select shipment_id,location_id,stop_num,loadslip_id,activity,nvl((select to_char(reporting_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=v.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) and shipment_id = a.shipment_id),(select to_char(v.grn_reporting_date,''YYYYMMDDHH24MISS'') from loadslip v where v.loadslip_id = a.loadslip_id and v.shipment_id=a.shipment_id)) as gate_in_date,nvl((select to_char(gateout_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=v.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) and shipment_id = a.shipment_id),(select to_char(v.grn_unloading_date,''YYYYMMDDHH24MISS'') from loadslip v where v.loadslip_id = a.loadslip_id and v.shipment_id=a.shipment_id)) as gate_out_date from shipment_stop a where a.shipment_id=v.shipment_id order by stop_num,location_id) as shipment_stops,(x.tte_qty) as TTE_QTY,(x.truck_tte) as TRUCK_TTE,cursor(select a.loadslip_id,a.ship_to,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,a.lr_num,a.status,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date, a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,a.delivery,v.truck_type,(x.mkt_segment) as mk_seg,a.item_category,a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,a.weight as wt,a.volume as vol,cursor(select p.loadslip_id,p.line_no,p.item_id,p.qty as qty,p.batch_code,nvl(p.weight,0)*p.qty as weight,nvl(p.weight_uom,''KG'') as weight_uom,nvl(p.volume,0) as volume,nvl(p.volume_uom,''CUMTR'') as volume_uom,p.invoice_number as invoice_number,cursor(select grn as grn_num,to_char(grn_date,''YYYYMMDDHH24MISS'') as grn_date from loadslip where loadslip_id = p.loadslip_id and rownum=1)as grn_details,to_char(h.invoice_date,''YYYYMMDDHH24MISS'') as invoice_date,h.so_sto_num as so_sto_num,h.delivery_number as delivery,g.load_factor,g.tte,(g.tte * p.qty) as tte_qty from loadslip_line_detail p,loadslip_inv_header h, mt_item g where p.loadslip_id=a.loadslip_id and p.item_id = g.item_id and p.loadslip_id=h.loadslip_id order by p.line_no asc) as LS_ITM_D from loadslip a where a.shipment_id= v.shipment_id and a.status <> ''CANCELLED'') as S_LS from shipment v,TABLE(atl_actual_ship_int_api.get_shipment_details(v.shipment_id)) x where v.shipment_id='||''''||p_ship_id||'''';  
   --'select v.shipment_id,round(v.tte_util,2) as tte_util,round(v.weight_util,2) as weight_util,round(v.volume_util,2) as volume_util,v.driver_name as driver_name,v.driver_mobile as driver_mobile, v.driver_license as driver_license,v.shipment_name,v.shipment_type,v.status,v.servprov as servprov_gid,v.transporter_sap_code,nvl(v.actual_truck_type,v.truck_type) as equipment_group_gid,v.truck_number as equipment_number,v.shipment_id||''-1'' as shipment_equipment,v.truck_type as pl_tt,v.variant_1 as special_service,v.variant_2,v.transport_mode,(x.so_sto_num) as so_sto_num,(x.invoice_num) as sap_invoice,to_char(x.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,(x.grn_number) as grn_num,to_char(x.grn_date,''YYYYMMDDHH24MISS'') as grn_date,(x.delivery_num) as delivery,(x.lr_number) as lr_num,to_char(x.lr_date,''YYYYMMDDHH24MISS'') as lr_date,(x.mkt_segment) as mk_seg,(x.bay_number)as bay,cursor(select shipment_id,location_id,stop_num,loadslip_id,activity,nvl((select to_char(reporting_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=v.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) and shipment_id = a.shipment_id),(select to_char(v.grn_reporting_date,''YYYYMMDDHH24MISS'') from loadslip v where v.loadslip_id = a.loadslip_id and v.shipment_id=a.shipment_id)) as gate_in_date,nvl((select to_char(gateout_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=v.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) and shipment_id = a.shipment_id),(select to_char(v.grn_unloading_date,''YYYYMMDDHH24MISS'') from loadslip v where v.loadslip_id = a.loadslip_id and v.shipment_id=a.shipment_id)) as gate_out_date from shipment_stop a where a.shipment_id=v.shipment_id order by stop_num,location_id) as shipment_stops,(x.tte_qty) as TTE_QTY,(x.truck_tte) as TRUCK_TTE,cursor(select a.loadslip_id,a.ship_to,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,a.lr_num,a.status,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date, a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,a.delivery,v.truck_type,(x.mkt_segment) as mk_seg,a.item_category,a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,a.weight as wt,a.volume as vol,cursor(select p.loadslip_id,p.line_no,p.item_id,p.qty as qty,p.batch_code,nvl(p.weight,0)*p.qty as weight,nvl(p.weight_uom,''KG'') as weight_uom,nvl(p.volume,0) as volume,nvl(p.volume_uom,''CUMTR'') as volume_uom,p.invoice_number as invoice_number,cursor(select grn as grn_num,to_char(grn_date,''YYYYMMDDHH24MISS'') as grn_date from loadslip where loadslip_id = p.loadslip_id and rownum=1)as grn_details,(select TO_CHAR(max(invoice_date),''YYYYMMDDHH24MISS'') from loadslip_inv_header where loadslip_id=p.loadslip_id and invoice_number = p.invoice_number) as invoice_date,(select so_sto_num from loadslip_inv_header where loadslip_id=p.loadslip_id and rownum=1) as so_sto_num,(select listagg(delivery_number,'','') within group (order by delivery_number) from loadslip_inv_header where loadslip_id=p.loadslip_id and invoice_number = p.invoice_number ) as delivery,g.load_factor,g.tte,(g.tte * p.qty) as tte_qty from loadslip_line_detail p,mt_item g where p.loadslip_id=a.loadslip_id and p.item_id = g.item_id order by p.line_no asc) as LS_ITM_D from loadslip a where a.shipment_id= v.shipment_id and a.status <> ''CANCELLED'') as S_LS from shipment v,TABLE(atl_actual_ship_int_api.get_shipment_details(v.shipment_id)) x where v.shipment_id='||''''||p_ship_id||'''';
   
   -- commented on 23-apr-2019
   --'select v.shipment_id,round(v.tte_util,2) as tte_util,round(v.weight_util,2) as weight_util,round(v.volume_util,2) as volume_util,v.driver_name as driver_name,v.driver_mobile as driver_mobile, v.driver_license as driver_license,v.shipment_name,v.shipment_type,v.status,v.servprov as servprov_gid,v.transporter_sap_code,nvl(v.actual_truck_type,v.truck_type) as equipment_group_gid,v.truck_number as equipment_number,v.shipment_id||''-1'' as shipment_equipment,v.truck_type as pl_tt,v.variant_1 as special_service,v.variant_2,v.transport_mode,(x.so_sto_num) as so_sto_num,(x.invoice_num) as sap_invoice,to_char(x.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,(x.grn_number) as grn_num,to_char(x.grn_date,''YYYYMMDDHH24MISS'') as grn_date,(x.delivery_num) as delivery,(x.lr_number) as lr_num,to_char(x.lr_date,''YYYYMMDDHH24MISS'') as lr_date,(x.mkt_segment) as mk_seg,(x.bay_number)as bay,cursor(select shipment_id,location_id,stop_num,loadslip_id,activity,(select grn_remark from loadslip  where loadslip_id=a.loadslip_id) as G_R,nvl((select to_char(reporting_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=v.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) and shipment_id = a.shipment_id),(select to_char(v.grn_reporting_date,''YYYYMMDDHH24MISS'') from loadslip v where v.loadslip_id = a.loadslip_id and v.shipment_id=a.shipment_id)) as gate_in_date,nvl((select to_char(gateout_date,''YYYYMMDDHH24MISS'') from truck_reporting where truck_number=v.truck_number and reporting_location = (select location_id from shipment_stop b where b.shipment_id = a.shipment_id and b.stop_num = a.stop_num and rownum=1) and shipment_id = a.shipment_id),(select to_char(v.grn_unloading_date,''YYYYMMDDHH24MISS'') from loadslip v where v.loadslip_id = a.loadslip_id and v.shipment_id=a.shipment_id)) as gate_out_date from shipment_stop a where a.shipment_id=v.shipment_id order by stop_num,location_id) as shipment_stops,(x.tte_qty) as TTE_QTY,(x.truck_tte) as TRUCK_TTE,';
     'select v.shipment_id,v.stop_type,(select listagg(comments,'','') within group (order by loadslip_id) from loadslip where shipment_id=v.shipment_id) as ls_com,(select listagg(comments,'','') within group (order by gate_control_code) from truck_reporting where (truck_number,shipment_id) = (select truck_number,shipment_id from shipment where shipment_id=v.shipment_id)) as tr_com,round(v.tte_util,2) as tte_util,round(v.weight_util,2) as weight_util,round(v.volume_util,2) as volume_util,v.driver_name as driver_name,v.driver_mobile as driver_mobile, v.driver_license as driver_license,v.shipment_name,v.shipment_type,v.status,v.servprov as servprov_gid,v.transporter_sap_code,nvl(v.actual_truck_type,v.truck_type) as equipment_group_gid,v.truck_number as equipment_number,v.shipment_id||''-1'' as shipment_equipment,v.truck_type as pl_tt,v.variant_1 as special_service,v.variant_2,v.transport_mode,(x.so_sto_num) as so_sto_num,(x.invoice_num) as sap_invoice,to_char(x.invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,(x.grn_number) as grn_num,to_char(x.grn_date,''YYYYMMDDHH24MISS'') as grn_date,(x.delivery_num) as delivery,(x.lr_number) as lr_num,to_char(x.lr_date,''YYYYMMDDHH24MISS'') as lr_date,(x.mkt_segment) as mk_seg,(x.bay_number)as bay,cursor(SELECT shipment_id,location_id,stop_num,loadslip_id,activity,t.grn_remark,t.gate_in_date,t.gate_out_date,t.reporting_date,t.ls_date,t.le_date,t.sap_rep_date,t.sap_ul_date FROM shipment_stop a,table(atl_actual_ship_int_api.get_ship_stop_details(a.shipment_id,v.truck_number,a.stop_num,a.activity,a.loadslip_id,''FGS''))t WHERE a.shipment_id=v.shipment_id ORDER BY stop_num,location_id) as shipment_stops,(x.tte_qty) as TTE_QTY,(x.truck_tte) as TRUCK_TTE,';
   
   -- commented on 23-apr-2019
   -- l_sql_string := l_sql_string || 'cursor(select a.loadslip_id,a.ship_to,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,a.lr_num,a.status,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date, a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,a.delivery,v.truck_type,(x.mkt_segment) as mk_seg,a.item_category,a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,a.weight as wt,a.volume as vol,cursor(select p.loadslip_id,p.line_no,p.item_id,p.qty as qty,p.batch_code,nvl(p.weight,0)*p.qty as weight,nvl(p.weight_uom,''KG'') as weight_uom,nvl(p.volume,0) as volume,nvl(p.volume_uom,''CUMTR'') as volume_uom,p.invoice_number as invoice_number,cursor(select grn as grn_num,to_char(grn_date,''YYYYMMDDHH24MISS'') as grn_date from loadslip where loadslip_id = p.loadslip_id and rownum=1)as grn_details,(select TO_CHAR(max(invoice_date),''YYYYMMDDHH24MISS'') from loadslip_inv_header where loadslip_id=p.loadslip_id and invoice_number = p.invoice_number) as invoice_date,(select so_sto_num from loadslip_inv_header where loadslip_id=p.loadslip_id and rownum=1) as so_sto_num,(select listagg(delivery_number,'','') within group (order by delivery_number) from loadslip_inv_header where loadslip_id=p.loadslip_id and invoice_number = p.invoice_number ) as delivery,g.load_factor,g.tte,(g.tte * p.qty) as tte_qty from loadslip_line_detail p,mt_item g where p.loadslip_id=a.loadslip_id and p.item_id = g.item_id order by p.line_no asc) as LS_ITM_D from loadslip a where a.shipment_id= v.shipment_id and a.status <> ''CANCELLED'') as S_LS from shipment v,TABLE(atl_actual_ship_int_api.get_shipment_details(v.shipment_id)) x where v.shipment_id='||''''||p_ship_id||'''';
   l_sql_string := l_sql_string || 'cursor(select a.loadslip_id,a.ship_to,a.loadslip_type,a.source_loc,a.dest_loc,a.sto_so_num,a.sap_invoice,a.lr_num,a.status,to_char(a.arrived_date,''YYYYMMDDHH24MISS'') as arr_date,to_char(a.ls_date,''YYYYMMDDHH24MISS'') as ls_date,to_char(a.le_date,''YYYYMMDDHH24MISS'') as le_date,to_char(a.release_date,''YYYYMMDDHH24MISS'') as r_date,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as c_date,to_char(a.grn_reporting_date,''YYYYMMDDHH24MISS'') as g_r_date,to_char(a.grn_unloading_date,''YYYYMMDDHH24MISS'') as g_u_date,to_char(a.lr_date,''YYYYMMDDHH24MISS'') as lr_date, a.grn as grn_num,to_char(a.grn_date,''YYYYMMDDHH24MISS'') as grn_date,a.delivery,v.truck_type,(x.mkt_segment) as mk_seg,a.item_category,a.tte_qty,round(a.tte_util,2) as tte_util,round(a.weight_util,2) as weight_util,round(a.volume_util,2) as volume_util,to_char(a.sap_invoice_date,''YYYYMMDDHH24MISS'') as sap_invoice_date,nvl((select movement_type from order_type_lookup where order_type=a.loadslip_type and rownum=1),''NA'') as ps,a.bay,to_char(a.confirm_date,''YYYYMMDDHH24MISS'') as confirm_date,a.weight as wt,a.volume as vol,cursor(select p.loadslip_id,p.line_no,p.item_id,p.qty as qty,p.batch_code,atl_actual_ship_int_api.get_tyre_id(p.loadslip_id,p.item_id) as tyre_id,nvl(p.weight,0)*p.qty as weight,nvl(p.weight_uom,''KG'') as weight_uom,nvl(p.volume,0) as volume,nvl(p.volume_uom,''CUMTR'') as volume_uom,p.invoice_number as invoice_number,cursor(select grn as grn_num,to_char(grn_date,''YYYYMMDDHH24MISS'') as grn_date from loadslip where loadslip_id = p.loadslip_id and rownum=1)as grn_details,(select TO_CHAR(max(invoice_date),''YYYYMMDDHH24MISS'') from loadslip_inv_header where loadslip_id=p.loadslip_id and invoice_number = p.invoice_number) as invoice_date,(select so_sto_num from loadslip_inv_header where loadslip_id=p.loadslip_id and rownum=1) as so_sto_num,(select listagg(delivery_number,'','') within group (order by delivery_number) from loadslip_inv_header where loadslip_id=p.loadslip_id and invoice_number = p.invoice_number ) as delivery,g.load_factor,g.tte,(g.tte * p.qty) as tte_qty from loadslip_line_detail p,mt_item g where p.loadslip_id=a.loadslip_id and p.item_id = g.item_id order by p.line_no asc) as LS_ITM_D from loadslip a where a.shipment_id= v.shipment_id and a.status <> ''CANCELLED'') as S_LS from shipment v,TABLE(atl_actual_ship_int_api.get_shipment_details(v.shipment_id)) x where v.status <> ''CANCELLED'' and v.shipment_id='||''''||p_ship_id||'''';  
    
      return l_sql_string;
   end;
  
  procedure process_shipment(
      p_shipment_id in varchar2,
      p_loadslip_type in varchar2,
      p_instance varchar2, 
      p_int_seq in number)
  as
    l_resp_code varchar2(100);
    l_resp_clob clob;
    l_xml xmltype;
    l_otm_xml xmltype;
    l_resp_xmltype xmltype;
    l_sql_string clob;
    l_stylesheet clob;
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(4000);
    l_type del_inv_header.type%type;
  begin
  
    select nvl((select type
    from del_inv_header where shipment_id=p_shipment_id and rownum=1),'NA') 
    into l_type 
    from dual;
    
    --if p_loadslip_type in ('JIT_OEM','FGS_OEM','EXT_OEM') then
    if l_type = 'JIT_OEM' then
    l_sql_string := build_jit_sql(p_shipment_id); 
    --atl_sap_integration_pkg.make_request(p_shipment_id,1,'SHIP-LS-UPDT');
    begin
    atl_sap_integration_pkg.send_ship_ls_details(p_shipment_id);
    exception when others then
    null;
    end;
    elsif p_loadslip_type = 'FGS_EXP' then
    
    begin
    update loadslip a set a.custom_inv_number = (select listagg(custom_inv_number,'|') within group (
          order by loadslip_id) from del_inv_header where
    shipment_id= a.shipment_id and loadslip_id = a.loadslip_id group by loadslip_id)
    where a.shipment_id =p_shipment_id;
    exception when others then 
    null;
    end;
    
    l_sql_string := build_exp_sql(p_shipment_id);
    --atl_sap_integration_pkg.make_request(p_shipment_id,1,'SHIP-LS-UPDT');
    begin
    atl_sap_integration_pkg.send_ship_ls_details(p_shipment_id);
    exception when others then
    null;
    end;
    --elsif p_loadslip_type in ('RDC_ABU','FGS_ABU','FGS_DEL','FGS_RDC','FGS_JIT','FGS_EXW','FGS_EXT',
    --                            'FGS_PLT','RDC_RDC','JIT_JIT','JIT_RDC','RDC_JIT','EXT_RDC','EXT_PLT','JIT_PLT','RDC_PLT') then
    else
    l_sql_string := build_sql(p_shipment_id);
    end if;
    
    l_stylesheet := get_as_stylesheet(p_loadslip_type);
    
    -- Create the XML as SQL
    l_xml     := atl_util_pkg.sql2xml(l_sql_string);
    
    -- Transform XML using OTM XSL
    l_otm_xml := l_xml.transform(xmltype(l_stylesheet));
    --dbms_output.put_line('OTM XML: '||l_otm_xml.getclobval()); 
    
     -- insert into integration log table
    atl_util_pkg.insert_integration_log(p_json_data => l_otm_xml.getclobval(), p_int_in_out => 'N', p_interface_name => 'OTM', p_api_name => 'ActualShipment', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => p_int_seq);
        
    -- Sets character set of the body
    utl_http.set_body_charset('UTF-8');
    
    -- Clear headers before setting up
    apex_web_service.g_request_headers.delete();
    
    -- Build request header with content type and authorization
    apex_web_service.g_request_headers(1).name  := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/xml';
    apex_web_service.g_request_headers(2).name  := 'Authorization';
    apex_web_service.g_request_headers(2).value := 'Basic '||atl_app_config.c_otm_int_credential;
    
    -- Call OTM Integration API for XML processing
    if p_instance    = 'DEV' then
      l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_dev_api_url, p_http_method => 'POST', p_body => l_otm_xml.getclobval());
    elsif p_instance = 'TEST' then
      l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_test_api_url, p_http_method => 'POST', p_body => l_otm_xml.getclobval());
    elsif p_instance = 'PROD' then
      l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_prod_api_url, p_http_method => 'POST', p_body => l_otm_xml.getclobval());
    end if;
    --dbms_output.put_line('OTM Response XML: '||l_resp_clob);
    
    -- Convert output CLOB to XML for response reading data
    l_resp_xmltype := xmltype.createxml(l_resp_clob);
    
    -- Parse response
    l_resp_code := apex_web_service.parse_xml_clob( p_xml => l_resp_xmltype, p_xpath => '//TransmissionAck/EchoedTransmissionHeader/TransmissionHeader/ReferenceTransmissionNo/text()');
    -- p_response_code := to_number(l_resp_code);
    -- dbms_output.put_line('OTM Response Code: '||l_resp_code);
  
    if l_resp_code is not null then
    
    update integration_log
    set status    ='PROCESSED',
      otm_ack_no  = to_number(l_resp_code),
      update_user = 'INTEGRATION',
      update_date = sysdate
    where id      = p_int_seq;
    
    else
    l_int_error_seq := integration_error_seq.nextval;
    l_err_msg       := substr(l_resp_xmltype.getStringVal(), 1, 4000);
    atl_util_pkg.insert_error('ActualShipment',l_err_msg,-1,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;    
    end if;
    
    commit;
   exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('ActualShipment',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    update integration_log
    set status     ='ERROR',
      update_user  = 'INTEGRATION',
      update_date  = sysdate,
      error_log_id = l_int_error_seq
    where id       = p_int_seq;
    commit;
    raise; 
  
  end;
  
   /* function get_ship_stop_details(
      p_shipment_id  varchar2,
      p_truck_number varchar2,
      p_stop_num     number,
      p_stop_type    varchar2,
      p_loadslip_id  varchar2,
      p_type         varchar2)
    return ship_stop_details_list pipelined
  as
    l_grn_remark loadslip.grn_remark%type;
    l_gate_in_date   varchar2(20);
    l_gate_out_date  varchar2(20);
    l_reporting_date varchar2(20);
    l_ls_date        varchar2(20);
    l_le_date        varchar2(20);
    l_sap_rep_date   varchar2(20);
    l_sap_ul_date    varchar2(20);
  begin
    if p_type in ('OE','FGS') then
      begin
        select a.grn_remark,
          to_char(a.ls_date,'YYYYMMDDHH24MISS'),
          to_char(a.le_date,'YYYYMMDDHH24MISS'),
          to_char(a.grn_reporting_date,'YYYYMMDDHH24MISS'),
          to_char(a.grn_unloading_date,'YYYYMMDDHH24MISS')
        into l_grn_remark,
          l_ls_date,
          l_le_date,
          l_sap_rep_date,
          l_sap_ul_date
        from loadslip a
        where a.loadslip_id=p_loadslip_id;
      exception
      when no_data_found then
        l_grn_remark   := null;
        l_ls_date      := null;
        l_le_date      := null;
        l_sap_rep_date := null;
        l_sap_ul_date  := null;
      end;
      begin
        select nvl(
          (select to_char(reporting_date,'YYYYMMDDHH24MISS')
          from truck_reporting
          where truck_number     =p_truck_number
          and reporting_location =
            (select location_id
            from shipment_stop b
            where b.shipment_id = p_shipment_id
            and b.stop_num      = p_stop_num
            and rownum          =1
            )
          and shipment_id = p_shipment_id
          ),
          (select to_char(v.grn_reporting_date,'YYYYMMDDHH24MISS')
          from loadslip v
          where v.loadslip_id = p_loadslip_id
          and v.shipment_id   =p_shipment_id
          ))
        into l_gate_in_date
        from dual;
      exception
      when no_data_found then
        l_gate_in_date := null;
      end;
      begin
        select nvl(
          (select to_char(gateout_date,'YYYYMMDDHH24MISS')
          from truck_reporting
          where truck_number     =p_truck_number
          and reporting_location =
            (select location_id
            from shipment_stop b
            where b.shipment_id = p_shipment_id
            and b.stop_num      = p_stop_num
            and rownum          =1
            )
          and shipment_id = p_shipment_id
          ),
          (select to_char(v.grn_unloading_date,'YYYYMMDDHH24MISS')
          from loadslip v
          where v.loadslip_id = p_loadslip_id
          and v.shipment_id   =p_shipment_id
          ))
        into l_gate_out_date
        from dual;
      exception
      when no_data_found then
        l_gate_out_date := null;
      end;
      begin
        select to_char(reporting_date,'YYYYMMDDHH24MISS')
        into l_reporting_date
        from truck_reporting
        where truck_number     =p_truck_number
        and reporting_location =
          (select location_id
          from shipment_stop b
          where b.shipment_id = p_shipment_id
          and b.stop_num      = p_stop_num
          and rownum          =1
          );
      exception
      when no_data_found then
        l_reporting_date := null;
      when others then
        l_reporting_date := null;
      end;
      if p_stop_type    = 'P' then
        l_sap_rep_date := null;
        l_sap_ul_date  := null;
      else
        l_ls_date := null;
        l_le_date := null;
      end if;
    elsif p_type    ='EXP' then
      l_grn_remark := null;
      begin
        select to_char(a.vessel_arrive_pod_date,'YYYYMMDDHH24MISS'),
          to_char(a.vessel_depart_pol_date,'YYYYMMDDHH24MISS'),
          to_char(a.gatein_date_cfs,'YYYYMMDDHH24MISS'),
          to_char(a.gateout_date_cfs,'YYYYMMDDHH24MISS'),
          to_char(a.gatein_date_port,'YYYYMMDDHH24MISS'),
        into l_ls_date,
          to_char(a.shipped_onboard_date,'YYYYMMDDHH24MISS')
          l_le_date,
          l_sap_rep_date,
          l_sap_ul_date,
          l_gate_in_date,
          l_gate_out_date
        from shipment a
        where a.shipment_id=p_shipment_id;
      exception
      when no_data_found then
        l_ls_date       := null;
        l_le_date       := null;
        l_sap_rep_date  := null;
        l_sap_ul_date   := null;
        l_gate_in_date  := null;
        l_gate_out_date := null;
      end;
      begin
        select to_char(reporting_date,'YYYYMMDDHH24MISS')
        into l_reporting_date
        from truck_reporting
        where truck_number     =p_truck_number
        and reporting_location =
          (select location_id
          from shipment_stop b
          where b.shipment_id = p_shipment_id
          and b.stop_num      = p_stop_num
          and rownum          =1
          );
      exception
      when no_data_found then
        l_reporting_date := null;
      when others then
        l_reporting_date := null;
      end;
    end if;
  pipe row (ship_stop_details_obj (grn_remark => l_grn_remark, gate_in_date => l_gate_in_date, gate_out_date => l_gate_out_date, reporting_date => l_reporting_date, ls_date => l_ls_date, le_date => l_le_date, sap_rep_date => l_sap_rep_date, sap_ul_date => l_sap_ul_date));
  return;
  end;
  */
  
  -- Change 04-May-2019
  
  function get_ship_stop_details(
      p_shipment_id  varchar2,
      p_truck_number varchar2,
      p_stop_num     number,
      p_stop_type    varchar2,
      p_loadslip_id  varchar2,
      p_type         varchar2)
    return ship_stop_details_list pipelined
  as
    l_grn_remark loadslip.grn_remark%type;
    l_gate_in_date   varchar2(20);
    l_gate_out_date  varchar2(20);
    l_reporting_date varchar2(20);
    l_ls_date        varchar2(20);
    l_le_date        varchar2(20);
    l_sap_rep_date   varchar2(20);
    l_sap_ul_date    varchar2(20);
  begin
    if p_type in ('OE','FGS') then
      begin
        select a.grn_remark,
          to_char(a.ls_date,'YYYYMMDDHH24MISS'),
          to_char(a.le_date,'YYYYMMDDHH24MISS'),
          to_char(a.grn_reporting_date,'YYYYMMDDHH24MISS'),
          to_char(a.grn_unloading_date,'YYYYMMDDHH24MISS')
        into l_grn_remark,
          l_ls_date,
          l_le_date,
          l_sap_rep_date,
          l_sap_ul_date
        from loadslip a
        where a.loadslip_id=p_loadslip_id;
      exception
      when no_data_found then
        l_grn_remark   := null;
        l_ls_date      := null;
        l_le_date      := null;
        l_sap_rep_date := null;
        l_sap_ul_date  := null;
      end;
      begin
        select to_char(gatein_date,'YYYYMMDDHH24MISS')
		  into l_gate_in_date
          from truck_reporting
          where truck_number     =p_truck_number
          and reporting_location =
            (select location_id
            from shipment_stop b
            where b.shipment_id = p_shipment_id
            and b.stop_num      = p_stop_num
            and rownum          =1
            )
          and shipment_id = p_shipment_id;
      exception
      when no_data_found then
        l_gate_in_date := null;
      end;
      begin
        select to_char(gateout_date,'YYYYMMDDHH24MISS')
		  into l_gate_out_date
          from truck_reporting
          where truck_number     =p_truck_number
          and reporting_location =
            (select location_id
            from shipment_stop b
            where b.shipment_id = p_shipment_id
            and b.stop_num      = p_stop_num
            and rownum          =1
            )
          and shipment_id = p_shipment_id;
      exception
      when no_data_found then
        l_gate_out_date := null;
      end;
      begin
        select to_char(reporting_date,'YYYYMMDDHH24MISS')
        into l_reporting_date
        from truck_reporting
        where truck_number     =p_truck_number
        and reporting_location =
          (select location_id
          from shipment_stop b
          where b.shipment_id = p_shipment_id
          and b.stop_num      = p_stop_num
          and rownum          =1
          )
		  and shipment_id = p_shipment_id;
      exception
      when no_data_found then
        l_reporting_date := null;
      when others then
        l_reporting_date := null;
      end;
      if p_stop_type    = 'P' then
        l_sap_rep_date := null;
        l_sap_ul_date  := null;
      else
        l_ls_date := null;
        l_le_date := null;
      end if;
    elsif p_type    ='EXP' then
	l_grn_remark := null;
	if p_stop_type    = 'D' then
	
      
      begin
        select to_char(a.vessel_arrive_pod_date,'YYYYMMDDHH24MISS'),
          to_char(a.vessel_depart_pol_date,'YYYYMMDDHH24MISS'),
          to_char(a.gatein_date_cfs,'YYYYMMDDHH24MISS'),
          to_char(a.gateout_date_cfs,'YYYYMMDDHH24MISS'),
          to_char(a.gatein_date_port,'YYYYMMDDHH24MISS'),
          to_char(a.shipped_onboard_date,'YYYYMMDDHH24MISS')
        into l_ls_date,
          l_le_date, -- Planned/Estimated Arrival and Departure Date
          l_sap_rep_date, -- Shipment Stop (D) - Attribute Date 2
          l_sap_ul_date, -- Shipment Stop (D) - Attribute Date 3
          l_gate_in_date, -- Shipment Stop (D) - Attribute Date 7
          l_gate_out_date -- Shipment Stop (D) - Actual Arrival and Departure Date
        from shipment a
        where a.shipment_id=p_shipment_id;
      exception
      when no_data_found then
        l_ls_date       := null;
        l_le_date       := null;
        l_sap_rep_date  := null;
        l_sap_ul_date   := null;
        l_gate_in_date  := null;
        l_gate_out_date := null;
      end;
      begin
        select to_char(reporting_date,'YYYYMMDDHH24MISS')
        into l_reporting_date
        from truck_reporting
        where truck_number     =p_truck_number
        and reporting_location =
          (select location_id
          from shipment_stop b
          where b.shipment_id = p_shipment_id
          and b.stop_num      = p_stop_num
          and rownum          =1
          );
      exception
      when no_data_found then
        l_reporting_date := null;
      when others then
        l_reporting_date := null;
      end;
	  
	  else 
	  
	  begin
        select to_char(a.ls_date,'YYYYMMDDHH24MISS'),
          to_char(a.le_date,'YYYYMMDDHH24MISS')
        into l_ls_date,
          l_le_date
        from loadslip a
        where a.loadslip_id=p_loadslip_id;
      exception
      when no_data_found then        
        l_ls_date      := null;
        l_le_date      := null;        
      end;
	  
	  begin
        select to_char(gatein_date,'YYYYMMDDHH24MISS')
		  into l_gate_in_date
          from truck_reporting
          where truck_number     =p_truck_number
          and reporting_location =
            (select location_id
            from shipment_stop b
            where b.shipment_id = p_shipment_id
            and b.stop_num      = p_stop_num
            and rownum          =1
            )
          and shipment_id = p_shipment_id;
      exception
      when no_data_found then
        l_gate_in_date := null;
      end;
	  
	  begin
        select to_char(gateout_date,'YYYYMMDDHH24MISS')
		  into l_gate_out_date
          from truck_reporting
          where truck_number     =p_truck_number
          and reporting_location =
            (select location_id
            from shipment_stop b
            where b.shipment_id = p_shipment_id
            and b.stop_num      = p_stop_num
            and rownum          =1
            )
          and shipment_id = p_shipment_id;
      exception
      when no_data_found then
        l_gate_out_date := null;
      end;
	  
	  begin
        select to_char(reporting_date,'YYYYMMDDHH24MISS')
        into l_reporting_date
        from truck_reporting
        where truck_number     =p_truck_number
        and reporting_location =
          (select location_id
          from shipment_stop b
          where b.shipment_id = p_shipment_id
          and b.stop_num      = p_stop_num
          and rownum          =1
          )
		  and shipment_id = p_shipment_id;
      exception
      when no_data_found then
        l_reporting_date := null;
      when others then
        l_reporting_date := null;
      end;
	  
      l_sap_rep_date := null;
      l_sap_ul_date  := null;
      
	  
	  
	  end if;
	  
    end if;
  pipe row (ship_stop_details_obj (grn_remark => l_grn_remark, gate_in_date => l_gate_in_date, gate_out_date => l_gate_out_date, reporting_date => l_reporting_date, ls_date => l_ls_date, le_date => l_le_date, sap_rep_date => l_sap_rep_date, sap_ul_date => l_sap_ul_date));
  return;
  end; 
  
  
    function get_tyre_id(
      p_loadslip_id varchar2,
      p_item_id varchar2)
    return varchar2
  as
    l_itm_class mt_item.item_classification%type;
    l_ret_mesg mt_item.item_id%type;
  begin
    select nvl(item_classification,'NA')
    into l_itm_class
    from mt_item
    where item_id =p_item_id;
    if l_itm_class in ('NA','TYRE') then
      l_ret_mesg     := 'NA';
    elsif l_itm_class = 'TUBE' then
      select item_id
      into l_ret_mesg
      from loadslip_detail_bom
      where loadslip_id=p_loadslip_id 
      and tube_sku  = p_item_id
      and rownum      =1;
    elsif l_itm_class = 'FLAP' then
      select item_id
      into l_ret_mesg
      from loadslip_detail_bom
      where loadslip_id=p_loadslip_id 
      and flap_sku  = p_item_id
      and rownum      =1;
    elsif l_itm_class = 'VALVE' then
      select item_id
      into l_ret_mesg
      from loadslip_detail_bom
      where loadslip_id=p_loadslip_id 
      and valve_sku = p_item_id
      and rownum      =1;
    end if;
  return l_ret_mesg;
  end;
  
  procedure make_request(
      p_att1 varchar2,
      p_att2 number)
  as
    l_job_id varchar2(100) := 'JOB'||p_att2||to_char(sysdate,'ddmmyyhh24miss');
    l_loadslip_type loadslip.loadslip_type%type;
    l_status shipment.status%type;
    l_ft_trip_id shipment.ft_trip_id%type;
   
  begin
  
    select nvl(loadslip_type,'NA')
    into l_loadslip_type
    from loadslip
    where shipment_id=p_att1 and rownum=1;
    
    if l_loadslip_type <> 'NA' then
    
    dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_actual_ship_int_api.process_shipment
                             (
                             '''||p_att1||''',
                             '''||l_loadslip_type||''',
                             atl_app_config.c_otm_instance,
                             '||p_att2||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '5' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
        
    
    /*
    begin
    select status,nvl(ft_trip_id,'NA') 
    into l_status,l_ft_trip_id
    from shipment where shipment_id= p_att1;
    
    if l_ft_trip_id = 'NA' and l_status <> 'COMPLETED' then
    ATL_MASTER_DATA_FLOW_PKG.call_ft_createtrip(p_att1);
    elsif l_ft_trip_id <> 'NA' and l_status = 'COMPLETED' then
    ATL_MASTER_DATA_FLOW_PKG.call_ft_closetrip(p_att1);
    end if;
    exception when others then
    null;
    end;
    */
   end if;
   
   exception when others then
   raise;
  end;
  
  function get_exp_ship_details(
    p_shipment_id varchar2)
  return exp_ship_tab pipelined
as
  l_pi_no          varchar2(400);
  l_pre_inv_no     varchar2(400);
  l_post_inv_no    varchar2(400);
  l_sap_invoice    varchar2(100);
  l_inv_amount     varchar2(400);
  l_shipping_bill  varchar2(400);
  l_export_remarks varchar2(500);
  l_customer_name shipment_export.customer_name%type;
  l_inco_term shipment_export.inco_term%type;
  l_payment_terms shipment_export.payment_terms%type;
  l_pol shipment_export.pol%type;
  l_pod shipment_export.pod%type;
  l_cofd shipment_export.cofd%type;
  l_forwarder shipment_export.forwarder%type;
  l_billing_party shipment_export.billing_party%type;
  l_shipping_line shipment_export.shipping_line%type;
  l_container_num shipment_export.container_num%type;
  l_cont_pick_date shipment_export.cont_pick_date%type;
  l_stuffing_date shipment_export.stuffing_date%type;
  l_booking_num shipment_export.booking_num%type;
  l_cha shipment_export.cha%type;
  l_planned_vessel shipment_export.planned_vessel%type;
  l_vessel_depart_pol_date shipment_export.vessel_depart_pol_date%type;
  l_shipping_bill_date shipment_export.shipping_bill_date%type;
  l_gatein_date_cfs shipment_export.gatein_date_cfs%type;
  l_customs_exam_date shipment_export.customs_exam_date%type;
  l_leo_date shipment_export.leo_date%type;
  l_gateout_date_cfs shipment_export.gateout_date_cfs%type;
  l_gatein_date_port shipment_export.gatein_date_port%type;
  l_actual_vessel shipment_export.actual_vessel%type;
  l_shipped_onboard_date shipment_export.shipped_onboard_date%type;
  l_eta_pod shipment_export.eta_pod%type;
begin
  select listagg(pi_no,'|') within group (
  order by pi_no),
    listagg(pre_inv_no,'|') within group (
  order by pre_inv_no),
    listagg(post_inv_no,'|') within group (
  order by post_inv_no),
    listagg(sap_invoice,'|') within group (
  order by sap_invoice),
    listagg(inv_amount,'|') within group (
  order by sap_invoice),
    listagg(shipping_bill,'|') within group (
  order by shipping_bill),
    listagg(export_remarks,'|') within group (
  order by export_remarks)
  into l_pi_no,
    l_pre_inv_no,
    l_post_inv_no,
    l_sap_invoice,
    l_inv_amount,
    l_shipping_bill,
    l_export_remarks
  from shipment_export
  where shipment_id=p_shipment_id;
  select customer_name,
    inco_term,
    payment_terms,
    pol,
    pod,
    cofd,
    forwarder,
    billing_party,
    shipping_line,
    container_num,
    cont_pick_date,
    stuffing_date,
    booking_num,
    cha,
    planned_vessel,
    vessel_depart_pol_date,
    shipping_bill_date,
    gatein_date_cfs,
    customs_exam_date,
    leo_date,
    gateout_date_cfs,
    gatein_date_port,
    actual_vessel,
    shipped_onboard_date,
    eta_pod
  into l_customer_name,
    l_inco_term,
    l_payment_terms,
    l_pol,
    l_pod,
    l_cofd,
    l_forwarder,
    l_billing_party,
    l_shipping_line,
    l_container_num,
    l_cont_pick_date,
    l_stuffing_date,
    l_booking_num,
    l_cha,
    l_planned_vessel,
    l_vessel_depart_pol_date,
    l_shipping_bill_date,
    l_gatein_date_cfs,
    l_customs_exam_date,
    l_leo_date,
    l_gateout_date_cfs,
    l_gatein_date_port,
    l_actual_vessel,
    l_shipped_onboard_date,
    l_eta_pod
  from shipment_export
  where shipment_id=p_shipment_id
  and rownum       =1;
  pipe row (exp_ship_obj (pi_no => l_pi_no, customer_name => l_customer_name, pre_inv_no => l_pre_inv_no, inco_term => l_inco_term, payment_terms => l_payment_terms, pol => l_pol, pod => l_pod, cofd => l_cofd, forwarder => l_forwarder, billing_party => l_billing_party, shipping_line => l_shipping_line, container_num => l_container_num, cont_pick_date => l_cont_pick_date, stuffing_date => l_stuffing_date, booking_num => l_booking_num, post_inv_no => l_post_inv_no, sap_invoice => l_sap_invoice, inv_amount => l_inv_amount, cha => l_cha, planned_vessel => l_planned_vessel, vessel_depart_pol_date => l_vessel_depart_pol_date, shipping_bill => l_shipping_bill, shipping_bill_date => l_shipping_bill_date, gatein_date_cfs => l_gatein_date_cfs, customs_exam_date => l_customs_exam_date, leo_date => l_leo_date, gateout_date_cfs => l_gateout_date_cfs, gatein_date_port => l_gatein_date_port, actual_vessel => l_actual_vessel, shipped_onboard_date => l_shipped_onboard_date, eta_pod => l_eta_pod,
  export_remarks => l_export_remarks ));
  return;
end;
  
  
end atl_actual_ship_int_api;

/
