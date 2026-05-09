with
    order_header_staging as (
        select
            order_id,
            customer_id,
            order_status_code,
            order_purchase_at,
            order_approved_at,
            order_handed_to_carrier_at,
            order_delivered_customer_at,
            order_estimated_delivery_at,
            load_ts_utc,
            record_source
        from {{ ref("stg_order_header") }}
    )
select
    order_header_staging.order_id,
    order_header_staging.customer_id,
    order_header_staging.order_status_code,
    ord_st.order_status_name,
    ord_st.order_status_category,

    {{ get_date_key_format(date_value="order_header_staging.order_purchase_at") }}
    as purchase_date_key,
    order_header_staging.order_purchase_at,

    order_header_staging.order_approved_at,
    order_header_staging.order_handed_to_carrier_at,
    order_header_staging.order_delivered_customer_at,
    order_header_staging.order_estimated_delivery_at,
    order_header_staging.load_ts_utc,
    order_header_staging.record_source
from order_header_staging
left join
    {{ ref("ref_order_status") }} ord_st
    on order_header_staging.order_status_code = ord_st.order_status_code
