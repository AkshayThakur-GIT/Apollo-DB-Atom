--------------------------------------------------------
--  DDL for Package Body ATL_ATOM_API
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_ATOM_API" 
as

  l_err_num       number;
  l_err_msg       varchar2(100);
  l_int_error_seq number;
  
  procedure create_paas_shipment(p_int_seq number)
  as
    /*******************
     Local variables
    *******************/
    l_json_clob clob;
    l_json_obj json_object_t;
    l_shipment_obj json_object_t;
    l_shipment_header_obj json_object_t;
    l_shipment_ls_arr json_array_t;
    l_shipment_ls_obj json_object_t;
    l_ship_ls_detail_obj json_object_t;
    l_ls_line_arr json_array_t;
    l_ls_line_obj json_object_t;
    l_cnt pls_integer := 1;
    l_grn_cnt pls_integer;
    l_unique_id pls_integer;
    l_collection_count pls_integer;
    l_ls_id xx_shipment_loadslip.loadslip_id%type;
    l_ship_status varchar2(10);
  
    /*******************
     Record Types
    *******************/
    type shipment
    is
      record
    (
      serprov_id xx_shipment.servprov%type,
      truck_type xx_shipment.truck_type%type,
      variant xx_shipment.variant_1%type,
      truck_num xx_shipment.truck_number%type,
      driver_license xx_shipment.driver_license%type,
      driver_name xx_shipment.driver_name%type,
      driver_mobile xx_shipment.driver_mobile%type,
      container_num xx_shipment.container_num%type,
      sob_date xx_shipment.shipped_onboard_date%type,
      cod xx_shipment.dest_country%type );
  
    type loadslip
    is
      record
    (
      loadslip_id xx_shipment_loadslip.loadslip_id%type,
      source_loc mt_location.location_id%type,
      dest_loc mt_location.location_id%type,
      drop_seq pls_integer,
      rep_date        date,
      gate_in_date    date,
      gate_out_date   date,
      confirm_date    date,
      rel_date        date,
      e_way_bill_no   varchar2(200),
      e_way_bill_date date,
      cust_inv_num    varchar2(2000) );

    type loadslip_line
    is
      record
    (
      loadslip_id xx_shipment_loadslip.loadslip_id%type,
      line_no pls_integer,
      item_id mt_item.item_id%type,
      qty pls_integer,
      batch_code mt_batch_codes.batch_code%type,
      invoice_num loadslip_inv_header.invoice_number%type,
      invoice_date date,
      lr_num loadslip_inv_header.lr_number%type,
      lr_date date,
      del_num loadslip_inv_header.delivery_number%type,
      sosto_num loadslip_inv_header.so_sto_num%type,
      grn_num grn_header.grn_number%type,
      grn_date     date,
      grn_rep_date date,
      grn_ul_date  date );

    /*******************
     Collection Types
    *******************/    
    r_ship_detail shipment;
    type loadslip_tab is table of loadslip;
    loadslip_detail loadslip_tab;
    type loadslip_line_tab is table of loadslip_line;
    loadslip_line_detail loadslip_line_tab;
  
  procedure parse_content
  as
  begin
    -- Initialize collections
    loadslip_detail      := loadslip_tab();
    loadslip_line_detail := loadslip_line_tab();
    select json_data into l_json_clob from xx_json_document where id=p_int_seq;
    -- Parsing JSON data
    l_json_obj            := json_object_t(l_json_clob);
    l_shipment_obj        := l_json_obj.get_object('PaaSShipment');
    l_shipment_header_obj := l_shipment_obj.get_object('PaaSShipmentHeader');
    -- Getting Data from JSON object for Shipment Header
    r_ship_detail.serprov_id     := l_shipment_header_obj.get_string('Servprov');
    r_ship_detail.variant        := l_shipment_header_obj.get_string('Variant');
    r_ship_detail.truck_type     := l_shipment_header_obj.get_string('TruckType');
    r_ship_detail.truck_num      := l_shipment_header_obj.get_string('TruckNumber');
    r_ship_detail.driver_license := l_shipment_header_obj.get_string('DriverLicense');
    r_ship_detail.driver_name    := l_shipment_header_obj.get_string('DriverName');
    r_ship_detail.driver_mobile  := l_shipment_header_obj.get_string('DriverMobile');
    r_ship_detail.container_num  := l_shipment_header_obj.get_string('ContainerNumber');
    r_ship_detail.sob_date       := to_date(l_shipment_header_obj.get_string('SOBDate'),'DD-MM-YYYY HH24:MI:SS');
    r_ship_detail.cod            := l_shipment_header_obj.get_string('CountryOfDestination');
    -- Getting Data from JSON object for Shipment Loadslips
    l_shipment_ls_arr    := l_shipment_obj.get_array('LoadSlip');
    if l_shipment_ls_arr is not null then
      --dbms_output.put_line('100 - Loadslip Array exists');
      for i in 0 .. l_shipment_ls_arr.get_size - 1
      loop
        l_ship_ls_detail_obj := treat(l_shipment_ls_arr.get(i)
      as
        json_object_t);
        /*l_source             := l_ship_ls_detail_obj.get_string('SourceLocation');
        l_dest               := l_ship_ls_detail_obj.get_string('DestinationLocation');
        l_drop_seq           := nvl(l_ship_ls_detail_obj.get_string('DropSequence'),i+1);
        l_cust_inv_num       := l_ship_ls_detail_obj.get_string('CustomInvoiceNumber');
        */
        loadslip_detail.extend;
        --l_ls_id                            := atl_util_pkg.generate_business_number('LS',l_ship_ls_detail_obj.get_string('SourceLocation'),l_ship_ls_detail_obj.get_string('DestinationLocation'));
        l_ls_id := 'LS'||loadslip_seq.nextval;                          
        loadslip_detail(l_cnt).loadslip_id := l_ls_id;
        --dbms_output.put_line('114 - l_ls_id '||l_ls_id);
        loadslip_detail(l_cnt).source_loc      := l_ship_ls_detail_obj.get_string('SourceLocation');
        loadslip_detail(l_cnt).dest_loc        := l_ship_ls_detail_obj.get_string('DestinationLocation');
        loadslip_detail(l_cnt).drop_seq        := l_ship_ls_detail_obj.get_string('DropSequence');
        loadslip_detail(l_cnt).rep_date        := to_date(l_ship_ls_detail_obj.get_string('ReportingDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_detail(l_cnt).gate_in_date    := to_date(l_ship_ls_detail_obj.get_string('GateInDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_detail(l_cnt).gate_out_date   := to_date(l_ship_ls_detail_obj.get_string('GateOutDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_detail(l_cnt).confirm_date    := to_date(l_ship_ls_detail_obj.get_string('ConfirmDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_detail(l_cnt).rel_date        := to_date(l_ship_ls_detail_obj.get_string('ReleaseDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_detail(l_cnt).e_way_bill_date := to_date(l_ship_ls_detail_obj.get_string('EWayBillDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_detail(l_cnt).e_way_bill_no   := l_ship_ls_detail_obj.get_string('EWayBillNumber');
        loadslip_detail(l_cnt).cust_inv_num    := l_ship_ls_detail_obj.get_string('CustomInvoiceNumber');
        --dbms_output.put_line('Source '||loadslip_detail(l_cnt).source_loc||' Destination '||loadslip_detail(l_cnt).dest_loc);
        -- Getting Data from JSON object for Loadslip Lines
        l_ls_line_arr    := l_ship_ls_detail_obj.get_array('LoadslipDetail');
        if l_ls_line_arr is not null then
          --dbms_output.put_line('130 - Loadslip Line Array exists');
          l_collection_count := loadslip_line_detail.count;
          for i in 0 .. l_ls_line_arr.get_size - 1
          loop
            l_ls_line_obj := treat(l_ls_line_arr.get(i)
          as
            json_object_t);
            /*l_item_id           := l_ls_line_obj.get_string('SkuCode');
            */
            loadslip_line_detail.extend;
            loadslip_line_detail(l_collection_count+1).loadslip_id := l_ls_id;
            --dbms_output.put_line('140 in Loadslip Line Array - l_ls_id '||l_ls_id);
            loadslip_line_detail(l_collection_count+1).line_no      := i+1;
            loadslip_line_detail(l_collection_count+1).item_id      := l_ls_line_obj.get_string('SkuCode');
            loadslip_line_detail(l_collection_count+1).qty          := l_ls_line_obj.get_string('Qty');
            loadslip_line_detail(l_collection_count+1).batch_code   := l_ls_line_obj.get_string('BatchCode');
            loadslip_line_detail(l_collection_count+1).invoice_num  := l_ls_line_obj.get_string('InvoiceNumber');
            loadslip_line_detail(l_collection_count+1).invoice_date := to_date(l_ls_line_obj.get_string('InvoiceDate'),'DD-MM-YYYY HH24:MI:SS');
            loadslip_line_detail(l_collection_count+1).lr_num       := l_ls_line_obj.get_string('LRNumber');
            loadslip_line_detail(l_collection_count+1).lr_date      := to_date(l_ls_line_obj.get_string('LRDate'),'DD-MM-YYYY HH24:MI:SS');
            loadslip_line_detail(l_collection_count+1).del_num      := l_ls_line_obj.get_string('DeliveryNumber');
            loadslip_line_detail(l_collection_count+1).sosto_num    := l_ls_line_obj.get_string('SOSTONumber');
            loadslip_line_detail(l_collection_count+1).grn_num      := l_ls_line_obj.get_string('GRNNumber');
            loadslip_line_detail(l_collection_count+1).grn_date     := to_date(l_ls_line_obj.get_string('GRNDate'),'DD-MM-YYYY HH24:MI:SS');
            loadslip_line_detail(l_collection_count+1).grn_rep_date := to_date(l_ls_line_obj.get_string('GRNReportingDate'),'DD-MM-YYYY HH24:MI:SS');
            loadslip_line_detail(l_collection_count+1).grn_ul_date  := to_date(l_ls_line_obj.get_string('GRNUnloadingDate'),'DD-MM-YYYY HH24:MI:SS');
            --dbms_output.put_line('loadslip_line_detail(i).item_id '||loadslip_line_detail(i+1).item_id);
          l_collection_count := l_collection_count+1;
          end loop;
        else
          --dbms_output.put_line('157 - Loadslip Line Array Not exists '||loadslip_line_detail.count);
          l_collection_count := loadslip_line_detail.count;
          l_shipment_ls_obj  := l_ship_ls_detail_obj.get_object('LoadslipDetail');
          /*l_item_id           := l_shipment_ls_obj.get_string('SkuCode');
          */
          loadslip_line_detail.extend;
          loadslip_line_detail(l_collection_count+1).loadslip_id := l_ls_id;
          --dbms_output.put_line('163 in No Loadslip Line Array - l_ls_id '||l_ls_id);
          loadslip_line_detail(l_collection_count+1).line_no      := 1;
          loadslip_line_detail(l_collection_count+1).item_id      := l_shipment_ls_obj.get_string('SkuCode');
          loadslip_line_detail(l_collection_count+1).qty          := l_shipment_ls_obj.get_string('Qty');
          loadslip_line_detail(l_collection_count+1).batch_code   := l_shipment_ls_obj.get_string('BatchCode');
          loadslip_line_detail(l_collection_count+1).invoice_num  := l_shipment_ls_obj.get_string('InvoiceNumber');
          loadslip_line_detail(l_collection_count+1).invoice_date := to_date(l_shipment_ls_obj.get_string('InvoiceDate'),'DD-MM-YYYY HH24:MI:SS');
          loadslip_line_detail(l_collection_count+1).lr_num       := l_shipment_ls_obj.get_string('LRNumber');
          loadslip_line_detail(l_collection_count+1).lr_date      := to_date(l_shipment_ls_obj.get_string('LRDate'),'DD-MM-YYYY HH24:MI:SS');
          loadslip_line_detail(l_collection_count+1).del_num      := l_shipment_ls_obj.get_string('DeliveryNumber');
          loadslip_line_detail(l_collection_count+1).sosto_num    := l_shipment_ls_obj.get_string('SOSTONumber');
          loadslip_line_detail(l_collection_count+1).grn_num      := l_shipment_ls_obj.get_string('GRNNumber');
          loadslip_line_detail(l_collection_count+1).grn_date     := to_date(l_shipment_ls_obj.get_string('GRNDate'),'DD-MM-YYYY HH24:MI:SS');
          loadslip_line_detail(l_collection_count+1).grn_rep_date := to_date(l_shipment_ls_obj.get_string('GRNReportingDate'),'DD-MM-YYYY HH24:MI:SS');
          loadslip_line_detail(l_collection_count+1).grn_ul_date  := to_date(l_shipment_ls_obj.get_string('GRNUnloadingDate'),'DD-MM-YYYY HH24:MI:SS');
          --dbms_output.put_line('loadslip_line_detail(1).item_id '||loadslip_line_detail(1).item_id);
        end if;
        l_cnt := l_cnt+1;
      end loop;
    else
      --dbms_output.put_line('180 - Loadslip Array Not exists');
      l_ship_ls_detail_obj := l_shipment_obj.get_object('LoadSlip');
      /*l_source              := l_ship_ls_detail_obj.get_string('SourceLocation');
      l_dest                := l_ship_ls_detail_obj.get_string('DestinationLocation');
      dbms_output.put_line('Source '||l_source);
      */
      loadslip_detail.extend;
      --l_ls_id                        := atl_util_pkg.generate_business_number('LS',l_ship_ls_detail_obj.get_string('SourceLocation'),l_ship_ls_detail_obj.get_string('DestinationLocation'));
      l_ls_id := 'LS'||loadslip_seq.nextval;  
      loadslip_detail(1).loadslip_id := l_ls_id;
      --dbms_output.put_line('l_ls_id '||l_ls_id);
      loadslip_detail(1).source_loc      := l_ship_ls_detail_obj.get_string('SourceLocation');
      loadslip_detail(1).dest_loc        := l_ship_ls_detail_obj.get_string('DestinationLocation');
      loadslip_detail(1).drop_seq        := l_ship_ls_detail_obj.get_string('DropSequence');
      loadslip_detail(1).rep_date        := to_date(l_ship_ls_detail_obj.get_string('ReportingDate'),'DD-MM-YYYY HH24:MI:SS');
      loadslip_detail(1).gate_in_date    := to_date(l_ship_ls_detail_obj.get_string('GateInDate'),'DD-MM-YYYY HH24:MI:SS');
      loadslip_detail(1).gate_out_date   := to_date(l_ship_ls_detail_obj.get_string('GateOutDate'),'DD-MM-YYYY HH24:MI:SS');
      loadslip_detail(1).confirm_date    := to_date(l_ship_ls_detail_obj.get_string('ConfirmDate'),'DD-MM-YYYY HH24:MI:SS');
      loadslip_detail(1).rel_date        := to_date(l_ship_ls_detail_obj.get_string('ReleaseDate'),'DD-MM-YYYY HH24:MI:SS');
      loadslip_detail(1).e_way_bill_date := to_date(l_ship_ls_detail_obj.get_string('EWayBillDate'),'DD-MM-YYYY HH24:MI:SS');
      loadslip_detail(1).e_way_bill_no   := l_ship_ls_detail_obj.get_string('EWayBillNumber');
      loadslip_detail(1).cust_inv_num    := l_ship_ls_detail_obj.get_string('CustomInvoiceNumber');
      --dbms_output.put_line('Source '||loadslip_detail(1).source_loc||' Destination '||loadslip_detail(1).dest_loc);
      -- Getting Data from JSON object for Loadslip Lines
      l_ls_line_arr    := l_ship_ls_detail_obj.get_array('LoadslipDetail');
      if l_ls_line_arr is not null then
        --dbms_output.put_line('205 - Loadslip Line Array exists');
        for i in 0 .. l_ls_line_arr.get_size - 1
        loop
          l_ls_line_obj := treat(l_ls_line_arr.get(i)
        as
          json_object_t);
          /*l_item_id           := l_ls_line_obj.get_string('SkuCode');
          dbms_output.put_line('l_item_id '||l_item_id);
          */
          loadslip_line_detail.extend;
          loadslip_line_detail(i+1).loadslip_id  := l_ls_id;
          loadslip_line_detail(i+1).line_no      := i+1;
          loadslip_line_detail(i+1).item_id      := l_ls_line_obj.get_string('SkuCode');
          loadslip_line_detail(i+1).qty          := l_ls_line_obj.get_string('Qty');
          loadslip_line_detail(i+1).batch_code   := l_ls_line_obj.get_string('BatchCode');
          loadslip_line_detail(i+1).invoice_num  := l_ls_line_obj.get_string('InvoiceNumber');
          loadslip_line_detail(i+1).invoice_date := to_date(l_ls_line_obj.get_string('InvoiceDate'),'DD-MM-YYYY HH24:MI:SS');
          loadslip_line_detail(i+1).lr_num       := l_ls_line_obj.get_string('LRNumber');
          loadslip_line_detail(i+1).lr_date      := to_date(l_ls_line_obj.get_string('LRDate'),'DD-MM-YYYY HH24:MI:SS');
          loadslip_line_detail(i+1).del_num      := l_ls_line_obj.get_string('DeliveryNumber');
          loadslip_line_detail(i+1).sosto_num    := l_ls_line_obj.get_string('SOSTONumber');
          loadslip_line_detail(i+1).grn_num      := l_ls_line_obj.get_string('GRNNumber');
          loadslip_line_detail(i+1).grn_date     := to_date(l_ls_line_obj.get_string('GRNDate'),'DD-MM-YYYY HH24:MI:SS');
          loadslip_line_detail(i+1).grn_rep_date := to_date(l_ls_line_obj.get_string('GRNReportingDate'),'DD-MM-YYYY HH24:MI:SS');
          loadslip_line_detail(i+1).grn_ul_date  := to_date(l_ls_line_obj.get_string('GRNUnloadingDate'),'DD-MM-YYYY HH24:MI:SS');
          --dbms_output.put_line('loadslip_line_detail(i).item_id '||loadslip_line_detail(i+1).item_id);
        end loop;
      else
        l_collection_count := loadslip_line_detail.count;
        --dbms_output.put_line('232 - Loadslip Line Array Not exists');
        l_shipment_ls_obj := l_ship_ls_detail_obj.get_object('LoadslipDetail');
        /*l_item_id           := l_shipment_ls_obj.get_string('SkuCode');
        dbms_output.put_line('l_item_id '||l_item_id);
        */
        loadslip_line_detail.extend;
        loadslip_line_detail(l_collection_count+1).loadslip_id := l_ls_id;
        --dbms_output.put_line('Loadslip Line Array Not exists : l_ls_id '||l_ls_id);
        loadslip_line_detail(l_collection_count+1).line_no      := 1;
        loadslip_line_detail(l_collection_count+1).item_id      := l_shipment_ls_obj.get_string('SkuCode');
        loadslip_line_detail(l_collection_count+1).qty          := l_shipment_ls_obj.get_string('Qty');
        loadslip_line_detail(l_collection_count+1).batch_code   := l_shipment_ls_obj.get_string('BatchCode');
        loadslip_line_detail(l_collection_count+1).invoice_num  := l_shipment_ls_obj.get_string('InvoiceNumber');
        loadslip_line_detail(l_collection_count+1).invoice_date := to_date(l_shipment_ls_obj.get_string('InvoiceDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_line_detail(l_collection_count+1).lr_num       := l_shipment_ls_obj.get_string('LRNumber');
        loadslip_line_detail(l_collection_count+1).lr_date      := to_date(l_shipment_ls_obj.get_string('LRDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_line_detail(l_collection_count+1).del_num      := l_shipment_ls_obj.get_string('DeliveryNumber');
        loadslip_line_detail(l_collection_count+1).sosto_num    := l_shipment_ls_obj.get_string('SOSTONumber');
        loadslip_line_detail(l_collection_count+1).grn_num      := l_shipment_ls_obj.get_string('GRNNumber');
        loadslip_line_detail(l_collection_count+1).grn_date     := to_date(l_shipment_ls_obj.get_string('GRNDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_line_detail(l_collection_count+1).grn_rep_date := to_date(l_shipment_ls_obj.get_string('GRNReportingDate'),'DD-MM-YYYY HH24:MI:SS');
        loadslip_line_detail(l_collection_count+1).grn_ul_date  := to_date(l_shipment_ls_obj.get_string('GRNUnloadingDate'),'DD-MM-YYYY HH24:MI:SS');
        --dbms_output.put_line('loadslip_line_detail(1).item_id '||loadslip_line_detail(1).item_id);
      end if;
    end if;
  end;
  procedure add_ship_stage_info
  as
  begin
    insert
    into xx_shipment
      (
        servprov,
        truck_type,
        truck_number,
        driver_license,
        driver_mobile,
        driver_name,
        container_num,
        shipped_onboard_date,
        dest_country,
        insert_user,
        insert_date
      )
      values
      (
        r_ship_detail.serprov_id,
        r_ship_detail.truck_type,
        r_ship_detail.truck_num,
        r_ship_detail.driver_license,
        r_ship_detail.driver_mobile,
        r_ship_detail.driver_name,
        r_ship_detail.container_num,
        r_ship_detail.sob_date,
        r_ship_detail.cod,
        'INTEGRATION',
        sysdate
      )
    returning shipment_id
    into l_unique_id;
  end;
  procedure add_ship_ls_stage_info
  as
  begin
    for i in loadslip_detail.first .. loadslip_detail.last
    loop
      insert
      into xx_shipment_loadslip
        (
          shipment_id,
          loadslip_id,
          loadslip_type,
          source_loc,
          dest_loc,
          drop_seq,
          reporting_date,
          gate_in_date,
          confirm_date,
          release_date,
          gate_out_date,
          e_way_bill_no,
          e_way_bill_date,
          custom_inv_num,
          insert_user,
          insert_date
        )
        values
        (
          l_unique_id,
          loadslip_detail(i).loadslip_id,
          --atl_business_flow_pkg.get_order_type(loadslip_detail(i).source_loc,loadslip_detail(i).dest_loc,'X'),
          'NA',
          loadslip_detail(i).source_loc,
          loadslip_detail(i).dest_loc,
          loadslip_detail(i).drop_seq,
          loadslip_detail(i).rep_date,
          loadslip_detail(i).gate_in_date,
          loadslip_detail(i).confirm_date,
          loadslip_detail(i).rel_date,
          loadslip_detail(i).gate_out_date,
          loadslip_detail(i).e_way_bill_no,
          loadslip_detail(i).e_way_bill_date,
          loadslip_detail(i).cust_inv_num ,
          'INTEGRATION',
          sysdate
        );
    end loop;
  end;
  procedure add_ship_ls_line_stage_info
  as
  begin
    for i in loadslip_line_detail.first .. loadslip_line_detail.last
    loop
      insert
      into xx_shipment_loadslip_line
        (
          loadslip_id,
          line_no,
          item_id,
          qty,
          batch_code,
          so_sto_number,
          invoice_number,
          invoice_date,
          lr_number,
          lr_date,
          delivery_number,
          grn_number,
          grn_date,
          reporting_date,
          unloading_date,
          insert_user,
          insert_date
        )
        values
        (
          loadslip_line_detail(i).loadslip_id,
          loadslip_line_detail(i).line_no,
          loadslip_line_detail(i).item_id,
          loadslip_line_detail(i).qty,
          loadslip_line_detail(i).batch_code,
          loadslip_line_detail(i).sosto_num,
          loadslip_line_detail(i).invoice_num,
          loadslip_line_detail(i).invoice_date,
          loadslip_line_detail(i).lr_num,
          loadslip_line_detail(i).lr_date,
          loadslip_line_detail(i).del_num,
          loadslip_line_detail(i).grn_num,
          loadslip_line_detail(i).grn_date,
          loadslip_line_detail(i).grn_rep_date,
          loadslip_line_detail(i).grn_ul_date,
          'INTEGRATION',
          sysdate
        );
    end loop;
  end;
  procedure insert_shipment_stops
    (
      p_shipment_id varchar2,
      p_user_id     varchar2
    )
  as
    l_source shipment_stop.location_id%type := null;
    l_dest shipment_stop.location_id%type   := null;
    l_loop_cnt pls_integer                  := 1;
    l_max_stop pls_integer;
  begin
    delete
    from shipment_stop
    where shipment_id= p_shipment_id;
    --commit;
    -- Pickup logic
    for i in
    (select a.loadslip_id,
      b.shipment_id,
      a.source_loc,
      a.dest_loc,
      nvl(a.drop_seq,0)
    from xx_shipment_loadslip a,
      shipment b
    where a.paas_ship_id = b.shipment_id
    and b.shipment_id    =p_shipment_id
    order by nvl(drop_seq,0) asc,
      a.insert_date asc--source_loc asc
    )
    loop
      if l_source is null then
        insert
        into shipment_stop
          (
            shipment_id,
            stop_num,
            location_id,
            activity,
            loadslip_id,
            insert_user,
            insert_date
          )
          values
          (
            p_shipment_id,
            l_loop_cnt,
            i.source_loc,
            'P',
            i.loadslip_id,
            -- l_ls_id,
            p_user_id,
            sysdate
          );
        --l_loop_cnt := l_loop_cnt+1;
      elsif l_source  = i.source_loc then
        if l_loop_cnt > 1 then
          insert
          into shipment_stop
            (
              shipment_id,
              stop_num,
              location_id,
              activity,
              loadslip_id,
              insert_user,
              insert_date
            )
            values
            (
              p_shipment_id,
              l_loop_cnt -1,
              i.source_loc,
              'P',
            i.loadslip_id,
           --  l_ls_id,
              p_user_id,
              sysdate
            );
        else
          insert
          into shipment_stop
            (
              shipment_id,
              stop_num,
              location_id,
              activity,
              loadslip_id,
              insert_user,
              insert_date
            )
            values
            (
              p_shipment_id,
              1,
              i.source_loc,
              'P',
             i.loadslip_id,
             --l_ls_id,
              p_user_id,
              sysdate
            );
        end if;
        l_loop_cnt := l_loop_cnt-1;
      else
        insert
        into shipment_stop
          (
            shipment_id,
            stop_num,
            location_id,
            activity,
            loadslip_id,
            insert_user,
            insert_date
          )
          values
          (
            p_shipment_id,
            l_loop_cnt,
            i.source_loc,
            'P',
           i.loadslip_id,
          -- l_ls_id,
            p_user_id,
            sysdate
          );
      end if;
      l_source   := i.source_loc;
      l_loop_cnt := l_loop_cnt+1;
    end loop;
    
    select max(stop_num)+1
    into l_max_stop
    from shipment_stop
    where shipment_id=p_shipment_id;
    l_loop_cnt      := l_max_stop;
    -- Drop logic
    for j in
    (select a.loadslip_id,
      b.shipment_id,
      a.source_loc,
      a.dest_loc,
      nvl(a.drop_seq,0)
    from xx_shipment_loadslip a,
      shipment b
    where a.paas_ship_id = b.shipment_id
    and b.shipment_id    =p_shipment_id
    order by nvl(drop_seq,0) asc,
      a.insert_date desc
    )
    loop
      if l_dest is null then
        insert
        into shipment_stop
          (
            shipment_id,
            stop_num,
            location_id,
            activity,
            loadslip_id,
            insert_user,
            insert_date
          )
          values
          (
            p_shipment_id,
            l_loop_cnt,
            j.dest_loc,
            'D',
            j.loadslip_id,
            p_user_id,
            sysdate
          );
      elsif l_dest = j.dest_loc then
        insert
        into shipment_stop
          (
            shipment_id,
            stop_num,
            location_id,
            activity,
            loadslip_id,
            insert_user,
            insert_date
          )
          values
          (
            p_shipment_id,
            l_max_stop,
            j.dest_loc,
            'D',
            j.loadslip_id,
            p_user_id,
            sysdate
          );
      else
        insert
        into shipment_stop
          (
            shipment_id,
            stop_num,
            location_id,
            activity,
            loadslip_id,
            insert_user,
            insert_date
          )
          values
          (
            p_shipment_id,
            l_loop_cnt,
            j.dest_loc,
            'D',
            j.loadslip_id,
            p_user_id,
            sysdate
          );
      end if;
      l_dest := j.dest_loc;
      --l_loop_cnt := l_loop_cnt+1;
      select max(stop_num)+1
      into l_loop_cnt
      from shipment_stop
      where shipment_id=p_shipment_id;
    end loop;
    --commit;
  end;
  procedure create_shipment
  as
    l_indent_id indent_summary.indent_id%type;
    l_tran_sap_code truck_reporting.transporter_sap_code%type;
    l_frt_flag varchar2(1);
    l_ship_id  varchar2(100);
    l_ls_id    varchar2(100);
    l_freight freight.base_freight%type;
    l_tte_capacity mt_truck_type.tte_capacity%type;
    l_gross_wt      number;
    l_gross_vol     number;
    l_loadslip_type varchar2(50);
    l_loop_count pls_integer :=1;
    l_ship_stop_type varchar2(10);
    l_ls_source_loc xx_shipment_loadslip.source_loc%type := 'NA';
    l_gc truck_reporting.gate_control_code%type;
    l_ref_code truck_reporting.gate_control_code%type;
    l_tt_days number;
    l_source_loc xx_shipment_loadslip.source_loc%type;
    l_variant freight.condition1%type;
    l_cont_num xx_shipment.container_num%type;
    l_chk_cnt pls_integer :=1;
    l_chk_gnt_cnt pls_integer :=1;
  begin
    
    l_ship_status := 'INTRANSIT';
    select a.tte_capacity,
      a.gross_wt,
      a.gross_vol,
      (case when b.container_num is not null then 'EXP' else 'X' end)
    into l_tte_capacity,
      l_gross_wt,
      l_gross_vol,
      l_cont_num
    from mt_truck_type a,
      xx_shipment b
    where a.truck_type= b.truck_type
    and b.shipment_id = l_unique_id
    and rownum        =1;
    
    select source_loc 
    into l_source_loc
    from xx_shipment_loadslip 
    where loadslip_id = (select loadslip_id from (select loadslip_id from
    xx_shipment_loadslip where shipment_id =l_unique_id order by nvl(drop_seq,0) asc)
    where rownum=1)
    and shipment_id =l_unique_id;
    
    -- if l_cnt = 1 then
    --   dbms_output.put_line('Single drop shipment');
    select count(1)
    into l_cnt
    from mt_truck
    where (truck_number) =
      (select truck_number from xx_shipment where shipment_id=l_unique_id
      );
    if l_cnt = 0 then
      --dbms_output.put_line('new truck');
      insert
      into mt_truck
        (
          truck_number,
          servprov,
          truck_type,
          insert_user,
          insert_date,
          tt_id,
          gps_enabled
        )
      select a.truck_number,
        a.servprov,
        a.truck_type,
        'INTEGRATION',
        sysdate,
        b.tt_id,
        'N'
      from xx_shipment a,
        mt_truck_type b
      where a.shipment_id=l_unique_id
      and a.truck_type   = b.truck_type
      and rownum         =1;
    end if;
    for ls in
    (select *
    from xx_shipment_loadslip
    where shipment_id=l_unique_id
    order by nvl(drop_seq,0) asc
    )
    loop
      select atl_business_flow_pkg.get_order_type(b.source_loc,b.dest_loc,l_cont_num),
      atl_util_pkg.generate_business_number('LS',b.source_loc,b.dest_loc)
      into l_loadslip_type,l_ls_id
      from xx_shipment_loadslip b
      where shipment_id =l_unique_id
      and b.loadslip_id = ls.loadslip_id;
      if l_loop_count   = 1 then
        begin
          select a.transporter_sap_code,
            a.base_freight,
            a.tt_days
          into l_tran_sap_code,
            l_freight,
            l_tt_days
          from freight a,
            xx_shipment b,
            xx_shipment_loadslip c
          where a.source_loc           = c.source_loc
          and a.dest_loc               = c.dest_loc
          and a.truck_type             = b.truck_type
          and a.servprov               =b.servprov
          and ((a.expiry_date         is null
          and trunc(a.effective_date) <= trunc(sysdate))
          or (trunc(a.expiry_date)    >= trunc(sysdate)
          and trunc(a.effective_date) <= trunc(sysdate)))
          and b.shipment_id            = l_unique_id
          and c.loadslip_id            = ls.loadslip_id
          and rownum                   =1;
          l_frt_flag                  := 'Y';
        exception
        when no_data_found then
          l_tran_sap_code := null;
          l_frt_flag      := 'N';
          l_freight       := null;
        end;
        
        begin
          
          select 'DED' 
          into l_variant
          from mt_truck_dedicated a,
               xx_shipment b
          where a.truck_number=b.truck_number
          and source_loc = ls.source_loc and dest_loc = ls.dest_loc
          and trunc(a.expiry_date) >= trunc(sysdate)
          and rownum=1;
          exception
          when no_data_found then
          
          begin
            
            select a.condition1
          into l_variant
          from freight a,
            xx_shipment b
          where a.source_loc           = ls.source_loc
          and a.dest_loc               = ls.dest_loc
          and a.truck_type             = b.truck_type
          and a.servprov               =b.servprov
          and ((a.expiry_date         is null
          and trunc(a.effective_date) <= trunc(sysdate))
          or (trunc(a.expiry_date)    >= trunc(sysdate)
          and trunc(a.effective_date) <= trunc(sysdate)))
          and b.shipment_id            = l_unique_id
          and rownum                   =1;
            exception
           when no_data_found then
            l_variant := null;
          end;
          
        end;
        
        select atl_util_pkg.generate_business_number('IND',b.source_loc,b.dest_loc),
          atl_util_pkg.generate_business_number('SH',b.source_loc,b.dest_loc),
          get_ship_stop_type(l_unique_id)
        into l_indent_id,
          l_ship_id,
          l_ship_stop_type
        from xx_shipment_loadslip b
        where shipment_id =l_unique_id
        and b.loadslip_id = ls.loadslip_id;
        update xx_shipment_loadslip
        set paas_ship_id = l_ship_id
        where shipment_id=l_unique_id;
        -- create indent
        insert
        into indent_summary
          (
            id,
            indent_id,
            dispatch_date,            
            source_loc,
            dest_loc,
            truck_type,
            load_factor,
            servprov,
            tte_capacity,
            indented,
            cancelled,
            net_requested,
            trans_confirmed,
            trans_declined,
            trans_assigned,
            reported,
            rejected,
            net_placed,
            net_balance,
            status,
            indent_aging,
            frt_avail_flag,
            insert_user,
            insert_date,
            dest_country
          )
        select indent_summary_seq.nextval,
          l_indent_id,
          --sysdate,
          to_char(b.reporting_date,'DD-MON-YY'),
          b.source_loc,
          b.dest_loc,
          a.truck_type,
          c.load_factor,
          a.servprov,
          c.tte_capacity,
          1,0,1,0,0,0,1,0,1,0,
          'CLOSED',
          0,
          l_frt_flag,
          'INTEGRATION',
          --sysdate,
          to_char(b.reporting_date,'DD-MON-YY'),
          a.dest_country
        from xx_shipment a,
          xx_shipment_loadslip b,
          mt_truck_type c
        where a.shipment_id = b.shipment_id
        and a.truck_type    =c.truck_type
        and b.loadslip_id   = ls.loadslip_id
        and rownum          =1;
        -- create shipment
        insert
        into shipment
          (
            shipment_id,
            servprov,
            transporter_sap_code,
            truck_type,
            truck_number,
            variant_1,
            indent_id,
            transport_mode,
            driver_license,
            driver_mobile,
            driver_name,
            transhipment,
            freight,
            freight_uom,
            start_time,
            total_qty,
            total_tte,
            total_weight,
            total_weight_uom,
            total_volume,
            total_volume_uom,
            tte_util,
            weight_util,
            volume_util,
            status,
            stop_type,
            insert_user,
            insert_date,
            frt_avail_flag,
            container_num,
            shipped_onboard_date,
            dest_country,
            is_sync_otm
          )
        select l_ship_id, servprov,
          l_tran_sap_code,
          truck_type,
          truck_number,
          l_variant,
          l_indent_id,
          'TL',
          driver_license,
          driver_mobile,
          driver_name,
          'N',
          l_freight,
          'INR',
          sysdate,
          (select sum(qty)
          from xx_shipment_loadslip_line
          where loadslip_id in
            (select loadslip_id
            from xx_shipment_loadslip
            where shipment_id = l_unique_id
            )
          ),
          (select sum(b.qty * nvl(c.tte,0))
          from xx_shipment_loadslip a,
            xx_shipment_loadslip_line b,
            mt_item c
          where a.loadslip_id = b.loadslip_id
          and b.item_id       = c.item_id
          and a.shipment_id   =l_unique_id
          ),
          (select sum(get_item_wt_vol(b.item_id,a.source_loc,'WT'))
          from xx_shipment_loadslip a,
            xx_shipment_loadslip_line b
          where a.loadslip_id = b.loadslip_id
          and a.shipment_id   =l_unique_id
          ),
          'KG',
          (select sum(get_item_wt_vol(b.item_id,a.source_loc,'VOL'))
          from xx_shipment_loadslip a,
            xx_shipment_loadslip_line b
          where a.loadslip_id = b.loadslip_id
          and a.shipment_id   =l_unique_id
          ),
          'CUMTR',
          round(
          (select sum(((b.qty * nvl(c.tte,0)) / l_tte_capacity) * 100)
          from xx_shipment_loadslip a,
            xx_shipment_loadslip_line b,
            mt_item c
          where a.loadslip_id = b.loadslip_id
          and b.item_id       = c.item_id
          and a.shipment_id   = l_unique_id
          ),2),
          round(
          (select sum(((b.qty * get_item_wt_vol(b.item_id,a.source_loc,'WT') ) / l_gross_wt) * 100)
          from xx_shipment_loadslip a,
            xx_shipment_loadslip_line b,
            mt_item c
          where a.loadslip_id = b.loadslip_id
          and b.item_id       = c.item_id
          and a.shipment_id   = l_unique_id
          ),2),
          round(
          (select sum(((b.qty * get_item_wt_vol(b.item_id,a.source_loc,'VOL') ) / l_gross_vol) * 100)
          from xx_shipment_loadslip a,
            xx_shipment_loadslip_line b,
            mt_item c
          where a.loadslip_id = b.loadslip_id
          and b.item_id       = c.item_id
          and a.shipment_id   = l_unique_id
          ),2),
          l_ship_status,
          l_ship_stop_type,
          'INTEGRATION',
          sysdate,
          l_frt_flag,
          container_num,
          shipped_onboard_date,
          dest_country,
          'T'
        from xx_shipment
        where shipment_id = l_unique_id;
        -- create shipment stop
        insert_shipment_stops(l_ship_id,'INTEGRATION');
      end if;
      if l_loop_count = 1 and l_ship_stop_type not in ('MP','MPMD') then
        select atl_util_pkg.generate_business_number('GC',source_loc,dest_loc)
        into l_gc
        from xx_shipment_loadslip
        where loadslip_id = ls.loadslip_id;
        insert
        into truck_reporting
          (
            gate_control_code,
            indent_id,
            type,
            transporter_sap_code,
            container_num,
            truck_number,
            driver_name,
            driver_mobile,
            driver_license,
            servprov,
            truck_type,
            reported_truck_type,
            reporting_location,
            source_loc,
            dest_loc,
            reporting_date,
            gatein_date,
            gateout_date,
            status,
            rej_status,
            bay_status,
            ref_code,
            insert_user,
            insert_date,
            shipment_id,
            activity,
            e_way_bill_no,
            dest_country,
            e_way_bill_date,
            tt_days
          )
        select l_gc,
          l_indent_id,
          'FGS',
          l_tran_sap_code,
          a.container_num,
          a.truck_number,
          a.driver_name,
          a.driver_mobile,
          a.driver_license,
          a.servprov,
          a.truck_type,
          a.truck_type,
          b.source_loc,
          l_source_loc,
          b.dest_loc,
          b.reporting_date,
          b.gate_in_date,
          b.gate_out_date,
          l_ship_status,
          'NORMAL',
          'RELEASE',
          null,
          'INTEGRATION',
          sysdate,
          l_ship_id,
          'P',
          b.e_way_bill_no,
          a.dest_country,
          b.e_way_bill_date,
          l_tt_days
        from xx_shipment a,
          xx_shipment_loadslip b
        where a.shipment_id=l_unique_id
        and a.shipment_id  = b.shipment_id
        and b.loadslip_id  = ls.loadslip_id;
      elsif l_loop_count  >= 1 and l_ship_stop_type in ('MP','MPMD') and l_ls_source_loc != ls.source_loc then
        select atl_util_pkg.generate_business_number('GC',source_loc,dest_loc)
        into l_gc
        from xx_shipment_loadslip
        where loadslip_id = ls.loadslip_id;
        -- create truck reporting
        insert
        into truck_reporting
          (
            gate_control_code,
            indent_id,
            type,
            transporter_sap_code,
            container_num,
            truck_number,
            driver_name,
            driver_mobile,
            driver_license,
            servprov,
            truck_type,
            reported_truck_type,
            reporting_location,
            source_loc,
            dest_loc,
            reporting_date,
            gatein_date,
            gateout_date,
            status,
            rej_status,
            bay_status,
            ref_code,
            insert_user,
            insert_date,
            shipment_id,
            activity,
            e_way_bill_no,
            dest_country,
            e_way_bill_date,
            tt_days
          )
        select l_gc,
          l_indent_id,
          'FGS',
          l_tran_sap_code,
          a.container_num,
          a.truck_number,
          a.driver_name,
          a.driver_mobile,
          a.driver_license,
          a.servprov,
          a.truck_type,
          a.truck_type,
          b.source_loc,
          /*(
          case
            when l_loop_count = 1
            then b.source_loc
            else l_ls_source_loc
          end)*/
          l_source_loc,          
          b.dest_loc,
          b.reporting_date,
          b.gate_in_date,
          b.gate_out_date,
          l_ship_status,
          'NORMAL',
          'RELEASE',
          (
          case
            when l_loop_count = 1
            then null
            else l_ref_code
          end),
          'INTEGRATION',
          sysdate,
          l_ship_id,
          'P',
          b.e_way_bill_no,
          a.dest_country,
          b.e_way_bill_date,
          (
          case
            when l_loop_count = 1
            then l_tt_days
            else null
          end)
        from xx_shipment a,
          xx_shipment_loadslip b
        where a.shipment_id=l_unique_id
        and a.shipment_id  = b.shipment_id
        and b.loadslip_id  = ls.loadslip_id;
      end if;
      -- create loadslip
      insert
      into loadslip
        (
          loadslip_id,
          loadslip_type,
          shipment_id,
          source_loc,
          dest_loc,
          lr_num,
          lr_date,
          sto_so_num,
          delivery,
          sap_invoice,
          sap_invoice_date,
          grn,
          grn_date,
          qty,
          tte_qty,
          weight,
          weight_uom,
          volume,
          volume_uom,
          status,
          drop_seq,
          confirm_date,
          release_date,
          insert_user,
          insert_date,
          tot_tyres,
          tot_tubes,
          tot_flaps,
          tot_valve,
          tte_util,
          item_category,
          weight_util,
          volume_util,
          grn_reporting_date,
          grn_unloading_date,
          tot_pctr,
          tot_qty,
          e_way_bill_no,
          mkt_seg,
          other,
          e_way_bill_date,
          custom_inv_number
        )
      select  
       --a.loadslip_id,
       l_ls_id,
        l_loadslip_type,
        l_ship_id,
        a.source_loc,
        a.dest_loc,
        (select listagg(lr_number,'|') within group (
        order by lr_number)
        from
          (select distinct lr_number
          from xx_shipment_loadslip_line
          where loadslip_id=a.loadslip_id
          )
        ),
        (select max(lr_date)
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
        ),
      /*  (select so_sto_number
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
        and rownum       =1
        ),*/  -- RAGHAVA 15-JUN
    (select listagg(so_sto_number,'|') within group (
        order by so_sto_number)
        from
          (select distinct so_sto_number
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
          )
        ),
     /*   (select delivery_number
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
        and rownum       =1
        ),*/  -- RAGHAVA 15-JUN
        (select listagg(delivery_number,'|') within group (
        order by delivery_number)
        from
          (select distinct delivery_number
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
          )
        ),
        (select listagg(invoice_number,'|') within group (
        order by invoice_number)
        from
          (select distinct invoice_number
          from xx_shipment_loadslip_line
          where loadslip_id=a.loadslip_id
          )
        ),
        (select max(invoice_date)
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
        ),
        (select listagg(grn_number,'|') within group (
        order by grn_number)
        from
          (select distinct grn_number
          from xx_shipment_loadslip_line
          where loadslip_id=a.loadslip_id
          )
        ),
        (select min(grn_date)
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
        ),
        (select sum(qty)
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
        ),
        (select sum(b.qty * nvl(c.tte,0))
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.item_id   = c.item_id
        and b.loadslip_id = a.loadslip_id
        ),
        (select sum(get_item_wt_vol(b.item_id,a.source_loc,'WT'))
        from xx_shipment_loadslip_line b
        where b.loadslip_id = a.loadslip_id
        ),
        'KG',
        (select sum(get_item_wt_vol(b.item_id,a.source_loc,'VOL'))
        from xx_shipment_loadslip_line b
        where b.loadslip_id = a.loadslip_id
        ),
        'CUMTR',
        l_ship_status,
        a.drop_seq,
        a.confirm_date,
        a.release_date,
        'INTEGRATION',
        sysdate,
        nvl(
        (select sum(qty)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.loadslip_id       = a.loadslip_id
        and b.item_id             = c.item_id
        and c.item_classification = 'TYRE'
        ),0),
        nvl(
        (select sum(qty)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.loadslip_id       = a.loadslip_id
        and b.item_id             = c.item_id
        and c.item_classification = 'TUBE'
        ),0),
        nvl(
        (select sum(qty)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.loadslip_id       = a.loadslip_id
        and b.item_id             = c.item_id
        and c.item_classification = 'FLAP'
        ),0),
        nvl(
        (select sum(qty)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.loadslip_id       = a.loadslip_id
        and b.item_id             = c.item_id
        and c.item_classification = 'VALVE'
        ),0) ,
        round(
        (select sum(((b.qty * nvl(c.tte,0)) / l_tte_capacity) * 100)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.item_id   = c.item_id
        and b.loadslip_id = a.loadslip_id
        ),2),
        (
        case
          when (select count(distinct c.item_category)
            from xx_shipment_loadslip_line b,
              mt_item c
            where b.item_id           = c.item_id
            and b.loadslip_id         = a.loadslip_id
            and c.item_classification = 'TYRE') = 1
          then
            (select c.item_category
            from xx_shipment_loadslip_line b,
              mt_item c
            where b.item_id           = c.item_id
            and b.loadslip_id         = a.loadslip_id
            and c.item_classification = 'TYRE'
            and rownum                =1
            )
          else 'MIX'
        end),
        round(
        (select sum(((b.qty * get_item_wt_vol(b.item_id,a.source_loc,'WT') ) / l_gross_wt) * 100)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.item_id   = c.item_id
        and b.loadslip_id = a.loadslip_id
        ),2),
        round(
        (select sum(((b.qty * get_item_wt_vol(b.item_id,a.source_loc,'VOL') ) / l_gross_vol) * 100)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.item_id   = c.item_id
        and b.loadslip_id = a.loadslip_id
        ),2),
        (select min(reporting_date)
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
        ) ,
        (select max(unloading_date)
        from xx_shipment_loadslip_line
        where loadslip_id=a.loadslip_id
        ),
        (select count(1)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.item_id           = c.item_id
        and b.loadslip_id         = a.loadslip_id
        and c.item_classification = 'TYRE'
        and c.item_category       = 'PCTR'
        ),
        (select sum(qty)
        from xx_shipment_loadslip_line b
        where b.loadslip_id = a.loadslip_id
        ),
        a.e_way_bill_no,
        (case when l_loadslip_type = 'FGS_EXP' then 'EXP' else
        atl_business_flow_pkg.get_market_segment(a.source_loc,a.dest_loc) end),
        nvl(
        (select sum(qty)
        from xx_shipment_loadslip_line b,
          mt_item c
        where b.loadslip_id                 = a.loadslip_id
        and b.item_id                       = c.item_id
        and nvl(c.item_classification,'NA') = 'NA'
        ),0),
        a.e_way_bill_date,
        a.custom_inv_num
      from xx_shipment_loadslip a
      where a.loadslip_id = ls.loadslip_id;
     
     --update shipment stop with vvalid loadslip id
    UPDATE shipment_stop set loadslip_id=l_ls_id
    where shipment_id= l_ship_id and loadslip_id=ls.loadslip_id;
     
      -- create loadslip line
      insert
      into loadslip_detail
        (
          loadslip_id,
          line_no,
          item_id,
          item_description,
          batch_code,
          load_qty,
          gross_wt,
          gross_wt_uom,
          gross_vol,
          gross_vol_uom,
          tte,
          scannable,
          insert_user,
          insert_date,
          invoice_number,
          is_split,
          is_loaded,
          item_category
        )
      select 
        --a.loadslip_id,
        l_ls_id,
        a.line_no,
        a.item_id,
        b.item_description,
        a.batch_code,
        a.qty,
        get_item_wt_vol(a.item_id,c.source_loc,'WT'),
        'KG',
        get_item_wt_vol(a.item_id,c.source_loc,'VOL'),
        'CUMTR',
        b.tte,
        'N',
        'INTEGRATION',
        sysdate,
        a.invoice_number,
        'N',
        'N',
        b.item_category
      from xx_shipment_loadslip c,
        xx_shipment_loadslip_line a,
        mt_item b
      where c.loadslip_id = a.loadslip_id
      and a.item_id       = b.item_id
      and c.loadslip_id   = ls.loadslip_id;
      
      -- create loadslip detail bom
      insert into loadslip_detail_bom
      (loadslip_id,
        item_id,
        insert_user,
        insert_date,
        line_no,
        tube_qty,
        flap_qty,
        valve_qty)
        select 
        loadslip_id,
        item_id,
        'INTEGRATION',
        sysdate,
        line_no,
        0,0,0
        from loadslip_detail
        where loadslip_id = l_ls_id;
   --     where loadslip_id = ls.loadslip_id;
   
      
      -- create loadslip line detail
      insert
      into loadslip_line_detail
        (
          loadslip_id,
          line_no,
          item_id,
          qty,
          batch_code,
          insert_date,
          weight,
          weight_uom,
          volume,
          volume_uom,
          invoice_number
        )
      select 
        --a.loadslip_id,
        l_ls_id,
        a.line_no,
        a.item_id,
        a.qty,
        a.batch_code,
        sysdate,
        get_item_wt_vol(a.item_id,c.source_loc,'WT'),
        'KG',
        get_item_wt_vol(a.item_id,c.source_loc,'VOL'),
        'CUMTR',
        a.invoice_number
      from xx_shipment_loadslip c,
        xx_shipment_loadslip_line a,
        mt_item b
      where c.loadslip_id = a.loadslip_id
      and a.item_id       = b.item_id
      and c.loadslip_id   = ls.loadslip_id;
      l_loop_count       := l_loop_count+1;
      l_ls_source_loc    := ls.source_loc;
      l_ref_code         := l_gc;
  
    --Check invoice exists in del_inv_header 
    --Raghava 12-July
      select count(d.invoice_number) into l_chk_cnt 
      from del_inv_header d 
      where d.shipment_id is null and d.invoice_number in (select distinct b.invoice_number from xx_shipment_loadslip_line b
                                    where b.loadslip_id = ls.loadslip_id);
     
     if l_chk_cnt > 0 then
     --Delete invoice from  del_inv_line, del_inv_header
     delete from del_inv_line dl 
     where dl.invoice_number in (select distinct b.invoice_number from xx_shipment_loadslip_line b
                                  where b.loadslip_id = ls.loadslip_id);
      
      delete from del_inv_header d 
      where d.shipment_id is null and d.invoice_number in (select distinct b.invoice_number from xx_shipment_loadslip_line b
                                  where b.loadslip_id = ls.loadslip_id);
       /* update del_inv_header set loadslip_id=l_ls_id,
            shipment_id = l_ship_id where invoice_number in (select distinct b.invoice_number from xx_shipment_loadslip_line b
                                  where b.loadslip_id = ls.loadslip_id); */
     end if;
     
      -- create loadslip invoice  
      if l_loadslip_type not in ('JIT_OEM','FGS_EXP') then
        insert
        into loadslip_inv_header
          (
            loadslip_id,
            shipment_id,
            invoice_number,
            delivery_number,
            so_sto_num,
            invoice_date,
            insert_user,
            insert_date,
            lr_number,
            truck_number,
            source_loc,
            dest_loc,
            lr_date,
            e_way_bill_no,
            e_way_bill_date
          )
        select distinct 
          --loadslip_id,
          l_ls_id,
          l_ship_id,
          invoice_number,
          delivery_number,
          so_sto_number,
          to_char(invoice_date,'DD-MON-YY'),
          'INTEGRATION',
          to_char(sysdate,'DD-MON-YY'),
          lr_number,
           (select truck_number from xx_shipment where shipment_id = l_unique_id
          ),
          ls.source_loc,
          ls.dest_loc,
          to_char(lr_date,'DD-MON-YY'),
          ls.e_way_bill_no,
          to_char(ls.e_way_bill_date,'DD-MON-YY')
        from xx_shipment_loadslip_line
        where loadslip_id = ls.loadslip_id;
        
    -- insert into loadslip_inv_line
        insert
        into loadslip_inv_line
          (
            loadslip_id,
            invoice_number,
            line_no,
            sap_line_no,
            item_id,
            qty,
            weight,
            weight_uom,
            insert_user,
            insert_date,
            batch_code
          )
        select loadslip_id,
          invoice_number,
          line_no,
          line_no * 10,
          item_id,
          qty,
          weight,
          weight_uom,
          'INTEGRATION',
          sysdate,
          batch_code
        from loadslip_line_detail
        where loadslip_id = l_ls_id;
    --    where loadslip_id = ls.loadslip_id;
        
        
        
      else
      dbms_output.put_line('Loadslip ID '||ls.loadslip_id);
       insert
        into del_inv_header
          (
            loadslip_id,
            shipment_id,
            invoice_number,
            delivery_number,
            so_sto_num,
            invoice_date,
            insert_user,
            insert_date,
            lr_number,
            truck_number,
            source_loc,
            dest_loc,
            lr_date,
            container_num,
            type,
            e_way_bill_no,
            e_way_bill_date,
            custom_inv_number
          )
        select distinct l_ls_id,--b.loadslip_id,
          l_ship_id,
          b.invoice_number,
          b.delivery_number,
          b.so_sto_number,
          to_char(b.invoice_date,'DD-MON-YY'),
          'INTEGRATION',
          to_char(sysdate,'DD-MON-YY'),
          b.lr_number,
          (select truck_number from xx_shipment where shipment_id = l_unique_id
          ),
          ls.source_loc,
          ls.dest_loc,
          to_char(b.lr_date,'DD-MON-YY'),
          (select container_num from xx_shipment where shipment_id = l_unique_id
          ),
          l_loadslip_type,
          ls.e_way_bill_no,
          to_char(ls.e_way_bill_date,'DD-MON-YY'),
          ls.custom_inv_num
        from xx_shipment_loadslip_line b
        where b.loadslip_id = ls.loadslip_id;
        insert
        into del_inv_line
          (
            invoice_number,
            line_no,
            sap_line_no,
            item_id,
            qty,
            weight,
            weight_uom,
            insert_user,
            insert_date
          )
        select invoice_number,
          line_no,
          line_no * 10,
          item_id,
          qty,
          weight,
          weight_uom,
          'INTEGRATION',
          sysdate
        from loadslip_line_detail
        where loadslip_id = l_ls_id;
    --    where loadslip_id = ls.loadslip_id;
        
        
      end if;
      
      -- create loadslip GRN
      if l_loadslip_type not in ('JIT_OEM','FGS_EXP','FGS_OEM','FGS_DEL','FGS_CM') then
        
        insert into grn_header 
        (loadslip_id,
            shipment_id,
            grn_type,
            sto_po_num,
            delivery_num,
            source_loc,
            dest_loc,
            grn_number,
            grn_date,
            reporting_date,
            unloading_date,
            insert_user,
            insert_date) 
        select 
        distinct l_ls_id, --loadslip_id,
        l_ship_id,
        'STO',
        so_sto_number,
        delivery_number,
        ls.source_loc,
        ls.dest_loc,
        grn_number,
        to_char(grn_date,'DD-MON-YY'),
        to_char(reporting_date,'DD-MON-YY'),
        unloading_date,
        'INTEGRATION',
        to_char(sysdate,'DD-MON-YY')
        from xx_shipment_loadslip_line where loadslip_id = ls.loadslip_id 
        and grn_number is not null;
        
      insert into grn_line 
      (loadslip_id,
        grn_number,
        line_no,
        sap_line_no,
        item_id,
        batch_code,
        grn_qty,
        insert_user,
        insert_date)
        select 
        --loadslip_id,
        l_ls_id,
        grn_number,
        line_no,
        line_no,
        item_id,
        batch_code,
        qty,
        'INTEGRATION',
        sysdate
        from xx_shipment_loadslip_line 
        where loadslip_id = ls.loadslip_id 
        and grn_number is not null;
        
      else
      
       select count(1) into l_chk_gnt_cnt from xx_shipment_loadslip_line xsll, grn_detail_so gso
            where gso.invoice_number = xsll.invoice_number and gso.sap_doc_number=xsll.grn_number
         --   and gso.oe_code =(select DISTINCT dest_loc from xx_shipment_loadslip xsl where xsl.loadslip_id=xsll.loadslip_id)
            and gso.loadslip_id IN ('JIT_LS','JIT_GRN')and xsll.loadslip_id = ls.loadslip_id and xsll.grn_number is not null;
  
      If l_chk_gnt_cnt= 0 then 
        insert into grn_detail_so
        (loadslip_id,
          shipment_id,
          oe_code,
          sap_doc_number,
          invoice_number,
          receiving_date,
          insert_user,
          insert_date)
          select
          --loadslip_id,
          l_ls_id,
          l_ship_id,
          ls.dest_loc,
          grn_number,
          invoice_number,
          grn_date,
          'INTEGRATION',
          sysdate
          from xx_shipment_loadslip_line 
          where loadslip_id = ls.loadslip_id 
          and grn_number is not null;
    else
    for i in (select xsll.grn_number,xsll.grn_date,xsll.reporting_date,xsll.unloading_date,xsll.invoice_number,xsll.delivery_number
       -- (select DISTINCT dest_loc from xx_shipment_loadslip xsl where xsl.loadslip_id=xsll.loadslip_id) oe_code 
        from xx_shipment_loadslip_line xsll
        where xsll.loadslip_id=ls.loadslip_id and xsll.grn_number is not null)
    loop

      update grn_detail_so
        set loadslip_id   =l_ls_id,
            shipment_id     = l_ship_id,
          --  receiving_date   = l_date1,            
            update_user     = 'INTEGRATION',
            update_date     = sysdate
        where loadslip_id in ('JIT_LS','JIT_GRN') 
        and invoice_number  = i.invoice_number
        and sap_doc_number    = i.grn_number;
      --  and oe_code = i.oe_code;
        
    end loop;
    end if;
      
    end if;
      
      if l_loadslip_type <> 'FGS_EXP' then
      -- Update loadslip status      
      select count(1)
      into l_grn_cnt
      from dual
      where (select count(1)
        from xx_shipment_loadslip_line
        where loadslip_id = ls.loadslip_id) =
        (select count(1)
        from xx_shipment_loadslip_line
        where loadslip_id = ls.loadslip_id 
        and grn_number is not null);
      
      else 
      
        select count(1)
      into l_grn_cnt
      from dual
      where (select count(1)
        from xx_shipment_loadslip_line
        where loadslip_id = ls.loadslip_id) =
        (select count(1)
        from loadslip
        where loadslip_id = l_ls_id --ls.loadslip_id 
        and 1= (select 1 from shipment where shipment_id = l_ship_id and shipped_onboard_date is not null));
       
      end if;
      
      if l_grn_cnt = 1 then
      update loadslip set status = 'COMPLETED' 
      where loadslip_id= l_ls_id;--ls.loadslip_id; 
      
      update truck_reporting 
      set status = 'COMPLETED' 
      where (shipment_id,truck_number) = 
      (select shipment_id,truck_number from shipment where shipment_id = l_ship_id) 
      and reporting_location = 
      (select location_id from shipment_stop where loadslip_id = l_ls_id--ls.loadslip_id 
      and activity='P' and rownum=1);
      
      end if; 
      
    end loop;
    -- end if;
    
    update 	shipment s
        set		s.status = 'COMPLETED'
        where	s.shipment_id = l_ship_id
        and  (select count(1) from loadslip where shipment_id = s.shipment_id and status = 'COMPLETED' ) = 
              (select count(1) from loadslip where shipment_id = s.shipment_id and status <> 'CANCELLED');
    
    
  end;
  procedure load_staging_data
  as
  begin
    -- Insert into Shipment staging
    add_ship_stage_info;
    -- Insert into Shipment Loadslip staging
    add_ship_ls_stage_info;
    -- Insert into Loadslip lines staging
    add_ship_ls_line_stage_info;
    --create_shipment;
  end;
  procedure purge_staging_data 
  as
  begin
    delete from xx_shipment_loadslip_line 
    where loadslip_id in (select loadslip_id from xx_shipment_loadslip where shipment_id= l_unique_id);
    delete from xx_shipment_loadslip where shipment_id = l_unique_id;
    delete from xx_shipment where shipment_id = l_unique_id;
    delete from xx_json_document where id=p_int_seq;
  end;
begin
  -- Parse Content
  parse_content;
  -- Load staging data
  load_staging_data;
  
  if is_duplicate(l_unique_id) then
    dbms_output.put_line('Duplicate data');
  else
    dbms_output.put_line('New data'); 
  -- Create Shipment
  create_shipment;
  commit;
  end if;
  
  -- Purge staging data
 -- purge_staging_data;
  commit;
  
  exception
  when others then
    l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('/api/uploadPaaSShipment',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq,p_int_seq);
  raise;
  
end;
  function get_item_wt_vol(
      p_item_id    varchar2,
      p_source_loc varchar2,
      p_type       varchar2)
    return number
  as
    l_itm_class mt_item.item_classification%type;
    l_weight number;
    l_volume mt_item.volume%type;
    l_ret_seg number;
  begin
    if p_type='WT' then
      select nvl(item_classification,'NA')
      into l_itm_class
      from mt_item
      where item_id=p_item_id;
      if l_itm_class in ('TYRE','NA') then
        begin
          select weight
          into l_weight
          from mt_item_plant_weight a
          where a.item_id        =p_item_id
          and a.plant_code       =p_source_loc
          and (a.effective_date) =
            (select max(effective_date)
            from mt_item_plant_weight
            where item_id =a.item_id
            and plant_code=a.plant_code
            );
        exception
        when no_data_found then
          --l_weight     := null;
          --l_weight_uom := null;
          select nvl(gross_wt,0)
          into l_weight
          from mt_item
          where item_id = p_item_id;
        end;
      elsif l_itm_class in ('TUBE','FLAP') then
        begin
          select weight
          into l_weight
          from mt_item_plant_weight a
          where a.item_id        =p_item_id
          and a.plant_code       ='3008'
          and (a.effective_date) =
            (select max(effective_date)
            from mt_item_plant_weight
            where item_id =a.item_id
            and plant_code='3008'
            );
        exception
        when no_data_found then
          -- l_weight     := 0;
          -- l_weight_uom := 'KG';
          select nvl(gross_wt,0)
          into l_weight
          from mt_item
          where item_id = p_item_id;
        end;
      elsif l_itm_class = 'VALVE' then
        select nvl(gross_wt,0) into l_weight from mt_item where item_id = p_item_id;
      end if;
      l_ret_seg := l_weight;
    elsif p_type ='VOL' then
      select nvl(volume,0) into l_volume from mt_item where item_id=p_item_id;
      l_ret_seg := l_volume;
    end if;
    return l_ret_seg;
  end;
  function get_ship_stop_type(
      p_shipment_id number)
    return varchar2
  as
    l_source_cnt pls_integer;
    l_dest_cnt pls_integer;
  begin
    select count(distinct source_loc)
    into l_source_cnt
    from xx_shipment_loadslip
    where shipment_id = p_shipment_id;
    select count(distinct dest_loc)
    into l_dest_cnt
    from xx_shipment_loadslip
    where shipment_id = p_shipment_id;
    if l_source_cnt   = 1 and l_dest_cnt = 1 then
      return 'S';
    elsif l_source_cnt > 1 and l_dest_cnt = 1 then
      return 'MP';
    elsif l_source_cnt = 1 and l_dest_cnt > 1 then
      return 'MD';
    elsif l_source_cnt > 1 and l_dest_cnt > 1 then
      return 'MPMD';
    else
      return 'NA';
    end if;
  end;
  
  procedure process_request(p_att1 varchar2,p_att2 number) 
  as
  l_job_id varchar2(100) := 'J'||to_char(systimestamp,'ddmmyyhh24missFF');
  begin
    
    if p_att1 = 'Shipment' then
      
      dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_atom_api.create_paas_shipment('||p_att2||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '2' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
    
    end if;
    
  end;
  
  function is_duplicate(
      p_shipment_id varchar2)
    return boolean
  as
    l_chk_cnt pls_integer;
  begin
    select
      count(1)
    into
      l_chk_cnt
    from
      (
        select
          1
        from
          xx_shipment a,
          xx_shipment_loadslip b,
          xx_shipment_loadslip_line c,
          loadslip_inv_header d
        where
          a.shipment_id      = b.shipment_id
        and b.loadslip_id    = c.loadslip_id
        and c.invoice_number = d.invoice_number
        and a.shipment_id    = p_shipment_id
        and rownum           =1
        union
        select
          1
        from
          xx_shipment a,
          xx_shipment_loadslip b,
          xx_shipment_loadslip_line c,
          del_inv_header d
        where
          a.shipment_id      = b.shipment_id
        and b.loadslip_id    = c.loadslip_id
        and c.invoice_number = d.invoice_number
        and a.shipment_id    = p_shipment_id
        and d.shipment_id is not null
        and rownum           =1
      );
    if l_chk_cnt = 1 then
      return true;
    else
      return false;
    end if;
  end;
  
end atl_atom_api;

/
