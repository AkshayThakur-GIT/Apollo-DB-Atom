--------------------------------------------------------
--  DDL for Procedure SEND_OTM_SHIPMENT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."SEND_OTM_SHIPMENT" 
as
l_int_num    number;
begin
   for ship in (select shipment_id from shipment where is_sync_otm = 'T') 
    loop
    
    l_int_num := integration_seq.nextval;
    
    atl_actual_ship_int_api.make_request(ship.shipment_id,l_int_num);
    
    update shipment set is_sync_otm = 'Y' 
    where shipment_id =ship.shipment_id;
    commit;
    
    end loop;

end;

/
