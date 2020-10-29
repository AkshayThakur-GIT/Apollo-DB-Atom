--------------------------------------------------------
--  DDL for Procedure INSERT_SHIPMENT_STOPS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."INSERT_SHIPMENT_STOPS" 
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

/
