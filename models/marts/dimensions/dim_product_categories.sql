with
    catg_int as (
        select
            product_category_name,
            product_category_name_english,
            load_ts_utc,
            record_source,
            category_issue_type
        from {{ ref("int_product_categories_base") }}
    )
select
    product_category_name,
    product_category_name_english,
    load_ts_utc,
    record_source,
    category_issue_type
from catg_int
