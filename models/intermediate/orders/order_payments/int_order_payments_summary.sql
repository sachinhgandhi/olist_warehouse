{{ config(materialized="table") }}

with
    order_payments_base as (
        select
            order_id,
            count(payment_sequential) as payment_record_count,
            avg(payment_installments) as average_installments,
            max(payment_installments) as max_installments,
            sum(payment_amount) as total_payment_received,
            max(load_ts_utc) as max_load_ts_utc

        from {{ ref("int_order_payments_base") }}
        group by order_id
    )
select
    order_payments_base.order_id,
    order_payments_base.payment_record_count,
    order_payments_base.average_installments,
    order_payments_base.max_installments,
    order_payments_base.total_payment_received,
    order_payments_base.max_load_ts_utc
from order_payments_base
