--------------------------------------------------------
--  DDL for Trigger TRG_LOADSLIP_BU
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "ATOM"."TRG_LOADSLIP_BU" before
  update of release_date on loadslip for each row 
 -- when (new.loadslip_type in ('JIT_OEM','FGS_EXP'))
  --when ((new.release_date is not null)
  --and (new.loadslip_type in ('JIT_OEM','FGS_EXP'))) 
  declare l_sap_inv_value del_inv_header.sap_inv_value%type;
  l_sap_wt del_inv_header.total_weight%type;
  l_e_way_bill_no del_inv_header.e_way_bill_no%type;
  l_err_msg       varchar2(100);
  begin
  
  if updating then 
  
  -- if :new.release_date is not null and :old.release_date is null then
      if :new.loadslip_type in ('JIT_OEM','FGS_EXP') then
          select nvl(sum(sap_inv_value),0),
            nvl(sum(total_weight),0)
          into l_sap_inv_value,
            l_sap_wt
          from del_inv_header
          where loadslip_id = :new.loadslip_id;
          select listagg(e_way_bill_no,'|') within group (
          order by e_way_bill_no)
          into l_e_way_bill_no
          from del_inv_header
          where loadslip_id    =:new.loadslip_id;
          :new.sap_inv_value  := l_sap_inv_value;
          :new.sap_inv_weight := l_sap_wt;
          :new.e_way_bill_no  := l_e_way_bill_no;
          update truck_reporting a
          set a.sap_inv_weight      = l_sap_wt,
            a.sap_inv_value         = l_sap_inv_value,
            a.e_way_bill_no         = l_e_way_bill_no
          where a.gate_control_code =
            (select gate_control_code
            from truck_reporting
            where shipment_id      = :new.shipment_id
            and truck_number       = a.truck_number
            and reporting_location = :new.source_loc
            and gateout_date is null
            )
            and a.shipment_id = :new.shipment_id 
            and a.gateout_date is null;
    
        end if;
       
   --  end if;
    
    end if;        
        
  exception
  when others then
 
  raise;
  end;
/
ALTER TRIGGER "ATOM"."TRG_LOADSLIP_BU" ENABLE;
