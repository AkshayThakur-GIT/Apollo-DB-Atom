--------------------------------------------------------
--  DDL for Procedure UPDATE_INVOICE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."UPDATE_INVOICE" 

as
l_count number:=0;

BEGIN

for item in (select l.*
            from loadslip l,shipment s,shipment_stop ss
            where
            l.delivery is not null
            and l.sap_invoice is null
            and l.shipment_id=s.shipment_id
            and s.stop_type='MP'
            and ss.loadslip_id=l.loadslip_id
            and ss.stop_num=2
            and l.loadslip_type='FGS_EXP')


     LOOP
        BEGIN
            update loadslip l
            set 
            (l.sap_invoice)=( select listagg(invoice_number,'|') within group (
                             order by invoice_number)
                             from
                             (select distinct invoice_number
                             from del_inv_header
                             where loadslip_id=item.loadslip_id)),
            (l.sap_invoice_date)=(select invoice_date
                                  from del_inv_header
                                  where loadslip_id=item.loadslip_id and rownum=1)
            where loadslip_id=item.loadslip_id;


            l_count := l_count+1;

        END;

      END LOOP;
      dbms_output.put_line('Total Rows Updated :'|| l_count);

EXCEPTION
   when no_data_found then
         dbms_output.put_line('No Rows Found');

END;

/
