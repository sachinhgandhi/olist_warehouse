with
    order_items_staging as (
        select
            order_id,
            order_item_id,
            product_id,
            seller_id,
            shipping_limit_at,
            product_price,
            freight_value,
            load_ts_utc,
            record_source
        from {{ ref("stg_order_items") }}
    )
select
    {{ dbt_utils.generate_surrogate_key(["order_id", "order_item_id"]) }}
    as order_lineitem_key,
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_at,
    to_number(to_char(shipping_limit_at, 'YYYYMMDD')) as shipping_limit_date_key,
    product_price,
    freight_value,
    (product_price + freight_value) as total_line_amount,
    1::number as quantity,
    load_ts_utc,
    record_source
from order_items_staging
