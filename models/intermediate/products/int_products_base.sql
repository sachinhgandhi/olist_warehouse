with
    prod_snap as (
        select
            product_id,
            product_category_name,
            product_name_length,
            product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm,
            load_ts_utc,
            record_source,
            dbt_valid_from,
            dbt_valid_to
        from {{ ref("snap_products") }}
    )
select
    prod_snap.product_id,
    prod_snap.product_category_name,
    pc.product_category_name_english,
    pc.category_issue_type,
    prod_snap.product_name_length,
    prod_snap.product_description_length,
    prod_snap.product_photos_qty,
    prod_snap.product_weight_g,
    prod_snap.product_length_cm,
    prod_snap.product_height_cm,
    prod_snap.product_width_cm,
    prod_snap.load_ts_utc,
    prod_snap.record_source,
    prod_snap.dbt_valid_from,
    prod_snap.dbt_valid_to,
    case
        when prod_snap.dbt_valid_to is null then true else false
    end as is_current_record
from prod_snap
left join
    {{ ref("int_product_categories_base") }} as pc
    on coalesce(prod_snap.product_category_name, 'MISSING_CATEGORY')
    = pc.product_category_name
