--------------------------------------------------------
--  DDL for Trigger TRG_DISPATCH_PLAN_T_BI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "ATOM"."TRG_DISPATCH_PLAN_T_BI" 
   before insert on "ATOM"."DISPATCH_PLAN_T" 
   for each row 
begin  
   if inserting then 
      if :NEW."ID" is null then 
         select RUNNING_ID_GENERATION_SEQ.nextval into :NEW."ID" from dual; 
      end if; 
   end if; 
end;
/
ALTER TRIGGER "ATOM"."TRG_DISPATCH_PLAN_T_BI" ENABLE;
