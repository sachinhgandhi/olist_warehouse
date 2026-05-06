with
    source_data as (
        select
            order_id,
            customer_id,
            order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date,
            load_ts
        from {{ source("olist_source_data", "raw_orders") }}
    ),
    renamed as (
        select
            order_id as order_id,  -- TEXT
            customer_id as customer_id,  -- TEXT
            lower(trim(order_status)) as order_status,  -- TEXT
            order_purchase_timestamp::timestamp_ntz as order_purchase_at,  -- TIMESTAMP_LTZ
            order_approved_at::timestamp_ntz as order_approved_at,  -- TIMESTAMP_LTZ
            order_delivered_carrier_date::timestamp_ntz as order_handed_to_carrier_at,  -- TIMESTAMP_LTZ
            order_delivered_customer_date::timestamp_ntz as order_delivered_customer_at,  -- TIMESTAMP_LTZ
            order_estimated_delivery_date::timestamp_ntz as order_estimated_delivery_at,  -- TIMESTAMP_LTZ
            load_ts::timestamp_ntz as load_ts_utc,  -- TIMESTAMP_LTZ
            'olist_source_data.raw_orders' as record_source
        from source_data
    )
select *
from renamed
