{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="order_id",
        transient=false,
        on_schema_change="append_new_columns",
    )
}}

with
    order_header_int as (
        select
            order_key,
            order_id,
            customer_id,

            order_status_code,
            order_status_name,
            order_status_category,

            purchase_date_key,
            order_purchase_at,
            is_purchased,

            approved_date_key,
            order_approved_at,
            is_approved,
            diff_between_purchase_approved_days,

            carrier_handoff_date_key,
            order_handed_to_carrier_at,
            is_handed_to_carrier,
            diff_between_approved_carrier_del_days,

            customer_delivery_date_key,
            order_delivered_customer_at,
            is_delivered,
            diff_between_carrier_customer_del_days,

            estimated_delivery_date_key,
            order_estimated_delivery_at,

            is_cancelled,
            is_unavailable,
            is_open_order,

            is_delivered_on_time,
            late_delivery_days,

            total_delivery_days,

            is_open_past_estimated_delivery,

            distinct_seller_count,
            has_multiple_sellers,

            is_seller_handoff_on_time,

            total_product_count,
            distinct_product_count,
            has_multiple_products,

            distinct_product_category_count,
            has_multiple_categories,

            total_product_quantity,
            total_product_amount,
            total_freight_amount,
            total_order_amount,

            payment_record_count,
            average_installments,
            max_installments,
            total_payment_received,

            payment_reconciliation_diff,

            payment_mismatch_flag,

            avg_review_score,
            total_responded_review_count,
            has_multiple_reviews,

            latest_review_score,

            customer_sentiment,

            load_ts_utc,
            record_source
        from {{ ref("int_order_header_summary") }}

        {% if is_incremental() %}
            where
                load_ts_utc > (
                    select coalesce(max(load_ts_utc), '1900-01-01'::timestamp_ntz)
                    from {{ this }}
                )
        {% endif %}
    )
select
    order_key,
    order_id,
    customer_id,

    order_status_code,
    order_status_name,
    order_status_category,

    purchase_date_key,
    order_purchase_at,
    is_purchased,

    approved_date_key,
    order_approved_at,
    is_approved,
    diff_between_purchase_approved_days,

    carrier_handoff_date_key,
    order_handed_to_carrier_at,
    is_handed_to_carrier,
    diff_between_approved_carrier_del_days,

    customer_delivery_date_key,
    order_delivered_customer_at,
    is_delivered,
    diff_between_carrier_customer_del_days,

    estimated_delivery_date_key,
    order_estimated_delivery_at,

    is_cancelled,
    is_unavailable,
    is_open_order,

    is_delivered_on_time,
    late_delivery_days,

    total_delivery_days,

    is_open_past_estimated_delivery,

    distinct_seller_count,
    has_multiple_sellers,

    is_seller_handoff_on_time,

    total_product_count,
    distinct_product_count,
    has_multiple_products,

    distinct_product_category_count,
    has_multiple_categories,

    total_product_quantity,
    total_product_amount,
    total_freight_amount,
    total_order_amount,

    payment_record_count,
    average_installments,
    max_installments,
    total_payment_received,

    payment_reconciliation_diff,

    payment_mismatch_flag,

    avg_review_score,
    total_responded_review_count,
    has_multiple_reviews,

    latest_review_score,

    customer_sentiment,

    load_ts_utc,
    record_source
from order_header_int
