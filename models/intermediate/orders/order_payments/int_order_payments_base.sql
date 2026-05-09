with
    order_payments_staging as (
        select
            order_id,
            payment_sequential,
            payment_type_code,
            payment_installments,
            payment_amount,
            load_ts_utc,
            record_source
        from {{ ref("stg_order_payments") }}
    )
select
    {{ dbt_utils.generate_surrogate_key(["order_id", "payment_sequential"]) }}
    as order_payment_key,
    order_payments_staging.order_id,
    order_payments_staging.payment_sequential,
    order_payments_staging.payment_type_code,
    ref_pt.payment_type_name,
    ref_pt.payment_category,
    ref_pt.is_installment_supported,
    order_payments_staging.payment_installments,
    case
        when order_payments_staging.payment_installments > 1 then true else false
    end as is_installment_payment,
    order_payments_staging.payment_amount,
    order_payments_staging.load_ts_utc,
    order_payments_staging.record_source
from order_payments_staging
left join
    {{ ref("ref_payment_types") }} as ref_pt
    on order_payments_staging.payment_type_code = ref_pt.payment_type_code
