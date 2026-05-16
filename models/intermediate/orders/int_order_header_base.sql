{{ config(materialized="table") }}

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
    {{ dbt_utils.generate_surrogate_key(["order_id", "customer_id"]) }} as order_key,

    order_header_staging.order_id,
    order_header_staging.customer_id,

    order_header_staging.order_status_code,
    ord_st.order_status_name,
    ord_st.order_status_category,

    {{ get_date_key(date_value="order_header_staging.order_purchase_at") }}
    as purchase_date_key,
    order_header_staging.order_purchase_at,
    true as is_purchased,

    {{ get_date_key(date_value="order_header_staging.order_approved_at") }}
    as approved_date_key,
    order_header_staging.order_approved_at,
    case
        when order_header_staging.order_approved_at is not null then true else false
    end is_approved,

    {{ get_date_key(date_value="order_header_staging.order_handed_to_carrier_at") }}
    as carrier_handoff_date_key,
    order_header_staging.order_handed_to_carrier_at,

    case
        when order_header_staging.order_handed_to_carrier_at is not null
        then true
        else false
    end is_handed_to_carrier,

    {{ get_date_key(date_value="order_header_staging.order_delivered_customer_at") }}
    as customer_delivery_date_key,
    order_header_staging.order_delivered_customer_at,

    case
        when order_header_staging.order_delivered_customer_at is not null
        then true
        else false
    end is_delivered,

    {{ get_date_key(date_value="order_header_staging.order_estimated_delivery_at") }}
    as estimated_delivery_date_key,
    order_header_staging.order_estimated_delivery_at,

    ord_st.is_cancelled_order as is_cancelled,

    ord_st.is_unavailable_order as is_unavailable,

    case
        when
            ord_st.is_cancelled_order = false
            and ord_st.is_unavailable_order = false
            and ord_st.is_active_order = true
        then false
        else true
    end as is_open_order,

    case
        when not ord_st.is_cancelled_order and not ord_st.is_unavailable_order
        then true
        else false
    end as is_valid_order,

    order_header_staging.load_ts_utc,
    order_header_staging.record_source
from order_header_staging
left join
    {{ ref("ref_order_status") }} ord_st
    on order_header_staging.order_status_code = ord_st.order_status_code
