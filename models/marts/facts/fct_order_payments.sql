{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="order_payment_key",
        on_schema_change="append_new_columns",
        transient=false,
    )
}}

with
    order_payments_int as (
        select
            order_payment_key,
            order_id,
            payment_sequential,
            payment_type_code,
            payment_type_name,
            payment_category,
            is_installment_supported,
            payment_installments,
            is_installment_payment,
            payment_amount,
            load_ts_utc,
            record_source
        from {{ ref("int_order_payments_base") }}

        {% if is_incremental() %}
            where
                load_ts_utc >= (
                    select coalesce(max(load_ts_utc), '1900-01-01'::timestamp_ntz)
                    from {{ this }}
                )
        {% endif %}
    )
select
    order_payment_key,
    order_id,
    payment_sequential,
    payment_type_code,
    payment_type_name,
    payment_category,
    is_installment_supported,
    payment_installments,
    is_installment_payment,
    payment_amount,
    load_ts_utc,
    record_source
from order_payments_int
