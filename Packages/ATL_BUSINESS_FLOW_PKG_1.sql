--------------------------------------------------------
--  DDL for Package Body ATL_BUSINESS_FLOW_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_BUSINESS_FLOW_PKG" 
as
  procedure upload_dispatch_plan(
      p_json_data clob,
      p_root_element varchar2,
      p_user         varchar2,
      p_tot_records out number,
      p_tot_error_records out number,
      p_total_tyre_count out number,
      p_c1_count out number,
      p_c2_count out number,
      p_c3_count out number,
      p_c4_count out number,
      p_c5_count out number,
      p_c6_count out number,
      p_plan_id out number,
      p_plan_status out nocopy varchar2)
  as
    /*
    l_item_id mt_item.item_id%type;
    l_dispatch_date varchar2(100);--dispatch_plan_t.dispatch_date%type;
    l_source_loc dispatch_plan_t.source_loc%type;
    l_dest_loc dispatch_plan_t.dest_loc%type;
    l_item_cat dispatch_plan_t.item_category%type;
    l_item_desc dispatch_plan_t.item_description%type;
    l_tte dispatch_plan_t.tte%type;
    l_batch_code dispatch_plan_t.batch_code%type;
    l_qty dispatch_plan_t.quantity%type;
    l_priority dispatch_plan_t.priority%type;
    l_mkt_seg dispatch_plan_t.market_segment%type;
    */
    l_dispatch_date varchar2(100);

    -- Collection variables
    l_disp_plan_data dispatch_plan_list;
    l_disp_plan_record dispatch_plan_obj;

    -- Common variables
    l_record  int := 1;
    l_date    date;
    l_plan_id number := dispatch_plan_seq.nextval;
    l_count pls_integer;
    l_dup_cnt pls_integer;
    --j apex_json.t_values;
    --l_json_data clob;

    -- Variables for JSON processing
    l_json_obj json_object_t;
    l_dispatch_plan_obj json_object_t;
    l_dispatch_plan_arr json_array_t;

    -- Output variables
    --l_tot_records pls_integer;
    l_tot_error_records pls_integer;
    l_total_tyre_count number;
    l_c1_count pls_integer;
    l_c2_count pls_integer;
    l_c3_count pls_integer;
    l_c4_count pls_integer;
    l_c5_count pls_integer;
    l_c6_count pls_integer;
    l_plan_status varchar2(20);

    /*
    procedure parse_dispatch_plan_data as
    begin
    -- select file_data into l_json_data from json_clob;
    -- parsing json data
    -- apex_json.parse(j,l_json_data,false);
    apex_json.parse(j,p_json_data,false);
    l_count := apex_json.get_count(p_values => j,p_path => p_root_element);
    -- dbms_output.put_line('Data Count '||l_count);
    p_tot_records    := l_count;
    p_plan_id        := l_plan_id;
    end;
    */
    procedure parse_dispatch_plan_data
    as
    begin
      -- select file_data into l_json_data from json_clob;
      -- parsing json data
      l_json_obj          := json_object_t.parse(p_json_data);
      l_dispatch_plan_arr := l_json_obj.get_array(p_root_element);
      l_count             := l_dispatch_plan_arr.get_size;
      --dbms_output.put_line('Data Count '||l_count);
      p_tot_records := l_count;
      p_plan_id     := l_plan_id;
    end;
  /*
  procedure fill_disp_plan_collection as
  begin
  -- initialize list for dispatch plan
  l_disp_plan_data := dispatch_plan_list();
  for i in 1 .. l_count
  loop
  l_item_id          := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].MaterialCode', p0 => i);
  l_dispatch_date    := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].DispatchDate', p0 => i);
  l_date             := trunc(to_date(l_dispatch_date,'DD/MM/YYYY HH24:MI:SS'));
  l_source_loc       := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].SourceLocation', p0 => i);
  l_dest_loc         := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].DestinationLocation', p0 => i);
  l_item_desc        := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].MaterialDescription', p0 => i);
  l_batch_code       := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].BatchCode', p0 => i);
  l_mkt_seg          := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].MarketingSegment', p0 => i);
  l_qty              := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].Quantity', p0 => i);
  l_priority         := apex_json.get_varchar2(p_values => j,p_path => p_root_element||'[%d].Priority', p0 => i);
  l_disp_plan_record := dispatch_plan_obj(dispatch_plan_id => l_plan_id, line_num => i, dispatch_date =>l_date, dest_loc =>l_dest_loc, source_loc => l_source_loc, item_id => l_item_id, item_description => l_item_desc, item_category => null, tte => null, batch_code => l_batch_code, quantity => l_qty, priority=> l_priority, market_segment => l_mkt_seg);
  l_disp_plan_data.extend;
  l_disp_plan_data(l_record) := l_disp_plan_record;
  l_record                   := l_record + 1;
  end loop;
  end;
  */
  procedure fill_disp_plan_collection
  as
  begin
    -- initialize list for dispatch plan
    l_disp_plan_data := dispatch_plan_list();
    for i in 0 .. l_count - 1
    loop
      l_dispatch_plan_obj := treat(l_dispatch_plan_arr.get(i)
    as
      json_object_t);
      l_dispatch_date    := l_dispatch_plan_obj.get_string('DispatchDate');
      l_date             := trunc(to_date(l_dispatch_date,'DD/MM/YYYY HH24:MI:SS'));
      l_disp_plan_record := dispatch_plan_obj(dispatch_plan_id => l_plan_id, line_num => i+1, dispatch_date => l_date, dest_loc => l_dispatch_plan_obj.get_string('DestinationLocation'), source_loc => l_dispatch_plan_obj.get_string('SourceLocation'), item_id => l_dispatch_plan_obj.get_string('MaterialCode'), item_description => l_dispatch_plan_obj.get_string('MaterialDescription'), item_category => null, tte => null, batch_code => l_dispatch_plan_obj.get_string('BatchCode'), quantity => l_dispatch_plan_obj.get_string('Quantity'), priority=> l_dispatch_plan_obj.get_string('Priority'), market_segment => l_dispatch_plan_obj.get_string('MarketingSegment'), dest_desc => null, comments => l_dispatch_plan_obj.get_string('Comments'));
      l_disp_plan_data.extend;
      l_disp_plan_data(l_record) := l_disp_plan_record;
      l_record                   := l_record + 1;
    end loop;
  end;
  procedure insert_disp_plan_temp_tbl
  as
  begin
    -- Populate dispatch plan temp table.
    forall i in l_disp_plan_data.first .. l_disp_plan_data.last
    insert
    into dispatch_plan_t
      (
        dispatch_plan_id,
        line_num,
        dispatch_date,
        dest_loc,
        source_loc,
        item_id,
        item_description,
        item_category,
        tte,
        batch_code,
        quantity,
        priority,
        market_segment,        
        dest_description,
        comments,
        status,
        insert_date,
        insert_user
      )
      values
      (
        l_disp_plan_data(i).dispatch_plan_id,
        l_disp_plan_data(i).line_num,
        l_disp_plan_data(i).dispatch_date,
        l_disp_plan_data(i).dest_loc,
        l_disp_plan_data(i).source_loc,
        l_disp_plan_data(i).item_id,
        l_disp_plan_data(i).item_description,
        l_disp_plan_data(i).item_category,
        l_disp_plan_data(i).tte,
        l_disp_plan_data(i).batch_code,
        l_disp_plan_data(i).quantity,
        l_disp_plan_data(i).priority,
        l_disp_plan_data(i).market_segment,
        l_disp_plan_data(i).dest_desc,
        l_disp_plan_data(i).comments,
        'ERROR',
        sysdate,
        p_user
      );
    commit;
  end;
  
  procedure perform_plan_validation
  as
  begin
    -- validation start
    -- C1 – Check Locations Codes
    insert
    into dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
    select dispatch_plan_id,
      line_num,
      'C1'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id
    and not exists
      (select location_id from mt_location where location_id= a.source_loc
      );
    --commit;
    insert
    into dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
    select distinct dispatch_plan_id,
      line_num,
      'C1'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id
    and (not exists
      (select location_id from mt_location where location_id= a.dest_loc union 
      select cust_id from mt_customer where cust_id= a.dest_loc));
    --commit;
    -- C2 – Check for material code
    -- if item not exists then in error table
    insert
    into dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
    select dispatch_plan_id,
      line_num,
      'C2'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id
    and not exists
      (select item_id from mt_item where item_id= a.item_id
      );
    -- if item exists then update item description from item master
    update dispatch_plan_t a
    set a.item_description =
      (select item_description from mt_item where item_id = a.item_id
      )
    where a.dispatch_plan_id = l_plan_id;
    --and a.item_description  is null;
    -- C3 – Check for material TTE
    -- if tte exists then update tte from item master
    update dispatch_plan_t a
    set a.tte =
      (select tte from mt_item where item_id = a.item_id
      )
    where a.tte is null;
    -- if tte not exists then in error table
    insert
    into dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
    select dispatch_plan_id,
      line_num,
      'C3'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id
    and a.tte               is null;
    -- C4 – Check for Item Category
    -- if item category then update item category from item master
    update dispatch_plan_t a
    set a.item_category =
      (select item_category from mt_item where item_id = a.item_id
      )
    where a.dispatch_plan_id = l_plan_id
    and item_category       is null;
    -- if item category not exists then in error table
    insert
    into dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
    select dispatch_plan_id,
      line_num,
      'C4'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id
    and item_category       is null;
    -- C5 – Check for Batch Code
    -- if no batch code then in error table
   /* insert
    into dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
    select dispatch_plan_id,
      line_num,
      'C5'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id
    and not exists
      (select batch_code from mt_batch_codes where batch_code= a.batch_code
      );
     */
     
     -- New batch code validation based on Plant cod
     -- Release : 01-AUG-2019
     
     insert
    into dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
      select dispatch_plan_id,
      line_num,
      'C5'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id
    and not exists
      (select batch_code from mt_batch_codes where batch_code= a.batch_code
      )
      union all
    /*select dispatch_plan_id,
      line_num,
      'C5'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id
    and not exists (select batch_code from mt_plant_batch where batch_code = substr(a.batch_code,1,2)
    and plant_id = atl_business_flow_pkg.get_valid_batch_location(a.source_loc)) 
    and ( ('PLANT' = (select location_type
    from mt_location where location_id = a.source_loc)) or
    ('EXT_WAREHOUSE' = (select location_class
    from mt_location where location_id = a.source_loc)));
    */
    select dispatch_plan_id,
      line_num,
      'C5'
    from dispatch_plan_t a
    where a.dispatch_plan_id = l_plan_id 
    and not exists (select batch_code from mt_plant_batch where batch_code = substr(a.batch_code,1,2)
    and plant_id = a.source_loc) 
    and ( ('PLANT' = (select location_type
    from mt_location where location_id = a.source_loc)) or
    ('EXT_WAREHOUSE' = (select location_class
    from mt_location where location_id = a.source_loc))) 
    and exists (select 1 from mt_item where item_id = a.item_id and item_classification = 'TYRE');
    
    --commit;
    -- C6 – Check for duplicate records
   /*
    INSERT
    INTO dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
    SELECT dispatch_plan_id,
      line_num,
      'C6'
    FROM dispatch_plan_t
    WHERE (source_loc, dest_loc, item_id,
      --quantity,
      (dispatch_date)) IN
      (SELECT source_loc,
        dest_loc,
        item_id,
        --quantity,
        (dispatch_date)
      FROM
        (SELECT DISTINCT a.source_loc,
          a.dest_loc,
          a.item_id,
          --quantity,
          (a.dispatch_date),
          COUNT(1)
        FROM dispatch_plan_t a
        WHERE a.dispatch_plan_id = l_plan_id
        GROUP BY a.source_loc,
          a.dest_loc,
          a.item_id,
          --quantity,
          (a.dispatch_date)
        HAVING COUNT(1) > 1
        )
      )
    AND dispatch_plan_id = l_plan_id ;

    */
    
    insert
    into dispatch_plan_t_error
      (
        dispatch_plan_id,
        line_num,
        error_code
      )
    select dispatch_plan_id,
      line_num,
      'C6'
    from dispatch_plan_t
    where 
    (source_loc,
    dest_loc,
    item_id,
   -- batch_code,
    --quantity,
    dispatch_date
    ) in
      (select source_loc,
        dest_loc,
        item_id,
       -- batch_code,
        --quantity,
        dispatch_date
      from (
        (
        /*select distinct source_loc,
          dest_loc,
          item_id,
          --quantity,
          (dispatch_date),
          count(1)
        from dispatch_plan_t
        where dispatch_plan_id = l_plan_id
        group by source_loc,
          dest_loc,
          item_id,
          --quantity,
          (dispatch_date)
        having count(1) > 1
        */
        select distinct a.source_loc,
          a.dest_loc,
          a.item_id,
          --quantity,
         -- a.batch_code,
          a.dispatch_date,
          count(1)
        from dispatch_plan_t a,dispatch_plan b 
        where a.source_loc=b.source_loc 
        and a.dest_loc=b.dest_loc
        and a.item_id=b.item_id
       -- and a.batch_code = b.batch_code
        and a.dispatch_date = b.dispatch_date
        and a.dispatch_plan_id = l_plan_id 
        group by a.source_loc,
          a.dest_loc,
          a.item_id,
         -- a.batch_code,
          --quantity,
         a.dispatch_date
        having count(1) > 0    
        union       
        select distinct a.source_loc,
          a.dest_loc,
          a.item_id,
          --quantity,
         -- a.batch_code,
          a.dispatch_date,
          count(1)
        from dispatch_plan_t a 
        where a.dispatch_plan_id = l_plan_id 
        group by a.source_loc,
          a.dest_loc,
          a.item_id,
         -- a.batch_code,
          --quantity,
         a.dispatch_date
        having count(1) > 1
        ))
      ) and dispatch_plan_id = l_plan_id;
    commit;
      
      
    /*
    SELECT COUNT(1)
    INTO l_dup_cnt
    FROM dispatch_plan_t_error
    WHERE dispatch_plan_id = l_plan_id ;
    IF l_dup_cnt           = 0 THEN
      INSERT INTO dispatch_plan_t_error
        ( dispatch_plan_id, line_num, error_code
        )
      SELECT dispatch_plan_id,
        line_num,
        'C6'
      FROM dispatch_plan_t
      WHERE (source_loc, dest_loc, item_id,
        --quantity,
        (dispatch_date)) IN
        (SELECT source_loc,
          dest_loc,
          item_id,
          --quantity,
          (dispatch_date)
        FROM (
          ( SELECT DISTINCT a.source_loc,
            a.dest_loc,
            a.item_id,
            --quantity,
            (a.dispatch_date),
            COUNT(1)
          FROM dispatch_plan_t a,
            dispatch_plan b
          WHERE a.source_loc     =b.source_loc
          AND a.dest_loc         =b.dest_loc
          AND a.item_id          =b.item_id
          AND a.dispatch_date    = b.dispatch_date
          AND a.dispatch_plan_id = l_plan_id
          GROUP BY a.source_loc,
            a.dest_loc,
            a.item_id,
            --quantity,
            (a.dispatch_date)
          HAVING COUNT(1) >= 1
          ))
        )
      AND dispatch_plan_id = l_plan_id;
    END IF;
    */
    --commit;

    -- update market segment
    update dispatch_plan_t a
    set a.market_segment    = get_market_segment(a.source_loc,a.dest_loc)
    where --a.market_segment is null
    --and 
    a.dispatch_plan_id  = l_plan_id;



    -- update destination description
    update dispatch_plan_t a
    set a.dest_description =
      (select location_desc from mt_location where location_id = a.dest_loc
      union
      select cust_name from mt_customer where cust_id = a.dest_loc
      )
    where a.dest_description is null and a.dispatch_plan_id  = l_plan_id;

    commit;
  end;
  procedure return_plan_output
  as
  l_job_id varchar2(400) := 'JOB'||l_plan_id||to_char(sysdate,'ddmmyyhh24miss');
  begin
    -- final check to see any errors in error table
    select count(1)
    into l_count
    from dispatch_plan_t_error
    where dispatch_plan_id = l_plan_id;
    select sum(quantity)
    into l_total_tyre_count
    from dispatch_plan_t
    where dispatch_plan_id = l_plan_id;
    p_total_tyre_count    := l_total_tyre_count;
    if l_count             > 0 then
      -- error found
      -- plan id created with errors
      l_plan_status := 'ERROR';
      -- insert into DISP_PLAN table for maintaing aggregated information
      insert
      into disp_plan
        (
          dispatch_plan_id,
          total_qty,
          status,
          insert_user,
          insert_date
        )
        values
        (
          l_plan_id,
          l_total_tyre_count,
          l_plan_status,
          p_user,
          sysdate
        );
      commit;
      select count(1)
      into l_tot_error_records
      from
        (select distinct dispatch_plan_id,
          line_num
        from dispatch_plan_t_error
        where dispatch_plan_id = l_plan_id
        );
      select count(1)
      into l_c1_count
      from dispatch_plan_t_error
      where dispatch_plan_id = l_plan_id
      and error_code         ='C1';
      select count(1)
      into l_c2_count
      from dispatch_plan_t_error
      where dispatch_plan_id = l_plan_id
      and error_code         ='C2';
      select count(1)
      into l_c3_count
      from dispatch_plan_t_error
      where dispatch_plan_id = l_plan_id
      and error_code         ='C3';
      select count(1)
      into l_c4_count
      from dispatch_plan_t_error
      where dispatch_plan_id = l_plan_id
      and error_code         ='C4';
      select count(1)
      into l_c5_count
      from dispatch_plan_t_error
      where dispatch_plan_id = l_plan_id
      and error_code         ='C5';
      select count(1)
      into l_c6_count
      from dispatch_plan_t_error
      where dispatch_plan_id = l_plan_id
      and error_code         ='C6';
      -- assigning out variables in case of errors
      p_tot_error_records := l_tot_error_records;
      p_c1_count          := l_c1_count;
      p_c2_count          := l_c2_count;
      p_c3_count          := l_c3_count;
      p_c4_count          := l_c4_count;
      p_c5_count          := l_c5_count;
      p_c6_count          := l_c6_count;
      p_plan_status       := 'Plan created with errors';
    else
      -- if no error then push data to base table of dispatch plan and delete from temp table
      l_plan_status := 'OPEN';
      -- insert into DISP_PLAN table for maintaing aggregated information
      insert
      into disp_plan
        (
          dispatch_plan_id,
          total_qty,
          status,
          insert_user,
          insert_date
        )
        values
        (
          l_plan_id,
          l_total_tyre_count,
          l_plan_status,
          p_user,
          sysdate
        );
      --commit;
      insert
      into dispatch_plan
        (
          id,
          dispatch_plan_id,
          line_num,
          dispatch_date,
          dest_loc,
          source_loc,
          item_id,
          item_description,
          item_category,
          tte,
          batch_code,
          quantity,
          priority,
          market_segment,
          status,
          app_status,
          approved_qty,
          deleted_qty,
          avail_qty,
          reserved_qty,
          dispatched_qty,
          dest_description,
          comments,
          unapp_qty,
          tot_avail_qty,
          unapp_del_qty,
          insert_user,
          insert_date,
          loaded_qty
        )
      select id,
        dispatch_plan_id,
        line_num,
        dispatch_date,
        dest_loc,
        source_loc,
        item_id,
        item_description,
        item_category,
        tte,
        batch_code,
        quantity,
        priority,
        market_segment,
        'OPEN',
        'APPROVAL_PENDING',
        0,0,0,0,0,
        dest_description,
        comments,
        --0,0,0,
        quantity,quantity,0,
        insert_user,
        sysdate,0 
      from dispatch_plan_t
      where dispatch_plan_id = l_plan_id;
      --commit;
      delete from dispatch_plan_t where dispatch_plan_id = l_plan_id;
      commit;
      
      begin
      
      -- update market segment
      update dispatch_plan a
      set a.weight= get_item_wt_vol(a.item_id,a.market_segment,a.source_loc,a.dest_loc,'WT'),
      a.weight_uom ='KG',
      a.volume= get_item_wt_vol(a.item_id,a.market_segment,a.source_loc,a.dest_loc,'VOL'),
      a.volume_uom = 'CUMTR'
      where a.dispatch_plan_id  = l_plan_id;
      commit;
      exception when others then
      raise;
      end;
      
      -- insert dispatch plan BOM
      --insert_disp_plan_bom(l_plan_id);

      INSERT
                            INTO dispatch_plan_bom
                              (
                                dispatch_plan_id,
                                line_num,
                                item_id,
                                tube_code,
                                tube_desc,
                                tube_comp_qty,
                                flap_code,
                                flap_desc,
                                flap_comp_qty,
                                valve_code,
                                valve_desc,
                                valve_comp_qty,
                                weight,
                                weight_uom,
                                volume,
                                volume_uom,
                                insert_user,
                                insert_date
                              )
                            SELECT dispatch_plan_id,
                              line_num,
                              item_id,
                              tube_code,
                              tube_desc,
                              tube_comp_qty,
                              flap_code,
                              flap_desc,
                              flap_comp_qty,
                              valve_code,
                              valve_desc,
                              valve_comp_qty,
                              weight,
                              weight_uom,
                              volume,
                              volume_uom,
                              p_user,
                              sysdate
                            FROM TABLE (atl_business_flow_pkg.get_disp_plan_bom_details(l_plan_id));
      commit;



      p_tot_error_records := 0;
      p_c1_count          := 0;
      p_c2_count          := 0;
      p_c3_count          := 0;
      p_c4_count          := 0;
      p_c5_count          := 0;
      p_c6_count          := 0;
      p_plan_status       := 'Plan created without any errors';
      
      dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_business_flow_pkg.dispatch_plan_notify
                             ('||l_plan_id||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '2' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
      
    end if;
  end;
begin
    
  -- Temp data
  --insert into json_clob (file_data) values (p_json_data);
  --commit;
  
  -- parse json data received from user
  parse_dispatch_plan_data;
  -- fill the collection for DB operation
  fill_disp_plan_collection;
  -- insert into temporary table DISPATCH_PLAN_T
  insert_disp_plan_temp_tbl;
  
  -- perform dispatch plan validation which includes below checks:
  -- C1: Check Locations Codes
  -- C2: Check for material code
  -- C3  Check for material TTE
  -- C4: Check for Item Category
  -- C5: Check for Batch Code
  -- C6: Check for duplicate records
  -- add records to DISPATCH_PLAN_T_ERROR table in case of validation errors
  perform_plan_validation;
  commit;
  -- perform cleaining and return output to caller
  return_plan_output;
end;

  procedure create_dispatch_plan_manual(
    p_disp_plan_id in number,
    p_user varchar2,
    p_status out nocopy varchar2)
as
  l_total_count number;
  l_plan_count number;
  l_job_id varchar2(400) := 'JOB'||p_disp_plan_id||to_char(sysdate,'ddmmyyhh24miss');
begin
  select count(1)
  into l_total_count
  from dispatch_plan_t
  where dispatch_plan_id = p_disp_plan_id;
  if l_total_count      <> 0 then
    select count(1)
    into l_total_count
    from dispatch_plan_t_error
    where dispatch_plan_id = p_disp_plan_id;
    if l_total_count       = 0 then
      select sum(quantity)
      into l_total_count
      from dispatch_plan_t
      where dispatch_plan_id = p_disp_plan_id;
      select count(1) into l_plan_count 
      from disp_plan where dispatch_plan_id = p_disp_plan_id;
      if l_plan_count > 0 then
      update disp_plan 
      set status = 'OPEN' where dispatch_plan_id = p_disp_plan_id;
      else
      insert
      into disp_plan
        (
          dispatch_plan_id,
          total_qty,
          status,
          insert_user,
          insert_date
        )
        values
        (
          p_disp_plan_id,
          l_total_count,
          'OPEN',
          p_user,
          sysdate
        );

        end if;

      insert
      into dispatch_plan
        (
          id,
          dispatch_plan_id,
          line_num,
          dispatch_date,
          dest_loc,
          source_loc,
          item_id,
          item_description,
          item_category,
          tte,
          batch_code,
          quantity,
          priority,
          market_segment,
          status,
          app_status,
          approved_qty,
          deleted_qty,
          avail_qty,
          reserved_qty,
          dispatched_qty,
          dest_description,
          comments,
          unapp_qty,
          tot_avail_qty,
          unapp_del_qty,
          insert_user,
          insert_date
        )
      select id,
        dispatch_plan_id,
        line_num,
        dispatch_date,
        dest_loc,
        source_loc,
        item_id,
        item_description,
        item_category,
        tte,
        batch_code,
        quantity,
        priority,
        market_segment,
        'OPEN',
        'APPROVAL_PENDING',
        0,0,0,0,0,
        dest_description,
        comments,
        --0,0,0,
        quantity,quantity,0,
        insert_user,
        sysdate
      from dispatch_plan_t
      where dispatch_plan_id = p_disp_plan_id;

      -- update market segment
    update dispatch_plan a
    set a.market_segment    = get_market_segment(a.source_loc,a.dest_loc)
    where --a.market_segment is null
    --and 
    a.dispatch_plan_id  = p_disp_plan_id;

      delete from dispatch_plan_t where dispatch_plan_id = p_disp_plan_id;
      commit;
      
      begin
      
      -- update market segment
      update dispatch_plan a
      set a.weight= get_item_wt_vol(a.item_id,a.market_segment,a.source_loc,a.dest_loc,'WT'),
      a.weight_uom ='KG',
      a.volume= get_item_wt_vol(a.item_id,a.market_segment,a.source_loc,a.dest_loc,'VOL'),
      a.volume_uom = 'CUMTR'
      where a.dispatch_plan_id  = p_disp_plan_id;
      commit;
      exception when others then
      raise;
      end;
      
      dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_business_flow_pkg.dispatch_plan_notify
                             ('||p_disp_plan_id||');
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '2' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
      
      p_status := 'SUCCESS';
    end if;
    else
    p_status := 'ERROR';
  end if;
  exception when others then
  p_status := 'ERROR';
  raise;
end;

  procedure insert_disp_plan_bom(p_disp_plan_id in number) as

  l_job_id varchar2(100) := 'JOB'||to_char(sysdate,'ddmmyyhh24miss');

  begin
  dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                            INSERT
                            INTO dispatch_plan_bom
                              (
                                dispatch_plan_id,
                                line_num,
                                item_id,
                                tube_code,
                                tube_desc,
                                tube_comp_qty,
                                flap_code,
                                flap_desc,
                                flap_comp_qty,
                                valve_code,
                                valve_desc,
                                valve_comp_qty,
                                weight,
                                weight_uom,
                                volume,
                                volume_uom,
                                insert_user,
                                insert_date
                              )
                            SELECT dispatch_plan_id,
                              line_num,
                              item_id,
                              tube_code,
                              tube_desc,
                              tube_comp_qty,
                              flap_code,
                              flap_desc,
                              flap_comp_qty,
                              valve_code,
                              valve_desc,
                              valve_comp_qty,
                              weight,
                              weight_uom,
                              volume,
                              volume_uom,
                              ''INTEGRATION'',
                              sysdate
                            FROM TABLE (atl_business_flow_pkg.get_disp_plan_bom_details('||p_disp_plan_id||'));
                            COMMIT;
                          END;',  
        start_date    =>  sysdate + interval '5' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');

  end;

  procedure cal_truck_summary
  as
  begin
    delete from truck_reporting_summary;
    commit;
    calc_truck_summary_delay;
    insert
    into truck_reporting_summary
      (
        reporting_loc,
        trucks_reported,        
        excess_waiting_rep,
        trucks_gatedin,
        excess_waiting_loc,
        trucks_loadingin,
        insert_user,
        insert_date
      )
    select reporting_location,
      (select count(1)
      from truck_reporting
      where status           ='REPORTED'
      and reporting_location = a.reporting_location
      ) as reported,
      (select count(1)
      from truck_reporting b
      where b.status             ='REPORTED'
      and b.reporting_location   = a.reporting_location
      and nvl(b.rep_wait_hrs,0) > nvl(
        (select nvl(excess_time,3)
        from mt_excess_waiting_rep_limit
        where reporting_loc=b.reporting_location
        ),3)
      ) as excess_waiting_rep,
      (select count(1)
      from truck_reporting
      where status           ='GATED_IN'
      and reporting_location = a.reporting_location
      ) as gated_in,
      (select count(1)
      from truck_reporting b
      where b.status             ='GATED_IN'
      and b.reporting_location   = a.reporting_location
      and nvl(b.loc_wait_hrs,0) > nvl(
        (select nvl(excess_time,3)
        from mt_excess_waiting_loc_limit
        where reporting_loc=b.reporting_location
        ),3)
      ) as excess_waiting_loc,
      (select count(1)
      from truck_reporting
      where status            in ('LOADING','ASSIGN_LS','LOADED')
      and reporting_location = a.reporting_location
      ) as loading_in,
      'SYSTEM',
      sysdate
    from
      (select distinct reporting_location
      from truck_reporting
      where status in ('GATED_IN','REPORTED')
      ) a;
    commit;
  end;

  function get_disp_plan_summary(
      p_disp_plan_id in number)
    return disp_plan_summary_list pipelined
  as
    l_tot_records pls_integer;
    l_tot_error_records pls_integer;
    l_total_tyre_count pls_integer;
    l_c1_count pls_integer;
    l_c2_count pls_integer;
    l_c3_count pls_integer;
    l_c4_count pls_integer;
    l_c5_count pls_integer;
    l_c6_count pls_integer;
    l_plan_status varchar2(20);
  begin
    select count(1)
    into l_tot_records
    from dispatch_plan_t
    where dispatch_plan_id = p_disp_plan_id;
    if l_tot_records       = 0 then
      l_plan_status := 'PLAN_SUCCESS';
      select count(1)
      into l_tot_records
      from dispatch_plan
      where dispatch_plan_id = p_disp_plan_id;
      l_tot_error_records   := 0;
      select sum(quantity)
      into l_total_tyre_count
      from dispatch_plan
      where dispatch_plan_id = p_disp_plan_id;
      if l_tot_records = 0 then
      l_plan_status := 'NO_DATA';
      l_total_tyre_count    := 0;      
      end if;
      l_c1_count            := 0;
      l_c2_count            := 0;
      l_c3_count            := 0;
      l_c4_count            := 0;
      l_c5_count            := 0;
      l_c6_count            := 0;
    else
      l_plan_status := 'PLAN_PENDING';
      select count(1)
      into l_tot_error_records
      from
        (select distinct dispatch_plan_id,
          line_num
        from dispatch_plan_t_error
        where dispatch_plan_id = p_disp_plan_id
        );
      select sum(quantity)
      into l_total_tyre_count
      from dispatch_plan_t
      where dispatch_plan_id = p_disp_plan_id;
      if l_total_tyre_count is null then
        l_total_tyre_count  := 0;
      end if;
      select count(1)
      into l_c1_count
      from dispatch_plan_t_error
      where dispatch_plan_id = p_disp_plan_id
      and error_code         ='C1';
      select count(1)
      into l_c2_count
      from dispatch_plan_t_error
      where dispatch_plan_id = p_disp_plan_id
      and error_code         ='C2';
      select count(1)
      into l_c3_count
      from dispatch_plan_t_error
      where dispatch_plan_id = p_disp_plan_id
      and error_code         ='C3';
      select count(1)
      into l_c4_count
      from dispatch_plan_t_error
      where dispatch_plan_id = p_disp_plan_id
      and error_code         ='C4';
      select count(1)
      into l_c5_count
      from dispatch_plan_t_error
      where dispatch_plan_id = p_disp_plan_id
      and error_code         ='C5';
      select count(1)
      into l_c6_count
      from dispatch_plan_t_error
      where dispatch_plan_id = p_disp_plan_id
      and error_code         ='C6';
    end if;
    pipe row (disp_plan_summary_obj(l_tot_records, l_tot_error_records, l_total_tyre_count, l_c1_count, l_c2_count, l_c3_count, l_c4_count, l_c5_count, l_c6_count, l_plan_status));
    return;
  end;

  function get_market_segment(
      p_source_loc_id in varchar2,
      p_dest_loc_id   in varchar2 )
    return varchar2
  as
    l_src_loc_type mt_location.location_type%type;
    l_dest_loc_type mt_location.location_type%type;
    l_seg varchar2(50);
    --l_order_type order_type_lookup.market_segment%type;
  begin
    /*select nvl(
      (select location_type from mt_location where location_id=p_source_loc_id
      ),'NA')
    into l_src_loc_type
    from dual;
    */
    
    select nvl(
          (select nvl(location_class,location_type) from mt_location where location_id=p_source_loc_id
         ),'NA')
          into l_src_loc_type
         from dual;
    
    select nvl(
      (select nvl(location_class,location_type) from mt_location where location_id=p_dest_loc_id
      ),'NA')
    into l_dest_loc_type
    from dual;
    
    if l_src_loc_type     <> 'NA' then
      if l_src_loc_type    = 'PLANT' then
        if l_dest_loc_type = 'NA' then
         
           select nvl(
            (select cust_type from mt_customer where cust_id=p_dest_loc_id
            ),'NA')
            into l_dest_loc_type
            from dual;
          if l_dest_loc_type = 'NON OE' then
          l_dest_loc_type := 'RDC';
          --select nvl((select get_order_type(p_source_loc_id,p_dest_loc_id,'xx') 
          --from dual),'NA')
          --into l_order_type
          --from dual;
          --if l_order_type = 'FGS_DEL'
          --then 
          --l_dest_loc_type := 'OEM';
          --else
          --l_dest_loc_type := 'RDC';
          --end if;
          elsif l_dest_loc_type = 'CM' then
          l_dest_loc_type := 'CM';
          else 
          l_dest_loc_type := 'OEM';
          end if;

        end if;
        
        select nvl(
          (select nvl(location_class,location_type) from mt_location where location_id=p_dest_loc_id
         ),l_dest_loc_type)
          into l_dest_loc_type
         from dual;
        
        select
          case
            when l_dest_loc_type = 'EXP_WAREHOUSE'
            then 'EXP'
            when l_dest_loc_type = 'RDC'
            then 'REP'
            when l_dest_loc_type = 'ABU'
            then 'REP'
            when l_dest_loc_type = 'OEM'
            then 'OE'
            when l_dest_loc_type = 'CM' 
            then 'CM'
            when l_dest_loc_type = 'JIT'
            then 'OE'
            when l_dest_loc_type in ('PLANT','EXT_WAREHOUSE')
            then 'INTERNAL'
            else 'NA'
          end
        into l_seg
        from dual;
        --return l_seg;
      elsif l_src_loc_type in('ABU','RDC') and l_dest_loc_type in('ABU','RDC') then

          l_seg := 'REP';
          --return l_seg;

       elsif l_src_loc_type    =  'JIT' then
         if l_dest_loc_type = 'NA' then
          l_dest_loc_type := 'OEM';
          l_seg := 'OE';
          --return l_seg;
          elsif l_dest_loc_type = 'EXP_WAREHOUSE' then
          l_seg := 'EXP';
        end if;        
      elsif l_src_loc_type ='RDC' and l_dest_loc_type ='PLANT' then
        l_seg := 'REP';
      
       elsif l_src_loc_type = 'EXT_WAREHOUSE' and l_dest_loc_type  in ('OE','JIT') then
       l_seg := 'OE';
       elsif l_src_loc_type = 'EXT_WAREHOUSE' and l_dest_loc_type in ('NON OE','PLANT','RDC','EXT_WAREHOUSE','ABU') then       
       l_seg := 'REP';
       elsif l_src_loc_type = 'EXT_WAREHOUSE' and l_dest_loc_type ='NA' then 
      
       select nvl(
            (select cust_type from mt_customer where cust_id=p_dest_loc_id
            ),'NA')
            into l_dest_loc_type
            from dual;
            
            if l_dest_loc_type ='NON OE' then
            l_seg := 'REP';
            elsif l_dest_loc_type ='OE' then
            l_seg := 'OE';
            elsif l_dest_loc_type ='CM' then
            l_seg := 'CM';
            end if;
       elsif l_src_loc_type = 'EXT_WAREHOUSE' and l_dest_loc_type = 'EXP_WAREHOUSE' then
       l_seg := 'EXP';
      end if;
      return l_seg;
    else
      return 'NA';
    end if;
  end;

  function get_disp_plan_bom_details(
      p_disp_plan_id in number)
    return disp_plan_bom_list pipelined
  as
    l_tube_code mt_item.item_id%type;
    l_tube_desc mt_item.item_description%type;
    l_tube_comp_qty number;
    l_flap_code mt_item.item_id%type;
    l_flap_desc mt_item.item_description%type;
    l_flap_comp_qty number;
    l_valve_code mt_item.item_id%type;
    l_valve_desc mt_item.item_description%type;
    l_valve_comp_qty number;
    l_weight         number;
    l_weight_uom mt_item.gross_wt_uom%type;
    l_tube_weight number;
    l_flap_weight number;
    l_valve_weight number;

 begin
/*
   for i in
    (select a.line_num,
      a.id,
      a.market_segment as rep_oe,
      a.dispatch_plan_id,
      a.item_id,
      b.gross_wt,
      b.gross_wt_uom,
      b.volume,
      b.vol_uom,
      a.item_description,
      a.source_loc,
      a.dest_loc,
      b.item_classification
    from dispatch_plan a,
      mt_item b
    where a.dispatch_plan_id=p_disp_plan_id
    and a.item_id           =b.item_id
    and b.item_classification = 'TYRE'
    )
    loop
      if i.rep_oe in ('REP','INTERNAL') then
        for j in
        (select b.item_id,
          nvl(a.comp_qty,1) as comp_qty,
          b.item_description,
          b.item_classification
        from mt_item_rep_bom a,
          mt_item b
        where a.sales_sku =
          (select sales_sku from mt_item_rep_bom where item_id=i.item_id and rownum=1
          )
        and a.item_id              = b.item_id
        and a.item_id             <> i.item_id
        and b.item_classification <> 'TYRE'
        )
        loop
          if j.item_classification    = 'TUBE' then
            l_tube_code              := j.item_id;
            l_tube_desc              := j.item_description;
            l_tube_comp_qty          := j.comp_qty;

           begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;


          elsif j.item_classification = 'FLAP' then
            l_flap_code              := j.item_id;
            l_flap_desc              := j.item_description;
            l_flap_comp_qty          := j.comp_qty;

            begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

          elsif j.item_classification = 'VALVE' then
            l_valve_code             := j.item_id;
            l_valve_desc             := j.item_description;
            l_valve_comp_qty         := j.comp_qty;
          end if;
        end loop;
      elsif i.rep_oe in ('CM', 'OE') then
        for j in
        (select b.item_id,
          nvl(a.comp_qty,1) as comp_qty,
          b.item_description,
          b.item_classification
        from mt_item_oe_bom a,
          mt_item b
        where a.sales_sku =
          (select sales_sku from mt_item_oe_bom where item_id=i.item_id and rownum=1 and oe_code = a.oe_code
          )
        and a.item_id              = b.item_id
        and a.item_id             <> i.item_id
        and b.item_classification <> 'TYRE'
        and a.oe_code              = i.dest_loc
        )
        loop
          if j.item_classification    = 'TUBE' then
            l_tube_code              := j.item_id;
            l_tube_desc              := j.item_description;
            l_tube_comp_qty          := j.comp_qty;

            begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;


          elsif j.item_classification = 'FLAP' then
            l_flap_code              := j.item_id;
            l_flap_desc              := j.item_description;
            l_flap_comp_qty          := j.comp_qty;

            begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

          elsif j.item_classification = 'VALVE' then
            l_valve_code             := j.item_id;
            l_valve_desc             := j.item_description;
            l_valve_comp_qty         := j.comp_qty;
          end if;
        end loop;
      end if;
      begin
        select weight,
          nvl(weight_uom,'KG')
        into l_weight,
          l_weight_uom
        from mt_item_plant_weight a
        where a.item_id        =i.item_id
        and a.plant_code       =i.source_loc
        and (a.effective_date) =
          (select max(effective_date)
          from mt_item_plant_weight
          where item_id =a.item_id
          and plant_code=a.plant_code
          );

      exception
      when no_data_found then
       -- l_weight     := 0;
       -- l_weight_uom := 'KG';
        select nvl(gross_wt,0),nvl(gross_wt_uom,'KG')
        into l_weight,l_weight_uom
        from mt_item
        where item_id = i.item_id;
      end;

      l_weight := l_weight + nvl(l_tube_weight,0) + nvl(l_flap_weight,0);      
      pipe row (disp_plan_bom_obj(dispatch_plan_id => i.dispatch_plan_id, line_num => i.line_num, item_id => i.item_id, item_class => i.item_classification, tube_code => l_tube_code, tube_desc => l_tube_desc, tube_comp_qty => l_tube_comp_qty, flap_code => l_flap_code, flap_desc => l_flap_desc, flap_comp_qty => l_flap_comp_qty, valve_code => l_valve_code, valve_desc => l_valve_desc, valve_comp_qty => l_valve_comp_qty, weight => l_weight, weight_uom => l_weight_uom, volume => i.volume, volume_uom => i.vol_uom));
      l_tube_code      := null;
      l_tube_desc      := null;
      l_tube_comp_qty  := null;
      l_tube_weight    := null;
      l_flap_code      := null;
      l_flap_desc      := null;
      l_flap_comp_qty  := null;
      l_flap_weight    := null;
      l_valve_code     := null;
      l_valve_desc     := null;
      l_valve_comp_qty := null;
    end loop;
    return;
	
*/
	for i in
    (select a.line_num,
      a.id,
      a.market_segment as rep_oe,
      a.dispatch_plan_id,
      a.item_id,
      b.gross_wt,
      b.gross_wt_uom,
      b.volume,
      b.vol_uom,
      a.item_description,
      a.source_loc,
      a.dest_loc,
      b.item_classification,
	  nvl((select bom_type from order_type_lookup where order_type = 
      atl_business_flow_pkg.get_order_type(a.source_loc,a.dest_loc,a.item_id)),'NA') as bom
    from dispatch_plan a,
      mt_item b
    where a.dispatch_plan_id=p_disp_plan_id
    and a.item_id           =b.item_id
    and b.item_classification = 'TYRE'
    )
    loop
      if i.bom ='REP' then
        for j in
        (select b.item_id,
          nvl(a.comp_qty,1) as comp_qty,
          b.item_description,
          b.item_classification
        from mt_item_rep_bom a,
          mt_item b
        where a.sales_sku =
          (select sales_sku from mt_item_rep_bom where item_id=i.item_id and rownum=1
          )
        and a.item_id              = b.item_id
        and a.item_id             <> i.item_id
        and b.item_classification <> 'TYRE'
        )
        loop
          if j.item_classification    = 'TUBE' then
            l_tube_code              := j.item_id;
            l_tube_desc              := j.item_description;
            l_tube_comp_qty          := j.comp_qty;

           begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;


          elsif j.item_classification = 'FLAP' then
            l_flap_code              := j.item_id;
            l_flap_desc              := j.item_description;
            l_flap_comp_qty          := j.comp_qty;

            begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

          elsif j.item_classification = 'VALVE' then
            l_valve_code             := j.item_id;
            l_valve_desc             := j.item_description;
            l_valve_comp_qty         := j.comp_qty;            
            select nvl(gross_wt,0)
              into l_valve_weight
              from mt_item
              where item_id = j.item_id;
          end if;
        end loop;
      elsif i.bom = 'OE' then
        for j in
        (select b.item_id,
          nvl(a.comp_qty,1) as comp_qty,
          b.item_description,
          b.item_classification
        from mt_item_oe_bom a,
          mt_item b
        where a.sales_sku =
          (select sales_sku from mt_item_oe_bom where item_id=i.item_id and rownum=1 and oe_code = a.oe_code
          )
        and a.item_id              = b.item_id
        and a.item_id             <> i.item_id
        and b.item_classification <> 'TYRE'
        and a.oe_code              = i.dest_loc
        )
        loop
          if j.item_classification    = 'TUBE' then
            l_tube_code              := j.item_id;
            l_tube_desc              := j.item_description;
            l_tube_comp_qty          := j.comp_qty;

            begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;


          elsif j.item_classification = 'FLAP' then
            l_flap_code              := j.item_id;
            l_flap_desc              := j.item_description;
            l_flap_comp_qty          := j.comp_qty;

            begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

          elsif j.item_classification = 'VALVE' then
            l_valve_code             := j.item_id;
            l_valve_desc             := j.item_description;
            l_valve_comp_qty         := j.comp_qty;
             select nvl(gross_wt,0)
              into l_valve_weight
              from mt_item
              where item_id = j.item_id;
          end if;
        end loop;
      end if;
      begin
        select weight,
          nvl(weight_uom,'KG')
        into l_weight,
          l_weight_uom
        from mt_item_plant_weight a
        where a.item_id        =i.item_id
        and a.plant_code       =i.source_loc
        and (a.effective_date) =
          (select max(effective_date)
          from mt_item_plant_weight
          where item_id =a.item_id
          and plant_code=a.plant_code
          );

      exception
      when no_data_found then
       -- l_weight     := 0;
       -- l_weight_uom := 'KG';
        select nvl(gross_wt,0),nvl(gross_wt_uom,'KG')
        into l_weight,l_weight_uom
        from mt_item
        where item_id = i.item_id;
      end;

      l_weight := l_weight + nvl(l_tube_weight,0) + nvl(l_flap_weight,0) + nvl(l_valve_weight,0);      
      pipe row (disp_plan_bom_obj(dispatch_plan_id => i.dispatch_plan_id, line_num => i.line_num, item_id => i.item_id, item_class => i.item_classification, tube_code => l_tube_code, tube_desc => l_tube_desc, tube_comp_qty => l_tube_comp_qty, flap_code => l_flap_code, flap_desc => l_flap_desc, flap_comp_qty => l_flap_comp_qty, valve_code => l_valve_code, valve_desc => l_valve_desc, valve_comp_qty => l_valve_comp_qty, weight => l_weight, weight_uom => l_weight_uom, volume => i.volume, volume_uom => i.vol_uom));
      l_tube_code      := null;
      l_tube_desc      := null;
      l_tube_comp_qty  := null;
      l_tube_weight    := null;
      l_flap_code      := null;
      l_flap_desc      := null;
      l_flap_comp_qty  := null;
      l_flap_weight    := null;
      l_valve_code     := null;
      l_valve_desc     := null;
      l_valve_comp_qty := null;
    end loop;
    return;
  end;

  function get_order_type(
    p_source_loc varchar2,
    p_dest_loc   varchar2,
    p_item_id    varchar2)
  return varchar2
  as
    l_s_loc_type mt_location.location_type%type;
    l_d_loc_type mt_location.location_type%type;
    l_itm_type mt_item.item_type%type;
    l_cnt pls_integer;
    l_wh_cnt pls_integer;
    l_ret_msg varchar2(100) := 'NA';
  begin
  
  if p_item_id = 'EXP' then
  l_ret_msg := 'FGS_EXP';
  elsif p_item_id = 'JIT' then
  l_ret_msg := 'JIT_OEM';
  else
  
    select nvl(location_class,location_type)
    into l_s_loc_type
    from mt_location
    where location_id=p_source_loc;
    select nvl(
      (select location_class from mt_location where location_id=p_dest_loc),      
      (select location_type from mt_location where location_id=p_dest_loc
      ))
    into l_d_loc_type
    from dual;
    
    
    
    if l_d_loc_type = 'NA' or l_d_loc_type is null then
    select nvl(
      (select location_class from mt_location where location_id=p_dest_loc
      ),      
      (select nvl(cust_type,'OE') from mt_customer where cust_id = p_dest_loc)      
      )
    into l_d_loc_type
    from dual;
    end if;
    
    
   -- select count(1) into l_wh_cnt from mt_ext_warehouse where location_id=p_dest_loc;

    select nvl((select nvl(item_type,'NA')    
    from mt_item
    where item_id          = p_item_id),'NA')
    into l_itm_type
    from dual;
    
    if l_s_loc_type       <> 'NA' then
      if l_s_loc_type      = 'PLANT' then
        if l_d_loc_type    = 'RDC' and l_wh_cnt <> 0 then
          l_ret_msg       := 'FGS_EXT';
        elsif l_d_loc_type    = 'RDC' then
          l_ret_msg       := 'FGS_RDC';
        elsif l_d_loc_type = 'ABU' then
          l_ret_msg       := 'FGS_ABU';
        elsif l_d_loc_type = 'JIT' then
          l_ret_msg       := 'FGS_JIT';
        elsif l_d_loc_type = 'EXP_WAREHOUSE' then
          l_ret_msg       := 'FGS_EXW';
        elsif l_d_loc_type = 'PLANT' and l_itm_type = 'ZFGS' then
          l_ret_msg       := 'FGS_PLT';
        elsif l_d_loc_type = 'EXT_WAREHOUSE' then
        l_ret_msg       := 'FGS_EXT';
        elsif l_d_loc_type = 'NON OE' then
        l_ret_msg       := 'FGS_DEL';
        elsif l_d_loc_type = 'CM' then
        l_ret_msg       := 'FGS_CM';
        else
          select count(1) into l_cnt from mt_customer where cust_id=p_dest_loc;
          if l_cnt     = 1 then
            l_ret_msg := 'FGS_OEM';
          end if;
        end if;
      elsif l_s_loc_type   = 'RDC' then
        if l_d_loc_type    = 'ABU' then
          l_ret_msg       := 'RDC_ABU';
        elsif l_d_loc_type = 'RDC' then
          l_ret_msg       := 'RDC_RDC';
           elsif l_d_loc_type = 'PLANT' then
          l_ret_msg       := 'RDC_PLT';
          elsif l_d_loc_type = 'EXP_WAREHOUSE' then   -- Added by Aman Gumasta : 20/07/2020
          l_ret_msg       := 'RDC_EXW';
          elsif l_d_loc_type = 'NON OE' then          -- Added by Aman Gumasta : 25/08/2020
          l_ret_msg       := 'RDC_DEL';
        end if;
      elsif l_s_loc_type = 'JIT' then
        if l_d_loc_type = 'JIT' then
        l_ret_msg       := 'JIT_JIT';
        elsif l_d_loc_type = 'RDC' then
        l_ret_msg       := 'JIT_RDC';
        elsif l_d_loc_type = 'NON OE' then
        l_ret_msg       := 'FGS_DEL';
        else
        select count(1) into l_cnt from mt_customer where cust_id = p_dest_loc;
        if l_cnt     = 1 then
          l_ret_msg := 'JIT_OEM';
        end if;
         end if;
         elsif l_s_loc_type   = 'EXT_WAREHOUSE' then
          if l_d_loc_type    = 'OE' then
          l_ret_msg       := 'EXT_OEM';
          elsif l_d_loc_type = 'JIT' then
          l_ret_msg       := 'EXT_JIT';
          elsif l_d_loc_type = 'PLANT' then
          l_ret_msg       := 'EXT_PLT';
          elsif l_d_loc_type    = 'ABU' then
          l_ret_msg       := 'EXT_ABU';
           elsif l_d_loc_type    = 'RDC' then
          l_ret_msg       := 'EXT_RDC';
          elsif l_d_loc_type = 'EXT_WAREHOUSE' then
          l_ret_msg       := 'EXT_EXT';
          elsif l_d_loc_type = 'CM' then
          l_ret_msg       := 'EXT_CM';
          elsif l_d_loc_type = 'NON OE' then
          l_ret_msg       := 'EXT_DEL';
          elsif l_d_loc_type = 'EXP_WAREHOUSE' then
          l_ret_msg       := 'EXT_EXW';
          end if;
      end if;
    else
      l_ret_msg := 'NA';
    end if;
    
    end if;
  return l_ret_msg;
end;

  function is_scannable (p_loc_id varchar2,p_item_category varchar2) return varchar2 
  as 
  l_scan location_scan.scannable%type;
  begin

      select nvl((select scannable from location_scan 
      where location_id=p_loc_id and item_category = p_item_category),'N')
      into l_scan from dual;

      return l_scan;

  end;

  /*function get_item_bom(p_item_id varchar2,p_source_loc varchar2,p_dest_loc varchar2)
    return item_bom_list
  is
    l_tab item_bom_list := item_bom_list();
    l_rep_oe varchar2(10);
    l_itm_class mt_item.item_classification%type;
    l_tube_code mt_item.item_id%type;
    l_tube_desc mt_item.item_description%type;
    l_tube_comp_qty number;
    l_flap_code mt_item.item_id%type;
    l_flap_desc mt_item.item_description%type;
    l_flap_comp_qty number;
    l_valve_code mt_item.item_id%type;
    l_valve_desc mt_item.item_description%type;
    l_valve_comp_qty number;
    l_weight         number;
    l_weight_uom mt_item.gross_wt_uom%type;
    l_volume mt_item.volume%type;
    l_volume_uom mt_item.vol_uom%type;
    l_tube_weight number;
    l_flap_weight number;    
  begin
    select
      (select 'REP' from mt_location where location_id = p_dest_loc
      union
      select 'OE' from mt_customer where cust_id=p_dest_loc
      ) as rep_oe
    into l_rep_oe
    from dual;
    select volume,
      vol_uom,
      nvl(item_classification,'NA')
    into l_volume,
      l_volume_uom,
      l_itm_class
    from mt_item
    where item_id=p_item_id;
	
	--if l_itm_class = 'TYRE' then
	
    if l_rep_oe  = 'REP' then
      for j in
      (select b.item_id,
        nvl(a.comp_qty,1) as comp_qty,
        b.item_description,
        b.item_classification
      from mt_item_rep_bom a,
        mt_item b
      where a.sales_sku =
        (select sales_sku from mt_item_rep_bom where item_id=p_item_id and rownum=1
        )
      and a.item_id              = b.item_id
      and a.item_id             <> p_item_id
      and b.item_classification <> 'TYRE'
      )
      loop
        if j.item_classification    = 'TUBE' then
          l_tube_code              := j.item_id;
          l_tube_desc              := j.item_description;
          l_tube_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'FLAP' then
          l_flap_code              := j.item_id;
          l_flap_desc              := j.item_description;
          l_flap_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'VALVE' then
          l_valve_code             := j.item_id;
          l_valve_desc             := j.item_description;
          l_valve_comp_qty         := j.comp_qty;
        end if;
      end loop;
    elsif l_rep_oe = 'OE' then
      for j in
      (select b.item_id,
        nvl(a.comp_qty,1) as comp_qty,
        b.item_description,
        b.item_classification
      from mt_item_oe_bom a,
        mt_item b
      where a.sales_sku =
        (select sales_sku from mt_item_oe_bom where item_id=p_item_id and rownum=1
        )
      and a.item_id              = b.item_id
      and a.item_id             <> p_item_id
      and b.item_classification <> 'TYRE'
      and a.oe_code              = p_dest_loc
      )
      loop
        if j.item_classification    = 'TUBE' then
          l_tube_code              := j.item_id;
          l_tube_desc              := j.item_description;
          l_tube_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'FLAP' then
          l_flap_code              := j.item_id;
          l_flap_desc              := j.item_description;
          l_flap_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'VALVE' then
          l_valve_code             := j.item_id;
          l_valve_desc             := j.item_description;
          l_valve_comp_qty         := j.comp_qty;
        end if;
      end loop;
    end if;
  begin
    select weight,
      nvl(weight_uom,'KG')
    into l_weight,
      l_weight_uom
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

    select nvl(gross_wt,0),nvl(gross_wt_uom,'KG')
    into l_weight,l_weight_uom
    from mt_item
    where item_id = p_item_id;

  end;  
  l_weight := l_weight + nvl(l_tube_weight,0) + nvl(l_flap_weight,0);      
  l_tab.extend;
  l_tab(1) := item_bom_obj(item_id => p_item_id, tube_code => l_tube_code, tube_desc => l_tube_desc, tube_comp_qty => l_tube_comp_qty, flap_code => l_flap_code, flap_desc => l_flap_desc, flap_comp_qty => l_flap_comp_qty, valve_code => l_valve_code, valve_desc => l_valve_desc, valve_comp_qty => l_valve_comp_qty, weight => l_weight, weight_uom => l_weight_uom, volume => l_volume, volume_uom => l_volume_uom);
  return l_tab;
 -- else
 -- return null;
 -- end if;
  
  end;
  */
  
  function get_item_bom(p_item_id varchar2,p_source_loc varchar2,p_dest_loc varchar2)
    return item_bom_list
  is
    l_tab item_bom_list := item_bom_list();
    l_rep_oe varchar2(10);
    l_itm_class mt_item.item_classification%type;
    l_tube_code mt_item.item_id%type;
    l_tube_desc mt_item.item_description%type;
    l_tube_comp_qty number;
    l_flap_code mt_item.item_id%type;
    l_flap_desc mt_item.item_description%type;
    l_flap_comp_qty number;
    l_valve_code mt_item.item_id%type;
    l_valve_desc mt_item.item_description%type;
    l_valve_comp_qty number;
    l_weight         number;
    l_weight_uom mt_item.gross_wt_uom%type;
    l_volume mt_item.volume%type;
    l_volume_uom mt_item.vol_uom%type;
    l_tube_weight number;
    l_flap_weight number;
    l_valve_weight number;
    l_bom order_type_lookup.bom_type%type;
  begin
    /*
    select
      get_market_segment(p_source_loc,p_dest_loc) as rep_oe      
     into l_rep_oe
    from dual;
    select volume,
      vol_uom,
      nvl(item_classification,'NA')
    into l_volume,
      l_volume_uom,
      l_itm_class
    from mt_item
    where item_id=p_item_id;
	
	if l_itm_class = 'TYRE' then
	
    if l_rep_oe  in ('REP','INTERNAL') then
      for j in
      (select b.item_id,
        nvl(a.comp_qty,1) as comp_qty,
        b.item_description,
        b.item_classification
      from mt_item_rep_bom a,
        mt_item b
      where a.sales_sku =
        (select sales_sku from mt_item_rep_bom where item_id=p_item_id and rownum=1
        )
      and a.item_id              = b.item_id
      and a.item_id             <> p_item_id
      and b.item_classification <> 'TYRE'
      )
      loop
        if j.item_classification    = 'TUBE' then
          l_tube_code              := j.item_id;
          l_tube_desc              := j.item_description;
          l_tube_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'FLAP' then
          l_flap_code              := j.item_id;
          l_flap_desc              := j.item_description;
          l_flap_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'VALVE' then
          l_valve_code             := j.item_id;
          l_valve_desc             := j.item_description;
          l_valve_comp_qty         := j.comp_qty;
        end if;
      end loop;
    elsif l_rep_oe in ('CM', 'OE') then
      for j in
      (select b.item_id,
        nvl(a.comp_qty,1) as comp_qty,
        b.item_description,
        b.item_classification
      from mt_item_oe_bom a,
        mt_item b
      where a.sales_sku =
        (select sales_sku from mt_item_oe_bom where item_id=p_item_id and rownum=1 and oe_code = a.oe_code
        )
      and a.item_id              = b.item_id
      and a.item_id             <> p_item_id
      and b.item_classification <> 'TYRE'
      and a.oe_code              = p_dest_loc
      )
      loop
        if j.item_classification    = 'TUBE' then
          l_tube_code              := j.item_id;
          l_tube_desc              := j.item_description;
          l_tube_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'FLAP' then
          l_flap_code              := j.item_id;
          l_flap_desc              := j.item_description;
          l_flap_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'VALVE' then
          l_valve_code             := j.item_id;
          l_valve_desc             := j.item_description;
          l_valve_comp_qty         := j.comp_qty;
        end if;
      end loop;
    end if;
  begin
    select weight,
      nvl(weight_uom,'KG')
    into l_weight,
      l_weight_uom
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

    select nvl(gross_wt,0),nvl(gross_wt_uom,'KG')
    into l_weight,l_weight_uom
    from mt_item
    where item_id = p_item_id;

  end;  
  l_weight := l_weight + nvl(l_tube_weight,0) + nvl(l_flap_weight,0);      
  l_tab.extend;
  l_tab(1) := item_bom_obj(item_id => p_item_id, tube_code => l_tube_code, tube_desc => l_tube_desc, tube_comp_qty => l_tube_comp_qty, flap_code => l_flap_code, flap_desc => l_flap_desc, flap_comp_qty => l_flap_comp_qty, valve_code => l_valve_code, valve_desc => l_valve_desc, valve_comp_qty => l_valve_comp_qty, weight => l_weight, weight_uom => l_weight_uom, volume => l_volume, volume_uom => l_volume_uom);
  return l_tab;
 else
 begin
 if l_itm_class in ('TUBE','FLAP') then
    select weight,
      nvl(weight_uom,'KG')
    into l_weight,
      l_weight_uom
    from mt_item_plant_weight a
    where a.item_id        =p_item_id
    and a.plant_code       =p_source_loc
    and (a.effective_date) =
      (select max(effective_date)
      from mt_item_plant_weight
      where item_id =a.item_id
      and plant_code='3008'
      );
      else
      l_weight := 0;
      l_weight_uom := 'KG';
      end if;
  exception
  when no_data_found then
    --l_weight     := null;
    --l_weight_uom := null;

    select nvl(gross_wt,0),nvl(gross_wt_uom,'KG')
    into l_weight,l_weight_uom
    from mt_item
    where item_id = p_item_id;

  end;
  l_tab.extend;
  l_tab(1) := item_bom_obj(item_id => p_item_id, 
                            tube_code => null, 
                            tube_desc => null,
                            tube_comp_qty => null, 
                            flap_code => null, 
                            flap_desc => null, 
                            flap_comp_qty => null, 
                            valve_code => null, 
                            valve_desc => null, 
                            valve_comp_qty => null, 
                            weight => l_weight, weight_uom => l_weight_uom, 
                            volume => l_volume, volume_uom => l_volume_uom);
  return l_tab;
 end if;
  */
  
  select
      get_market_segment(p_source_loc,p_dest_loc) as rep_oe
     into l_rep_oe
    from dual;
    select volume,
      vol_uom,
      nvl(item_classification,'NA'),
	  nvl((select bom_type from order_type_lookup where order_type = 
      atl_business_flow_pkg.get_order_type(p_source_loc,p_dest_loc,p_item_id)),'NA') as bom
    into l_volume,
      l_volume_uom,
      l_itm_class,
	  l_bom
    from mt_item
    where item_id=p_item_id;
	
	if l_itm_class = 'TYRE' then
	
    if l_bom ='REP' then
      for j in
      (select b.item_id,
        nvl(a.comp_qty,1) as comp_qty,
        b.item_description,
        b.item_classification
      from mt_item_rep_bom a,
        mt_item b
      where a.sales_sku =
        (select sales_sku from mt_item_rep_bom where item_id=p_item_id and rownum=1
        )
      and a.item_id              = b.item_id
      and a.item_id             <> p_item_id
      and b.item_classification <> 'TYRE'
      )
      loop
        if j.item_classification    = 'TUBE' then
          l_tube_code              := j.item_id;
          l_tube_desc              := j.item_description;
          l_tube_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'FLAP' then
          l_flap_code              := j.item_id;
          l_flap_desc              := j.item_description;
          l_flap_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'VALVE' then
          l_valve_code             := j.item_id;
          l_valve_desc             := j.item_description;
          l_valve_comp_qty         := j.comp_qty;
          select nvl(gross_wt,0)
              into l_valve_weight
              from mt_item
              where item_id = j.item_id;
        end if;
      end loop;
    elsif l_bom = 'OE' then
      for j in
      (select b.item_id,
        nvl(a.comp_qty,1) as comp_qty,
        b.item_description,
        b.item_classification
      from mt_item_oe_bom a,
        mt_item b
      where a.sales_sku =
        (select sales_sku from mt_item_oe_bom where item_id=p_item_id and rownum=1 and oe_code = a.oe_code
        )
      and a.item_id              = b.item_id
      and a.item_id             <> p_item_id
      and b.item_classification <> 'TYRE'
      and a.oe_code              = p_dest_loc
      )
      loop
        if j.item_classification    = 'TUBE' then
          l_tube_code              := j.item_id;
          l_tube_desc              := j.item_description;
          l_tube_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_tube_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_tube_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'FLAP' then
          l_flap_code              := j.item_id;
          l_flap_desc              := j.item_description;
          l_flap_comp_qty          := j.comp_qty;

          begin
              select weight
              into l_flap_weight
              from mt_item_plant_weight a
              where a.item_id        =j.item_id
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
              into l_flap_weight
              from mt_item
              where item_id = j.item_id;
            end;

        elsif j.item_classification = 'VALVE' then
          l_valve_code             := j.item_id;
          l_valve_desc             := j.item_description;
          l_valve_comp_qty         := j.comp_qty;
          
          select nvl(gross_wt,0)
              into l_valve_weight
              from mt_item
              where item_id = j.item_id;
        end if;
      end loop;
    end if;
  begin
    select weight,
      nvl(weight_uom,'KG')
    into l_weight,
      l_weight_uom
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

    select nvl(gross_wt,0),nvl(gross_wt_uom,'KG')
    into l_weight,l_weight_uom
    from mt_item
    where item_id = p_item_id;

  end;  
  l_weight := l_weight + nvl(l_tube_weight,0) + nvl(l_flap_weight,0) + nvl(l_valve_weight,0);      
  l_tab.extend;
  l_tab(1) := item_bom_obj(item_id => p_item_id, tube_code => l_tube_code, tube_desc => l_tube_desc, tube_comp_qty => l_tube_comp_qty, flap_code => l_flap_code, flap_desc => l_flap_desc, flap_comp_qty => l_flap_comp_qty, valve_code => l_valve_code, valve_desc => l_valve_desc, valve_comp_qty => l_valve_comp_qty, weight => l_weight, weight_uom => l_weight_uom, volume => l_volume, volume_uom => l_volume_uom);
  return l_tab;
 else
 begin
 if l_itm_class in ('TUBE','FLAP') then
    select weight,
      nvl(weight_uom,'KG')
    into l_weight,
      l_weight_uom
    from mt_item_plant_weight a
    where a.item_id        =p_item_id
    and a.plant_code       =p_source_loc
    and (a.effective_date) =
      (select max(effective_date)
      from mt_item_plant_weight
      where item_id =a.item_id
      and plant_code='3008'
      );
      else
      l_weight := 0;
      l_weight_uom := 'KG';
      end if;
  exception
  when no_data_found then
    --l_weight     := null;
    --l_weight_uom := null;

    select nvl(gross_wt,0),nvl(gross_wt_uom,'KG')
    into l_weight,l_weight_uom
    from mt_item
    where item_id = p_item_id;

  end;
  l_tab.extend;
  l_tab(1) := item_bom_obj(item_id => p_item_id, 
                            tube_code => null, 
                            tube_desc => null,
                            tube_comp_qty => null, 
                            flap_code => null, 
                            flap_desc => null, 
                            flap_comp_qty => null, 
                            valve_code => null, 
                            valve_desc => null, 
                            valve_comp_qty => null, 
                            weight => l_weight, weight_uom => l_weight_uom, 
                            volume => l_volume, volume_uom => l_volume_uom);
  return l_tab;
 end if;
  
end;

  function get_sap_tt_code(p_shipment_id varchar2) return varchar2
  as
    l_att shipment.actual_truck_type%type;
    l_v1 shipment.variant_1%type;
    l_return mt_sap_truck_type.sap_truck_type%type;
  begin
    select nvl(actual_truck_type,'NA'),
      nvl(variant_1,'NA')
    into l_att,
      l_v1
    from shipment
    where shipment_id = p_shipment_id;
    if l_att = 'NA' then
    select nvl(truck_type,'NA')     
    into l_att      
    from shipment
    where shipment_id = p_shipment_id;
    end if;

    if l_att          = 'NA' then
      l_return       := 'NA';
    else
      select nvl(
        (select sap_truck_type
        from mt_sap_truck_type
        where rownum=1 and ops_truck_type        =l_att
        --and nvl(ops_variant_1,'NA') = l_v1
        ),'NA')
      into l_return
      from dual;
    end if;
  return l_return;
  end;

  procedure insert_shipment_stops(p_shipment_id varchar2,p_user_id varchar2)
  as
	  l_source shipment_stop.location_id%type := null;
	  l_dest shipment_stop.location_id%type   := null;
	  l_loop_cnt pls_integer                  := 1;
	  l_max_stop pls_integer;
	begin
	  delete
	  from shipment_stop where shipment_id= p_shipment_id;
	  commit;
	  -- Pickup logic
	  for i in
	  (select a.loadslip_id,
		b.shipment_id,
		a.source_loc,
		a.dest_loc,
		nvl(a.drop_seq,0)
	  from loadslip a,
		shipment b
	  where a.shipment_id = b.shipment_id
	  and a.shipment_id   =p_shipment_id 
    and nvl(a.status,'NA') <> 'CANCELLED'
	  order by nvl(drop_seq,0) asc,a.insert_date asc--source_loc asc
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
			  p_user_id,
			  sysdate
			);
    --l_loop_cnt := l_loop_cnt+1;
		elsif l_source = i.source_loc then
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
			  p_user_id,
			  sysdate
			);
      end if;
      l_loop_cnt := 1;
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
		nvl(a.ship_to,a.dest_loc) as dest_loc,
		nvl(a.drop_seq,0)
	  from loadslip a,
		shipment b
	  where a.shipment_id = b.shipment_id
	  and a.shipment_id   =p_shipment_id
    and a.status <> 'CANCELLED'
	  order by nvl(drop_seq,0) asc,a.insert_date desc
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
	  commit;
	end;

  function get_truck_type_details(
    p_truck_type_id varchar2,
    p_variant_1     varchar2)
  return truck_type_list pipelined
    as
    begin
      for i in
      (select truck_type,
        load_factor,
        truck_desc,
        tte_capacity,
        gross_wt,
        gross_wt_uom,
        gross_vol,
        gross_vol_uom,
        variant1,
        variant2
      from mt_truck_type
      where truck_type       = p_truck_type_id
      and nvl(variant1,'NA') = nvl(p_variant_1,'NA')
      and rownum=1
      )
      loop
        pipe row( truck_type_obj (truck_type => i.truck_type, load_factor => i.load_factor, truck_desc => i.truck_desc, tte_capacity => i.tte_capacity, gross_wt => i.gross_wt, gross_wt_uom => i.gross_wt_uom, gross_vol => i.gross_vol, gross_vol_uom => i.gross_vol_uom, variant1 => i.variant1, variant2 => i.variant2 ));
      end loop;
    return;
    end;

	/*
procedure update_item_line(
      p_json_data clob,
      p_root_element varchar2,
      p_user         varchar2,
      p_tot_records out number,
      p_tot_error_records out number,
      p_total_tyre_count out number,
      p_c1_count out number,
      p_c2_count out number,
      p_c3_count out number,
      p_c4_count out number,
      p_c5_count out number,
      p_c6_count out number,
      p_plan_id out number,
      p_plan_status out nocopy varchar2)
  as

    -- Collection variables
    l_item_record item_obj;

    -- Common variables
    l_record  int := 1;
    l_count pls_integer;

    -- Variables for JSON processing
    l_json_obj json_object_t;
    l_item_obj json_object_t;
    l_item_arr json_array_t;

    -- Output variables
    --l_tot_records pls_integer;
    l_tot_error_records pls_integer;
    l_total_tyre_count number;
    l_c1_count pls_integer;
    l_c2_count pls_integer;
    l_c3_count pls_integer;
    l_c4_count pls_integer;
    l_c5_count pls_integer;
    l_c6_count pls_integer;

   procedure parse_item_data
    as
    begin
      -- select file_data into l_json_data from json_clob;
      -- parsing json data
      l_json_obj    := json_object_t.parse(p_json_data);
      l_item_arr 	:= l_json_obj.get_array(p_root_element);
      l_count       := l_item_arr.get_size;
      --dbms_output.put_line('Data Count '||l_count);
      p_tot_records := l_count;
      p_plan_id     := l_plan_id;
    end;
  
  procedure fill_item_collection
  as
  begin
    -- initialize list for dispatch plan
    l_item_data := dispatch_plan_list();
    for i in 0 .. l_count - 1
    loop
      l_item_obj := treat(l_item_arr.get(i)
    as
      json_object_t);
     
      l_item_record := item_obj(Item_ID => l_item_obj.get_string('ItemID'),  tte => l_item_obj.get_string('TTE'), load_factor => l_item_obj.get_string('LoadFactor'), item_category => l_item_obj.get_string('Category') );
      l_item_data.extend;
      l_item_data(l_record) := l_item_record;
      l_record                   := l_record + 1;
    end loop;
  end;
  
  procedure update_item_temp_tbl
  as
  begin
    -- update Item table.
    forall i in l_item_data.first .. l_item_data.last
    update mt_item
      set 
	  item_id 		= l_item_data(i).item_id
	  ,tte 			= l_item_data(i).tte
	  ,load_factor 	= l_item_data(i).load_factor
	  ,item_category = l_item_data(i).item_category
	  ,insert_date	= sysdate
      ,insert_user	= p_user
    where item_id = l_item_data(i).item_id;
    commit;
  end;
 */
 
/*
 procedure update_item_line(
      p_json_data clob,
      p_root_element varchar2,
      p_user         varchar2,
	  p_tot_records out number)
	 as
	
	-- Collection variables
    l_item_record item_obj;

    -- Common variables
    l_record  int := 1;
    l_count pls_integer;

    -- Variables for JSON processing
    l_json_obj json_object_t;
    l_item_obj json_object_t;
    l_item_arr json_array_t;

    -- Output variables
    --l_tot_records pls_integer;
    l_tot_error_records pls_integer;
    l_total_tyre_count number;
	
	 begin
      -- parsing json data
      l_json_obj    := json_object_t.parse(p_json_data);
      l_item_arr 	:= l_json_obj.get_array(p_root_element);
      l_count       := l_item_arr.get_size;
      --dbms_output.put_line('Data Count '||l_count);
      p_tot_records := l_count;
    --  p_plan_id     := l_plan_id;
	
    end;
	
	begin
	-- initialize list for dispatch plan
    l_item_data := dispatch_plan_list();
	end;
	 
	   
	begin
    -- initialize list for dispatch plan
    l_item_data := dispatch_plan_list();
    for i in 0 .. l_count - 1
    loop
      l_item_obj := treat(l_item_arr.get(i)
    as
      json_object_t);
     
      l_item_record := item_obj(Item_ID => l_item_obj.get_string('ItemID'),  tte => l_item_obj.get_string('TTE'), load_factor => l_item_obj.get_string('LoadFactor'), item_category => l_item_obj.get_string('Category') );
      l_item_data.extend;
      l_item_data(l_record) := l_item_record;
      l_record                   := l_record + 1;
    end loop;
  end;
  

   
 begin
    -- update Item table.
    forall i in l_item_data.first .. l_item_data.last
    update mt_item
      set 
	  item_id 		= l_item_data(i).item_id
	  ,tte 			= l_item_data(i).tte
	  ,load_factor 	= l_item_data(i).load_factor
	  ,item_category = l_item_data(i).item_category
	  ,insert_date	= sysdate
      ,insert_user	= p_user
    where item_id = l_item_data(i).item_id;
    commit;
  end;
 */
 
   /*function loadslip_dashboard(
      p_loadslip_id in varchar2)
    return ls_dashboard_list pipelined
  as
  begin
    for i in
    (select loadslip_id,sto_so_num,item_id,item_description,source_loc,dest_loc,ls_qty,inv_qty,grn_qty,dit_qty,short_qty
 from (select distinct a.loadslip_id ,
      a.sto_so_num ,
      b.line_no,
      b.item_id,
      d.item_description,
      a.source_loc,
      a.dest_loc,
      b.qty              as ls_qty,
      nvl(c.qty,0)       as inv_qty,
      nvl(e.grn_qty,0)   as grn_qty,
      nvl(e.dit_qty,0)   as dit_qty,
      nvl(e.short_qty,0) as short_qty
    from loadslip a,
      loadslip_line_detail b,
      loadslip_inv_line c,
      mt_item d,
      grn_line e
    where a.loadslip_id =p_loadslip_id
    and a.loadslip_id   = b.loadslip_id
    and b.loadslip_id   = c.loadslip_id(+)
    and a.loadslip_id   = e.loadslip_id(+)
    and b.item_id       = d.item_id
    and b.line_no       =c.line_no(+)
    and c.line_no       =e.line_no(+))
    order by loadslip_id asc,line_no asc)
    loop
      pipe row (ls_dashboard_obj( loadslip_id => i.loadslip_id, sto_so_num => i.sto_so_num, item_id => i.item_id, item_description => i.item_description, source_location => i.source_loc, dest_location => i.dest_loc, loadslip_quantity => i.ls_qty, invoice_quantity => i.inv_qty, grn_quantity=> i.grn_qty, dit_quantity => i.dit_qty, short_quantity => i.short_qty));
    end loop;
  return;
  end;*/
  
  function loadslip_dashboard(
      p_loadslip_id in varchar2)
    return ls_dashboard_list pipelined
  as
  l_inv_qty number;
  l_grn_qty number;
  l_dit_qty number;
  l_short_qty number;
  begin
    for i in
    (select 
      a.loadslip_id ,
      b.line_no,
      b.qty as ls_qty,
      a.sto_so_num ,
      b.item_id,
      d.item_description,
      a.source_loc,
      a.dest_loc
    from loadslip a,
      loadslip_line_detail b,    
      mt_item d    
    where a.loadslip_id =p_loadslip_id
    and a.loadslip_id   = b.loadslip_id  
    and b.item_id       = d.item_id  
    order by b.line_no asc)
    loop
    
    -- check invoices received from SAP
    select nvl((select sum(qty)
    from LOADSLIP_INV_LINE where loadslip_id=i.loadslip_id
    and item_id = i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_inv_qty
    from dual;
    
    -- check grn received from SAP
    select nvl((select sum(grn_qty) as grn_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_grn_qty
    from dual;
    select nvl((select sum(dit_qty) as dit_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_dit_qty
    from dual;
    select nvl((select sum(short_qty) as short_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_short_qty
    from dual;
        
      pipe row (ls_dashboard_obj( loadslip_id => i.loadslip_id, sto_so_num => i.sto_so_num, item_id => i.item_id, item_description => i.item_description, source_location => i.source_loc, dest_location => i.dest_loc, loadslip_quantity => i.ls_qty, invoice_quantity => l_inv_qty, grn_quantity=> l_grn_qty, dit_quantity => l_dit_qty, short_quantity => l_short_qty));
    end loop;
  return;
  end;
  
 /* function loadslip_dashboard_ui(
      p_loadslip_id in varchar2)
    return ls_dashboard_ui_list pipelined
  as
  l_inv_qty number;
  l_grn_qty number;
  l_dit_qty number;
  l_short_qty number;
  l_inv_number loadslip_inv_header.invoice_number%type;
  l_grn_number grn_header.grn_number%type;
  begin
    for i in
    (select 
      a.loadslip_id ,
      b.line_no,
      b.qty as ls_qty,
      a.sto_so_num ,
      b.item_id,
      d.item_description,
      a.source_loc,
      a.dest_loc
    from loadslip a,
      loadslip_line_detail b,    
      mt_item d    
    where a.loadslip_id =p_loadslip_id
    and a.loadslip_id   = b.loadslip_id  
    and b.item_id       = d.item_id  
    order by b.line_no asc)
    loop
    
    -- get invoice number
    begin
     select listagg(invoice_number,',') within group (order by 1)
     into l_inv_number
     from (select distinct item_id,invoice_number from loadslip_inv_line where loadslip_id=p_loadslip_id 
     and item_id =i.item_id)
     group by item_id;
     
     exception when no_data_found then
     l_inv_number := null;
     end;
    
    -- get grn number
    begin
     select listagg(grn_number,',') within group (order by 1)
     into l_grn_number
     from (select distinct item_id,grn_number from grn_line where loadslip_id=p_loadslip_id 
     and item_id =i.item_id)
     group by item_id;
     
     exception when no_data_found then
     l_grn_number := null;
    end;
    -- check invoices received from SAP
    select nvl((select sum(qty)
    from LOADSLIP_INV_LINE where loadslip_id=i.loadslip_id
    and item_id = i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_inv_qty
    from dual;
    
    -- check grn received from SAP
    select nvl((select sum(grn_qty) as grn_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_grn_qty
    from dual;
    select nvl((select sum(dit_qty) as dit_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_dit_qty
    from dual;
    select nvl((select sum(short_qty) as short_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_short_qty
    from dual;
        
      pipe row (ls_dashboard_ui_obj( loadslip_id => i.loadslip_id, sto_so_num => i.sto_so_num,invoice_number => l_inv_number, grn_number => l_grn_number, item_id => i.item_id, item_description => i.item_description, source_location => i.source_loc, dest_location => i.dest_loc, loadslip_quantity => i.ls_qty, invoice_quantity => l_inv_qty, grn_quantity=> l_grn_qty, dit_quantity => l_dit_qty, short_quantity => l_short_qty));
    end loop;
  return;
  end;
 */
 
 function loadslip_dashboard_ui(
      p_loadslip_id in varchar2)
    return ls_dashboard_ui_list pipelined
  as
  l_inv_qty number;
  l_grn_qty number;
  l_dit_qty number;
  l_short_qty number;
  l_inv_number loadslip_inv_header.invoice_number%type;
  l_grn_number grn_header.grn_number%type;
  
  begin
    for i in
    (select 
      a.loadslip_id ,
      b.line_no,
      b.qty as ls_qty,
      a.sto_so_num ,
      b.item_id,
      d.item_description,
      a.source_loc,
      a.dest_loc,
      (select sap_order_type from order_type_lookup where order_type = a.loadslip_type) as o_type
    from loadslip a,
      loadslip_line_detail b,    
      mt_item d    
    where a.loadslip_id =p_loadslip_id
    and a.loadslip_id   = b.loadslip_id  
    and b.item_id       = d.item_id  
    order by b.line_no asc)
    loop
    
    
    -- get invoice number
    begin
     select listagg(invoice_number,',') within group (order by 1)
     into l_inv_number
     from (select distinct item_id,invoice_number from loadslip_inv_line where loadslip_id=p_loadslip_id 
     and item_id =i.item_id)
     group by item_id;
     
     exception when no_data_found then
     l_inv_number := null;
     end;
    if i.o_type = 'STO' then
    -- get grn number
    begin
     select listagg(grn_number,',') within group (order by 1)
     into l_grn_number
     from (select distinct item_id,grn_number from grn_line where loadslip_id=p_loadslip_id 
     and item_id =i.item_id)
     group by item_id;
     
     exception when no_data_found then
     l_grn_number := null;
    end;
    elsif i.o_type = 'SO' then
    -- get grn number
    begin
     select listagg(sap_doc_number,',') within group (order by 1) 
     into l_grn_number
     from (select distinct sap_doc_number from grn_detail_so 
     where loadslip_id=p_loadslip_id
     and invoice_number in (select invoice_number from 
     loadslip_inv_line where item_id=i.item_id and loadslip_id=p_loadslip_id));
     
     exception when no_data_found then
     l_grn_number := null;
    end;
        
    end if;
    
    
    -- check invoices received from SAP
    select nvl((select sum(qty)
    from LOADSLIP_INV_LINE where loadslip_id=i.loadslip_id
    and item_id = i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_inv_qty
    from dual;
    
    if i.o_type = 'STO' then
    
    -- check grn received from SAP
    select nvl((select sum(grn_qty) as grn_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_grn_qty
    from dual;
    select nvl((select sum(dit_qty) as dit_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_dit_qty
    from dual;
    select nvl((select sum(short_qty) as short_qty
    from grn_line 
    where  loadslip_id=i.loadslip_id
    and item_id =i.item_id and line_no = i.line_no
    group by item_id),0)
    into l_short_qty
    from dual;
    
    elsif i.o_type = 'SO' then
   
    select nvl((select sum(qty)
    from LOADSLIP_INV_LINE where loadslip_id=i.loadslip_id
    and item_id = i.item_id and line_no = i.line_no 
    and invoice_number in (select invoice_number from grn_detail_so 
      where loadslip_id=i.loadslip_id)
    group by item_id),0)
    into l_grn_qty
    from dual;
    
    
    l_dit_qty := 0;
    l_short_qty := 0;
    
    end if;
        
      pipe row (ls_dashboard_ui_obj( loadslip_id => i.loadslip_id, sto_so_num => i.sto_so_num,invoice_number => l_inv_number, grn_number => l_grn_number, item_id => i.item_id, item_description => i.item_description, source_location => i.source_loc, dest_location => i.dest_loc, loadslip_quantity => i.ls_qty, invoice_quantity => l_inv_qty, grn_quantity=> l_grn_qty, dit_quantity => l_dit_qty, short_quantity => l_short_qty));
    end loop;
  return;
  end;
  
  procedure calc_truck_summary_delay
  
  as
  
  begin
     
    -- get reported trucks and calculate wait time hours
    for x in (select *  from truck_reporting a where a.status = 'REPORTED')
    loop
    
     update truck_reporting 
     set 
         rep_wait_hrs = round(nvl((sysdate - reporting_date) * 24,0)),
         loc_wait_hrs = 0
        where truck_number = x.truck_number 
        and gate_control_code = x.gate_control_code;
    
    end loop;
    commit;
    for y in (select *  from truck_reporting a where a.status = 'GATED_IN')
    loop
    
     update truck_reporting 
     set 
         rep_wait_hrs = round(nvl((gatein_date - reporting_date) * 24,0))
        where truck_number = y.truck_number 
        and gate_control_code = y.gate_control_code;
    
    end loop;
    commit;
    
    for z in (select * from truck_reporting where gatein_date is not null and gateout_date is null)
    loop
    
    update truck_reporting 
     set 
         loc_wait_hrs = round(nvl((sysdate - gatein_date) * 24,0))
        where truck_number = z.truck_number 
        and gate_control_code = z.gate_control_code; 
    
    end loop;
    commit;
    
   -- exception when others then
   -- raise;
    
  end;
  
  procedure upload_exp_shipments_data(p_file_data blob,p_user varchar2,p_result out nocopy varchar2) 
  as
  l_id number;
  l_job_id varchar2(100) := 'JOB'||to_char(sysdate,'ddmmyyhh24miss');
  begin
    
    insert into atom_upload_files (file_data,insert_user) 
    values (p_file_data,p_user) 
    RETURNING file_id INTO l_id;
    commit;
    
    dbms_scheduler.create_job 
        (  
          job_name      =>  l_job_id,  
          job_type      =>  'PLSQL_BLOCK',  
          job_action    =>  'BEGIN
                               atl_business_flow_pkg.process_data('||l_id||');
                               COMMIT;
                             END;',  
          start_date    =>  (sysdate - interval '330' minute) + interval '2' second,  
          enabled       =>  TRUE,  
          auto_drop     =>  TRUE,  
          comments      =>  'Trigger only one time');
          commit;
    
    p_result := 'SUCCESS';
    
    exception when others then
    p_result := 'FAILED';  
    raise;
  end;
  
  procedure process_data(
    p_file_id number)
as
  c_limit constant pls_integer default 500;
  cursor file_data
  is
   /* select csv.*
    from x_dump d,
      table(blob_to_csv(d.blob_value,',',1)) csv
    where csv.line_raw is not null;
   */
   select csv.*
    from atom_upload_files d,
      table(atl_util_pkg.blob_to_csv(d.file_data,',',1)) csv
    where csv.line_raw is not null and d.file_id = p_file_id and csv.c023 is not null;
type csv_array
is
  table of file_data%rowtype;
  l_csv_array csv_array;
  l_shipment_id shipment.shipment_id%type;
  l_count pls_integer;
  l_job_id varchar2(100) := 'JOB'||to_char(sysdate,'ddmmyyhh24miss');
  l_location varchar2(20);
  l_sob_date date;
begin
  open file_data;
  loop
    fetch file_data bulk collect into l_csv_array limit c_limit;
    exit
  when l_csv_array.count = 0;
    dbms_output.put_line ('Total valid records ' || l_csv_array.count);
    for indx in 1 .. l_csv_array.count
    loop
      -- DBMS_OUTPUT.put_line (l_csv_array (indx).c023);
      begin
        select shipment_id
        into l_shipment_id
        from loadslip
        where loadslip_id =
          (select loadslip_id
          from loadslip_detail
          where invoice_number = l_csv_array (indx).c023
          and rownum           =1
          );
      exception
      when no_data_found then
        l_shipment_id := 'NA';
      end;
      DBMS_OUTPUT.put_line('Shipment ID '||l_shipment_id);
      if l_shipment_id <> 'NA' then
      l_location := substr(substr(l_shipment_id,3),1,length(substr(l_shipment_id,3))-9);
        -- check if export shipment data already exists
        select count(1)
        into l_count
        from shipment_export
        where shipment_id = l_shipment_id ;
       -- and sap_invoice = l_csv_array (indx).c023;
        if l_count        = 0 then
       -- DBMS_OUTPUT.put_line('in if');
          -- insert data into table
          insert
          into shipment_export
            (
              shipment_id,
              pi_no,
              customer_name,
              pre_inv_no,
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
              post_inv_no,
              sap_invoice,
              inv_amount,
              cha,
              planned_vessel,
              vessel_depart_pol_date,
              shipping_bill,
              shipping_bill_date,
              gatein_date_cfs,
              customs_exam_date,
              leo_date,
              gateout_date_cfs,
              gatein_date_port,
              actual_vessel,
              shipped_onboard_date,
              eta_pod,
              export_remarks,
              insert_user,
              insert_date,
              is_sync_otm,
              source_loc
            )
            values
            (
              l_shipment_id,
              l_csv_array (indx).c002,
              l_csv_array (indx).c003,
              l_csv_array (indx).c009,
              l_csv_array (indx).c010,
              l_csv_array (indx).c011,
              l_csv_array (indx).c012,
              l_csv_array (indx).c013,
              l_csv_array (indx).c014,
              l_csv_array (indx).c015,
              l_csv_array (indx).c016,
              l_csv_array (indx).c017,
              l_csv_array (indx).c018,
              upper(l_csv_array (indx).c019),
              upper(l_csv_array (indx).c020), --l_stuffing_date,
              l_csv_array (indx).c021,
              l_csv_array (indx).c022,
              l_csv_array (indx).c023,
              l_csv_array (indx).c024,
              l_csv_array (indx).c025,
              l_csv_array (indx).c026,
              upper(l_csv_array (indx).c027),
              l_csv_array (indx).c028,
              upper(l_csv_array (indx).c029),
              upper(l_csv_array (indx).c030),
              upper(l_csv_array (indx).c031),
              upper(l_csv_array (indx).c032),
              upper(l_csv_array (indx).c033),
              upper(l_csv_array (indx).c034),
              l_csv_array (indx).c035,
              upper(l_csv_array (indx).c036),
              upper(l_csv_array (indx).c037),
              l_csv_array (indx).c038,
              'INTEGRATION',
              sysdate,
              'N',
              l_location
            );
          commit;
          update shipment
          set vessel_depart_pol_date = upper(l_csv_array (indx).c027),
            gatein_date_cfs          = upper(l_csv_array (indx).c030),
            gateout_date_cfs         = upper(l_csv_array (indx).c033),
            gatein_date_port         = upper(l_csv_array (indx).c034),
            shipped_onboard_date     = upper(l_csv_array (indx).c036),
            update_date              = sysdate,
            update_user              = 'INTEGRATION'
          where shipment_id          = l_shipment_id;
          commit;
          --dbms_output.put_line('Data inserted');
          
                
        if l_csv_array (indx).c036 is not null then
            begin
              update loadslip
              set status         = 'COMPLETED'
              where loadslip_id in
                (select loadslip_id from loadslip where shipment_id = l_shipment_id
                )
              and status <> 'COMPLETED';
              update truck_reporting
              set status                       = 'COMPLETED'
              where (shipment_id,truck_number) =
                (select shipment_id,
                  truck_number
                from shipment
                where shipment_id = l_shipment_id
                )
              and reporting_location in
                (select location_id
                from shipment_stop
                where shipment_id = l_shipment_id
                and activity      ='P'
                )
              and status <> 'COMPLETED';
              update shipment
              set status        = 'COMPLETED'
              where shipment_id = l_shipment_id
              and status       <> 'COMPLETED';
              commit;
            exception
            when others then
              raise;
            end;
          end if;
          
        else
       -- DBMS_OUTPUT.put_line('in else');
       
       select shipped_onboard_date
        into l_sob_date
        from shipment_export
        where shipment_id = l_shipment_id 
        --and sap_invoice = l_csv_array (indx).c023
        and rownum=1;
        
        
        if (l_sob_date is not null and l_sob_date <> upper(l_csv_array (indx).c036))
        or l_sob_date is null  then
        
        /*select count(1)
        into l_count
        from shipment_export
        where shipment_id = l_shipment_id 
        and shipped_onboard_date is null 
        and sap_invoice = l_csv_array (indx).c023;
        */
        
      --  if l_count > 0 then -- if ship on board date already updated then skip the record to be sync to OTM
        
          update shipment_export
          set pi_no                = l_csv_array (indx).c002,
            customer_name          = l_csv_array (indx).c003,
            pre_inv_no             = l_csv_array (indx).c009,
            inco_term              = l_csv_array (indx).c010,
            payment_terms          = l_csv_array (indx).c011,
            pol                    = l_csv_array (indx).c012,
            pod                    = l_csv_array (indx).c013,
            cofd                   = l_csv_array (indx).c014,
            forwarder              = l_csv_array (indx).c015,
            billing_party          = l_csv_array (indx).c016,
            shipping_line          = l_csv_array (indx).c017,
            container_num          = l_csv_array (indx).c018,
            cont_pick_date         = upper(l_csv_array (indx).c019),
            stuffing_date          = upper(l_csv_array (indx).c020),
            booking_num            = l_csv_array (indx).c021,
            post_inv_no            = l_csv_array (indx).c022,
            sap_invoice            = l_csv_array (indx).c023,
            inv_amount             = l_csv_array (indx).c024,
            cha                    = l_csv_array (indx).c025,
            planned_vessel         = l_csv_array (indx).c026,
            vessel_depart_pol_date = upper(l_csv_array (indx).c027),
            shipping_bill          = l_csv_array (indx).c028,
            shipping_bill_date     = upper(l_csv_array (indx).c029),
            gatein_date_cfs        = upper(l_csv_array (indx).c030),
            customs_exam_date      = upper(l_csv_array (indx).c031),
            leo_date               = upper(l_csv_array (indx).c032),
            gateout_date_cfs       = upper(l_csv_array (indx).c033),
            gatein_date_port       = upper(l_csv_array (indx).c034),
            actual_vessel          = l_csv_array (indx).c035,
            shipped_onboard_date   = upper(l_csv_array (indx).c036),
            eta_pod                = upper(l_csv_array (indx).c037),
            export_remarks         = l_csv_array (indx).c038,
            update_date            = sysdate,
            update_user            = 'INTEGRATION',
            is_sync_otm            = 'N',
            source_loc             = l_location
          where shipment_id        = l_shipment_id ;
         -- and sap_invoice = l_csv_array (indx).c023;
          update shipment
          set vessel_depart_pol_date = upper(l_csv_array (indx).c027),
            gatein_date_cfs          = upper(l_csv_array (indx).c030),
            gateout_date_cfs         = upper(l_csv_array (indx).c033),
            gatein_date_port         = upper(l_csv_array (indx).c034),
            shipped_onboard_date     = upper(l_csv_array (indx).c036),
            update_date              = sysdate,
            update_user              = 'INTEGRATION'
          where shipment_id          = l_shipment_id;
          commit;
          if l_csv_array (indx).c036 is not null then
            begin
              update loadslip
              set status         = 'COMPLETED'
              where loadslip_id in
                (select loadslip_id from loadslip where shipment_id = l_shipment_id
                )
              and status <> 'COMPLETED';
              update truck_reporting
              set status                       = 'COMPLETED'
              where (shipment_id,truck_number) =
                (select shipment_id,
                  truck_number
                from shipment
                where shipment_id = l_shipment_id
                )
              and reporting_location in
                (select location_id
                from shipment_stop
                where shipment_id = l_shipment_id
                and activity      ='P'
                )
              and status <> 'COMPLETED';
              update shipment
              set status        = 'COMPLETED'
              where shipment_id = l_shipment_id
              and status       <> 'COMPLETED';
              commit;
            exception
            when others then
              raise;
            end;
          end if;
          
        --  end if;
        
        
        end if;
        
          
        end if;
      end if;
    end loop;
  end loop;
  close file_data;
  commit;
  
 atl_business_flow_pkg.sync_export_sh_to_otm;
  
 /* dbms_scheduler.create_job 
      (  
        job_name      =>  l_job_id,  
        job_type      =>  'PLSQL_BLOCK',  
        job_action    =>  'BEGIN
                             atl_business_flow_pkg.sync_export_sh_to_otm;
                             COMMIT;
                           END;',  
        start_date    =>  (sysdate - interval '330' minute) + interval '2' second,  
        enabled       =>  TRUE,  
        auto_drop     =>  TRUE,  
        comments      =>  'Trigger only one time');
        commit;
  */
end;

procedure sync_export_sh_to_otm 
as
l_int_num    number;
begin
  
  for ship in (select distinct shipment_id from shipment_export where is_sync_otm ='N' and shipped_onboard_date is not null)
  loop
  l_int_num     := integration_seq.nextval;
  atl_actual_ship_int_api.make_request(ship.shipment_id,l_int_num); 
  update shipment_export set is_sync_otm='Y' 
  where shipment_id=ship.shipment_id;
  commit;
  end loop;
  
end;

function get_item_wt_vol(
      p_item_id     varchar2,
      p_mkt_segment varchar2,
      p_source_loc  varchar2,
      p_dest_loc    varchar2,
      p_type        varchar2)
    return number
  as
    l_weight number;
    l_weight_uom mt_item.gross_wt_uom%type;
    l_volume mt_item.volume%type;
    l_volume_uom mt_item.vol_uom%type;
    l_itm_class mt_item.item_classification%type;
    l_ret_seg      number;
    l_tube_weight  number;
    l_flap_weight  number;
    l_valve_weight number;
	l_bom order_type_lookup.bom_type%type;
  begin
    if p_type='WT' then
      select nvl(item_classification,'NA'),
	  nvl((select bom_type from order_type_lookup where order_type = 
      atl_business_flow_pkg.get_order_type(p_source_loc,p_dest_loc,p_item_id)),'NA') as bom
      into l_itm_class,l_bom
      from mt_item
      where item_id=p_item_id;
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
      if l_itm_class     = 'NA' then
        l_ret_seg       := l_weight;
      elsif l_itm_class  ='TYRE' then
        if l_bom = 'REP' then
          for j in
          (select b.item_id,
            b.item_classification
          from mt_item_rep_bom a,
            mt_item b
          where a.sales_sku =
            (select sales_sku from mt_item_rep_bom where item_id=p_item_id and rownum=1
            )
          and a.item_id              = b.item_id
          and a.item_id             <> p_item_id
          and b.item_classification <> 'TYRE'
          )
          loop
            if j.item_classification = 'TUBE' then
              begin
                select weight
                into l_tube_weight
                from mt_item_plant_weight a
                where a.item_id        =j.item_id
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
                into l_tube_weight
                from mt_item
                where item_id = j.item_id;
              end;
            elsif j.item_classification = 'FLAP' then
              begin
                select weight
                into l_flap_weight
                from mt_item_plant_weight a
                where a.item_id        =j.item_id
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
                into l_flap_weight
                from mt_item
                where item_id = j.item_id;
              end;
            elsif j.item_classification = 'VALVE' then
              select nvl(gross_wt,0)
              into l_valve_weight
              from mt_item
              where item_id = j.item_id;
            end if;
          end loop;
        elsif l_bom = 'OE' then
          for j             in
          (select b.item_id,
            b.item_classification
          from mt_item_oe_bom a,
            mt_item b
          where a.sales_sku =
            (select sales_sku
            from mt_item_oe_bom
            where item_id=p_item_id
            and rownum   =1
            and oe_code  = a.oe_code
            )
          and a.item_id              = b.item_id
          and a.item_id             <> p_item_id
          and b.item_classification <> 'TYRE'
          and a.oe_code              = p_dest_loc
          )
          loop
            if j.item_classification = 'TUBE' then
              begin
                select weight
                into l_tube_weight
                from mt_item_plant_weight a
                where a.item_id        =j.item_id
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
                into l_tube_weight
                from mt_item
                where item_id = j.item_id;
              end;
            elsif j.item_classification = 'FLAP' then
              begin
                select weight
                into l_flap_weight
                from mt_item_plant_weight a
                where a.item_id        =j.item_id
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
                into l_flap_weight
                from mt_item
                where item_id = j.item_id;
              end;
            elsif j.item_classification = 'VALVE' then
              select nvl(gross_wt,0)
              into l_valve_weight
              from mt_item
              where item_id = j.item_id;
            end if;
          end loop;
        end if;
        l_weight  := l_weight + nvl(l_tube_weight,0) + nvl(l_flap_weight,0);
        l_ret_seg := l_weight;
      else 
      begin
       if l_itm_class in ('TUBE','FLAP','VALVE') then
          select nvl(weight,0)
          into l_weight
          from mt_item_plant_weight a
          where a.item_id        =p_item_id
          and a.plant_code       =p_source_loc
          and (a.effective_date) =
            (select max(effective_date)
            from mt_item_plant_weight
            where item_id =a.item_id
            and plant_code='3008'
            );
            else
            l_weight := 0;
            end if;
        exception
        when no_data_found then
          --l_weight     := null;
          --l_weight_uom := null;
      
          select nvl(gross_wt,0)
          into l_weight
          from mt_item
          where item_id = p_item_id;
      
        end;
        l_ret_seg := l_weight;
      
      end if;
    elsif p_type='VOL' then
      select nvl(volume,0) into l_volume from mt_item where item_id=p_item_id;
      l_ret_seg := l_volume;
    end if;
    return l_ret_seg;
  end;
  
procedure dispatch_plan_notify (p_disp_plan_id number) as 

    l_body      CLOB;
    l_body_html CLOB;
    l_workspace_id      number;
    l_insert_user dispatch_plan.insert_user%type;
    l_insert_date dispatch_plan.insert_date%type;
    l_count number;
    l_email varchar2(4000);
BEGIN
  
  select insert_user, insert_date
  into l_insert_user,l_insert_date
  from dispatch_plan where dispatch_plan_id = p_disp_plan_id 
  and rownum=1;
  
  /*select email_id
  into l_email
  from um_user where user_id = l_insert_user;
  */
  
 /* select nvl(listagg(email_id,',') within group (order by 1),'NA')
  into l_email
  from plant_contact_details  
  where plant_code = (select source_loc from dispatch_plan where 
  dispatch_plan_id = p_disp_plan_id and rownum=1);
  */
  
  begin
  select nvl(email_id,'NA')
  into l_email
  from mt_location
  where location_id = (select source_loc from dispatch_plan where 
  dispatch_plan_id = p_disp_plan_id and rownum=1);
  exception when others then
  l_email := 'NA';
  end;
  
  if l_email <> 'NA' then 
  select count(1) 
  into l_count
  from dispatch_plan where dispatch_plan_id = p_disp_plan_id ;

    l_body := 'To view the content of this message, please use an HTML enabled mail client.'||utl_tcp.crlf;

    l_body_html := '<html>
                    <body>';--||utl_tcp.crlf;
    l_body_html := l_body_html ||'Plan ID : '||p_disp_plan_id||' generated by '||l_insert_user||' on '||to_char(l_insert_date,'DD-MON-YYYY')||' with '||l_count||' lines.'||utl_tcp.crlf;
    l_body_html := l_body_html ||'</body></html>'; 
    
   atl_util_pkg.send_email(
    l_email,
    'XX',
    l_body,
    l_body_html,
    'Dispatch Plan Upload Notification');
    else
    dbms_output.put_line('No email...');
    end if;
    
END;

procedure indent_notify
                          (p_login_user varchar2,
                           p_indent_id varchar2,
                           p_eb clob,
                           p_att blob default null,
                           p_fn varchar2,
                           p_mimt varchar2,
                           p_status out nocopy varchar2)
as
l_body      CLOB;
l_att       BLOB;
l_source_loc indent_summary.source_loc%type;
l_email varchar2(4000); -- := 'akshay.thakur@inspirage.com';
e_no_email exception;
pragma exception_init(e_no_email, -101);
begin
    
    --select file_data into l_att from atom_upload_files where file_id='134';
    select source_loc into l_source_loc 
    from indent_summary where indent_id= p_indent_id;
    
    begin
    
    /*select trim(substr(association_value,instr(association_value,'_')+1))
    into l_email
    from um_user_association 
    where user_id = (select servprov from indent_summary where indent_id= p_indent_id)
    and association_identifier = 'LOCATION_EMAIL' 
    and substr(association_value,1,instr(association_value,'_')-1) = l_source_loc;
    */
    
    select listagg(b.email_id,',') within group (order by email_id)
    into l_email
    from um_user_association a,um_user b where a.association_value = 
    (select servprov from indent_summary where indent_id=p_indent_id) 
    and a.user_id=b.user_id and b.plant_code =  l_source_loc; 
    
    if l_email is null then
    select listagg(b.email_id,',') within group (order by email_id)
    into l_email
    from um_user_association a,um_user b where a.association_value = 
    (select servprov from indent_summary where indent_id=p_indent_id) 
    and a.user_id=b.user_id and b.plant_code = 
    (select linked_plant from mt_location where location_id = l_source_loc);
    
    if l_email is null then
    raise e_no_email;
    end if;
    
    end if;
    
    exception 
    when e_no_email then
    p_status :='FAILED';
    when others then
    p_status :='FAILED';
    raise;
    end;
    
    
    l_body := 'To view the content of this message, please use an HTML enabled mail client.'||utl_tcp.crlf;
    atl_util_pkg.send_email(
    p_email_to => l_email,
    p_email_from => 'XX',
    p_email_body => l_body,
    p_email_body_html => p_eb,--'<html><body>Test</body></html>',
    p_email_subj => l_source_loc || '- Indent Notification',
    p_email_cc => null,
    p_email_bcc => null,
    p_is_attachment => 'Y',
    p_attachment => p_att,--l_att,
    p_filename => p_fn, --'Myfile.csv',
    p_mime_type => p_mimt--'text/csv'
    );
    
    p_status := 'SUCCESS';
    
    exception when others then
    p_status :='FAILED';
    raise;
  
end;

function get_valid_batch_location(p_location_id varchar2) return varchar2 
as

l_loc_type varchar2(25);
l_loc_id mt_location.location_id%type;
l_ret_seg mt_location.location_id%type;
begin

  select nvl(location_class,location_type) 
  into l_loc_type 
  from mt_location where location_id = p_location_id;
  
  if l_loc_type = 'EXT_WAREHOUSE' then
  select nvl(linked_plant,'NA') 
  into l_loc_id 
  from mt_location where location_id = p_location_id;
  l_ret_seg := l_loc_id;
  else
  l_ret_seg := p_location_id; 
  end if;
  
  return l_ret_seg;
  
end;

procedure freight_approve_notify (p_tot_records number,p_approve_user varchar2) as 

    l_body      CLOB;
    l_body_html CLOB;  
	  l_user_role um_user.user_role_id%type;
    l_count number;
    l_email varchar2(4000);
BEGIN
  
  begin
  select user_role_id into l_user_role from um_user where user_id=p_approve_user;
  exception when others then
  l_user_role := 'NA';
  end;
 
  begin
  if l_user_role = 'L1_MGR' then
  select listagg(email_id,',') within group (order by email_id)
  into l_email
  from um_user
  where user_role_id in ('L2_MGR','ADMIN') 
  and email_id is not null;
  
  elsif l_user_role = 'L2_MGR' then
  select listagg(email_id,',') within group (order by email_id)
  into l_email
  from um_user
  where user_role_id in ('ADMIN') 
  and email_id is not null;
  
  elsif l_user_role = 'ADMIN' then
  select listagg(email_id,',') within group (order by email_id)
  into l_email
  from um_user
  where user_role_id in ('L1_MGR','ADMIN') 
  and email_id is not null;
  
  end if;
  
  exception when others then
  l_email := 'NA';
  end;
 
  
  if l_email <> 'NA' then 
  

    l_body := 'To view the content of this message, please use an HTML enabled mail client.'||utl_tcp.crlf;

    l_body_html := '<html>
                    <body>';--||utl_tcp.crlf;
    if l_user_role = 'ADMIN' then
    l_body_html := l_body_html ||'Rates are uploaded by : '||p_approve_user||' on '||to_char(sysdate,'DD-MON-YYYY')||' with '||p_tot_records||' lines.'||utl_tcp.crlf;
    else    
    l_body_html := l_body_html ||'Rates are approved by : '||p_approve_user||' on '||to_char(sysdate,'DD-MON-YYYY')||' with '||p_tot_records||' lines.'||utl_tcp.crlf;
    end if;
    l_body_html := l_body_html ||'</body></html>'; 
    
   atl_util_pkg.send_email(
    l_email,
    'XX',
    l_body,
    l_body_html,
    'Rates Notification');
    else
    dbms_output.put_line('No email...');
    end if;
    
END;

procedure loadslip_wt_vol_cal (
    p_loadslip_id varchar2
) is

    l_plant_id      loadslip.source_loc%type;
    l_itm_wt        number;
    l_count         pls_integer;
    l_itm_vol       mt_item.volume%type;
    l_itm_class     mt_item.item_classification%type;
    l_tube_check    loadslip_detail_bom.tube_sku%type;
    l_flap_check    loadslip_detail_bom.flap_sku%type;
    l_valve_check   loadslip_detail_bom.valve_sku%type;
    l_shipment_id   loadslip.shipment_id%type;
    l_tub_wt        number;
    l_t_gross_wt    number;
    l_t_gross_vol   number;
    l_flap_wt       number;
    l_valve_wt      number;
begin



	-- For all items in loadsip_detail
    for item in (
        select
            a.item_id,
            a.line_no,
            b.shipment_id,
            b.source_loc as source_loc,
            nvl(c.gross_wt, 0) as wt,
            nvl(c.volume, 0) as vol,
            nvl(c.item_classification, 'NA') as item_classification,
            a.loadslip_id
        from
            loadslip_detail   a,
            loadslip          b,
            mt_item           c
        where
            b.loadslip_id = p_loadslip_id
            and a.loadslip_id = b.loadslip_id
            and a.item_id = c.item_id
    ) loop
	   -- Get the weight of item from mt_item_plant_weight table by comparing loadslip source location and max effective date
        begin
            select
                nvl(weight,0)
            into l_itm_wt
            from
                mt_item_plant_weight
            where
                effective_date = (
                    select
                        max(effective_date)
                    from
                        mt_item_plant_weight
                    where
                        item_id = item.item_id
                )
                and plant_code = item.source_loc
                and item_id = item.item_id;

            dbms_output.put_line('Weight(from mt_item__plant_weight): '
                                 || l_itm_wt
                                 || ' item_id: '
                                 || item.item_id);
        exception
            when no_data_found then
	       
                l_itm_wt := item.wt;
                dbms_output.put_line('Weight(mt_item): '
                                     || l_itm_wt
                                     || ' item_id: '
                                     || item.item_id);
        end;

        if item.item_classification = 'TYRE' then

		        -- Check whether BOM presnt in loadslip_detail_bom for each item	
            select
                count(1)
            into l_count
            from
                loadslip_detail_bom
            where
                item_id = item.item_id
                and line_no = item.line_no
                and loadslip_id = item.loadslip_id;

            if l_count > 0 then
		                -- check if tube,flap,valve available for item in loadslip_detail_bom
                select
                    tube_sku,
                    flap_sku,
                    valve_sku
                into
                    l_tube_check,
                    l_flap_check,
                    l_valve_check
                from
                    loadslip_detail_bom
                where
                    item_id = item.item_id
                    and loadslip_id = item.loadslip_id
                    and line_no = item.line_no;

					    -- if tube is avaiable for particular 'TYRE'

                if l_tube_check is not null then
					        -- get tube weight from mt_item_plant_weight
                    begin
                        select
                            weight
                        into l_tub_wt
                        from
                            mt_item_plant_weight
                        where
                            item_id = l_tube_check
                            and effective_date = (
                                select
                                    max(effective_date)
                                from
                                    mt_item_plant_weight
                                where
                                    item_id = l_tube_check
                            )
                            and plant_code = '3008';

						    -- get tube weight from mt_item

                    exception
                        when no_data_found then
                            select
                                nvl(gross_wt, 0)
                            into l_tub_wt
                            from
                                mt_item
                            where
                                item_id = l_tube_check;

                    end;
                else
                l_tub_wt := 0;
                end if;

					    -- if flap is avaiable for particular 'TYRE'

                if l_flap_check is not null then
					        -- get flap weight from mt_item_plant_weight
                    begin
                        select
                            weight
                        into l_flap_wt
                        from
                            mt_item_plant_weight
                        where
                            item_id = l_flap_check
                            and effective_date = (
                                select
                                    max(effective_date)
                                from
                                    mt_item_plant_weight
                                where
                                    item_id = l_flap_check
                            )
                            and plant_code = '3008';

						    -- get flap weight from mt_item

                    exception
                        when no_data_found then
                            select
                                nvl(gross_wt, 0)
                            into l_flap_wt
                            from
                                mt_item
                            where
                                item_id = l_flap_check;

                    end;
                else
                l_flap_wt := 0;
                end if;

					    -- if valve is avaiable for particular 'TYRE'

                if l_valve_check is not null then   
                            -- get valve weight from mt_item_plant_weight
                    select
                        nvl(gross_wt, 0)
                    into l_valve_wt
                    from
                        mt_item
                    where
                        item_id = l_valve_check;
               else
               l_valve_wt := 0;
                end if;

            else
                l_tub_wt := 0;
                l_flap_wt := 0;
                l_valve_wt := 0;
            end if;
               
				-- calculating total weight of item incluuding tube,flap,valve

            dbms_output.put_line(' Item: '
                                 || l_itm_wt
                                 || ' tube: '
                                 || l_tub_wt);
            dbms_output.put_line(' flap: '
                                 || l_flap_wt
                                 || ' valve: '
                                 || l_valve_wt);
            l_itm_wt := l_itm_wt + l_tub_wt + l_flap_wt + l_valve_wt;
            dbms_output.put_line(' l_item_wt: ' || l_itm_wt);

				--updating loadslip_detail table with gross_wt and gross_vol
            update loadslip_detail
            set
                gross_wt = nvl(l_itm_wt,0),
                gross_vol = nvl(item.vol,0)
            where
                item_id = item.item_id
                and line_no = item.line_no
                and loadslip_id = item.loadslip_id;
                
        else   
          --Code Added for TUBE,FLAP,VALVE by : Aman Gumasta   
          --Dated :- 14/08/2020
           if item.item_classification in ('TUBE','FLAP','VALVE') then
           begin
                  update loadslip_detail
                  set
                  gross_wt = nvl(l_itm_wt,0),
                  gross_vol = nvl(item.vol,0)
                  where
                  item_id = item.item_id
                  and line_no = item.line_no
                  and loadslip_id = item.loadslip_id;
            end;   
            end if;
        end if;

    end loop;

	    -- update loadslip weight and volume
		-- nvl constraint added on 14/08/2020 : by Aman Gumasta
    update loadslip a
    set
        ( a.weight,
          a.volume ) = (
            select
                nvl(sum(load_qty * gross_wt),0),
                nvl(sum(load_qty * gross_vol),0)
            from
                loadslip_detail
            where
                loadslip_id = a.loadslip_id
        )
    where
        a.loadslip_id = p_loadslip_id;

    select
        tt.gross_wt,
        tt.gross_vol
    into
        l_t_gross_wt,
        l_t_gross_vol
    from
        mt_truck_type   tt,
        shipment        s,
        loadslip        l
    where
        nvl(tt.variant1, 'NA') = nvl(s.variant_1, 'NA')
        and tt.truck_type = s.truck_type
        and s.shipment_id = l.shipment_id
        and l.loadslip_id = p_loadslip_id;

    update loadslip
    set
        weight_util = ( weight / l_t_gross_wt )*100,
        volume_util = ( volume / l_t_gross_vol )*100
    where
        loadslip_id = p_loadslip_id;
      
        -- to update shipment ith weight,volume,weight_util,volume_util 

    update shipment s
    set
        ( s.total_weight,
          s.total_volume,
          s.weight_util,
          s.volume_util ) = (
            select
                sum(weight),
                sum(volume),
                sum(weight_util),
                sum(volume_util)
            from
                loadslip
            where
                shipment_id = s.shipment_id
        )
    where
        s.shipment_id = (
            select
                shipment_id
            from
                loadslip
            where
                loadslip_id = p_loadslip_id
        );

    commit;
    
    
exception
    when others then
        dbms_output.put_line('Ignore Error');
        --raise;
end;
 
end atl_business_flow_pkg;

/
