--------------------------------------------------------
--  DDL for Procedure TEMP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."TEMP" as 
l_tran_sap_code varchar2(100);
l_date date := sysdate;
begin

select a.transporter_sap_code
          into l_tran_sap_code           
          from freight a,
            shipment b,
            loadslip c
          where a.source_loc           = c.source_loc
          and a.dest_loc               = c.dest_loc
          and a.truck_type             = b.truck_type
          and a.servprov               =b.servprov
          and ((a.expiry_date         is null
          and (a.effective_date) <= sysdate)
          or (to_date(a.expiry_date,'YYYY-MM-DD')    >= to_date(l_date,'YYYY-MM-DD')
          and trunc(a.effective_date) <= (l_date)))
          and b.shipment_id            = 'SH1002240320003'
          and c.loadslip_id            = 'LS1002INHZA240320001'
          and rownum                   =1;
          
          dbms_output.put_line ('Value '||l_tran_sap_code);
          
          end;

/
