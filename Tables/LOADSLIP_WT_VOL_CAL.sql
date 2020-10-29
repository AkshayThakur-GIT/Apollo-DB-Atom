--------------------------------------------------------
--  DDL for Procedure LOADSLIP_WT_VOL_CAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."LOADSLIP_WT_VOL_CAL" (
    p_loadslip_id varchar2
) is

    l_plant_id      loadslip.source_loc%type;
    l_itm_wt        number;
    l_count         pls_integer;
    l_itm_vol       mt_item.volume%type;
    l_itm_class     mt_item.item_classification%type;
    l_tube_check    loadslip_detail_bom.tube_sku%type;
    l_flap_check    loadslip_detail_bom.flap_sku%type;
    l_valve_check   loadslip_detail_bom.valve_sku%type;
    l_shipment_id   loadslip.shipment_id%type;
    l_tub_wt        number;
    l_t_gross_wt    number;
    l_t_gross_vol   number;
    l_flap_wt       number;
    l_valve_wt      number;
begin



	-- For all items in loadsip_detail
    for item in (
        select
            a.item_id,
            a.line_no,
            b.shipment_id,
            b.source_loc as source_loc,
            nvl(c.gross_wt, 0) as wt,
            nvl(c.volume, 0) as vol,
            nvl(c.item_classification, 'NA') as item_classification,
            a.loadslip_id
        from
            loadslip_detail   a,
            loadslip          b,
            mt_item           c
        where
            b.loadslip_id = p_loadslip_id
            and a.loadslip_id = b.loadslip_id
            and a.item_id = c.item_id
    ) loop
	   -- Get the weight of item from mt_item_plant_weight table by comparing loadslip source location and max effective date
        begin
            select
                weight
            into l_itm_wt
            from
                mt_item_plant_weight
            where
                effective_date = (
                    select
                        max(effective_date)
                    from
                        mt_item_plant_weight
                    where
                        item_id = item.item_id
                )
                and plant_code = item.source_loc
                and item_id = item.item_id;

            dbms_output.put_line('Weight(from mt_item__plant_weight): '
                                 || l_itm_wt
                                 || ' item_id: '
                                 || item.item_id);
        exception
            when no_data_found then
	       
                l_itm_wt := item.wt;
                dbms_output.put_line('Weight(mt_item): '
                                     || l_itm_wt
                                     || ' item_id: '
                                     || item.item_id);
        end;

        if item.item_classification = 'TYRE' then

		        -- Check whether BOM presnt in loadslip_detail_bom for each item	
            select
                count(1)
            into l_count
            from
                loadslip_detail_bom
            where
                item_id = item.item_id
                and line_no = item.line_no
                and loadslip_id = item.loadslip_id;

            if l_count > 0 then
		                -- check if tube,flap,valve available for item in loadslip_detail_bom
                select
                    tube_sku,
                    flap_sku,
                    valve_sku
                into
                    l_tube_check,
                    l_flap_check,
                    l_valve_check
                from
                    loadslip_detail_bom
                where
                    item_id = item.item_id
                    and loadslip_id = item.loadslip_id
                    and line_no = item.line_no;

					    -- if tube is avaiable for particular 'TYRE'

                if l_tube_check is not null then
					        -- get tube weight from mt_item_plant_weight
                    begin
                        select
                            weight
                        into l_tub_wt
                        from
                            mt_item_plant_weight
                        where
                            item_id = l_tube_check
                            and effective_date = (
                                select
                                    max(effective_date)
                                from
                                    mt_item_plant_weight
                                where
                                    item_id = l_tube_check
                            )
                            and plant_code = '3008';

						    -- get tube weight from mt_item

                    exception
                        when no_data_found then
                            select
                                nvl(gross_wt, 0)
                            into l_tub_wt
                            from
                                mt_item
                            where
                                item_id = l_tube_check;

                    end;
                else
                l_tub_wt := 0;
                end if;

					    -- if flap is avaiable for particular 'TYRE'

                if l_flap_check is not null then
					        -- get flap weight from mt_item_plant_weight
                    begin
                        select
                            weight
                        into l_flap_wt
                        from
                            mt_item_plant_weight
                        where
                            item_id = l_flap_check
                            and effective_date = (
                                select
                                    max(effective_date)
                                from
                                    mt_item_plant_weight
                                where
                                    item_id = l_flap_check
                            )
                            and plant_code = '3008';

						    -- get flap weight from mt_item

                    exception
                        when no_data_found then
                            select
                                nvl(gross_wt, 0)
                            into l_flap_wt
                            from
                                mt_item
                            where
                                item_id = l_flap_check;

                    end;
                else
                l_flap_wt := 0;
                end if;

					    -- if valve is avaiable for particular 'TYRE'

                if l_valve_check is not null then   
                            -- get valve weight from mt_item_plant_weight
                    select
                        nvl(gross_wt, 0)
                    into l_valve_wt
                    from
                        mt_item
                    where
                        item_id = l_valve_check;
               else
               l_valve_wt := 0;
                end if;

            else
                l_tub_wt := 0;
                l_flap_wt := 0;
                l_valve_wt := 0;
            end if;
               
				-- calculating total weight of item incluuding tube,flap,valve

            dbms_output.put_line(' Item: '
                                 || l_itm_wt
                                 || ' tube: '
                                 || l_tub_wt);
            dbms_output.put_line(' flap: '
                                 || l_flap_wt
                                 || ' valve: '
                                 || l_valve_wt);
            l_itm_wt := l_itm_wt + l_tub_wt + l_flap_wt + l_valve_wt;
            dbms_output.put_line(' l_item_wt: ' || l_itm_wt);

				--updating loadslip_detail table with gross_wt and gross_vol
            update loadslip_detail
            set
                gross_wt = l_itm_wt,
                gross_vol = item.vol
            where
                item_id = item.item_id
                and line_no = item.line_no
                and loadslip_id = item.loadslip_id;

        end if;

    end loop;

	    -- update loadslip weight and volume
		
    update loadslip a
    set
        ( a.weight,
          a.volume ) = (
            select
                sum(load_qty * gross_wt),
                sum(load_qty * gross_vol)
            from
                loadslip_detail
            where
                loadslip_id = a.loadslip_id
        )
    where
        a.loadslip_id = p_loadslip_id;

    select
        tt.gross_wt,
        tt.gross_vol
    into
        l_t_gross_wt,
        l_t_gross_vol
    from
        mt_truck_type   tt,
        shipment        s,
        loadslip        l
    where
        nvl(tt.variant1, 'NA') = nvl(s.variant_1, 'NA')
        and tt.truck_type = s.truck_type
        and s.shipment_id = l.shipment_id
        and l.loadslip_id = p_loadslip_id;

    update loadslip
    set
        weight_util = ( weight / l_t_gross_wt ),
        volume_util = ( volume / l_t_gross_vol )
    where
        loadslip_id = p_loadslip_id;
      
        -- to update shipment ith weight,volume,weight_util,volume_util 

    update shipment s
    set
        ( s.total_weight,
          s.total_volume,
          s.weight_util,
          s.volume_util ) = (
            select
                sum(weight),
                sum(volume),
                sum(weight_util),
                sum(volume_util)
            from
                loadslip
            where
                shipment_id = s.shipment_id
        )
    where
        s.shipment_id = (
            select
                shipment_id
            from
                loadslip
            where
                loadslip_id = p_loadslip_id
        );

    commit;
    
    
exception
    when others then
        dbms_output.put_line('Ignore Error');
        --raise;
end;

/
