{{ config(materialized="table") }}

with
    cat_staging as (
        select
            product_category_name,
            product_category_name_english,
            load_ts_utc,
            record_source,
            'VALID_CATEGORY' as category_issue_type
        from {{ ref("stg_product_categories") }}
    ),
    cat_missing as (
        select distinct
            coalesce(product_category_name, 'MISSING_CATEGORY') as product_category_name
        from {{ ref("snap_products") }} prd
        where
            not exists (
                select *
                from cat_staging
                where cat_staging.product_category_name = prd.product_category_name
            )
    ),
    cat_union as (
        select
            product_category_name,
            product_category_name_english,
            load_ts_utc,
            record_source,
            category_issue_type
        from cat_staging
        union all
        select
            product_category_name,
            product_category_name as product_category_name_english,
            null as load_ts_utc,
            'DQ.RECONCILIATION' as record_source,
            case
                when product_category_name = 'MISSING_CATEGORY'
                then 'NULL_CATEGORY'
                else 'UNMAPPED_CATEGORY'
            end category_issue_type
        from cat_missing
    )
select
    product_category_name,
    coalesce(
        product_category_name_english, product_category_name
    ) as product_category_name_english,
    load_ts_utc,
    record_source,
    category_issue_type
from cat_union
