with
    source_data as (
        select
            order_id,
            payment_sequential,
            payment_type,
            payment_installments,
            payment_value,
            load_ts
        from {{ source("olist_source_data", "raw_order_payments") }}
    ),
    renamed as (
        select
            order_id as order_id,  -- TEXT
            payment_sequential::number as payment_sequential,  -- NUMBER
            lower(trim(payment_type)) as payment_type,  -- TEXT
            payment_installments::number as payment_installments,  -- NUMBER
            payment_value::number(18, 2) as payment_amount,  -- NUMBER
            load_ts::timestamp_ntz as load_ts_utc,  -- TIMESTAMP_LTZ
            'olist_source_data.raw_order_payments' as record_source
        from source_data
    )
select *
from renamed
