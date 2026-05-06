with
    source_data as (
        select
            order_id,
            order_item_id,
            product_id,
            seller_id,
            shipping_limit_date,
            price,
            freight_value,
            load_ts
        from {{ source("olist_source_data", "raw_order_items") }}
    ),
    renamed as (
        select
            order_id as order_id,  -- TEXT
            order_item_id::number as order_item_id,  -- NUMBER
            product_id as product_id,  -- TEXT
            seller_id as seller_id,  -- TEXT
            shipping_limit_date::timestamp_ntz as shipping_limit_at,  -- TIMESTAMP_NTZ
            price::number(18, 2) as product_price,  -- NUMBER
            freight_value::number(18, 2) as freight_value,  -- NUMBER
            load_ts::timestamp_ntz as load_ts_utc,  -- TIMESTAMP_LTZ
            'olist_source_data.raw_order_items' as record_source
        from source_data
    )
select *
from renamed
