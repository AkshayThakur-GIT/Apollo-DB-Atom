--------------------------------------------------------
--  DDL for Trigger TRG_TRUCK_REPORTING_BU
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "ATOM"."TRG_TRUCK_REPORTING_BU" before
  update on truck_reporting for each row
    --when (new.gateout_date is not null)
    declare 
    l_err_msg varchar2(100);
    l_rel_date date;
    l_lo_date date;
  begin
    if updating then
      if :old.gateout_date is null and :new.gateout_date is not null then
        :new.gi_go_hrs     := round(nvl((:new.gateout_date - :new.gatein_date) * 24,0),3);
        :new.rep_go_hrs    := round(nvl((:new.gateout_date - :new.reporting_date) * 24,0),3);
        
        begin
        select release_date
        into l_rel_date
        from loadslip
        where shipment_id = :new.shipment_id
          --and ls_date is not null
        and source_loc      = :new.reporting_location 
        and rownum=1;
        exception when no_data_found then
        l_rel_date := null;
        end;
        
        :new.rel_go_hrs      := round(nvl((:new.gateout_date - l_rel_date) * 24,0),3);
        --:new.release_time_hrs := round(nvl((:new.release_date - :new.gatein_date) * 24,0));
      elsif :old.gatein_date is null and :new.gatein_date is not null then
        :new.rep_gi_hrs      := round(nvl((:new.gatein_date - :new.reporting_date) * 24,0),3);
      elsif :new.bay_status   = 'RELEASE' and :old.bay_status <> 'RELEASE' then
        :new.gi_rel_hrs      := round(nvl((sysdate - :new.gatein_date) * 24,0),3);
        --:new.rel_go_hrs      := round(nvl((sysdate - :new.gateout_date) * 24,0),3);
        begin
        select ls_date,release_date
        into l_lo_date,l_rel_date
        from loadslip
        where shipment_id = :new.shipment_id
          --and ls_date is not null
        and source_loc      = :new.reporting_location 
        and rownum=1;
        exception when no_data_found then
        l_lo_date := null;
        l_rel_date := null;
        end;
        :new.lo_rel_hrs    := round(nvl((l_rel_date            -  l_lo_date) * 24,0),3);
      --elsif :old.bay_status ='RELEASE' and :new.bay_status in ('LEPB','LSPB','ARVD') then
      --  :new.bay_status    := 'RELEASE';
      end if;
    end if;
  exception
  when others then
  
    raise;
  end;
/
ALTER TRIGGER "ATOM"."TRG_TRUCK_REPORTING_BU" ENABLE;
