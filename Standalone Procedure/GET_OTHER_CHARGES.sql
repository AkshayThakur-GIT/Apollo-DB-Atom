--------------------------------------------------------
--  DDL for Function GET_OTHER_CHARGES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ATOM"."GET_OTHER_CHARGES" (
    p_id number)
  return number
as
  l_c1 freight.others1_code%type;
  l_c2 freight.others1_code%type;
  l_c3 freight.others1_code%type;
  l_c1_cost  number := 0;
  l_c2_cost  number := 0;
  l_c3_cost  number := 0;
  l_tot_cost number;
begin
  select others1_code,
    others2_code,
    others3_code
  into l_c1,
    l_c2,
    l_c3
  from freight
  where id = p_id;
  if l_c1 is null and l_c2 is null and l_c3 is null then
    return null;
  else
    if l_c1 not like '%DETENTION%' and l_c1 not like '%PENALTY%' then
      select others1 into l_c1_cost from freight where id= p_id;
    end if;
    if l_c2 not like '%DETENTION%' and l_c2 not like '%PENALTY%' then
      select others2 into l_c2_cost from freight where id= p_id;
    end if;
    if l_c3 not like '%DETENTION%' and l_c3 not like '%PENALTY%' then
      select others3 into l_c3_cost from freight where id= p_id;
    end if;
    l_tot_cost   := l_c1_cost + l_c2_cost + l_c3_cost;
    if l_tot_cost = 0 then
      return null;
    else
      return l_tot_cost;
    end if;
  end if;
end;

/
