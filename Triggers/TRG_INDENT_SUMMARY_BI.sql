--------------------------------------------------------
--  DDL for Trigger TRG_INDENT_SUMMARY_BI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "ATOM"."TRG_INDENT_SUMMARY_BI" 
before insert on indent_summary for each row  
declare
l_err_msg       varchar2(100);
l_indent_id varchar2(250);
begin
  if inserting then 
   if :new.indent_id is null then
  select atl_util_pkg.generate_business_number('IND',:new.source_loc,:new.dest_loc)
  into l_indent_id
  from dual;
  :new.indent_id := l_indent_id;
  --update indent_summary set indent_id = l_indent_id 
  --where id = :new.id;
 
  end if;
  
  end if;
  exception when others then
  l_err_msg       := substr(sqlerrm, 1, 100);
  insert into trg_log (trigger_name,trigger_status,ERROR_DESCRIPTION,insert_user,insert_date)
  values
  ('TRG_BI_INDENT_SUMMARY','ERROR',l_err_msg,'SYSTEM',sysdate);
  
  raise;
  
end;
/
ALTER TRIGGER "ATOM"."TRG_INDENT_SUMMARY_BI" ENABLE;
