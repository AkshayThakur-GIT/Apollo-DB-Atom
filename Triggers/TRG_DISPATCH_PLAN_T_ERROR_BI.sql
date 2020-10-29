--------------------------------------------------------
--  DDL for Trigger TRG_DISPATCH_PLAN_T_ERROR_BI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "ATOM"."TRG_DISPATCH_PLAN_T_ERROR_BI" 
   before insert on "ATOM"."DISPATCH_PLAN_T_ERROR" 
   for each row 
begin  
   if inserting then 
      if :NEW."ERROR_REC_ID" is null then 
         select ERROR_RECORDS_SEQ.nextval into :NEW."ERROR_REC_ID" from dual; 
      end if; 
   end if; 
end;

/
ALTER TRIGGER "ATOM"."TRG_DISPATCH_PLAN_T_ERROR_BI" ENABLE;
