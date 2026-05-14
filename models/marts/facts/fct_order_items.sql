{{
    config(
        materialized="incremental",
        unique_key="order_lineitem_key",
        incremental_strategy="merge",
        on_schema_change="append_new_columns",
        transient=false,
    )
}}

with
    order_items_int as (
        select
            order_lineitem_key,
            order_id,
            order_item_id,
            product_id,
            seller_id,
            shipping_limit_at,
            shipping_limit_date_key,
            product_price,
            freight_value,
            total_line_amount,
            quantity,
            load_ts_utc,
            record_source
        from {{ ref("int_order_items_base") }}

        {% if is_incremental() %}
            where
                load_ts_utc >= (
                    select coalesce(max(load_ts_utc), '1900-01-01'::timestamp_ntz)
                    from {{ this }}
                )
        {% endif %}
    )
select
    order_lineitem_key,
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_at,
    shipping_limit_date_key,
    product_price,
    freight_value,
    total_line_amount,
    quantity,
    load_ts_utc,
    record_source
from order_items_int
