with
    source_data as (
        select product_category_name, product_category_name_english, load_ts
        from {{ source("olist_source_data", "raw_product_category") }}
    ),
    renamed as (
        select
            lower(trim(product_category_name)) as product_category_name,  -- TEXT
            lower(trim(product_category_name_english)) as product_category_name_english,  -- TEXT
            load_ts::timestamp_ntz as load_ts_utc,  -- TIMESTAMP_NTZ
            'olist_source_data.raw_product_category' as record_source
        from source_data
    )
select *
from renamed
