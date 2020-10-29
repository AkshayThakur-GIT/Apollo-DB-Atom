--------------------------------------------------------
--  DDL for Package Body ATL_INTEGRATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_INTEGRATION_PKG" 
as

  procedure sync_item_master(
      p_data in clob)
  as
    -- Item Table variables
    l_item_id mt_item.item_id%type;
    l_material_class mt_item.item_classification%type;
    l_item_description mt_item.item_description%type;
    l_item_type mt_item.item_type%type;
    l_item_group mt_item.item_group%type;
    l_tte mt_item.tte%type;
    l_load_factor mt_item.load_factor%type;
    l_gross_wt mt_item.gross_wt%type;
    l_gross_wt_uom mt_item.gross_wt_uom%type;
    l_volume mt_item.volume%type;
    l_vol_uom mt_item.vol_uom%type;
    l_length mt_item.length%type;
    l_len_uom mt_item.len_uom%type;
    l_width mt_item.width%type;
    l_wd_uom mt_item.wd_uom%type;
    l_height mt_item.height%type;
    l_ht_uom mt_item.ht_uom%type;
    l_diameter mt_item.diameter%type;
    l_dm_uom mt_item.dm_uom%type;
    -- Item Sales BOM Table variables
    l_sales_bom_id mt_item_oe_bom.sales_sku%type;
    l_item_seq mt_item_rep_bom.item_seq%type;
    l_comp_qty mt_item_rep_bom.comp_qty%type;
    l_sales_sku_id mt_item_rep_bom.item_id%type;
    -- Item Sales BOM OE Table variables
    l_oe_code mt_item_oe_bom.oe_code%type;
    l_json_clob clob;
    l_json_obj json_object_t;
    l_item_master_obj json_object_t;
    l_item_master_arr json_array_t;
    l_item_obj json_object_t;
    l_item_arr json_array_t;
    l_item_sb_obj json_object_t;
    l_item_sb_arr json_array_t;
    l_item_sbd_obj json_object_t;
    l_item_sbd_arr json_array_t;
    l_mt_item_count pls_integer;
    l_mt_item_rep_bom_count pls_integer;
    l_count pls_integer;
    l_loop_cnt pls_integer := 1;
    procedure insert_to_mt_item_api(
        p_item_id          varchar2,
        p_materiap_class   varchar2,
        p_item_description varchar2,
        p_item_type        varchar2,
        p_item_group       varchar2,
        p_tte              number,
        p_load_factor      number,
        p_gross_wt         number,
        p_gross_wt_uom     varchar2,
        p_volume           number,
        p_vol_uom          varchar2,
        p_length           number,
        p_len_uom          varchar2,
        p_width            number,
        p_wd_uom           varchar2,
        p_height           number,
        p_ht_uom           varchar2,
        p_diameter         number,
        p_dm_uom           varchar2)
    as
    begin
      insert
      into mt_item
        (
          item_id,
          item_classification,
          item_description,
          item_type,
          item_group,
          tte,
          load_factor,
          gross_wt,
          gross_wt_uom,
          volume,
          vol_uom,
          length,
          len_uom,
          width,
          wd_uom,
          height,
          ht_uom,
          diameter,
          dm_uom,
          insert_user,
          insert_date,
          item_category
        )
        values
        (
          p_item_id,
          p_materiap_class,
          p_item_description,
          p_item_type,
          p_item_group,
          p_tte,
          --p_load_factor,
          nvl(p_tte,0) * atl_app_config.c_loadfactor,
          p_gross_wt,
          p_gross_wt_uom,
          p_volume,
          p_vol_uom,
          p_length,
          p_len_uom,
          p_width,
          p_wd_uom,
          p_height,
          p_ht_uom,
          p_diameter,
          p_dm_uom,
          'INTEGRATION',
          sysdate,
          nvl((select nvl(scm_group,'NA') from mt_material_group where material_group_id = p_item_group and rownum=1),'NA')
        );
      commit;
    end;
  procedure update_to_mt_item_api
    (
      p_item_id          varchar2,
      p_materiap_class   varchar2,
      p_item_description varchar2,
      p_item_type        varchar2,
      p_item_group       varchar2,
      p_tte              number,
      p_load_factor      number,
      p_gross_wt         number,
      p_gross_wt_uom     varchar2,
      p_volume           number,
      p_vol_uom          varchar2,
      p_length           number,
      p_len_uom          varchar2,
      p_width            number,
      p_wd_uom           varchar2,
      p_height           number,
      p_ht_uom           varchar2,
      p_diameter         number,
      p_dm_uom           varchar2
    )
  as
  begin
    update mt_item
    set item_classification= p_materiap_class,
      item_description     = p_item_description,
      item_type            = p_item_type,
      item_group           = p_item_group,
      tte                  = (case when p_tte is null then tte else p_tte end),
      load_factor          = nvl(p_tte,0) * atl_app_config.c_loadfactor,
      gross_wt             = p_gross_wt,
      gross_wt_uom         = p_gross_wt_uom,
      volume               = p_volume,
      vol_uom              = p_vol_uom,
      length               = p_length,
      len_uom              = p_len_uom,
      width                = p_width,
      wd_uom               = p_wd_uom,
      height               = p_height,
      ht_uom               = p_ht_uom,
      diameter             = p_diameter,
      dm_uom               = p_dm_uom,
      update_date          = sysdate,
      update_user          = 'INTEGRATION',
      item_category        = nvl((select nvl(scm_group,'NA') from mt_material_group where material_group_id = p_item_group and rownum=1),'NA')
    where item_id          = p_item_id;
    commit;
  end;
  procedure insert_to_mt_item_rep_bom_api(
      p_sales_bom_id varchar2,
      p_sales_sku_id varchar2,
      p_comp_qty     number,
      p_item_seq     number)
  as
  begin
    insert
    into mt_item_rep_bom
      (
        sales_sku,
        item_id,
        comp_qty,
        item_seq,
        insert_user,
        insert_date
      )
      values
      (
        p_sales_bom_id,
        p_sales_sku_id,
        p_comp_qty,
        p_item_seq,
        'INTEGRATION',
        sysdate
      );
    commit;
  end;
 /* procedure update_to_mt_item_rep_bom_api
    (
      p_sales_bom_id varchar2,
      p_sales_sku_id varchar2,
      p_comp_qty     number,
      p_item_seq     number
    )
  as
  begin
    update mt_item_rep_bom
    set comp_qty    = p_comp_qty,
      item_seq      = p_item_seq,
      update_date   = sysdate,
      update_user   = 'INTEGRATION'
    where sales_sku = p_sales_bom_id
    and item_id     = p_sales_sku_id;
    commit;
  end;
  */
  procedure insert_to_mt_item_oe_bom_api(
      p_sales_bom_id varchar2,
      p_sales_sku_id varchar2,
      p_comp_qty     number,
      p_item_seq     number,
      p_oe_code      varchar2)
  as
  begin
    insert
    into mt_item_oe_bom
      (
        sales_sku,
        item_id,
        comp_qty,
        item_seq,
        oe_code,
        insert_user,
        insert_date
      )
      values
      (
        p_sales_bom_id,
        p_sales_sku_id,
        p_comp_qty,
        p_item_seq,
        p_oe_code,
        'INTEGRATION',
        sysdate
      );
    commit;
  end;
  /*procedure update_to_mt_item_oe_bom_api
    (
      p_sales_bom_id varchar2,
      p_sales_sku_id varchar2,
      p_comp_qty     number,
      p_item_seq     number,
      p_oe_code      varchar2
    )
  as
  begin
    update mt_item_oe_bom
    set comp_qty    = p_comp_qty,
      item_seq      = p_item_seq,
      update_date   = sysdate,
      update_user   = 'INTEGRATION'
    where sales_sku = p_sales_bom_id
    and item_id     = p_sales_sku_id
    and oe_code     = p_oe_code;
    commit;
  end;
  */
begin
  --select file_data into l_json_clob from json_clob;
  -- parsing json data
  l_json_obj        := json_object_t(p_data);
  l_item_master_obj := l_json_obj.get_object('ItemMaster');
  -- get item array
  l_item_arr    := l_item_master_obj.get_array('Item');
  if l_item_arr is not null then
    --dbms_output.put_line('Item Array exists');
    l_count := l_item_arr.get_size;
    --dbms_output.put_line('Total Items '||l_count);
    for i in 0 .. l_item_arr.get_size - 1
    loop
      l_item_obj := treat(l_item_arr.get(i)
    as
      json_object_t);
      l_item_id          := l_item_obj.get_string('ItemId');
      l_material_class   := l_item_obj.get_string('MaterialClassification');
      l_item_description := l_item_obj.get_string('Description');
      l_item_type        := l_item_obj.get_string('MaterialType');
      l_item_group       := l_item_obj.get_string('MaterialGroup');
      l_tte              := l_item_obj.get_string('TTE');
      l_load_factor      := l_item_obj.get_string('LoadFactor');
      l_gross_wt         := l_item_obj.get_string('Weight');
      l_gross_wt_uom     := l_item_obj.get_string('WeightUOM');
      l_volume           := l_item_obj.get_string('Volume');
      l_vol_uom          := l_item_obj.get_string('VolumeUOM');
      l_length           := l_item_obj.get_string('Length');
      l_len_uom          := l_item_obj.get_string('LengthUOM');
      l_width            := l_item_obj.get_string('Width');
      l_wd_uom           := l_item_obj.get_string('WidthUOM');
      l_height           := l_item_obj.get_string('Height');
      l_ht_uom           := l_item_obj.get_string('HeightUOM');
      l_diameter         := l_item_obj.get_string('Diameter');
      l_dm_uom           := l_item_obj.get_string('DiameterUOM');
      select count(1) into l_count from mt_item where item_id=l_item_id;
      if l_count = 0 then
        insert_to_mt_item_api(l_item_id, l_material_class, l_item_description, l_item_type, l_item_group, l_tte, l_load_factor, l_gross_wt, l_gross_wt_uom, l_volume, l_vol_uom, l_length, l_len_uom, l_width, l_wd_uom, l_height, l_ht_uom, l_diameter, l_dm_uom);
      else
        update_to_mt_item_api(l_item_id, l_material_class, l_item_description, l_item_type, l_item_group, l_tte, l_load_factor, l_gross_wt, l_gross_wt_uom, l_volume, l_vol_uom, l_length, l_len_uom, l_width, l_wd_uom, l_height, l_ht_uom, l_diameter, l_dm_uom);
      end if;
      
      -- Delete REP BOM if already exists
      delete from mt_item_rep_bom 
      where sales_sku = (select sales_sku from mt_item_rep_bom 
      where item_id = l_item_id and rownum=1) 
      and l_material_class = 'TYRE';
      commit;
      
      
      -- get sales bom object
      l_item_sb_obj    := l_item_obj.get_object('SalesBOMDetails');
      if l_item_sb_obj is null then
        null;
        --dbms_output.put_line('No Sales BOM Object exists');
      else
        --dbms_output.put_line('Sales BOM Object exists');
        -- get sales BOM array
        l_item_sb_arr    := l_item_sb_obj.get_array('SalesBOM');
        if l_item_sb_arr is null then
          --dbms_output.put_line('No Sales BOM Array exists');
          l_item_sbd_obj := l_item_sb_obj.get_object('SalesBOM');
          l_sales_bom_id := l_item_sbd_obj.get_string('SalesBOMId');
          l_item_seq     := l_item_sbd_obj.get_string('ItemSeq');
          l_comp_qty     := l_item_sbd_obj.get_string('CompQty');
          l_oe_code      := l_item_sbd_obj.get_string('OECode');
          l_sales_sku_id := l_item_sbd_obj.get_string('SKUId');
          if l_oe_code   is not null and l_sales_sku_id is not null then
          --l_oe_code := lpad(l_oe_code,10,'0');
          
          -- Sales BOM ID to be created 
           l_sales_bom_id := l_item_id||'-'||l_oe_code;
           delete from mt_item_oe_bom 
            where sales_sku = l_sales_bom_id;
            commit;
            
            /*select count(1)
            into l_count
            from mt_item_oe_bom
            where sales_sku = l_sales_bom_id
            and item_id     = l_sales_sku_id
            and oe_code     = l_oe_code;*/
           -- if l_count      = 0 then
              insert_to_mt_item_oe_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq, l_oe_code);
           -- else
           --   update_to_mt_item_oe_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq, l_oe_code);
           -- end if;
          else
          if l_sales_sku_id is not null then
            /*select count(1)
            into l_count
            from mt_item_rep_bom
            where sales_sku = l_sales_bom_id
            and item_id     = l_sales_sku_id;*/
            
           -- if l_count      = 0 then
              insert_to_mt_item_rep_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq);
           -- else
           --   update_to_mt_item_rep_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq);
           -- end if;
          end if;
          end if;
        else
          --dbms_output.put_line('Sales BOM Array exists');
          --dbms_output.put_line('Sales BOM Count '||l_item_sb_arr.get_size);
          for j in 0 .. l_item_sb_arr.get_size - 1
          loop
            l_item_sbd_obj := treat(l_item_sb_arr.get(j)
          as
            json_object_t);
            l_sales_bom_id := l_item_sbd_obj.get_string('SalesBOMId');
            l_item_seq     := l_item_sbd_obj.get_string('ItemSeq');
            l_comp_qty     := l_item_sbd_obj.get_string('CompQty');
            l_oe_code      := l_item_sbd_obj.get_string('OECode');
            l_sales_sku_id := l_item_sbd_obj.get_string('SKUId');
            if l_oe_code   is not null and l_sales_sku_id is not null then
              --l_oe_code := lpad(l_oe_code,10,'0');
              
              -- Sales BOM ID to be created 
             l_sales_bom_id := l_item_id||'-'||l_oe_code;
             --dbms_output.put_line('PaaS Sales BOM ID for OE '||l_sales_bom_id);
             
             if l_loop_cnt = 1 then
             delete from mt_item_oe_bom 
              where sales_sku = l_sales_bom_id;
              --dbms_output.put_line('Delete .. done');
              commit;
              end if;
              
              /*select count(1)
              into l_count
              from mt_item_oe_bom
              where sales_sku = l_sales_bom_id
              and item_id     = l_sales_sku_id
              and oe_code     = l_oe_code;*/
              
             -- if l_count      = 0 then
                insert_to_mt_item_oe_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq, l_oe_code);
             -- else
             --   update_to_mt_item_oe_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq, l_oe_code);
             -- end if;
             l_loop_cnt := l_loop_cnt +1;
            else
            if l_sales_sku_id is not null then
              /*select count(1)
              into l_count
              from mt_item_rep_bom
              where sales_sku = l_sales_bom_id
              and item_id     = l_sales_sku_id;*/
              
             -- if l_count      = 0 then
                insert_to_mt_item_rep_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq);
             -- else
             --   update_to_mt_item_rep_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq);
             -- end if;
            end if;
            end if;
          end loop;
        end if;
      end if;
    end loop;
  else
    --dbms_output.put_line('No Item Array exists');
    l_item_obj         := l_item_master_obj.get_object('Item');
    l_item_id          := l_item_obj.get_string('ItemId');
    l_material_class   := l_item_obj.get_string('MaterialClassification');
    l_item_description := l_item_obj.get_string('Description');
    l_item_type        := l_item_obj.get_string('MaterialType');
    l_item_group       := l_item_obj.get_string('MaterialGroup');
    l_tte              := l_item_obj.get_string('TTE');
    l_load_factor      := l_item_obj.get_string('LoadFactor');
    l_gross_wt         := l_item_obj.get_string('Weight');
    l_gross_wt_uom     := l_item_obj.get_string('WeightUOM');
    l_volume           := l_item_obj.get_string('Volume');
    l_vol_uom          := l_item_obj.get_string('VolumeUOM');
    l_length           := l_item_obj.get_string('Length');
    l_len_uom          := l_item_obj.get_string('LengthUOM');
    l_width            := l_item_obj.get_string('Width');
    l_wd_uom           := l_item_obj.get_string('WidthUOM');
    l_height           := l_item_obj.get_string('Height');
    l_ht_uom           := l_item_obj.get_string('HeightUOM');
    l_diameter         := l_item_obj.get_string('Diameter');
    l_dm_uom           := l_item_obj.get_string('DiameterUOM');
    select count(1) into l_count from mt_item where item_id=l_item_id;
    if l_count = 0 then
      insert_to_mt_item_api(l_item_id, l_material_class, l_item_description, l_item_type, l_item_group, l_tte, l_load_factor, l_gross_wt, l_gross_wt_uom, l_volume, l_vol_uom, l_length, l_len_uom, l_width, l_wd_uom, l_height, l_ht_uom, l_diameter, l_dm_uom);
    else
      update_to_mt_item_api(l_item_id, l_material_class, l_item_description, l_item_type, l_item_group, l_tte, l_load_factor, l_gross_wt, l_gross_wt_uom, l_volume, l_vol_uom, l_length, l_len_uom, l_width, l_wd_uom, l_height, l_ht_uom, l_diameter, l_dm_uom);
    end if;
    
     -- Delete REP BOM if already exists
      delete from mt_item_rep_bom 
      where sales_sku = (select sales_sku from mt_item_rep_bom 
      where item_id = l_item_id and rownum=1) 
      and l_material_class = 'TYRE';
      commit;
    
    -- get sales bom object
    l_item_sb_obj    := l_item_obj.get_object('SalesBOMDetails');
    if l_item_sb_obj is null then
      null;
      --dbms_output.put_line('No Sales BOM Object exists');
    else
      --dbms_output.put_line('Sales BOM Object exists');
      -- get sales BOM array
      l_item_sb_arr    := l_item_sb_obj.get_array('SalesBOM');
      if l_item_sb_arr is null then
        --dbms_output.put_line('No Sales BOM Array exists');
        l_item_sbd_obj := l_item_sb_obj.get_object('SalesBOM');
        l_sales_bom_id := l_item_sbd_obj.get_string('SalesBOMId');
        l_item_seq     := l_item_sbd_obj.get_string('ItemSeq');
        l_comp_qty     := l_item_sbd_obj.get_string('CompQty');
        l_oe_code      := l_item_sbd_obj.get_string('OECode');
        l_sales_sku_id := l_item_sbd_obj.get_string('SKUId');
        if l_oe_code   is not null and l_sales_sku_id is not null then
         --l_oe_code := lpad(l_oe_code,10,'0');
         
         -- Sales BOM ID to be created 
             l_sales_bom_id := l_item_id||'-'||l_oe_code;
             --dbms_output.put_line('PaaS Sales BOM ID for OE '||l_sales_bom_id);
             
             delete from mt_item_oe_bom 
              where sales_sku = l_sales_bom_id;
              commit;
         
          /*select count(1)
          into l_count
          from mt_item_oe_bom
          where sales_sku = l_sales_bom_id
          and item_id     = l_sales_sku_id
          and oe_code     = l_oe_code;*/
          
         -- if l_count      = 0 then
            insert_to_mt_item_oe_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq, l_oe_code);
         -- else
         --   update_to_mt_item_oe_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq, l_oe_code);
         -- end if;
        else
        if l_sales_sku_id is not null then
          /*select count(1)
          into l_count
          from mt_item_rep_bom
          where sales_sku = l_sales_bom_id
          and item_id     = l_sales_sku_id;*/
          
         -- if l_count      = 0 then
            insert_to_mt_item_rep_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq);
         -- else
         --   update_to_mt_item_rep_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq);
         -- end if;
        end if;
        end if;
        --dbms_output.put_line('Sales BOM ID : '||l_item_sbd_obj.get_string('SalesBOMId'));
      else
        --dbms_output.put_line('Sales BOM Array exists');
        -- get sales BOM array
        l_item_sb_arr := l_item_sb_obj.get_array('SalesBOM');
        --dbms_output.put_line('Data Count '||l_item_sb_arr.get_size);
        for j in 0 .. l_item_sb_arr.get_size - 1
        loop
          l_item_sbd_obj := treat(l_item_sb_arr.get(j)
        as
          json_object_t);
          l_sales_bom_id := l_item_sbd_obj.get_string('SalesBOMId');
          l_item_seq     := l_item_sbd_obj.get_string('ItemSeq');
          l_comp_qty     := l_item_sbd_obj.get_string('CompQty');
          l_oe_code      := l_item_sbd_obj.get_string('OECode');
          l_sales_sku_id := l_item_sbd_obj.get_string('SKUId');
          if l_oe_code   is not null and l_sales_sku_id is not null then
            --l_oe_code := lpad(l_oe_code,10,'0');
            
            -- Sales BOM ID to be created 
             l_sales_bom_id := l_item_id||'-'||l_oe_code;
            
             if l_loop_cnt = 1 then
             delete from mt_item_oe_bom 
              where sales_sku =l_sales_bom_id;
              --dbms_output.put_line('Delete .. done');
              commit;
            end if;
            
            /*select count(1)
            into l_count
            from mt_item_oe_bom
            where sales_sku = l_sales_bom_id
            and item_id     = l_sales_sku_id
            and oe_code     = l_oe_code;*/
            
           -- if l_count      = 0 then
              insert_to_mt_item_oe_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq, l_oe_code);
           -- else
           --   update_to_mt_item_oe_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq, l_oe_code);
           -- end if;
           l_loop_cnt := l_loop_cnt+1;
          else
          if l_sales_sku_id is not null then
            /*select count(1)
            into l_count
            from mt_item_rep_bom
            where sales_sku = l_sales_bom_id
            and item_id     = l_sales_sku_id;*/
            
           -- if l_count      = 0 then
              insert_to_mt_item_rep_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq);
           -- else
           --   update_to_mt_item_rep_bom_api(l_sales_bom_id, l_sales_sku_id, l_comp_qty, l_item_seq);
           --  end if;
          end if;
            
          end if;
        end loop;
      end if;
    end if;
  end if;
end;

/*
  procedure sync_item_master(
      p_data in clob)
  as
    l_json_clob clob;
    l_count pls_integer;
  begin    
    --select file_data into l_json_clob from json_clob;    
    -- parsing json data
    for i in (select * from json_table(p_data format json , '$'
             columns (
               nested             path '$.ItemMaster.Item[*]'
                 columns(
                   itemid                  varchar2 path '$.ItemId',
                   description             varchar2 path '$.Description',
                   materialclassification  varchar2 path '$.MaterialClassification',
                   materialtype            varchar2 path '$.MaterialType',
                   materialgroup           varchar2 path '$.MaterialGroup',
                   tte                     number   path '$.TTE',
                   loadfactor              number   path '$.LoadFactor',
                   weight                  number   path '$.Weight',
                   weightuom               varchar2 path '$.WeightUOM',
                   vol                     number   path '$.Volume',
                   volumeuom               varchar2 path '$.VolumeUOM',
                   len                     number   path '$.Length',
                   lengthuom               varchar2 path '$.LengthUOM',
                   width                   number   path '$.Width',
                   widthuom                varchar2 path '$.WidthUOM',
                   height                  number   path '$.Height',
                   heightuom               varchar2 path '$.HeightUOM',
                   diameter                number   path '$.Diameter',
                   diameteruom             varchar2 path '$.DiameterUOM',
                   nested path '$.SalesBOMDetails.SalesBOM[*]'
                     columns (
                       salesbomid varchar2 path '$.SalesBOMId',
                       skuid      varchar2 path '$.SKUId',
                       itemseq    number   path '$.ItemSeq',
                       compqty    number   path '$.CompQty',
                       oecode     varchar2 path '$.OECode'                       
                       )))))
    loop
      select count(1) into l_count from mt_item where item_id=i.itemid;
      if l_count = 0 then
        insert
        into mt_item
          (
            item_id,
            item_classification,
            item_description,
            item_type,
            item_group,
            tte,
            load_factor,
            gross_wt,
            gross_wt_uom,
            volume,
            vol_uom,
            length,
            len_uom,
            width,
            wd_uom,
            height,
            ht_uom,
            diameter,
            dm_uom,
            insert_user,
            insert_date
          )
          values
          (
            i.itemid,
            i.materialclassification,
            i.description,
            i.materialtype,
            i.materialgroup,
            i.tte,
            i.loadfactor,
            i.weight,
            i.weightuom,
            i.vol,
            i.volumeuom,
            i.len,
            i.lengthuom,
            i.width,
            i.widthuom,
            i.height,
            i.heightuom,
            i.diameter,
            i.diameteruom,
            'INTEGRATION',
            sysdate
          );
        commit;
        if i.salesbomid is not null then
          select count(1)
          into l_count
          from mt_item_rep_bom
          where sales_sku = i.salesbomid
          and item_id     = i.skuid;
          if l_count      = 0 then
            insert
            into mt_item_rep_bom
              (
                sales_sku,
                item_id,
                comp_qty,
                item_seq,
                insert_user,
                insert_date
              )
              values
              (
                i.salesbomid,
                i.skuid,
                i.compqty,
                i.itemseq,
                'INTEGRATION',
                sysdate
              );
            commit;
          else
            update mt_item_rep_bom
            set comp_qty    = i.compqty,
              item_seq      = i.itemseq,
              update_date   = sysdate,
              update_user   = 'INTEGRATION'
            where sales_sku = i.salesbomid
            and item_id     = i.skuid;
            commit;
          end if;
          if i.oecode is not null then
            select count(1)
            into l_count
            from mt_item_oe_bom
            where sales_sku = i.salesbomid
            and item_id     = i.skuid
            and oe_code     = i.oecode;
            if l_count      = 0 then
              insert
              into mt_item_oe_bom
                (
                  sales_sku,
                  item_id,
                  comp_qty,
                  item_seq,
                  oe_code,
                  insert_user,
                  insert_date
                )
                values
                (
                  i.salesbomid,
                  i.skuid,
                  i.compqty,
                  i.itemseq,
                  i.oecode,
                  'INTEGRATION',
                  sysdate
                );
              commit;
            else
              update mt_item_oe_bom
              set comp_qty    = i.compqty,
                item_seq      = i.itemseq,
                update_date   = sysdate,
                update_user   = 'INTEGRATION'
              where sales_sku = i.salesbomid
              and item_id     = i.skuid
              and oe_code     = i.oecode;
              commit;
            end if;
          end if;
        end if;
      else
        update mt_item
        set item_id           = i.itemid,
          item_classification = i.materialclassification,
          item_description    = i.description,
          item_type           = i.materialtype,
          item_group          = i.materialgroup,
          tte                 = i.tte,
          load_factor         = i.loadfactor,
          gross_wt            = i.weight,
          gross_wt_uom        = i.weightuom,
          volume              = i.vol,
          vol_uom             = i.volumeuom,
          length              = i.len,
          len_uom             = i.lengthuom,
          width               = i.width,
          wd_uom              = i.widthuom,
          height              = i.height,
          ht_uom              = i.heightuom,
          diameter            = i.diameter,
          dm_uom              = i.diameteruom,
          update_date         = sysdate,
          update_user         = 'INTEGRATION'
        where item_id         = i.itemid;
        commit;
        if i.salesbomid is not null then
          select count(1)
          into l_count
          from mt_item_rep_bom
          where sales_sku = i.salesbomid
          and item_id     = i.skuid;
          if l_count      = 0 then
            insert
            into mt_item_rep_bom
              (
                sales_sku,
                item_id,
                comp_qty,
                item_seq,
                insert_user,
                insert_date
              )
              values
              (
                i.salesbomid,
                i.skuid,
                i.compqty,
                i.itemseq,
                'INTEGRATION',
                sysdate
              );
            commit;
          else
            update mt_item_rep_bom
            set comp_qty    = i.compqty,
              item_seq      = i.itemseq,
              update_date   = sysdate,
              update_user   = 'INTEGRATION'
            where sales_sku = i.salesbomid
            and item_id     = i.skuid;
            commit;
          end if;
          if i.oecode is not null then
            select count(1)
            into l_count
            from mt_item_oe_bom
            where sales_sku = i.salesbomid
            and item_id     = i.skuid
            and oe_code     = i.oecode;
            if l_count      = 0 then
              insert
              into mt_item_oe_bom
                (
                  sales_sku,
                  item_id,
                  comp_qty,
                  item_seq,
                  oe_code,
                  insert_user,
                  insert_date
                )
                values
                (
                  i.salesbomid,
                  i.skuid,
                  i.compqty,
                  i.itemseq,
                  i.oecode,
                  'INTEGRATION',
                  sysdate
                );
              commit;
            else
              update mt_item_oe_bom
              set comp_qty    = i.compqty,
                item_seq      = i.itemseq,
                update_date   = sysdate,
                update_user   = 'INTEGRATION'
              where sales_sku = i.salesbomid
              and item_id     = i.skuid
              and oe_code     = i.oecode;
              commit;
            end if;
          end if;
        end if;
      end if;
    end loop;
  end;

*/

  procedure sync_item_master(
      p_data in clob,
      p_type in varchar2)
  as
    l_count pls_integer;
    l_mt_item_pw_count pls_integer;
    l_mt_item_plant_count pls_integer;
    l_date date;
    -- Item Plant Table variables
    l_item_id mt_item_plant_weight.item_id%type;
    l_plant_code mt_item_plant_weight.plant_code%type;
    l_eff_date mt_item_plant_weight.effective_date%type;
    l_wt mt_item_plant_weight.weight%type;
    l_wt_uom mt_item_plant_weight.weight_uom%type;
    l_json_clob clob;
    l_json_obj json_object_t;
    l_item_master_obj json_object_t;
    l_item_master_arr json_array_t;
    l_item_obj json_object_t;
    l_item_arr json_array_t;
    l_item_plant_obj json_object_t;
    l_item_plant_arr json_array_t;
    l_item_pd_obj json_object_t;
    l_item_pd json_array_t;
  begin
    -- parsing json data
    l_json_obj        := json_object_t(p_data);
    l_item_master_obj := l_json_obj.get_object('ItemMaster');
    -- get item array
    l_item_arr    := l_item_master_obj.get_array('Item');
    if l_item_arr is not null then
      --dbms_output.put_line('Item Array exists');
      l_count := l_item_arr.get_size;
      --dbms_output.put_line('Total Items '||l_count);
      for i in 0 .. l_item_arr.get_size - 1
      loop
        l_item_obj := treat(l_item_arr.get(i)
      as
        json_object_t);
        l_item_id := l_item_obj.get_string('ItemId');
        -- get plant object
        l_item_plant_obj    := l_item_obj.get_object('PlantDetails');
        if l_item_plant_obj is null then
          null;
          --dbms_output.put_line('No Plant Object exists');
        else
          --dbms_output.put_line('Plant Object exists');
          -- get plant array
          l_item_plant_arr    := l_item_plant_obj.get_array('Plant');
          if l_item_plant_arr is null then
            --dbms_output.put_line('No Plant Array exists');
            l_item_pd_obj := l_item_plant_obj.get_object('Plant');
            l_plant_code  := l_item_pd_obj.get_string('PlantCode');
            l_eff_date    := l_item_pd_obj.get_string('EffectiveDate');
            l_wt          := l_item_pd_obj.get_string('Weight');
            l_wt_uom      := l_item_pd_obj.get_string('WeightUOM');
            l_date        := trunc(to_date(l_eff_date,'DD-MON-YY HH24:MI:SS'));
            select count(1)
            into l_count
            from mt_item_plant_weight
            where plant_code     = l_plant_code
            and item_id          = l_item_id
            and (effective_date) = (l_date);
            if l_count           = 0 then
              insert
              into mt_item_plant_weight
                (
                  plant_code,
                  item_id,
                  effective_date,
                  weight,
                  weight_uom,
                  insert_user,
                  insert_date
                )
                values
                (
                  l_plant_code,
                  l_item_id,
                  l_date,
                  l_wt,
                  l_wt_uom,
                  'INTEGRATION',
                  sysdate
                );
            else
              update mt_item_plant_weight
              set weight           = l_wt,
                weight_uom         = l_wt_uom,
                update_date        = sysdate,
                update_user        = 'INTEGRATION'
              where plant_code     = l_plant_code
              and (effective_date) = (l_date)
              and item_id          = l_item_id;
            end if;
          else
            --dbms_output.put_line('Plant Array exists');
            for j in 0 .. l_item_plant_arr.get_size - 1
            loop
              l_item_pd_obj := treat(l_item_plant_arr.get(j)
            as
              json_object_t);
              l_plant_code := l_item_pd_obj.get_string('PlantCode');
              l_eff_date   := l_item_pd_obj.get_string('EffectiveDate');
              l_wt         := l_item_pd_obj.get_string('Weight');
              l_wt_uom     := l_item_pd_obj.get_string('WeightUOM');
              l_date       := trunc(to_date(l_eff_date,'DD-MON-YY HH24:MI:SS'));
              select count(1)
              into l_count
              from mt_item_plant_weight
              where plant_code     = l_plant_code
              and item_id          = l_item_id
              and (effective_date) = (l_date);
              if l_count           = 0 then
                insert
                into mt_item_plant_weight
                  (
                    plant_code,
                    item_id,
                    effective_date,
                    weight,
                    weight_uom,
                    insert_user,
                    insert_date
                  )
                  values
                  (
                    l_plant_code,
                    l_item_id,
                    l_date,
                    l_wt,
                    l_wt_uom,
                    'INTEGRATION',
                    sysdate
                  );
              else
                update mt_item_plant_weight
                set weight           = l_wt,
                  weight_uom         = l_wt_uom,
                  update_date        = sysdate,
                  update_user        = 'INTEGRATION'
                where plant_code     = l_plant_code
                and (effective_date) = (l_date)
                and item_id          = l_item_id;
              end if;
            end loop;
          end if;
        end if;
      end loop;
    else
      --dbms_output.put_line('No Item Array exists');
      l_item_obj := l_item_master_obj.get_object('Item');
      l_item_id  := l_item_obj.get_string('ItemId');
      -- get plant object
      l_item_plant_obj    := l_item_obj.get_object('PlantDetails');
      if l_item_plant_obj is null then
        null;
        --dbms_output.put_line('No Plant Object exists');
      else
        --dbms_output.put_line('Plant Object exists');
        -- get plant array
        l_item_plant_arr    := l_item_plant_obj.get_array('Plant');
        if l_item_plant_arr is null then
          --dbms_output.put_line('No Plant Array exists');
          l_item_pd_obj := l_item_plant_obj.get_object('Plant');
          l_plant_code  := l_item_pd_obj.get_string('PlantCode');
          l_eff_date    := l_item_pd_obj.get_string('EffectiveDate');
          l_wt          := l_item_pd_obj.get_string('Weight');
          l_wt_uom      := l_item_pd_obj.get_string('WeightUOM');
          l_date        := trunc(to_date(l_eff_date,'DD-MON-YY HH24:MI:SS'));
          select count(1)
          into l_count
          from mt_item_plant_weight
          where plant_code     = l_plant_code
          and item_id          = l_item_id
          and (effective_date) = (l_date);
          if l_count           = 0 then
            insert
            into mt_item_plant_weight
              (
                plant_code,
                item_id,
                effective_date,
                weight,
                weight_uom,
                insert_user,
                insert_date
              )
              values
              (
                l_plant_code,
                l_item_id,
                l_date,
                l_wt,
                l_wt_uom,
                'INTEGRATION',
                sysdate
              );
          else
            update mt_item_plant_weight
            set weight           = l_wt,
              weight_uom         = l_wt_uom,
              update_date        = sysdate,
              update_user        = 'INTEGRATION'
            where plant_code     = l_plant_code
            and (effective_date) = (l_date)
            and item_id          = l_item_id;
          end if;
        else
          --dbms_output.put_line('Plant Array exists');
          for j in 0 .. l_item_plant_arr.get_size - 1
          loop
            l_item_pd_obj := treat(l_item_plant_arr.get(j)
          as
            json_object_t);
            l_plant_code := l_item_pd_obj.get_string('PlantCode');
            l_eff_date   := l_item_pd_obj.get_string('EffectiveDate');
            l_wt         := l_item_pd_obj.get_string('Weight');
            l_wt_uom     := l_item_pd_obj.get_string('WeightUOM');
            l_date       := trunc(to_date(l_eff_date,'DD-MON-YY HH24:MI:SS'));
            select count(1)
            into l_count
            from mt_item_plant_weight
            where plant_code     = l_plant_code
            and item_id          = l_item_id
            and (effective_date) = (l_date);
            if l_count           = 0 then
              insert
              into mt_item_plant_weight
                (
                  plant_code,
                  item_id,
                  effective_date,
                  weight,
                  weight_uom,
                  insert_user,
                  insert_date
                )
                values
                (
                  l_plant_code,
                  l_item_id,
                  l_date,
                  l_wt,
                  l_wt_uom,
                  'INTEGRATION',
                  sysdate
                );
            else
              update mt_item_plant_weight
              set weight           = l_wt,
                weight_uom         = l_wt_uom,
                update_date        = sysdate,
                update_user        = 'INTEGRATION'
              where plant_code     = l_plant_code
              and (effective_date) = (l_date)
              and item_id          = l_item_id;
            end if;
          end loop;
        end if;
      end if;
    end if;
    commit;
  end;

/*  
  procedure sync_item_master(
      p_data in clob,
      p_type in varchar2)
  as
    l_count pls_integer;
    l_date date;
  begin
    for i in (select * from json_table(p_data format json , '$'
             columns (
               nested             path '$.ItemMaster.Item[*]'
                 columns(
                   itemid                  varchar2 path '$.ItemId',                   
                   nested path '$.PlantDetails.Plant[*]'
                     columns (
                       plantcode     varchar2 path '$.PlantCode',
                       weight        number   path '$.Weight',
                       weightuom     varchar2 path '$.WeightUOM',
                       effectivedate varchar2 path '$.EffectiveDate')))))
    loop
      l_date := trunc(to_date(i.effectivedate,'DD-MON-YY HH24:MI:SS'));
      select count(1)
      into l_count
      from mt_item_plant_weight
      where plant_code     = i.plantcode
      and item_id          = i.itemid
      and (effective_date) = (l_date);
      if l_count           = 0 then
        insert
        into mt_item_plant_weight
          (
            plant_code,
            item_id,
            effective_date,
            weight,
            weight_uom,
            insert_user,
            insert_date
          )
          values
          (
            i.plantcode,
            i.itemid,
            l_date,
            i.weight,
            i.weightuom,
            'INTEGRATION',
            sysdate
          );
        commit;
      else
        update mt_item_plant_weight
        set weight           = i.weight,
          weight_uom         = i.weightuom,
          update_date        = sysdate,
          update_user        = 'INTEGRATION'
        where plant_code     = i.plantcode
        and (effective_date) = (l_date)
        and item_id          = i.itemid;
        commit;
      end if;
    end loop;
  end;
*/
  procedure sync_location_master(
      p_data in clob)
  as
    l_count pls_integer;
    l_json_clob clob;
    l_json_obj json_object_t;
    l_location_master_obj json_object_t;
    l_location_obj json_object_t;
    l_location_add_obj json_object_t;
    l_location_con_obj json_object_t;
    l_location_st_obj json_object_t;
    l_location_st_arr json_array_t;
    l_location_std_obj json_object_t;
    l_location_std_arr json_array_t;
    l_location_id mt_location.location_id%type;
    l_location_desc mt_location.location_desc%type;
    l_location_type mt_location.location_type%type;
    l_is_active mt_location.is_active%type;
    l_location_add mt_location.location_address%type;
    l_location_city mt_location.city%type;
    l_location_country mt_location.country%type;
    l_location_post_code mt_location.postal_code%type;
    l_location_lat number;
    l_location_lon number;
    l_location_state mt_location.state%type;
    l_location_state_code mt_location.state_code%type;
    l_location_con_num mt_contact.mobile%type;
    l_location_con_email mt_contact.email%type;
    l_location_inds_key mt_supplier.industry_key%type;
    l_customer_type mt_customer.cust_type%type;
    l_location_ship_to mt_customer.cust_id%type;
    l_location_acc_grp mt_customer.cust_acct_grp%type;
    l_location_del_term mt_customer.delivery_terms%type;
    
    l_gst_no mt_location.gst_no%type;
    l_gst_state mt_location.gst_state%type;
    l_panno mt_location.pan_no%type;
    
  begin
     --select file_data into l_json_clob from json_clob;
    -- parsing json data
    l_json_obj            := json_object_t(p_data);
    l_location_master_obj := l_json_obj.get_object('LocationMaster');
    -- get location object
    l_location_obj  := l_location_master_obj.get_object('Location');
    l_location_id   := l_location_obj.get_string('LocationId');
    l_location_desc := l_location_obj.get_string('Description');
    l_location_type := l_location_obj.get_string('LocationType');
    l_is_active     := l_location_obj.get_string('IsActive');
    
    l_gst_no := l_location_obj.get_string('GSTNo');
    l_gst_state := l_location_obj.get_string('GSTState');
    l_panno     := l_location_obj.get_string('PANNo');
    
    
    --dbms_output.put_line('Location Details : '||l_location_id||' '||l_location_desc||' '||l_location_type||' '||l_is_active);
    -- get address object
    l_location_add_obj    := l_location_obj.get_object('Address');
    l_location_add        := l_location_add_obj.get_string('AddressLine');
    l_location_city       := l_location_add_obj.get_string('City');
    l_location_country    := l_location_add_obj.get_string('Country');
    l_location_post_code  := l_location_add_obj.get_string('PostalCode');
    l_location_lat        := l_location_add_obj.get_string('Lat');
    l_location_lon        := l_location_add_obj.get_string('Lon');
    l_location_state      := l_location_add_obj.get_string('State');
    l_location_state_code := l_location_add_obj.get_string('StateCode');
    --dbms_output.put_line('Address Data '||l_location_state_code);
    if l_location_type not in ('SUPPLIER','CUSTOMER') then
      select count(1) into l_count from mt_location where location_id=l_location_id;
      if l_count = 0 then
        -- insert data
        insert
        into mt_location
          (
            location_id,
            location_desc,
            location_type,
            location_address,
            city,
            state,
            postal_code,
            country,
            is_active,
            lat,
            lon,
            insert_user,
            insert_date,
            gst_no,
            gst_state,
            pan_no,
            state_code
          )
          values
          (
            l_location_id,
            l_location_desc,
            --l_location_type,
            (select case when l_location_type = 'EXT_WH' then 'RDC' else l_location_type end from dual),
            l_location_add,
            l_location_city,
            l_location_state,
            l_location_post_code,
            l_location_country,
            l_is_active,
            l_location_lat,
            l_location_lon,
            'INTEGRATION',
            sysdate,
            l_gst_no,
            l_gst_state,
            l_panno,
            l_location_state_code
          );
      
      if l_location_type = 'EXT_WH' then
      
      insert
        into MT_EXT_WAREHOUSE
          (
            location_id,
            location_desc,
            location_type,
            location_address,
            city,
            state,
            postal_code,
            country,
            is_active,
            lat,
            lon,
            insert_user,
            insert_date
          )
          values
          (
            l_location_id,
            l_location_desc,
            'EXT_WH',
            l_location_add,
            l_location_city,
            l_location_state,
            l_location_post_code,
            l_location_country,
            l_is_active,
            l_location_lat,
            l_location_lon,
            'INTEGRATION',
            sysdate
          );
      
      
      end if;
      
      else
        -- update data
        update mt_location
        set location_desc  = l_location_desc,
          location_type    = (select case when l_location_type = 'EXT_WH' then 'RDC' else l_location_type end from dual),
          location_address = l_location_add,
          city             = l_location_city,
          state            = l_location_state,
          postal_code      = l_location_post_code,
          country          = l_location_country,
          --is_active        = nvl(l_is_active,'Y'),
          is_active        = l_is_active,
          lat              = l_location_lat,
          lon              = l_location_lon,
          update_user      = 'INTEGRATION',
          update_date      = sysdate,
          gst_no = l_gst_no,
          gst_state = l_gst_state,
          pan_no = l_panno,
          state_code = l_location_state_code
        where location_id  =l_location_id;
        
        if l_location_type = 'EXT_WH' then
        
        update MT_EXT_WAREHOUSE
        set location_desc  = l_location_desc,
          location_type    = 'EXT_WH',
          location_address = l_location_add,
          city             = l_location_city,
          state            = l_location_state,
          postal_code      = l_location_post_code,
          country          = l_location_country,
          is_active        = nvl(l_is_active,'Y'),
          lat              = l_location_lat,
          lon              = l_location_lon,
          update_user      = 'INTEGRATION',
          update_date      = sysdate
        where location_id  =l_location_id;
        
        end if;
 
 
      end if;
    elsif l_location_type  = 'SUPPLIER' then
      l_location_inds_key := l_location_obj.get_string('IndustryKey');
      select count(1) into l_count from mt_supplier where supplier_id=l_location_id;
      if l_count = 0 then
        -- insert data
        insert
        into mt_supplier
          (
            supplier_id,
            supplier_name,
            supplier_address,
            city,
            state,
            postal_code,
            country,
            is_active,
            lat,
            lon,
            industry_key,
            insert_user,
            insert_date,
            state_code
          )
          values
          (
            l_location_id,
            l_location_desc,
            l_location_add,
            l_location_city,
            l_location_state,
            l_location_post_code,
            l_location_country,
            l_is_active,
            l_location_lat,
            l_location_lon,
            l_location_inds_key,
            'INTEGRATION',
            sysdate,
            l_location_state_code
          );
      else
        -- update data
        update mt_supplier
        set supplier_name  = l_location_desc,
          supplier_address = l_location_add,
          city             = l_location_city,
          state            = l_location_state,
          postal_code      = l_location_post_code,
          country          = l_location_country,
          is_active        = nvl(l_is_active,'Y'),
          lat              = l_location_lat,
          lon              = l_location_lon,
          industry_key     = l_location_inds_key,
          update_user      = 'INTEGRATION',
          update_date      = sysdate,
          state_code = l_location_state_code
        where supplier_id  =l_location_id;
      end if;
    elsif l_location_type  = 'CUSTOMER' then
    dbms_output.put_line('in customer');
      l_location_acc_grp  := l_location_obj.get_string('AccountGroup');
      l_location_del_term := l_location_obj.get_string('DeliveryTerms');
      l_customer_type     := l_location_obj.get_string('CustomerType');
      select count(1) into l_count from mt_customer where cust_id=l_location_id;
      if l_count = 0 then
        -- insert data
        insert
        into mt_customer
          (
            cust_id,
            cust_name,
            cust_acct_grp,
            cust_address,
            city,
            state,
            postal_code,
            country,
            is_active,
            lat,
            lon,
            delivery_terms,
            cust_type,
            insert_user,
            insert_date,
            gst_no,
            gst_state,
            pan_no,
            state_code
          )
          values
          (
            l_location_id,
            l_location_desc,
            l_location_acc_grp,
            l_location_add,
            l_location_city,
            l_location_state,
            l_location_post_code,
            l_location_country,
            l_is_active,
            l_location_lat,
            l_location_lon,
            l_location_del_term,
            l_customer_type,
            'INTEGRATION',
            sysdate,
            l_gst_no,
            l_gst_state,
            l_panno,
            l_location_state_code
          );
        -- get ship to details object
        l_location_st_obj    := l_location_obj.get_object('ShipToDetails');
        if l_location_st_obj is not null then
          --dbms_output.put_line('Ship To Details Object exists');
          -- get ship to array
          l_location_std_arr    := l_location_st_obj.get_array('ShipTo');
          if l_location_std_arr is null then
            --dbms_output.put_line('No Ship To Array exists');
            l_location_std_obj := l_location_st_obj.get_object('ShipTo');
            l_location_ship_to := l_location_std_obj.get_string('ShipToId');
            select count(1)
            into l_count
            from mt_customer_ship_to
            where cust_id  = l_location_id
            and ship_to_id = l_location_ship_to;
            if l_count    <> 0 then
              null;
            else
              -- insert data
              insert
              into mt_customer_ship_to
                (
                  cust_id,
                  ship_to_id,
                  insert_user,
                  insert_date
                )
                values
                (
                  l_location_id,
                  l_location_ship_to,
                  'INTEGRATION',
                  sysdate
                );
            end if;
          else
            --dbms_output.put_line('Ship To Array exists');
            -- get ship to array
            l_location_std_arr := l_location_st_obj.get_array('ShipTo');
            for i in 0 .. l_location_std_arr.get_size - 1
            loop
              l_location_std_obj := treat
              (
                l_location_std_arr.get(i)
              as
                json_object_t
              )
              ;
              l_location_ship_to := l_location_std_obj.get_string('ShipToId');
              select count(1)
              into l_count
              from mt_customer_ship_to
              where cust_id  = l_location_id
              and ship_to_id = l_location_ship_to;
              if l_count    <> 0 then
                null;
              else
                -- insert data
                insert
                into mt_customer_ship_to
                  (
                    cust_id,
                    ship_to_id,
                    insert_user,
                    insert_date
                  )
                  values
                  (
                    l_location_id,
                    l_location_ship_to,
                    'INTEGRATION',
                    sysdate
                  );
              end if;
            end loop;
          end if;
        end if;
      else
       
        update mt_customer
        set cust_name    = l_location_desc,
          cust_acct_grp  = l_location_acc_grp,
          cust_address   = l_location_add,
          city           = l_location_city,
          state          = l_location_state,
          postal_code    = l_location_post_code,
          country        = l_location_country,
          is_active      = nvl(l_is_active,'Y'),
          lat            = l_location_lat,
          lon            = l_location_lon,
          delivery_terms = l_location_del_term,
          cust_type      = l_customer_type,
          update_user    = 'INTEGRATION',
          update_date    = sysdate,
          gst_no = l_gst_no,
          gst_state = l_gst_state,
          pan_no = l_panno,
          state_code = l_location_state_code
        where cust_id    =l_location_id;
        
        -- get ship to details object
        l_location_st_obj    := l_location_obj.get_object('ShipToDetails');
        if l_location_st_obj is not null then
          --dbms_output.put_line('Ship To Details Object exists');
          -- get ship to array
          l_location_std_arr    := l_location_st_obj.get_array('ShipTo');
          if l_location_std_arr is null then
            --dbms_output.put_line('No Ship To Array exists');
            l_location_std_obj := l_location_st_obj.get_object('ShipTo');
            l_location_ship_to := l_location_std_obj.get_string('ShipToId');
            select count(1)
            into l_count
            from mt_customer_ship_to
            where cust_id  = l_location_id
            and ship_to_id = l_location_ship_to;
            if l_count    <> 0 then
              null;
            else
              -- insert data
              insert
              into mt_customer_ship_to
                (
                  cust_id,
                  ship_to_id,
                  insert_user,
                  insert_date
                )
                values
                (
                  l_location_id,
                  l_location_ship_to,
                  'INTEGRATION',
                  sysdate
                );
            end if;
          else
            --dbms_output.put_line('Ship To Array exists');
            -- get ship to array
            l_location_std_arr := l_location_st_obj.get_array('ShipTo');
            for i in 0 .. l_location_std_arr.get_size - 1
            loop
              l_location_std_obj := treat
              (
                l_location_std_arr.get(i)
              as
                json_object_t
              )
              ;
              l_location_ship_to := l_location_std_obj.get_string('ShipToId');
              select count(1)
              into l_count
              from mt_customer_ship_to
              where cust_id  = l_location_id
              and ship_to_id = l_location_ship_to;
              if l_count    <> 0 then
                null;
              else
                -- insert data
                insert
                into mt_customer_ship_to
                  (
                    cust_id,
                    ship_to_id,
                    insert_user,
                    insert_date
                  )
                  values
                  (
                    l_location_id,
                    l_location_ship_to,
                    'INTEGRATION',
                    sysdate
                  );
              end if;
            end loop;
          end if;
        end if;
        
        
      end if;
    end if;
    -- get contact object
    l_location_con_obj     := l_location_obj.get_object('Contact');
    if l_location_con_obj  is not null then
      l_location_con_num   := l_location_con_obj.get_string('MobileNum');
      l_location_con_email := l_location_con_obj.get_string('EmailId');
      --dbms_output.put_line('Conatct Data '||l_location_con_num||' '||l_location_con_email);
      select count(1)
      into l_count
      from mt_contact
      where location_id=l_location_id
      and contact_id   = l_location_id;
      if l_count       = 0 then
        -- insert data
        insert
        into mt_contact
          (
            contact_id,
            email,
            mobile,
            location_id,
            insert_user,
            insert_date
          )
          values
          (
            l_location_id,
            l_location_con_email,
            l_location_con_num,
            l_location_id,
            'INTEGRATION',
            sysdate
          );
      else
        -- update data
        update mt_contact
        set email        = l_location_con_email,
          mobile         = l_location_con_num,
          update_user    = 'INTEGRATION',
          update_date    = sysdate
        where location_id=l_location_id
        and contact_id   = l_location_id;
      end if;
    end if;
    commit;
  end;
  
  procedure sync_transporter_master(p_data in clob) as
  l_count pls_integer;
  --l_json_clob clob;
  l_json_obj json_object_t;
  l_transporter_master_obj json_object_t;
  l_transporter_master_arr json_array_t;
  l_transporter_obj json_object_t;
  l_transporter_add_obj json_object_t;
  l_transporter_con_obj json_object_t;
  l_transporter_id mt_transporter.transporter_id%type;
  l_transporter_name mt_transporter.transporter_desc%type;
  l_is_active mt_transporter.is_active%type;
  l_transporter_add mt_transporter.transporter_address%type;
  l_transporter_city mt_transporter.city%type;
  l_transporter_country mt_transporter.country%type;
  l_transporter_post_code mt_transporter.postal_code%type;  
  l_transporter_state mt_transporter.state%type;
  l_transporter_state_code mt_transporter.state_code%type;
  l_transporter_con_num mt_contact.mobile%type;
  l_transporter_con_email mt_contact.email%type;
  l_transporter_inds_key mt_supplier.industry_key%type;
  
    l_gst_no mt_location.gst_no%type;
    l_gst_state mt_location.gst_state%type;
    l_panno mt_location.pan_no%type;
    
  begin
  
  -- select file_data into l_json_clob from json_clob;
  -- parsing json data
    l_json_obj        := json_object_t(p_data);
    l_transporter_master_obj := l_json_obj.get_object('TransporterMaster');
    -- get transporter object
    l_transporter_obj := l_transporter_master_obj.get_object('Transporter');
    l_transporter_id          := l_transporter_obj.get_string('TransporterId');
    l_transporter_name          := l_transporter_obj.get_string('TransporterName');
    l_is_active := l_transporter_obj.get_string('IsActive');
    
    l_gst_no := l_transporter_obj.get_string('GSTNo');
    l_gst_state := l_transporter_obj.get_string('GSTState');
    l_panno     := l_transporter_obj.get_string('PANNo');
    
    --dbms_output.put_line('Location Details : '||l_transporter_id||' '||l_transporter_name||' '||' '||l_is_active);
    
    -- get address object
    l_transporter_add_obj    := l_transporter_obj.get_object('Address');
    l_transporter_add := l_transporter_add_obj.get_string('AddressLine');
    l_transporter_city := l_transporter_add_obj.get_string('City');
    l_transporter_country := l_transporter_add_obj.get_string('Country');
    l_transporter_post_code := l_transporter_add_obj.get_string('PostalCode');    
    l_transporter_state := l_transporter_add_obj.get_string('State');
    l_transporter_state_code := l_transporter_add_obj.get_string('StateCode');
    l_transporter_inds_key := l_transporter_obj.get_string('IndustryKey');
    --dbms_output.put_line('Address Data '||l_transporter_state_code);
    
    select count(1) into l_count from mt_transporter where transporter_id=l_transporter_id;
    if l_count = 0 then
    -- insert data    
          insert
          into mt_transporter
            (
              transporter_id,
              transporter_desc,
              transporter_address,
              city,
              state,
              postal_code,
              country,
              industry_key,
              is_active,
              insert_user,
              insert_date,
              gst_no,
              gst_state,
              pan_no
            )
            values
            (
              l_transporter_id,
              l_transporter_name,
              l_transporter_add,
              l_transporter_city,
              l_transporter_state,
              l_transporter_post_code,
              l_transporter_country,
              l_transporter_inds_key,
              l_is_active,
             'INTEGRATION',
              sysdate,
              l_gst_no,
              l_gst_state,
              l_panno
            );  
    
    else
    -- update data
    
    update mt_transporter 
    set transporter_desc = l_transporter_name,
        transporter_address = l_transporter_add,
        city = l_transporter_city,
        state = l_transporter_state,
        postal_code = l_transporter_post_code,
        country = l_transporter_country,
        is_active = nvl(l_is_active,'Y'),
        industry_key = l_transporter_inds_key,
        update_user = 'INTEGRATION',
        update_date = sysdate,
        gst_no = l_gst_no,
        gst_state = l_gst_state,
        pan_no = l_panno
        where transporter_id =l_transporter_id;
        
    end if;
           
    -- get contact object
    l_transporter_con_obj    := l_transporter_obj.get_object('Contact');
    if l_transporter_con_obj is not null then
    l_transporter_con_num := l_transporter_con_obj.get_string('MobileNum');
    l_transporter_con_email := l_transporter_con_obj.get_string('EmailId');
    --dbms_output.put_line('Conatct Data '||l_transporter_con_num||' '||l_transporter_con_email);
    select count(1) into l_count from mt_contact 
    where location_id=l_transporter_id and contact_id = l_transporter_id;
    
    if l_count = 0 then
    -- insert data
    insert into mt_contact (contact_id,email,mobile,location_id,insert_user,insert_date) 
    values (l_transporter_id,l_transporter_con_email,l_transporter_con_num,l_transporter_id,'INTEGRATION',sysdate);    
    else
    -- update data
    update mt_contact 
    set email = l_transporter_con_email,
    mobile = l_transporter_con_num,
    update_user = 'INTEGRATION',
    update_date = sysdate
    where location_id=l_transporter_id and contact_id = l_transporter_id;    
    end if;
        
    end if;
  commit;
  end;
  
  procedure updt_inv_response(
      p_data in clob)
  as
        l_count pls_integer;
    --l_json_clob clob;
    l_date1 date;
    l_date2 date;
    l_json_obj json_object_t;
    l_inv_response_obj json_object_t;
    l_inv_line_obj json_object_t;
    l_inv_linedetail_obj json_object_t;
    l_inv_linedetail_arr json_array_t;
    -- LoadSlip Invoice Header Table Variables
    l_loadslip_id loadslip_inv_header.loadslip_id%type;
    l_delivery_num loadslip_inv_header.delivery_number%type;
    l_invoice_num loadslip_inv_header.invoice_number%type;
    l_sosto_num loadslip_inv_header.so_sto_num%type;
    l_source_loc loadslip_inv_header.source_loc%type;
    l_dest_loc loadslip_inv_header.dest_loc%type;
    l_shipment_id loadslip_inv_header.shipment_id%type;
    l_invoice_date loadslip_inv_header.invoice_date%type;
    l_lr_num loadslip_inv_header.lr_number%type;
    l_lr_date loadslip_inv_header.lr_date%type;
    l_truck_num loadslip_inv_header.truck_number%type;
    -- LoadSlip Invoice Line Table Variables
    l_sap_linno loadslip_inv_line.sap_line_no%type;
    l_loadslip_linno loadslip_inv_line.line_no%type;
    l_item_id loadslip_inv_line.item_id%type;
    l_qty loadslip_inv_line.qty%type;
    l_weight loadslip_inv_line.weight%type;
    l_weight_uom loadslip_inv_line.weight_uom%type;
    l_invoice_value loadslip_inv_header.sap_inv_value%type;
    l_tot_wt loadslip_inv_header.total_weight%type;
    -- Del Invoice Header Table Variables
    l_container_num del_inv_header.container_num%type;
    l_pol          varchar2(100);
    l_pod          varchar2(100);
    l_incoterm     varchar2(10);
    l_incotermloc  varchar2(50);
    l_billtocode   varchar2(30);
    l_billtoname   varchar2(200);
    l_shiptocode   varchar2(30);
    l_shiptoname   varchar2(200);
    l_destctcode   varchar2(3);
    l_inv_can_flag varchar2(1);
    -- Invoice update flag
    l_inv_upd_flag varchar2(1) := 'N';
    l_cust_inv_num del_inv_header.custom_inv_number%type;
  begin
    -- select file_data into l_json_clob from json_clob;
    -- parsing json data
    l_json_obj := json_object_t(p_data);
    -- get InvoiceResponse object
    l_inv_response_obj := l_json_obj.get_object('InvoiceResponse');
    -- get Invoice header data
    l_loadslip_id  := l_inv_response_obj.get_string('LoadSlipID');
    l_delivery_num := l_inv_response_obj.get_string('DeliveryNumber');
    l_shipment_id  := l_inv_response_obj.get_string('ShipmentID');
    l_sosto_num    := l_inv_response_obj.get_string('SOSTONumber');
    l_source_loc   := l_inv_response_obj.get_string('SourceLocation');
    l_dest_loc     := l_inv_response_obj.get_string('DestinationLocation');
    l_invoice_num  := l_inv_response_obj.get_string('InvoiceNumber');
    l_invoice_date := l_inv_response_obj.get_string('InvoiceDate');
    l_lr_num       := l_inv_response_obj.get_string('LRNumber');
    l_lr_date      := l_inv_response_obj.get_string('LRDate');
    l_truck_num    := l_inv_response_obj.get_string('TruckNumber');
    l_invoice_value:= l_inv_response_obj.get_string('InvoiceValue');
    l_tot_wt       := l_inv_response_obj.get_string('TotalWT');
    -- Export elements
    l_container_num   := l_inv_response_obj.get_string('ContainerNumber');
    l_pol             := l_inv_response_obj.get_string('POL');
    l_pod             := l_inv_response_obj.get_string('POD');
    l_incoterm        := l_inv_response_obj.get_string('Incoterm');
    l_incotermloc     := l_inv_response_obj.get_string('IncotermLocation');
    l_billtocode      := l_inv_response_obj.get_string('BillToCode');
    l_billtoname      := l_inv_response_obj.get_string('BillToName');
    l_shiptocode      := l_inv_response_obj.get_string('ShipToCode');
    l_shiptoname      := l_inv_response_obj.get_string('ShipToName');
    l_destctcode      := l_inv_response_obj.get_string('DestCountryCode');
    l_date1           := trunc(to_date(l_invoice_date,'DD-MON-YY HH24:MI:SS'));
    l_date2           := trunc(to_date(l_lr_date,'DD-MON-YY HH24:MI:SS'));
    l_inv_can_flag    := l_inv_response_obj.get_string('IsInvoiceCancelled');
    l_cust_inv_num    := l_inv_response_obj.get_string('CustomsInvoiceNum');
    if l_inv_can_flag is null or l_inv_can_flag ='N' then
      if l_loadslip_id not in ('JIT_LS','EXP_LS') then
        -- FGS PLANT / RDC case
        select count(1)
        into l_count
        from loadslip_inv_header
        where loadslip_id  = l_loadslip_id
        and invoice_number = l_invoice_num;
      else
        -- FGS JIT / EXPORT case
        select count(1)
        into l_count
        from del_inv_header
        where invoice_number = l_invoice_num;
      end if;
      if l_loadslip_id not in ('JIT_LS','EXP_LS') then
        if l_count = 0 then
          insert
          into loadslip_inv_header
            (
              loadslip_id,
              shipment_id,
              invoice_number,
              delivery_number,
              so_sto_num,
              invoice_date,
              lr_number,
              lr_date,
              truck_number,
              source_loc,
              dest_loc,
              insert_user,
              insert_date,
              sap_inv_value,
              total_weight,
              total_weight_uom
            )
            values
            (
              l_loadslip_id,
              l_shipment_id,
              l_invoice_num,
              l_delivery_num,
              l_sosto_num,
              l_date1,
              l_lr_num,
              l_date2,
              l_truck_num,
              l_source_loc,
              l_dest_loc,
              'INTEGRATION',
              sysdate,
              l_invoice_value,
              l_tot_wt,
              'KG'
            );
        else
        -- Update invoice received
        l_inv_upd_flag := 'Y';
          update loadslip_inv_header
          set lr_number      = l_lr_num,
            lr_date          = l_date2,
            truck_number     = l_truck_num,
            source_loc       = l_source_loc,
            dest_loc         = l_dest_loc,
            update_user      = 'INTEGRATION',
            update_date      = sysdate,
            sap_inv_value    = l_invoice_value,
            total_weight     = l_tot_wt
          where loadslip_id  = l_loadslip_id
          and invoice_number = l_invoice_num;
        end if;
        -- update invoice number and date in loadslip
        /*update loadslip a
        set a.sap_invoice = (select listagg(invoice_number,'|') within group (order by invoice_number)
        from loadslip_inv_header where loadslip_id=a.loadslip_id) where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.delivery = (select listagg(delivery_number,'|') within group (order by delivery_number)
        from loadslip_inv_header where loadslip_id=a.loadslip_id) where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.lr_num = (select listagg(lr_number,'|') within group (order by lr_number)
        from loadslip_inv_header where loadslip_id=a.loadslip_id) where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.sap_invoice_date = (select max(invoice_date)
        from loadslip_inv_header where loadslip_id=a.loadslip_id) where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.lr_date = (select max(lr_date)
        from loadslip_inv_header where loadslip_id=a.loadslip_id) where a.loadslip_id=l_loadslip_id;
        */
        commit;
      else
        if l_count = 0 then
          insert
          into del_inv_header
            (
              loadslip_id,
              shipment_id,
              invoice_number,
              delivery_number,
              so_sto_num,
              invoice_date,
              lr_number,
              lr_date,
              truck_number,
              source_loc,
              dest_loc,
              insert_user,
              insert_date,
              container_num,
              pol,
              pod,
              incoterm,
              incoterm_loc,
              bill_to,
              bill_to_name,
              ship_to,
              ship_to_name,
              dest_loc_country,
              type,
              sap_inv_value,
              total_weight,
              total_weight_uom,
              custom_inv_number
            )
            values
            (
              l_loadslip_id,
              l_shipment_id,
              l_invoice_num,
              l_delivery_num,
              l_sosto_num,
              l_date1,
              l_lr_num,
              l_date2,
              l_truck_num,
              l_source_loc,
              --l_dest_loc,
              --(case when l_loadslip_id = 'EXP_LS' then l_shiptocode else l_dest_loc end),
              l_shiptocode,
              'INTEGRATION',
              sysdate,
              l_container_num,
              l_pol,
              l_pod,
              l_incoterm,
              l_incotermloc,
              l_billtocode,
              l_billtoname,
              l_shiptocode,
              l_shiptoname,
              l_destctcode,
              (
              case
                when l_loadslip_id = 'EXP_LS'
                then 'FGS_EXP'
                else 'JIT_OEM'
              end),
              l_invoice_value,
              l_tot_wt,
              'KG',
              l_cust_inv_num
            );
        else
		
		
          update del_inv_header
          set lr_number      = l_lr_num,
            lr_date          = l_date2,
            truck_number     = l_truck_num,
            source_loc       = l_source_loc,
            dest_loc         = l_shiptocode,--(case when l_loadslip_id = 'EXP_LS' then l_shiptocode else l_dest_loc end),
            update_user      = 'INTEGRATION',
            update_date      = sysdate,
            container_num    = l_container_num,
            pol              = l_pol,
            pod              = l_pod,
            incoterm         = l_incoterm,
            incoterm_loc     = l_incotermloc,
            bill_to          = l_billtocode,
            bill_to_name     = l_billtoname,
            ship_to          = l_shiptocode,
            ship_to_name     = l_shiptoname,
            dest_loc_country = l_destctcode,
            sap_inv_value    = l_invoice_value,
            total_weight     = l_tot_wt,
            custom_inv_number = l_cust_inv_num
          where nvl(loadslip_id,'NA')  = (select nvl(loadslip_id,'NA') from del_inv_header where invoice_number = l_invoice_num and rownum=1)
          and invoice_number = l_invoice_num;
        end if;
      end if;
      commit;
      -- get Invoice line object
      l_inv_line_obj    := l_inv_response_obj.get_object('InvoiceLineDetails');
      if l_inv_line_obj is not null then
        --dbms_output.put_line('Invoice line Details object Exists');
        -- get Invoice line detail object
        l_inv_linedetail_arr    := l_inv_line_obj.get_array('InvoiceLine');
        if l_inv_linedetail_arr is not null then
          --dbms_output.put_line('Invoice line Array Exists');
          for j in 0 .. l_inv_linedetail_arr.get_size - 1
          loop
            l_inv_linedetail_obj := treat(l_inv_linedetail_arr.get(j)
          as
            json_object_t);
            l_sap_linno      := l_inv_linedetail_obj.get_string('SAPLineNo');
            l_loadslip_linno := l_inv_linedetail_obj.get_string('LoadSlipLineNo');
            l_item_id        := l_inv_linedetail_obj.get_string('MaterialCode');
            l_qty            := l_inv_linedetail_obj.get_string('Qty');
            l_weight         := l_inv_linedetail_obj.get_string('Weight');
            l_weight_uom     := l_inv_linedetail_obj.get_string('UOM');
            if l_loadslip_id not in ('JIT_LS','EXP_LS') then
              select count(1)
              into l_count
              from loadslip_inv_line
              where loadslip_id  = l_loadslip_id
              and invoice_number = l_invoice_num
              and line_no        = l_loadslip_linno
              and sap_line_no    = l_sap_linno;
            else
              select count(1)
              into l_count
              from del_inv_line
              where invoice_number = l_invoice_num
              and sap_line_no      = l_sap_linno;
            end if;
            if l_loadslip_id not in ('JIT_LS','EXP_LS') then
              if l_count = 0 then
                insert
                into loadslip_inv_line
                  (
                    loadslip_id,
                    invoice_number,
                    line_no,
                    sap_line_no,
                    item_id,
                    qty,
                    weight,
                    weight_uom,
                    insert_user,
                    insert_date,
                    batch_code
                  )
                  values
                  (
                    l_loadslip_id,
                    l_invoice_num,
                    l_loadslip_linno,
                    l_sap_linno,
                    l_item_id,
                    l_qty,
                    l_weight,
                    l_weight_uom,
                    'INTEGRATION',
                    sysdate,
                    nvl((select batch_code from loadslip_line_detail 
                  where loadslip_id=l_loadslip_id 
                  and item_id=l_item_id and line_no=l_loadslip_linno and rownum=1),'NA')                    
                  );
                update loadslip_line_detail
                set invoice_number = l_invoice_num
                where loadslip_id  = l_loadslip_id
                and line_no        = l_loadslip_linno
                and item_id        = l_item_id;
                commit;
              else
                update loadslip_inv_line
                set item_id        = l_item_id,
                  qty              = l_qty,
                  weight           = l_weight,
                  weight_uom       = l_weight_uom,
                  update_user      = 'INTEGRATION',
                  update_date      = sysdate
                where loadslip_id  = l_loadslip_id
                and invoice_number = l_invoice_num
                and sap_line_no    = l_sap_linno
                and line_no        = l_loadslip_linno;
              end if;
            else
              if l_count = 0 then
                insert
                into del_inv_line
                  (
                    invoice_number,
                    line_no,
                    sap_line_no,
                    item_id,
                    qty,
                    weight,
                    weight_uom,
                    insert_user,
                    insert_date
                  )
                  values
                  (
                    l_invoice_num,
                    l_loadslip_linno,
                    l_sap_linno,
                    l_item_id,
                    l_qty,
                    l_weight,
                    l_weight_uom,
                    'INTEGRATION',
                    sysdate
                  );
              else
                update del_inv_line
                set item_id          = l_item_id,
                  qty                = l_qty,
                  weight             = l_weight,
                  weight_uom         = l_weight_uom,
                  update_user        = 'INTEGRATION',
                  update_date        = sysdate
                where invoice_number = l_invoice_num
                and sap_line_no      = l_sap_linno;
              end if;
            end if;
          end loop;
        else
          --dbms_output.put_line('Invoice line Array not Exists');
          l_inv_linedetail_obj := l_inv_line_obj.get_object('InvoiceLine');
          l_sap_linno          := l_inv_linedetail_obj.get_string('SAPLineNo');
          l_loadslip_linno     := l_inv_linedetail_obj.get_string('LoadSlipLineNo');
          l_item_id            := l_inv_linedetail_obj.get_string('MaterialCode');
          l_qty                := l_inv_linedetail_obj.get_string('Qty');
          l_weight             := l_inv_linedetail_obj.get_string('Weight');
          l_weight_uom         := l_inv_linedetail_obj.get_string('UOM');
          if l_loadslip_id not in ('JIT_LS','EXP_LS') then
            select count(1)
            into l_count
            from loadslip_inv_line
            where loadslip_id  = l_loadslip_id
            and invoice_number = l_invoice_num
            and line_no        = l_loadslip_linno
            and sap_line_no    = l_sap_linno;
          else
            select count(1)
            into l_count
            from del_inv_line
            where invoice_number = l_invoice_num
            and sap_line_no      = l_sap_linno;
          end if;
          if l_loadslip_id not in ('JIT_LS','EXP_LS') then
            if l_count = 0 then
              insert
              into loadslip_inv_line
                (
                  loadslip_id,
                  invoice_number,
                  line_no,
                  sap_line_no,
                  item_id,
                  qty,
                  weight,
                  weight_uom,
                  insert_user,
                  insert_date,
                  batch_code
                )
                values
                (
                  l_loadslip_id,
                  l_invoice_num,
                  l_loadslip_linno,
                  l_sap_linno,
                  l_item_id,
                  l_qty,
                  l_weight,
                  l_weight_uom,
                  'INTEGRATION',
                  sysdate,
                  nvl((select batch_code from loadslip_line_detail 
                  where loadslip_id=l_loadslip_id 
                  and item_id=l_item_id and line_no=l_loadslip_linno and rownum=1),'NA')
                );
              update loadslip_line_detail
              set invoice_number = l_invoice_num
              where loadslip_id  = l_loadslip_id
              and line_no        = l_loadslip_linno
              and item_id        = l_item_id;
              commit;
            else
              update loadslip_inv_line
              set item_id        = l_item_id,
                qty              = l_qty,
                weight           = l_weight,
                weight_uom       = l_weight_uom,
                update_user      = 'INTEGRATION',
                update_date      = sysdate
              where loadslip_id  = l_loadslip_id
              and invoice_number = l_invoice_num
              and sap_line_no    = l_sap_linno
              and line_no        = l_loadslip_linno;
            end if;
          else
            if l_count = 0 then
              insert
              into del_inv_line
                (
                  invoice_number,
                  line_no,
                  sap_line_no,
                  item_id,
                  qty,
                  weight,
                  weight_uom,
                  insert_user,
                  insert_date
                )
                values
                (
                  l_invoice_num,
                  l_loadslip_linno,
                  l_sap_linno,
                  l_item_id,
                  l_qty,
                  l_weight,
                  l_weight_uom,
                  'INTEGRATION',
                  sysdate
                );
            else
              update del_inv_line
              set item_id          = l_item_id,
                qty                = l_qty,
                weight             = l_weight,
                weight_uom         = l_weight_uom,
                update_user        = 'INTEGRATION',
                update_date        = sysdate
              where invoice_number = l_invoice_num
              and sap_line_no      = l_sap_linno;
            end if;
          end if;
        end if;
      end if;
      commit;
    begin
      if l_loadslip_id not in ('JIT_LS','EXP_LS') then
        -- update invoice number and date in loadslip
        /*
        update loadslip a
        set a.delivery =
          (select listagg(delivery_number,'|') within group (
          order by delivery_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.lr_num =
          (select listagg(lr_number,'|') within group (
          order by lr_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.sap_invoice_date =
          (select max(invoice_date)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.sap_invoice =
          (select listagg(invoice_number,'|') within group (
          order by invoice_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.lr_date =
          (select max(lr_date) from loadslip_inv_header where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        
        update loadslip a 
        set (a.sap_inv_value,a.sap_inv_weight) = (select nvl(sum(sap_inv_value),0),nvl(sum(total_weight),0) 
                              from loadslip_inv_header 
                              where loadslip_id = a.loadslip_id),
            a.e_way_bill_no = (select listagg(e_way_bill_no,'|') within group (
                              order by e_way_bill_no)
                              from loadslip_inv_header
                              where loadslip_id=a.loadslip_id)
        where a.loadslip_id = l_loadslip_id;
        */
        
        update loadslip a
        set a.delivery =
          (select listagg(delivery_number,'|') within group (
          order by delivery_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          ),
        a.lr_num =
          (select listagg(lr_number,'|') within group (
          order by lr_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          ),
		  a.lr_date =
          (select max(lr_date) from loadslip_inv_header where loadslip_id=a.loadslip_id
          ),
		  a.sap_invoice_date =
          (select max(invoice_date)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          ),
		  a.sap_invoice =
          (select listagg(invoice_number,'|') within group (
          order by invoice_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id),
		  (a.sap_inv_value,a.sap_inv_weight) = (select nvl(sum(sap_inv_value),0),nvl(sum(total_weight),0) 
                              from loadslip_inv_header 
                              where loadslip_id = a.loadslip_id),
		  a.e_way_bill_no = (select listagg(e_way_bill_no,'|') within group (
                              order by e_way_bill_no)
                              from loadslip_inv_header
                              where loadslip_id=a.loadslip_id),
		  a.e_way_bill_date =
          (select max(e_way_bill_date) from loadslip_inv_header where loadslip_id=a.loadslip_id)
        where a.loadslip_id=l_loadslip_id;
        
        begin
        update truck_reporting a set (a.sap_inv_weight,a.sap_inv_value) = 
        (select nvl(sum(total_weight),0),nvl(sum(sap_inv_value),0) 
                              from loadslip_inv_header 
                              where loadslip_id = l_loadslip_id),
                              a.e_way_bill_no = (select listagg(e_way_bill_no,'|') within group (
                              order by e_way_bill_no)
                              from loadslip_inv_header
                              where loadslip_id=l_loadslip_id),
                              a.e_way_bill_date = (select max(e_way_bill_date) from loadslip_inv_header 
                              where loadslip_id=l_loadslip_id)
        where a.gate_control_code = (select gate_control_code
        from truck_reporting where shipment_id = l_shipment_id
        and truck_number = a.truck_number 
        and reporting_location = (select source_loc from loadslip where 
        shipment_id = l_shipment_id and loadslip_id = l_loadslip_id));
        exception when others then
        null;
        end;
        
        commit;
        
      end if;
    end;
    if l_loadslip_id not in ('JIT_LS','EXP_LS') and l_inv_upd_flag ='N' then
    post_to_atom(l_loadslip_id,'N',l_invoice_num);
    end if;
  else
    
    if l_loadslip_id not in ('JIT_LS','EXP_LS') then
	-- Invoice is cancelled
    post_to_atom(l_loadslip_id,'Y',l_invoice_num);
    
	update loadslip_line_detail
    set invoice_number = null
    where loadslip_id  = l_loadslip_id
    and invoice_number = l_invoice_num;
    --commit;
       
       delete from loadslip_inv_line where invoice_number = l_invoice_num;
       delete from loadslip_inv_header where invoice_number = l_invoice_num;
       commit;
    
	begin
    /*
    update loadslip a
        set a.delivery =
          (select listagg(delivery_number,'|') within group (
          order by delivery_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.lr_num =
          (select listagg(lr_number,'|') within group (
          order by lr_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.sap_invoice_date =
          (select max(invoice_date)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.sap_invoice =
          (select listagg(invoice_number,'|') within group (
          order by invoice_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        update loadslip a
        set a.lr_date =
          (select max(lr_date) from loadslip_inv_header where loadslip_id=a.loadslip_id
          )
        where a.loadslip_id=l_loadslip_id;
        
        update loadslip a 
        set (a.sap_inv_value,a.sap_inv_weight) = (select nvl(sum(sap_inv_value),0),nvl(sum(total_weight),0) 
                              from loadslip_inv_header 
                              where loadslip_id = a.loadslip_id),
            a.e_way_bill_no = (select listagg(e_way_bill_no,'|') within group (
                              order by e_way_bill_no)
                              from loadslip_inv_header
                              where loadslip_id=a.loadslip_id)
        where a.loadslip_id = l_loadslip_id;
        */
        
        update loadslip a
        set a.delivery =
          (select listagg(delivery_number,'|') within group (
          order by delivery_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          ),
        a.lr_num =
          (select listagg(lr_number,'|') within group (
          order by lr_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          ),
		  a.lr_date =
          (select max(lr_date) from loadslip_inv_header where loadslip_id=a.loadslip_id
          ),
		  a.sap_invoice_date =
          (select max(invoice_date)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id
          ),
		  a.sap_invoice =
          (select listagg(invoice_number,'|') within group (
          order by invoice_number)
          from loadslip_inv_header
          where loadslip_id=a.loadslip_id),
		  (a.sap_inv_value,a.sap_inv_weight) = (select nvl(sum(sap_inv_value),0),nvl(sum(total_weight),0) 
                              from loadslip_inv_header 
                              where loadslip_id = a.loadslip_id),
		  a.e_way_bill_no = (select listagg(e_way_bill_no,'|') within group (
                              order by e_way_bill_no)
                              from loadslip_inv_header
                              where loadslip_id=a.loadslip_id),
          a.release_date = null,                    
		  a.e_way_bill_date =  (select max(e_way_bill_date) from loadslip_inv_header 
      where loadslip_id=a.loadslip_id)
      where a.loadslip_id=l_loadslip_id;
        
        begin
        update truck_reporting a set (a.sap_inv_weight,a.sap_inv_value) = 
        (select nvl(sum(total_weight),0),nvl(sum(sap_inv_value),0) 
                              from loadslip_inv_header 
                              where loadslip_id = l_loadslip_id),
                              e_way_bill_no = (select listagg(e_way_bill_no,'|') within group (
                              order by e_way_bill_no)
                              from loadslip_inv_header
                              where loadslip_id=l_loadslip_id),
                              a.e_way_bill_date = (select max(e_way_bill_date) from loadslip_inv_header 
                              where loadslip_id=l_loadslip_id)
        where a.gate_control_code = (select gate_control_code
        from truck_reporting where shipment_id = l_shipment_id
        and truck_number = a.truck_number 
        and reporting_location = (select source_loc from loadslip where 
        shipment_id = l_shipment_id and loadslip_id = l_loadslip_id));
        exception when others then
        null;
        end;
    
    commit;
    end;
       
	   else
	   
	   select nvl(loadslip_id,'NA') into l_loadslip_id 
	   from del_inv_header where invoice_number = l_invoice_num;	   
	   if l_loadslip_id in ('JIT_LS','EXP_LS','NA') then 
	   delete from del_inv_line where invoice_number = l_invoice_num;
       delete from del_inv_header where invoice_number = l_invoice_num;
       commit;
	    else	
     
	   update loadslip set release_date=null where loadslip_id = l_loadslip_id;
	   update del_inv_header set status ='CANCELLED' where loadslip_id = l_loadslip_id and invoice_number = l_invoice_num;
	  /* update shipment set status = 'CANCELLED' where shipment_id = (select shipment_id 
	   from loadslip where loadslip_id = l_loadslip_id);
	   update truck_reporting a 
	   set a.status = 'GATED_IN' 
	   where a.gate_control_code = (select gate_control_code
        from truck_reporting where shipment_id = (select shipment_id 
	   from loadslip where loadslip_id = l_loadslip_id)
        and truck_number = a.truck_number 
        and reporting_location = (select source_loc from loadslip where loadslip_id = l_loadslip_id)) 
		and a.shipment_id = (select shipment_id 
	   from loadslip where loadslip_id = l_loadslip_id); */
	   commit;
	   
     
	   end if;
	   
       
       
    end if;
  end if;
  end;
  
  procedure updt_barcode_response(
      p_data in clob)
  as
  --l_json_clob clob;
  l_count pls_integer;
  l_json_obj json_object_t;
  l_bc_response_obj json_object_t;
  l_bc_line_obj json_object_t;
  l_bc_linedetail_obj json_object_t;
  l_bc_linedetail_arr json_array_t;
  l_loadslip_id loadslip_line_detail.loadslip_id%type;
  l_line_no loadslip_line_detail.line_no%type;
  l_item_id loadslip_line_detail.item_id%type;
  l_scan_qty loadslip_detail.scanned_qty%type;
  l_batch_id loadslip_detail.batch_code%type;
  l_uom ct_uom.uom_code%type;
  begin
    -- select file_data into l_json_clob from json_clob;
    -- parsing json data
    l_json_obj := json_object_t(p_data);
    -- get BarcodeResponse object
    l_bc_response_obj := l_json_obj.get_object('BarCodeResponse');
    -- get Barcode header data
    l_loadslip_id := l_bc_response_obj.get_string('LoadSlipID');
    --dbms_output.put_line('Loadslip ID '||l_loadslip_id);
    select count(1)
    into l_count
    from loadslip_line_detail
    where loadslip_id = l_loadslip_id;
    if l_count        > 0 then
      -- get Barcode line object
      l_bc_line_obj    := l_bc_response_obj.get_object('BarCodeLineDetails');
      if l_bc_line_obj is not null then
        --dbms_output.put_line('Barcode line Details object Exists');
        -- get Barcode line detail object
        l_bc_linedetail_arr    := l_bc_line_obj.get_array('BarCodeLine');
        if l_bc_linedetail_arr is not null then
          --dbms_output.put_line('Barcode line Array Exists');
          for j in 0 .. l_bc_linedetail_arr.get_size - 1
          loop
            l_bc_linedetail_obj := treat(l_bc_linedetail_arr.get(j)
          as
            json_object_t);
            l_line_no  := l_bc_linedetail_obj.get_string('LineNo');
            l_item_id  := l_bc_linedetail_obj.get_string('MaterialCode');
            l_scan_qty := l_bc_linedetail_obj.get_string('ScanQty');
            --l_batch_id      := l_bc_linedetail_obj.get_string('BatchID');
            --l_uom      := l_bc_linedetail_obj.get_string('UOM');
            update loadslip_detail
            set scanned_qty = l_scan_qty,
              update_user   = 'INTEGRATION',
              update_date   = sysdate
            where item_id   = l_item_id
            and loadslip_id = l_loadslip_id
            and rownum=1;
            --and line_no     = l_line_no;
            commit;
          end loop;
        else
          --dbms_output.put_line('Barcode line Array not Exists');
          l_bc_linedetail_obj := l_bc_line_obj.get_object('BarCodeLine');
          l_line_no           := l_bc_linedetail_obj.get_string('LineNo');
          l_item_id           := l_bc_linedetail_obj.get_string('MaterialCode');
          l_scan_qty          := l_bc_linedetail_obj.get_string('ScanQty');
          --l_batch_id      := l_bc_linedetail_obj.get_string('BatchID');
          --l_uom      := l_bc_linedetail_obj.get_string('UOM');
          update loadslip_detail
          set scanned_qty = l_scan_qty,
            update_user   = 'INTEGRATION',
            update_date   = sysdate
          where item_id   = l_item_id
          and loadslip_id = l_loadslip_id
          and rownum=1;
          --and line_no     = l_line_no;
          commit;
        end if;
      end if;
    end if;
  end;
  
  procedure updt_grn_response(
    p_data clob)
  as
  
    --l_json_clob clob;
    l_date1 date;
    l_date2 date;
    l_date3 date;
    l_count pls_integer;
    l_json_obj json_object_t;
    l_grn_response_obj json_object_t;
    l_grn_line_obj json_object_t;
    l_grn_linedetail_obj json_object_t;
    l_grn_linedetail_arr json_array_t;
    l_loadslip_id grn_header.loadslip_id%type;
    l_delivery_num grn_header.delivery_num%type;
    l_shipment_id grn_header.shipment_id%type;
    l_sosto_num grn_header.sto_po_num%type;
    l_source_loc grn_header.source_loc%type;
    l_dest_loc grn_header.dest_loc%type;
    l_grn_num grn_header.grn_number%type;
    l_grn_date varchar2(100);--grn_header.grn_date%type;
    l_grn_type varchar2(20);
    l_rep_date varchar2(100);--grn_header.reporting_date%type;
    l_unload_date varchar2(100);--grn_header.unloading_date%type;
    l_remarks grn_header.remarks%type;
    l_sap_linno grn_line.sap_line_no%type;
    l_loadslip_linno grn_line.line_no%type;
    l_item_id grn_line.item_id%type;
    l_qty grn_line.grn_qty%type;
    l_batch_code grn_line.batch_code%type;
  begin
    -- select file_data into l_json_clob from json_clob;
    -- parsing json data
    l_json_obj := json_object_t(p_data);
    -- get GRNResponse object
    l_grn_response_obj := l_json_obj.get_object('GRNResponse');
    -- get GRN header data
    l_loadslip_id  := l_grn_response_obj.get_string('LoadSlipID');
    l_delivery_num := l_grn_response_obj.get_string('DeliveryNumber');
    l_shipment_id  := l_grn_response_obj.get_string('ShipmentID');
    l_sosto_num    := l_grn_response_obj.get_string('SOSTOPONumber');
    l_source_loc   := l_grn_response_obj.get_string('SourceLocation');
    l_dest_loc     := l_grn_response_obj.get_string('DestLocation');
    l_grn_num      := l_grn_response_obj.get_string('GRNNumber');
    l_grn_date     := l_grn_response_obj.get_string('GRNDate');
    l_grn_type     := l_grn_response_obj.get_string('GRNType');
    l_remarks      := l_grn_response_obj.get_string('Remarks');
    l_rep_date     := l_grn_response_obj.get_string('ReportingDate');
    l_unload_date  := l_grn_response_obj.get_string('UnloadingDate');
    l_date1        := (to_date(l_grn_date,'DD-MON-YYYY HH24:MI:SS'));
    l_date2        := (to_date(l_rep_date,'DD-MON-YYYY HH24:MI:SS'));
    l_date3        := (to_date(l_unload_date,'DD-MON-YYYY HH24:MI:SS'));
    --dbms_output.put_line('l_rep_date '||l_date2);
    select count(1)
    into l_count
    from grn_header
    where loadslip_id = l_loadslip_id
    and delivery_num  = l_delivery_num
    and grn_number    = l_grn_num;
    if l_grn_type     = 'STO' then
      if l_count      = 0 then
        insert
        into grn_header
          (
            loadslip_id,
            shipment_id,
            grn_type,
            sto_po_num,
            delivery_num,
            --LR_NUMBER,
            --TRUCK_REG_NUMBER,
            --VENDOR_NUMBER,
            source_loc,
            dest_loc,
            grn_number,
            grn_date,
            reporting_date,
            unloading_date,
            remarks,
            insert_date,
            insert_user
          )
          values
          (
            l_loadslip_id,
            l_shipment_id,
            l_grn_type,
            l_sosto_num,
            l_delivery_num,
            l_source_loc,
            l_dest_loc,
            l_grn_num,
            l_date1,--l_grn_date,
            l_date2,--l_rep_date,
            l_date3,--l_unload_date,
            l_remarks,
            sysdate,
            'INTEGRATION'
          );
        commit;
     
        
      else
        update grn_header
        set loadslip_id   =l_loadslip_id,
          shipment_id     = l_shipment_id,
          grn_type        = l_grn_type,
          sto_po_num      = l_sosto_num,
          delivery_num    = l_delivery_num,
          source_loc      = l_source_loc,
          dest_loc        = l_dest_loc,
          grn_number      = l_grn_num,
          grn_date        = l_date1,--l_grn_date,
          reporting_date  = l_date2,--l_rep_date,
          unloading_date  = l_date3,--l_unload_date,
          remarks         = l_remarks,
          update_user     = 'INTEGRATION',
          update_date     = sysdate
        where loadslip_id = l_loadslip_id
        and delivery_num  = l_delivery_num
        and grn_number    = l_grn_num;
        commit;
      end if;
      -- get GRN line object
      l_grn_line_obj    := l_grn_response_obj.get_object('GRNLineDetails');
      if l_grn_line_obj is not null then
        --dbms_output.put_line('GRN line Details object Exists');
        -- get GRN line detail object
        l_grn_linedetail_arr    := l_grn_line_obj.get_array('GRNLine');
        if l_grn_linedetail_arr is not null then
          --dbms_output.put_line('GRN line Array Exists');
          for j in 0 .. l_grn_linedetail_arr.get_size - 1
          loop
            l_grn_linedetail_obj := treat(l_grn_linedetail_arr.get(j)
          as
            json_object_t);
            l_sap_linno := l_grn_linedetail_obj.get_string('SAPLineNo');
            --dbms_output.put_line('l_sap_linno '||l_sap_linno);
            l_loadslip_linno := l_grn_linedetail_obj.get_string('LineNo');
            l_item_id        := l_grn_linedetail_obj.get_string('MaterialCode');
            l_qty            := l_grn_linedetail_obj.get_string('Qty');
            l_batch_code     := l_grn_linedetail_obj.get_string('BatchCode');
            select count(1)
            into l_count
            from grn_line
            where loadslip_id = l_loadslip_id
            and grn_number    = l_grn_num
            and line_no       = l_loadslip_linno
            and sap_line_no   = l_sap_linno;
            if l_count        = 0 then
              insert
              into grn_line
                (
                  loadslip_id,
                  grn_number,
                  line_no,
                  sap_line_no,
                  item_id,
                  batch_code,
                  grn_qty,
                  insert_user,
                  insert_date
                )
                values
                (
                  l_loadslip_id,
                  l_grn_num,
                  l_loadslip_linno,
                  l_sap_linno,
                  l_item_id,
                  l_batch_code,
                  l_qty,
                  'INTEGRATION',
                  sysdate
                );
              commit;
            else
              update grn_line
              set loadslip_id   =l_loadslip_id,
                grn_number      = l_grn_num,
                line_no         = l_loadslip_linno,
                sap_line_no     = l_sap_linno,
                item_id         = l_item_id,
                batch_code      = l_batch_code,
                grn_qty         = l_qty,
                update_user     = 'INTEGRATION',
                update_date     = sysdate
              where loadslip_id = l_loadslip_id
              and grn_number    = l_grn_num
              and line_no       = l_loadslip_linno
              and sap_line_no   = l_sap_linno;
              commit;
            end if;
          end loop;
        else
          --dbms_output.put_line('GRN line Array not Exists');
          l_grn_linedetail_obj := l_grn_line_obj.get_object('GRNLine');
          l_sap_linno          := l_grn_linedetail_obj.get_string('SAPLineNo');
          l_loadslip_linno     := l_grn_linedetail_obj.get_string('LineNo');
          l_item_id            := l_grn_linedetail_obj.get_string('MaterialCode');
          l_qty                := l_grn_linedetail_obj.get_string('Qty');
          l_batch_code         := l_grn_linedetail_obj.get_string('BatchCode');
          select count(1)
          into l_count
          from grn_line
          where loadslip_id = l_loadslip_id
          and grn_number    = l_grn_num
          and line_no       = l_loadslip_linno
          and sap_line_no   = l_sap_linno;
          if l_count        = 0 then
            insert
            into grn_line
              (
                loadslip_id,
                grn_number,
                line_no,
                sap_line_no,
                item_id,
                batch_code,
                grn_qty,
                insert_user,
                insert_date
              )
              values
              (
                l_loadslip_id,
                l_grn_num,
                l_loadslip_linno,
                l_sap_linno,
                l_item_id,
                l_batch_code,
                l_qty,
                'INTEGRATION',
                sysdate
              );
            commit;
          else
            update grn_line
            set loadslip_id   =l_loadslip_id,
              grn_number      = l_grn_num,
              line_no         = l_loadslip_linno,
              sap_line_no     = l_sap_linno,
              item_id         = l_item_id,
              batch_code      = l_batch_code,
              grn_qty         = l_qty,
              update_user     = 'INTEGRATION',
              update_date     = sysdate
            where loadslip_id = l_loadslip_id
            and grn_number    = l_grn_num
            and line_no       = l_loadslip_linno
            and sap_line_no   = l_sap_linno;
            commit;
          end if;
        end if;
      --else
        --dbms_output.put_line('GRN line Details object not Exists');
      end if;
    end if;
    
    begin 
    update loadslip a 
    set a.grn = (select listagg(grn_number,'|') within group (order by grn_number)
                 from grn_header where loadslip_id= a.loadslip_id)
    where a.loadslip_id = l_loadslip_id;
    
    update loadslip a 
    set a.grn_date = (select min(grn_date) from grn_header where loadslip_id= a.loadslip_id)
    where a.loadslip_id = l_loadslip_id;
    
    -- update remarks from grn to loadslip
    update loadslip a 
    set a.grn_remark = (select remarks from grn_header where loadslip_id= a.loadslip_id
    and (unloading_date) = (select (max(unloading_date)) 
    from grn_header where loadslip_id= a.loadslip_id) and rownum=1)
    where a.loadslip_id = l_loadslip_id;
    -- update reporting_date from grn to loadslip
    update loadslip a 
    set a.grn_reporting_date = (select min(reporting_date)
    from grn_header where loadslip_id= a.loadslip_id)
    where a.loadslip_id = l_loadslip_id;
    
    -- update unloading_date from grn to loadslip
    update loadslip a 
    set a.grn_unloading_date = (select max(unloading_date)
    from grn_header where loadslip_id= a.loadslip_id)
    where a.loadslip_id = l_loadslip_id;
    
    commit;
    
    exception when others then
    raise;
    
    end;
    -- Close Shipment
    -- close_pass_shipment(l_shipment_id,l_loadslip_id);
    -- check if GRN fully done
   -- if is_grn_complete(l_loadslip_id) = 'CLOSE' then
    -- Close Shipment
    select shipment_id into l_shipment_id from loadslip where loadslip_id = l_loadslip_id;
    close_pass_shipment(l_shipment_id,l_loadslip_id);
   -- end if;
        
  end;
  
  procedure updt_so_grn_response(
    p_data clob)
  as
  
    --l_json_clob clob;
    l_date1 date;    
    l_count pls_integer;
    l_json_obj json_object_t;
    l_grn_response_obj json_object_t; 
    l_grn_obj json_object_t;
    l_grn_line_item_arr json_array_t;
    l_loadslip_id grn_detail_so.loadslip_id%type;
    l_shipment_id grn_detail_so.shipment_id%type;  
    l_doc_num grn_detail_so.sap_doc_number%type;  
    l_inv_num grn_detail_so.invoice_number%type; 
    l_oe_code grn_detail_so.oe_code%type;
    l_recv_date varchar2(100);
    
    l_new_ls_id grn_detail_so.loadslip_id%type;
    l_new_ship_id grn_detail_so.shipment_id%type;  
    
    begin
    -- select file_data into l_json_clob from json_clob;
    -- parsing json data
    l_json_obj := json_object_t(p_data);
    -- get SOGRNResponse object
    l_grn_response_obj := l_json_obj.get_object('SOGRNResponse');
    -- get line array
    l_grn_line_item_arr    := l_grn_response_obj.get_array('Line');
    
    if l_grn_line_item_arr is not null then
    --dbms_output.put_line('Line Array exists');
    l_count := l_grn_line_item_arr.get_size;
    
    
    for i in 0 .. l_grn_line_item_arr.get_size - 1
    loop
      l_grn_obj := treat(l_grn_line_item_arr.get(i)
    as
      json_object_t);
      
    l_loadslip_id  := l_grn_obj.get_string('LoadSlipID');
    l_shipment_id  := l_grn_obj.get_string('ShipmentID');
    l_doc_num      := l_grn_obj.get_string('DocNumber');
    l_oe_code      := l_grn_obj.get_string('OECode');
    l_inv_num      := l_grn_obj.get_string('InvoiceNumber');
    l_recv_date    := l_grn_obj.get_string('ReceivingDate');
    l_date1        := (to_date(l_recv_date,'DD-MON-YYYY HH24:MI:SS'));
    
    if l_loadslip_id is null then
    l_loadslip_id := 'JIT_GRN';
    end if;
    
    if l_shipment_id is null then
    l_shipment_id := 'JIT_GRN';
    end if;
      
    select count(1)
    into l_count
    from grn_detail_so
    where loadslip_id = l_loadslip_id
    and invoice_number  = l_inv_num
    and sap_doc_number    = l_doc_num 
	and oe_code = l_oe_code;
      if l_count      = 0 then
        insert
        into grn_detail_so
          (
            loadslip_id,
            shipment_id,
            oe_code,
            sap_doc_number,
            invoice_number,           
            receiving_date,
            insert_date,
            insert_user
          )
          values
          (
            l_loadslip_id,
            l_shipment_id,
            l_oe_code,
            l_doc_num,
            l_inv_num,
            l_date1,
            sysdate,
            'INTEGRATION'
          );
          
          update grn_detail_so a 
          set (a.loadslip_id,a.shipment_id) = 
          (select loadslip_id,shipment_id from del_inv_header where invoice_number= a.invoice_number) 
          where a.invoice_number = l_inv_num and a.loadslip_id in ('JIT_GRN','JIT_LS');
          commit;
          
          update loadslip a 
          set a.grn = (select listagg(sap_doc_number,'|') within group (order by sap_doc_number)
          from grn_detail_so where loadslip_id=a.loadslip_id)
          where a.loadslip_id= (select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
          
          update loadslip a 
          set a.grn_date = (select max(receiving_date)
          from grn_detail_so where loadslip_id=a.loadslip_id) 
          where a.loadslip_id=(select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
          
        commit;
        
      else
        update grn_detail_so
        set loadslip_id   =l_loadslip_id,
            shipment_id     = l_shipment_id,
            invoice_number = l_inv_num,
            sap_doc_number = l_doc_num,
            receiving_date        = l_date1,            
            update_user     = 'INTEGRATION',
            update_date     = sysdate
        where loadslip_id = l_loadslip_id
        and invoice_number  = l_inv_num
        and sap_doc_number    = l_doc_num 
        and oe_code = l_oe_code;
        
        update grn_detail_so a 
          set (a.loadslip_id,a.shipment_id) = 
          (select loadslip_id,shipment_id from del_inv_header where invoice_number= a.invoice_number) 
          where a.invoice_number = l_inv_num and a.loadslip_id in ('JIT_GRN','JIT_LS');
          
          commit;
          
        
        update loadslip a 
          set a.grn = (select listagg(sap_doc_number,'|') within group (order by sap_doc_number)
          from grn_detail_so where loadslip_id=a.loadslip_id)
          where a.loadslip_id= (select loadslip_id from grn_detail_so where invoice_number = l_inv_num);
          
          update loadslip a 
          set a.grn_date = (select max(receiving_date)
          from grn_detail_so where loadslip_id=a.loadslip_id) 
          where a.loadslip_id=(select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
       
        commit;
      end if;
	  
	  /*
    select loadslip_id,shipment_id
          into l_new_ls_id,l_new_ship_id
          from grn_detail_so where invoice_number= l_inv_num
          and rownum=1;
		  
		  -- check if GRN fully done
		  if is_grn_complete(l_new_ls_id) = 'CLOSE' then
		  -- Close Shipment
			close_pass_shipment(l_new_ship_id,l_new_ls_id);
		  end if;
      */
      end loop;
    
      
    else
    --dbms_output.put_line('Line Array not exists');
    l_grn_obj         := l_grn_response_obj.get_object('Line');
    
    l_loadslip_id  := l_grn_obj.get_string('LoadSlipID');
    l_shipment_id  := l_grn_obj.get_string('ShipmentID');
    l_doc_num      := l_grn_obj.get_string('DocNumber');
    l_oe_code      := l_grn_obj.get_string('OECode');
    l_inv_num      := l_grn_obj.get_string('InvoiceNumber');
    l_recv_date    := l_grn_obj.get_string('ReceivingDate');
    l_date1        := (to_date(l_recv_date,'DD-MON-YYYY HH24:MI:SS'));
    
    if l_loadslip_id is null then
    l_loadslip_id := 'JIT_GRN';
    end if;
    
    if l_shipment_id is null then
    l_shipment_id := 'JIT_GRN';
    end if;
    
    select count(1)
    into l_count
    from grn_detail_so
    where loadslip_id = l_loadslip_id
    and invoice_number  = l_inv_num
    and sap_doc_number    = l_doc_num 
	and oe_code = l_oe_code;
      if l_count      = 0 then
        insert
        into grn_detail_so
          (
            loadslip_id,
            shipment_id,
            oe_code,
            sap_doc_number,
            invoice_number,           
            receiving_date,
            insert_date,
            insert_user
          )
          values
          (
            l_loadslip_id,
            l_shipment_id,
            l_oe_code,
            l_doc_num,
            l_inv_num,
            l_date1,
            sysdate,
            'INTEGRATION'
          );
          
          update grn_detail_so a 
          set (a.loadslip_id,a.shipment_id) = 
          (select loadslip_id,shipment_id from del_inv_header where invoice_number= a.invoice_number) 
          where a.invoice_number = l_inv_num and a.loadslip_id in ('JIT_GRN','JIT_LS');
          commit;
          
          
          update loadslip a 
          set a.grn = (select listagg(sap_doc_number,'|') within group (order by sap_doc_number)
          from grn_detail_so where loadslip_id=a.loadslip_id)
          where a.loadslip_id= (select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
          
          update loadslip a 
          set a.grn_date = (select max(receiving_date)
          from grn_detail_so where loadslip_id=a.loadslip_id) 
          where a.loadslip_id=(select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
       
          
        commit;
     else
        update grn_detail_so
        set loadslip_id   =l_loadslip_id,
            shipment_id     = l_shipment_id,
            invoice_number = l_inv_num,
            sap_doc_number = l_doc_num,
            receiving_date        = l_date1,            
            update_user     = 'INTEGRATION',
            update_date     = sysdate
        where loadslip_id = l_loadslip_id
        and invoice_number  = l_inv_num
        and sap_doc_number    = l_doc_num 
        and oe_code = l_oe_code;
        
        update grn_detail_so a 
          set (a.loadslip_id,a.shipment_id) = 
          (select loadslip_id,shipment_id from del_inv_header where invoice_number= a.invoice_number) 
          where a.invoice_number = l_inv_num and a.loadslip_id in ('JIT_GRN','JIT_LS');
          commit;
          
        update loadslip a 
          set a.grn = (select listagg(sap_doc_number,'|') within group (order by sap_doc_number)
          from grn_detail_so where loadslip_id=a.loadslip_id)
          where a.loadslip_id= (select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
          
          update loadslip a 
          set a.grn_date = (select max(receiving_date)
          from grn_detail_so where loadslip_id=a.loadslip_id) 
          where a.loadslip_id=(select loadslip_id from grn_detail_so where invoice_number=l_inv_num);
       
        commit;
      end if;
	  
	 /* select loadslip_id,shipment_id
          into l_new_ls_id,l_new_ship_id
          from grn_detail_so where invoice_number= l_inv_num
          and rownum=1;
		  
		  -- check if GRN fully done
		  if is_grn_complete(l_new_ls_id) = 'CLOSE' then
		  -- Close Shipment
			close_pass_shipment(l_new_ship_id,l_new_ls_id);
		  end if;
     */ 
      end if;
      
      
      select loadslip_id,shipment_id
          into l_new_ls_id,l_new_ship_id
          from grn_detail_so where invoice_number= l_inv_num
          and rownum=1;
		  
		  -- check if GRN fully done
		  --if is_grn_complete(l_new_ls_id) = 'CLOSE' then
		  -- Close Shipment
			close_pass_shipment(l_new_ship_id,l_new_ls_id);
		  --end if;
      
      
     end;
  
  /*
  procedure updt_so_grn_response(
    p_data clob)
  as
  
    --l_json_clob clob;
    l_date1 date;    
    l_count pls_integer;
    l_json_obj json_object_t;
    l_grn_response_obj json_object_t; 
    l_grn_obj json_object_t;
    l_grn_line_item_arr json_array_t;
    l_loadslip_id grn_detail_so.loadslip_id%type;
    l_shipment_id grn_detail_so.shipment_id%type;  
    l_doc_num grn_detail_so.sap_doc_number%type;  
    l_inv_num grn_detail_so.invoice_number%type; 
    l_oe_code grn_detail_so.oe_code%type;
    l_recv_date varchar2(100);
    
    l_new_ls_id grn_detail_so.loadslip_id%type;
    l_new_ship_id grn_detail_so.shipment_id%type;  
    
    begin
    -- select file_data into l_json_clob from json_clob;
    -- parsing json data
    l_json_obj := json_object_t(p_data);
    -- get SOGRNResponse object
    l_grn_response_obj := l_json_obj.get_object('SOGRNResponse');
    -- get line array
    l_grn_line_item_arr    := l_grn_response_obj.get_array('Line');
    
    if l_grn_line_item_arr is not null then
    --dbms_output.put_line('Line Array exists');
    l_count := l_grn_line_item_arr.get_size;
    
    
    for i in 0 .. l_grn_line_item_arr.get_size - 1
    loop
      l_grn_obj := treat(l_grn_line_item_arr.get(i)
    as
      json_object_t);
      
    l_loadslip_id  := l_grn_obj.get_string('LoadSlipID');
    l_shipment_id  := l_grn_obj.get_string('ShipmentID');
    l_doc_num      := l_grn_obj.get_string('DocNumber');
    l_oe_code      := l_grn_obj.get_string('OECode');
    l_inv_num      := l_grn_obj.get_string('InvoiceNumber');
    l_recv_date    := l_grn_obj.get_string('ReceivingDate');
    l_date1        := (to_date(l_recv_date,'DD-MON-YYYY HH24:MI:SS'));
    
    if l_loadslip_id is null then
    l_loadslip_id := 'JIT_GRN';
    end if;
    
    if l_shipment_id is null then
    l_shipment_id := 'JIT_GRN';
    end if;
      
    select count(1)
    into l_count
    from grn_detail_so
    where loadslip_id = l_loadslip_id
    and invoice_number  = l_inv_num
    and sap_doc_number    = l_doc_num 
	and oe_code = l_oe_code;
      if l_count      = 0 then
        insert
        into grn_detail_so
          (
            loadslip_id,
            shipment_id,
            oe_code,
            sap_doc_number,
            invoice_number,           
            receiving_date,
            insert_date,
            insert_user
          )
          values
          (
            l_loadslip_id,
            l_shipment_id,
            l_oe_code,
            l_doc_num,
            l_inv_num,
            l_date1,
            sysdate,
            'INTEGRATION'
          );
          
          update grn_detail_so a 
          set (a.loadslip_id,a.shipment_id) = 
          (select loadslip_id,shipment_id from del_inv_header where invoice_number= a.invoice_number) 
          where a.invoice_number = l_inv_num and a.loadslip_id='JIT_LS';
          commit;
          
           select loadslip_id,shipment_id
          into l_new_ls_id,l_new_ship_id
          from del_inv_header where invoice_number= l_inv_num
          and rownum=1;
          
          update loadslip a 
          set a.grn = (select listagg(sap_doc_number,',') within group (order by sap_doc_number)
          from grn_detail_so where loadslip_id=a.loadslip_id)
          where a.loadslip_id= (select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
          
          update loadslip a 
          set a.grn_date = (select max(receiving_date)
          from grn_detail_so where loadslip_id=a.loadslip_id) 
          where a.loadslip_id=(select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
          
        commit;
        
      else
        update grn_detail_so
        set loadslip_id   =l_loadslip_id,
            shipment_id     = l_shipment_id,
            invoice_number = l_inv_num,
            sap_doc_number = l_doc_num,
            receiving_date        = l_date1,            
            update_user     = 'INTEGRATION',
            update_date     = sysdate
        where loadslip_id = l_loadslip_id
        and invoice_number  = l_inv_num
        and sap_doc_number    = l_doc_num 
        and oe_code = l_oe_code;
        
        update grn_detail_so a 
          set (a.loadslip_id,a.shipment_id) = 
          (select loadslip_id,shipment_id from del_inv_header where invoice_number= a.invoice_number) 
          where a.invoice_number = l_inv_num and a.loadslip_id in ('JIT_GRN','JIT_LS');
          
          commit;
           select loadslip_id,shipment_id
          into l_new_ls_id,l_new_ship_id
          from del_inv_header where invoice_number= l_inv_num
          and rownum=1;
        
        update loadslip a 
          set a.grn = (select listagg(sap_doc_number,',') within group (order by sap_doc_number)
          from grn_detail_so where loadslip_id=a.loadslip_id)
          where a.loadslip_id= (select loadslip_id from grn_detail_so where invoice_number = l_inv_num);
          
          update loadslip a 
          set a.grn_date = (select max(receiving_date)
          from grn_detail_so where loadslip_id=a.loadslip_id) 
          where a.loadslip_id=(select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
       
        commit;
      end if;

      end loop;
    
      
    else
    --dbms_output.put_line('Line Array not exists');
    l_grn_obj         := l_grn_response_obj.get_object('Line');
    
    l_loadslip_id  := l_grn_obj.get_string('LoadSlipID');
    l_shipment_id  := l_grn_obj.get_string('ShipmentID');
    l_doc_num      := l_grn_obj.get_string('DocNumber');
    l_oe_code      := l_grn_obj.get_string('OECode');
    l_inv_num      := l_grn_obj.get_string('InvoiceNumber');
    l_recv_date    := l_grn_obj.get_string('ReceivingDate');
    l_date1        := (to_date(l_recv_date,'DD-MON-YYYY HH24:MI:SS'));
    
    if l_loadslip_id is null then
    l_loadslip_id := 'JIT_GRN';
    end if;
    
    if l_shipment_id is null then
    l_shipment_id := 'JIT_GRN';
    end if;
    
    select count(1)
    into l_count
    from grn_detail_so
    where loadslip_id = l_loadslip_id
    and invoice_number  = l_inv_num
    and sap_doc_number    = l_doc_num 
	and oe_code = l_oe_code;
      if l_count      = 0 then
        insert
        into grn_detail_so
          (
            loadslip_id,
            shipment_id,
            oe_code,
            sap_doc_number,
            invoice_number,           
            receiving_date,
            insert_date,
            insert_user
          )
          values
          (
            l_loadslip_id,
            l_shipment_id,
            l_oe_code,
            l_doc_num,
            l_inv_num,
            l_date1,
            sysdate,
            'INTEGRATION'
          );
          
          update grn_detail_so a 
          set (a.loadslip_id,a.shipment_id) = 
          (select loadslip_id,shipment_id from del_inv_header where invoice_number= a.invoice_number) 
          where a.invoice_number = l_inv_num and a.loadslip_id in ('JIT_GRN','JIT_LS');
          commit;
          
          select loadslip_id,shipment_id
          into l_new_ls_id,l_new_ship_id
          from del_inv_header where invoice_number= l_inv_num
          and rownum=1;
          
          update loadslip a 
          set a.grn = (select listagg(sap_doc_number,',') within group (order by sap_doc_number)
          from grn_detail_so where loadslip_id=a.loadslip_id)
          where a.loadslip_id= (select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
          
          update loadslip a 
          set a.grn_date = (select max(receiving_date)
          from grn_detail_so where loadslip_id=a.loadslip_id) 
          where a.loadslip_id=(select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
       
          
        commit;
     else
        update grn_detail_so
        set loadslip_id   =l_loadslip_id,
            shipment_id     = l_shipment_id,
            invoice_number = l_inv_num,
            sap_doc_number = l_doc_num,
            receiving_date        = l_date1,            
            update_user     = 'INTEGRATION',
            update_date     = sysdate
        where loadslip_id = l_loadslip_id
        and invoice_number  = l_inv_num
        and sap_doc_number    = l_doc_num 
        and oe_code = l_oe_code;
        
        update grn_detail_so a 
          set (a.loadslip_id,a.shipment_id) = 
          (select loadslip_id,shipment_id from del_inv_header where invoice_number= a.invoice_number) 
          where a.invoice_number = l_inv_num and a.loadslip_id in ('JIT_GRN','JIT_LS');
          commit;
          
           select loadslip_id,shipment_id
          into l_new_ls_id,l_new_ship_id
          from del_inv_header where invoice_number= l_inv_num
          and rownum=1;
          
        update loadslip a 
          set a.grn = (select listagg(sap_doc_number,',') within group (order by sap_doc_number)
          from grn_detail_so where loadslip_id=a.loadslip_id)
          where a.loadslip_id= (select loadslip_id from grn_detail_so where invoice_number= l_inv_num);
          
          update loadslip a 
          set a.grn_date = (select max(receiving_date)
          from grn_detail_so where loadslip_id=a.loadslip_id) 
          where a.loadslip_id=(select loadslip_id from grn_detail_so where invoice_number=l_inv_num);
       
        commit;
      end if;
      
      end if;
      -- Close Shipment
      close_pass_shipment(l_new_ship_id,l_new_ls_id);
      
     end;
     */
  
  procedure updt_ds_response(
    p_data clob)
  as
  
    --l_json_clob clob;
    l_date1 date;
    l_otm_clob clob;
    l_resp_clob clob;
    l_count pls_integer;
    l_json_obj json_object_t;
    l_grn_response_obj json_object_t;
    l_grn_line_obj json_object_t;
    l_grn_linedetail_obj json_object_t;
    l_grn_linedetail_arr json_array_t;
    l_loadslip_id grn_header.loadslip_id%type;
    l_shipment_id grn_header.shipment_id%type;
    l_grn_num grn_header.grn_number%type;
    l_grn_date varchar2(100);--grn_header.grn_date%type;
    l_sap_linno grn_line.sap_line_no%type;
    l_loadslip_linno grn_line.line_no%type;
    --l_item_id grn_line.item_id%type;
    l_dit_cnt grn_line.dit_qty%type;
    l_st_cnt grn_line.short_qty%type;
    l_qty grn_line.grn_qty%type;
    --l_batch_code grn_line.batch_code%type;
  begin
    -- select file_data into l_json_clob from json_clob;
    -- parsing json data
    l_json_obj := json_object_t(p_data);
    -- get GRNResponse object
    l_grn_response_obj := l_json_obj.get_object('GRNResponse');
    -- get GRN header data
    l_loadslip_id  := l_grn_response_obj.get_string('LoadSlipID');    
    l_shipment_id  := l_grn_response_obj.get_string('ShipmentID');    
    l_grn_num      := l_grn_response_obj.get_string('GRNNumber');
    l_grn_date     := l_grn_response_obj.get_string('GRNDate');    
    l_date1        := (to_date(l_grn_date,'DD-MON-YYYY HH24:MI:SS'));
   
    /*select count(1)
    into l_count
    from grn_header
    where loadslip_id = l_loadslip_id
    and grn_number    = l_grn_num;
    */
     
      -- get GRN line object
      l_grn_line_obj    := l_grn_response_obj.get_object('GRNLineDetails');
      if l_grn_line_obj is not null then
        --dbms_output.put_line('GRN line Details object Exists');
        -- get GRN line detail object
        l_grn_linedetail_arr    := l_grn_line_obj.get_array('GRNLine');
        if l_grn_linedetail_arr is not null then
          --dbms_output.put_line('GRN line Array Exists');
          for j in 0 .. l_grn_linedetail_arr.get_size - 1
          loop
            l_grn_linedetail_obj := treat(l_grn_linedetail_arr.get(j)
          as
            json_object_t);
            l_sap_linno := l_grn_linedetail_obj.get_string('SAPLineNo');
            --dbms_output.put_line('l_sap_linno '||l_sap_linno);
            l_loadslip_linno := l_grn_linedetail_obj.get_string('LineNo');
            --l_item_id        := l_grn_linedetail_obj.get_string('MaterialCode');
            --l_qty            := l_grn_linedetail_obj.get_string('Qty');
            --l_batch_code     := l_grn_linedetail_obj.get_string('BatchCode');
            l_dit_cnt     	   := l_grn_linedetail_obj.get_string('DIT');
            l_st_cnt     	     := l_grn_linedetail_obj.get_string('Shortage');
            
            
              update grn_line
              set loadslip_id   =l_loadslip_id,
                --grn_number      = l_grn_num,
                --line_no         = l_loadslip_linno,
                --sap_line_no     = l_sap_linno,
                --item_id         = l_item_id,
                --batch_code      = l_batch_code,
                --grn_qty         = l_qty,
                dit_qty 		      = l_dit_cnt,
                short_qty		      = l_st_cnt,
                update_user     = 'INTEGRATION',
                update_date     = sysdate
              where loadslip_id = l_loadslip_id
              and grn_number    = l_grn_num
              and line_no       = l_loadslip_linno
              and sap_line_no   = l_sap_linno;
              commit;
           
          end loop;
        else
          --dbms_output.put_line('GRN line Array not Exists');
          l_grn_linedetail_obj := l_grn_line_obj.get_object('GRNLine');
          l_sap_linno          := l_grn_linedetail_obj.get_string('SAPLineNo');
          l_loadslip_linno     := l_grn_linedetail_obj.get_string('LineNo');
          --l_item_id            := l_grn_linedetail_obj.get_string('MaterialCode');
          --l_qty                := l_grn_linedetail_obj.get_string('Qty');
          --l_batch_code         := l_grn_linedetail_obj.get_string('BatchCode');
          l_dit_cnt     	     := l_grn_linedetail_obj.get_string('DIT');
          l_st_cnt     	 	     := l_grn_linedetail_obj.get_string('Shortage');
          

            update grn_line
              set loadslip_id   =l_loadslip_id,
                --grn_number      = l_grn_num,
                --line_no         = l_loadslip_linno,
                --sap_line_no     = l_sap_linno,
                --item_id         = l_item_id,
                --batch_code      = l_batch_code,
                --grn_qty         = l_qty,
                dit_qty 		      = l_dit_cnt,
                short_qty		      = l_st_cnt,
                update_user     = 'INTEGRATION',
                update_date     = sysdate
              where loadslip_id = l_loadslip_id
              and grn_number    = l_grn_num
              and line_no       = l_loadslip_linno
              and sap_line_no   = l_sap_linno;
            commit;
          end if;
          -- Sending details to OTM
          if l_loadslip_id like 'LS%' then 
          if l_dit_cnt > 0 or l_st_cnt > 0 then 
            
            l_otm_clob := '<?xml version="1.0" encoding="utf-8"?>
                            <Transmission>
                              <TransmissionHeader>
                              <SenderSystemId>ORACLE-PAAS</SenderSystemId>
                              </TransmissionHeader>
                              <TransmissionBody>
                                <GLogXMLElement>
                                  <Release>
                                    <ReleaseGid>
                                      <Gid>
                                        <DomainName>ATL</DomainName>
                                        <Xid>'||l_loadslip_id||'</Xid>
                                      </Gid>
                                    </ReleaseGid>
                                    <TransactionCode>U</TransactionCode>                                    
                                    <ReleaseLine>
                                      <ReleaseLineGid>
                                        <Gid>
                                          <DomainName>ATL</DomainName>
                                          <Xid>'||l_loadslip_id||'-'||l_loadslip_linno||'</Xid>
                                        </Gid>
                                      </ReleaseLineGid>                            
                                      <FlexFieldNumbers>
                                        <AttributeNumber4>'||l_dit_cnt||'</AttributeNumber4>
                                        <AttributeNumber5>'||l_st_cnt||'</AttributeNumber5> 
                                      </FlexFieldNumbers>                                      
                                    </ReleaseLine>                          
                                  </Release>
                                </GLogXMLElement>
                              </TransmissionBody>
                            </Transmission>';
            
            
           /* if l_dit_cnt > 0 then
            
            l_otm_clob := '<?xml version="1.0" encoding="utf-8"?>
                            <Transmission>
                              <TransmissionHeader>
                              <SenderSystemId>ORACLE-PAAS</SenderSystemId>
                              </TransmissionHeader>
                              <TransmissionBody>
                                <GLogXMLElement>
                                  <Release>
                                    <ReleaseGid>
                                      <Gid>
                                        <DomainName>ATL</DomainName>
                                        <Xid>'||l_loadslip_id||'</Xid>
                                      </Gid>
                                    </ReleaseGid>
                                    <TransactionCode>U</TransactionCode>                                    
                                    <ReleaseLine>
                                      <ReleaseLineGid>
                                        <Gid>
                                          <DomainName>ATL</DomainName>
                                          <Xid>'||l_loadslip_id||'-'||l_loadslip_linno||'</Xid>
                                        </Gid>
                                      </ReleaseLineGid>                            
                                      <FlexFieldNumbers>
                                        <AttributeNumber4>'||l_dit_cnt||'</AttributeNumber4>                                                  
                                      </FlexFieldNumbers>                                      
                                    </ReleaseLine>                          
                                  </Release>
                                </GLogXMLElement>
                              </TransmissionBody>
                            </Transmission>';
            
            
            elsif l_st_cnt > 0 then
            l_otm_clob := '<?xml version="1.0" encoding="utf-8"?>
                            <Transmission>
                              <TransmissionHeader>
                              <SenderSystemId>ORACLE-PAAS</SenderSystemId>
                              </TransmissionHeader>
                              <TransmissionBody>
                                <GLogXMLElement>
                                  <Release>
                                    <ReleaseGid>
                                      <Gid>
                                        <DomainName>ATL</DomainName>
                                        <Xid>'||l_loadslip_id||'</Xid>
                                      </Gid>
                                    </ReleaseGid>
                                    <TransactionCode>U</TransactionCode>                                    
                                    <ReleaseLine>
                                      <ReleaseLineGid>
                                        <Gid>
                                          <DomainName>ATL</DomainName>
                                          <Xid>'||l_loadslip_id||'-'||l_loadslip_linno||'</Xid>
                                        </Gid>
                                      </ReleaseLineGid>                            
                                      <FlexFieldNumbers>
                                        <AttributeNumber5>'||l_st_cnt||'</AttributeNumber5>                                                  
                                      </FlexFieldNumbers>                                      
                                    </ReleaseLine>                          
                                  </Release>
                                </GLogXMLElement>
                              </TransmissionBody>
                            </Transmission>';
            end if;
            */
            
            
            
    -- Sets character set of the body
    utl_http.set_body_charset('UTF-8');
    
    -- Clear headers before setting up
    apex_web_service.g_request_headers.delete();
    
    -- Build request header with content type and authorization
    apex_web_service.g_request_headers(1).name  := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/xml';
    apex_web_service.g_request_headers(2).name  := 'Authorization';
    apex_web_service.g_request_headers(2).value := 'Basic '||atl_app_config.c_otm_int_credential;
    
    -- Call OTM Integration API for XML processing
    --if p_instance    = 'DEV' then
      l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_dev_api_url, p_http_method => 'POST', p_body => l_otm_clob);
    --elsif p_instance = 'TEST' then
    --  l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_test_api_url, p_http_method => 'POST', p_body => l_otm_clob);
    --elsif p_instance = 'PROD' then
    --  l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_prod_api_url, p_http_method => 'POST', p_body => l_otm_clob);
    --end if;
    dbms_output.put_line('OTM Response XML: '||l_resp_clob);
    
     end if;
          
     end if;     
     
     update loadslip set (dit_qty,short_qty) = (select nvl(sum(dit_qty),0),nvl(sum(short_qty),0) from grn_line where loadslip_id=l_loadslip_id)
     where loadslip_id = l_loadslip_id;
     commit;
     
        end if;
      --else
        --dbms_output.put_line('GRN line Details object not Exists');
    --  end if;
    --end if;
    
    
    
    
  end;
  
 function is_grn_complete(
      p_loadslip_id varchar2)
    return varchar2
  as
    l_inv_cnt pls_integer;
    l_grn_cnt pls_integer;
    l_shipment_id loadslip.shipment_id%type;
  begin
        select shipment_id into l_shipment_id from loadslip where loadslip_id = p_loadslip_id;
    -- logic to invoices created from SAP
    select count(1)
    into l_inv_cnt
    from loadslip_detail
    where loadslip_id in (select loadslip_id from loadslip where shipment_id = l_shipment_id)
    and invoice_number is null
    and rownum          =1;
    if l_inv_cnt        > 0 then
      select count(1)
      into l_inv_cnt
      from loadslip_inv_line--loadslip_line_detail
      where loadslip_id in (select loadslip_id from loadslip where shipment_id = l_shipment_id);
    else
      select count(1)
      into l_inv_cnt
      from loadslip_detail
      where loadslip_id in (select loadslip_id from loadslip where shipment_id = l_shipment_id);
    end if;
  select count(1)
  into l_grn_cnt
  from grn_detail_so
  where loadslip_id in (select loadslip_id from loadslip where shipment_id = l_shipment_id);
  if l_grn_cnt      = 0 then
    select count(1) into l_grn_cnt from grn_line where loadslip_id in (select loadslip_id from loadslip where shipment_id = l_shipment_id);
  end if;
  if l_inv_cnt = l_grn_cnt or l_grn_cnt > l_inv_cnt then
    return 'CLOSE';
  else
    return 'PENDING';
  end if;
  end;
  
  procedure post_to_otm(
    p_data in clob,
    p_instance varchar2,
    p_response_code out number)
as
  l_resp_code varchar2(100);
  l_resp_clob clob;
  l_xmltype xmltype;
begin
  -- Sets character set of the body
  utl_http.set_body_charset('UTF-8');
  
  apex_web_service.g_request_headers.delete();
  
  -- Build request header with content type and authorization
  apex_web_service.g_request_headers(1).name  := 'Content-Type';
  apex_web_service.g_request_headers(1).value := 'application/xml';
  apex_web_service.g_request_headers(2).name  := 'Authorization';
  apex_web_service.g_request_headers(2).value := 'Basic '||atl_app_config.c_otm_int_credential;
  -- Call OTM Integration API for XML processing
  if p_instance    = 'DEV' then
    l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_dev_api_url, p_http_method => 'POST', p_body => p_data);
  elsif p_instance = 'TEST' then
    l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_test_api_url, p_http_method => 'POST', p_body => p_data);
  elsif p_instance = 'PROD' then
    l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_prod_api_url, p_http_method => 'POST', p_body => p_data);
  end if;
  --dbms_output.put_line('OTM Response XML: '||l_resp_clob);
  -- Convert output CLOB to XML for response reading data
  l_xmltype := xmltype.createxml(l_resp_clob);
  -- Parse response
  l_resp_code := apex_web_service.parse_xml_clob( p_xml => l_xmltype, p_xpath => '//TransmissionAck/EchoedTransmissionHeader/TransmissionHeader/ReferenceTransmissionNo/text()');
  p_response_code := to_number(l_resp_code);
  --dbms_output.put_line('OTM Response Code: '||p_response_code);
exception
when others then
  p_response_code := '0';
  --dbms_output.put_line('OTM Response Code: '||p_response_code);
  raise;
end;

  procedure post_to_otm(
      p_sql_string in varchar2,
      p_stylesheet in varchar2,
      p_instance varchar2, 
      p_response_code out number)
  as
    l_resp_code varchar2(100);
    l_resp_clob clob;
    l_xml xmltype;
    l_otm_xml xmltype;
    l_resp_xmltype xmltype;
  begin
  
    -- Create the XML as SQL
    l_xml     := atl_util_pkg.sql2xml(p_sql_string);
    
    -- Transform XML using OTM XSL
    l_otm_xml := l_xml.transform(xmltype(atl_util_pkg.get_servprov_stylesheet));
    --dbms_output.put_line('OTM XML: '||l_otm_xml.getclobval()); 
    
    -- Sets character set of the body
    utl_http.set_body_charset('UTF-8');
    
    -- Clear headers before setting up
    apex_web_service.g_request_headers.delete();
    
    -- Build request header with content type and authorization
    apex_web_service.g_request_headers(1).name  := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/xml';
    apex_web_service.g_request_headers(2).name  := 'Authorization';
    apex_web_service.g_request_headers(2).value := 'Basic '||atl_app_config.c_otm_int_credential;
    
    -- Call OTM Integration API for XML processing
    if p_instance    = 'DEV' then
      l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_dev_api_url, p_http_method => 'POST', p_body => l_otm_xml.getclobval());
    elsif p_instance = 'TEST' then
      l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_test_api_url, p_http_method => 'POST', p_body => l_otm_xml.getclobval());
    elsif p_instance = 'PROD' then
      l_resp_clob   := apex_web_service.make_rest_request(p_url => atl_app_config.c_otm_prod_api_url, p_http_method => 'POST', p_body => l_otm_xml.getclobval());
    end if;
    --dbms_output.put_line('OTM Response XML: '||l_resp_clob);
    
    -- Convert output CLOB to XML for response reading data
    l_resp_xmltype := xmltype.createxml(l_resp_clob);
    
    -- Parse response
    l_resp_code := apex_web_service.parse_xml_clob( p_xml => l_resp_xmltype, p_xpath => '//TransmissionAck/EchoedTransmissionHeader/TransmissionHeader/ReferenceTransmissionNo/text()');
    p_response_code := to_number(l_resp_code);
    --dbms_output.put_line('OTM Response Code: '||p_response_code);
  exception
  when others then
    p_response_code := '0';
    --dbms_output.put_line('OTM Response Code: '||p_response_code);
    raise;
  end;
  
  /*
  procedure close_pass_shipment(p_shipment_id varchar2, p_loadslip_id varchar2) 
  as
  l_drop_count pls_integer;
  l_comp_count pls_integer;
  l_int_num    number := integration_seq.nextval;
  l_loadslip_type loadslip.loadslip_type%type;
  begin
   
	select count(1) 
    into l_drop_count
    from shipment_stop where activity='D' and shipment_id=p_shipment_id;
    
    if l_drop_count = 1 then
    -- Single drop shipment
    begin
     update 	loadslip
        set		status = 'COMPLETED'
        where	loadslip_id = p_loadslip_id;
        
    update 	shipment
        set		status = 'COMPLETED'
        where	shipment_id = p_shipment_id;
        
        update 	truck_reporting
        set		status = 'COMPLETED'
        where	shipment_id = p_shipment_id
        and		truck_number = (select	truck_number from 	shipment
        where	shipment_id =p_shipment_id);
        
        commit;
      end;  
        atl_actual_ship_int_api.make_request(p_shipment_id,l_int_num);
        
    else
    -- Multidrop shipment
    update 	loadslip
        set		status = 'COMPLETED'
        where	loadslip_id = p_loadslip_id;
     commit;
     -- if all loadslip completed then complete shipment
     select count(1)
        into l_comp_count
        from shipment s
        where s.shipment_id= p_shipment_id
        and ( (select count(1) from loadslip where shipment_id = s.shipment_id and status = 'COMPLETED' ) = 
              (select count(1) from loadslip where shipment_id = s.shipment_id));
     if l_comp_count <> 0 then
     
     update 	shipment
        set		status = 'COMPLETED'
        where	shipment_id = p_shipment_id;
        
        update 	truck_reporting
        set		status = 'COMPLETED'
        where	shipment_id = p_shipment_id
        and		truck_number = (select	truck_number from 	shipment
        where	shipment_id =p_shipment_id);
     commit;
     
     atl_actual_ship_int_api.make_request(p_shipment_id,l_int_num);
     
     end if;
        
    end if;
	
  end;
  */
  
  procedure close_pass_shipment(p_shipment_id varchar2, p_loadslip_id varchar2) 
  as
  --l_drop_count pls_integer;
  l_comp_count pls_integer;
  l_int_num    number := integration_seq.nextval;
  l_loadslip_type loadslip.loadslip_type%type;
  l_inv_qty number;
  l_load_qty number;
  l_grn_qty number;
  l_grn_count2 pls_integer;
  begin
  -- get the order type of each loadslip link to shipment
  for i in (select a.loadslip_id,a.loadslip_type,a.sto_so_num,nvl(b.sap_order_type,b.sap_doc_type) as c_type 
            from loadslip a,order_type_lookup b 
            where a.shipment_id = p_shipment_id 
            and a.loadslip_type = b.order_type 
            and a.status <> 'CANCELLED') 
   loop
   
   if i.c_type = 'STO' then
   
   select sum(qty)
      into l_inv_qty
      from loadslip_inv_line
      where loadslip_id=i.loadslip_id;
      
   select sum(grn_qty)
      into l_grn_qty
      from grn_line
      where loadslip_id=i.loadslip_id;
   
   if l_inv_qty = l_grn_qty then
   -- complete loadslip
      update 	loadslip
            set		status = 'COMPLETED'
            where	loadslip_id = i.loadslip_id 
            and status <> 'COMPLETED';
            
      -- complete truck reporting for loadslip     
      update truck_reporting 
      set status = 'COMPLETED' 
      where (shipment_id,truck_number) = 
      (select shipment_id,truck_number from shipment where shipment_id = p_shipment_id) 
      and reporting_location = 
      (select location_id from shipment_stop where loadslip_id = i.loadslip_id 
      and activity='P' and rownum=1) and status <> 'COMPLETED';
   
   end if;
   
   elsif i.c_type = 'SO' then
   -- YBDR007 upload / basline date update   
      /*select sum(qty)
      into l_inv_qty
      from loadslip_inv_line
      where loadslip_id=i.loadslip_id;
      */
      
      
      
      /*select sum(qty) 
      into l_grn_qty
      from loadslip_inv_line where loadslip_id=i.loadslip_id 
      and invoice_number in (select invoice_number from grn_detail_so 
      where loadslip_id=i.loadslip_id);
      */
      
    --  if i.loadslip_type = 'FGS_OEM'  then
    --11/26 ADDED TWO ORDER TYPES('FGS_DEL','FGS_CM') IN IF 
     if i.loadslip_type in ('FGS_OEM','FGS_DEL','FGS_CM')  then
      select sum(qty)
      into l_inv_qty
      from loadslip_line_detail where loadslip_id=i.loadslip_id;
      
      select sum(qty)
      into l_grn_qty
      from loadslip_inv_line where loadslip_id= i.loadslip_id 
      and invoice_number in (select invoice_number from grn_detail_so 
      where loadslip_id = i.loadslip_id );
      
      else
      select sum(load_qty)
      into l_inv_qty
      from loadslip_detail where loadslip_id=i.loadslip_id;
      
      select sum(load_qty)
      into l_grn_qty
      from loadslip_detail where loadslip_id= i.loadslip_id 
      and invoice_number in (select invoice_number from grn_detail_so 
      where loadslip_id = i.loadslip_id );
      end if;
      
     if l_inv_qty = l_grn_qty then
   -- complete loadslip
      update 	loadslip
            set		status = 'COMPLETED'
            where	loadslip_id = i.loadslip_id and status <> 'COMPLETED';
            
      -- complete truck reporting for loadslip     
      update truck_reporting 
      set status = 'COMPLETED' 
      where (shipment_id,truck_number) = 
      (select shipment_id,truck_number from shipment where shipment_id = p_shipment_id) 
      and reporting_location = 
      (select location_id from shipment_stop where loadslip_id = i.loadslip_id 
      and activity='P' and rownum=1) and status <> 'COMPLETED';
      
  
   end if; 
   
 
   end if;
   
   end loop;
   
   
  -- if all loadslip completed then complete shipment and send Actuals to OTM
     select count(1)
        into l_comp_count
        from shipment s
        where s.shipment_id= p_shipment_id
        and ( (select count(1) from loadslip where shipment_id = s.shipment_id and status = 'COMPLETED' ) = 
              (select count(1) from loadslip where shipment_id = s.shipment_id and status <> 'CANCELLED'));
     if l_comp_count <> 0 then
     -- complete shipment if all loadslips are completed
     update 	shipment
        set		status = 'COMPLETED'
        where	shipment_id = p_shipment_id;-- and status <> 'COMPLETED';
    commit;
    atl_actual_ship_int_api.make_request(p_shipment_id,l_int_num);
  end if;
  commit;
  
  end;
  
  procedure post_to_atom(
      p_loadslip_id varchar2,
      p_inv_can_flag varchar2 default 'N',
      p_invoice_number varchar2)
  as    
    l_resp_clob clob;
    l_status_code varchar2(100);
    l_request_data clob;
    l_user um_user.user_id%type;
    l_user_pass um_user.password%type;
    l_int_num        NUMBER := integration_seq.nextval;
    l_int_error_seq number;
    l_err_num       number;
    l_err_msg       varchar2(100);
  begin
    
    select a.insert_user,b.password
    into l_user,l_user_pass
    from loadslip a, um_user b
    where a.loadslip_id=p_loadslip_id
    and a.insert_user = b.user_id;
    l_user_pass := atl_util_pkg.decode_base64(l_user_pass);
    l_user_pass := substr(l_user_pass,instr(l_user_pass,':')+1);
    --dbms_output.put_line('Username : '||l_user||' Paasword : '||l_user_pass);
    -- Create the XML as SQL
   -- l_xml     := atl_util_pkg.sql2xml(p_sql_string);
    
    -- Transform XML using OTM XSL
  --  l_otm_xml := l_xml.transform(xmltype(atl_util_pkg.get_servprov_stylesheet));
    --dbms_output.put_line('OTM XML: '||l_otm_xml.getclobval()); 
    
    --l_request_data := '<loadslipid>'||p_loadslip_id||'</loadslipid>';
    
    /*select json_object('itemsData' value 
           json_arrayagg(json_object('itemId' value item_id,'batchCode' value batch_code)),
           'loadslipId' value loadslip_id,
           'password' value l_user_pass,
           'username' value l_user)
    into l_request_data
    from loadslip_detail where loadslip_id=p_loadslip_id
    group by loadslip_id;
    */
    if p_inv_can_flag = 'N' then
    select json_object('itemsData' value 
           json_arrayagg(json_object('itemId' value item_id,'batchCode' value batch_code, 'quantity' value qty)),
           'invoiceNum' value invoice_number,
           'loadslipId' value loadslip_id,
           'toDispatch' value 'true',           
           'password' value l_user_pass,
           'username' value l_user)   
    into l_request_data
    from loadslip_inv_line where loadslip_id=p_loadslip_id
    and invoice_number=p_invoice_number --and rownum=1
    group by loadslip_id,invoice_number;
    else
    select json_object('itemsData' value 
           json_arrayagg(json_object('itemId' value item_id,'batchCode' value batch_code, 'quantity' value qty)),
           'invoiceNum' value invoice_number,
           'loadslipId' value loadslip_id,
           'toDispatch' value 'false',           
           'password' value l_user_pass,
           'username' value l_user)    
    into l_request_data
    from loadslip_inv_line where loadslip_id=p_loadslip_id
    and invoice_number=p_invoice_number --and rownum=1
    group by loadslip_id,invoice_number;
    end if;
   
    --dbms_output.put_line('Request payload : '||l_request_data);
    -- insert into integration log table
      atl_util_pkg.insert_integration_log(p_json_data => l_request_data, p_int_in_out => 'N', p_interface_name => 'ATOM', p_api_name => '/user/update-dispatchQty', p_status => 'NEW', p_insert_user => 'INTEGRATION', p_int_num => l_int_num);
      
    
    -- Sets character set of the body
    utl_http.set_body_charset('UTF-8');
    
    -- Clear headers before setting up
    apex_web_service.g_request_headers.delete();
    
    -- Build request header with content type
    apex_web_service.g_request_headers(1).name := 'Content-Type';  
    apex_web_service.g_request_headers(1).value := 'application/json';  
    --apex_web_service.g_request_headers(1).name  := 'userId';
    --apex_web_service.g_request_headers(1).value := l_user;
    /*apex_web_service.g_request_headers(2).name  := 'toDispatch';
    if p_inv_can_flag = 'N' then
    apex_web_service.g_request_headers(2).value := 'true';
    else
    apex_web_service.g_request_headers(2).value := 'false';
    end if;
    */
    --apex_web_service.g_request_headers(3).name  := 'loadslipId';
    --apex_web_service.g_request_headers(3).value := p_loadslip_id;
    
    -- Call OTM Integration API for XML processing
    
      l_resp_clob   := apex_web_service.make_rest_request
                      (p_url => --'http://ci.thrymr.net:8090/api/v1/user/update-dispatchQty', 
                      'https://atomcloud-test.apollotyres.com/v7/api/v1/user/update-dispatchQty', 
                       p_http_method => 'POST', 
                       p_body => l_request_data);
    
    --dbms_output.put_line('ATOM: '||l_resp_clob ||' Response code '||apex_web_service.g_status_code);
    apex_json.parse (l_resp_clob);
    l_status_code := apex_json.get_varchar2 ('statusCode');
    --dbms_output.put_line (apex_json.get_varchar2 ('statusCode'));
    if l_status_code = '200' then
    update integration_log set status ='PROCESSED',
    update_user='INTEGRATION' , update_date= sysdate
    where id = l_int_num;
    commit;
    else
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('ATOM API',l_resp_clob,-1,'INTEGRATION',l_int_error_seq);
    update integration_log set status ='ERROR',
    error_log_id = l_int_error_seq,update_user='INTEGRATION' , update_date= sysdate
    where id = l_int_num;
    commit;
    end if;
    
  exception
  when others then
  l_err_num       := sqlcode;
    l_err_msg       := substr(sqlerrm, 1, 100);
    l_int_error_seq := integration_error_seq.nextval;
    atl_util_pkg.insert_error('ATOM API',l_err_msg,l_err_num,'INTEGRATION',l_int_error_seq);
    
    update integration_log set status ='ERROR',
    error_log_id = l_int_error_seq,update_user='INTEGRATION' , update_date= sysdate
    where id = l_int_num;
    commit;
   raise;
  end;
  
    function upd_loadslip_error (p_loadslip IN loadslip.loadslip_id%type)
  return varchar2
  is
    l_err_msg loadslip.int_message%type;
    l_occurence number (3);
    l_start_position number(3);
    l_err_msg1 loadslip.int_message%type;
  BEGIN
    l_occurence := 0;
    l_err_msg := 'Error:';
  
  
    select 	REGEXP_COUNT(int_message,'<MESSAGE_TEXT>') into l_occurence 
    from 	loadslip 
    where 	loadslip_id = p_loadslip 
    and 	int_status = 'ERROR' 
    and 	int_message is not null;
  
    for i in 1..l_occurence loop
  
      l_err_msg1 := null;
          l_start_position := i;
          --dbms_output.put_line(l_start_position);
          select 	replace(substr(int_message, REGEXP_INSTR(int_message,'<MESSAGE_TEXT>', 1,l_start_position,0), (REGEXP_INSTR(int_message,'</MESSAGE_TEXT>', 1,l_start_position,0)-REGEXP_INSTR(int_message,'<MESSAGE_TEXT>', 1,l_start_position,0))),'<MESSAGE_TEXT>','') 
          into l_err_msg1 
      from 	loadslip
      where 	loadslip_id = p_loadslip 
      and 	int_status = 'ERROR' 
      and 	int_message is not null;
  
      l_err_msg := l_err_msg||chr(10)||l_err_msg1;
    end loop;
      return l_err_msg;
  end;

end atl_integration_pkg;

/
