{{ config(materialized="table") }}

with
    int_order_header_base as (
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

            carrier_handoff_date_key,
            order_handed_to_carrier_at,
            is_handed_to_carrier,

            customer_delivery_date_key,
            order_delivered_customer_at,
            is_delivered,

            estimated_delivery_date_key,
            order_estimated_delivery_at,

            is_cancelled,
            is_unavailable,
            is_open_order,
            is_valid_order,

            load_ts_utc,
            record_source
        from {{ ref("int_order_header_base") }}
    )
select
    int_order_header_base.order_key,
    int_order_header_base.order_id,
    int_order_header_base.customer_id,

    int_order_header_base.order_status_code,
    int_order_header_base.order_status_name,
    int_order_header_base.order_status_category,

    int_order_header_base.purchase_date_key,
    int_order_header_base.order_purchase_at,
    int_order_header_base.is_purchased,

    int_order_header_base.approved_date_key,
    int_order_header_base.order_approved_at,
    int_order_header_base.is_approved,
    case
        when int_order_header_base.is_approved
        then
            datediff(
                day,
                int_order_header_base.order_purchase_at,
                int_order_header_base.order_approved_at
            )
        else null
    end as diff_between_purchase_approved_days,

    int_order_header_base.carrier_handoff_date_key,
    int_order_header_base.order_handed_to_carrier_at,
    int_order_header_base.is_handed_to_carrier,
    case
        when
            int_order_header_base.is_approved
            and int_order_header_base.is_handed_to_carrier
        then
            datediff(
                day,
                int_order_header_base.order_approved_at,
                int_order_header_base.order_handed_to_carrier_at
            )
        else null
    end as diff_between_approved_carrier_del_days,

    int_order_header_base.customer_delivery_date_key,
    int_order_header_base.order_delivered_customer_at,
    int_order_header_base.is_delivered,

    case
        when
            int_order_header_base.is_handed_to_carrier
            and int_order_header_base.is_delivered
        then
            datediff(
                day,
                int_order_header_base.order_handed_to_carrier_at,
                int_order_header_base.order_delivered_customer_at
            )
        else null
    end as diff_between_carrier_customer_del_days,

    int_order_header_base.estimated_delivery_date_key,
    int_order_header_base.order_estimated_delivery_at,

    int_order_header_base.is_cancelled,
    int_order_header_base.is_unavailable,
    int_order_header_base.is_open_order,
    int_order_header_base.is_valid_order,

    case
        when
            int_order_header_base.order_estimated_delivery_at is not null
            and int_order_header_base.is_delivered
        then
            case
                when
                    datediff(
                        day,
                        int_order_header_base.order_estimated_delivery_at,
                        int_order_header_base.order_delivered_customer_at
                    )
                    > 1
                then false
                else true
            end
        else null
    end as is_delivered_on_time,

    case
        when
            int_order_header_base.order_estimated_delivery_at is not null
            and int_order_header_base.is_delivered
        then
            greatest(
                datediff(
                    day,
                    int_order_header_base.order_estimated_delivery_at,
                    int_order_header_base.order_delivered_customer_at
                ),
                0
            )
        else null
    end as late_delivery_days,

    case
        when int_order_header_base.is_delivered
        then
            datediff(
                day,
                int_order_header_base.order_purchase_at,
                int_order_header_base.order_delivered_customer_at
            )
        else null
    end as total_delivery_days,

    case
        when
            int_order_header_base.is_open_order
            and datediff(day, order_estimated_delivery_at, current_timestamp()) > 1
        then true
        else false
    end as is_open_past_estimated_delivery,

    int_order_items_summary.distinct_seller_count,
    case
        when int_order_items_summary.distinct_seller_count > 1 then true else false
    end as has_multiple_sellers,

    case
        when int_order_items_summary.distinct_seller_count = 1
        then
            case
                when
                    datediff(
                        day,
                        int_order_items_summary.max_shipping_limit_at,
                        int_order_header_base.order_handed_to_carrier_at
                    )
                    > 0
                then false
                else true
            end
        else null
    end as is_seller_handoff_on_time,

    int_order_items_summary.total_product_count,
    int_order_items_summary.distinct_product_count,
    case
        when int_order_items_summary.distinct_product_count > 1 then true else false
    end as has_multiple_products,

    int_order_items_summary.distinct_product_category_count,
    case
        when int_order_items_summary.distinct_product_category_count > 1
        then true
        else false
    end as has_multiple_categories,

    int_order_items_summary.total_product_quantity,
    int_order_items_summary.total_product_amount,
    int_order_items_summary.total_freight_amount,
    int_order_items_summary.total_order_amount,

    int_order_payments_summary.payment_record_count,
    int_order_payments_summary.average_installments,
    int_order_payments_summary.max_installments,
    int_order_payments_summary.total_payment_received,

    coalesce(int_order_items_summary.total_order_amount, 0) - coalesce(
        int_order_payments_summary.total_payment_received, 0
    ) as payment_reconciliation_diff,

    case
        when
            (
                abs(
                    round(
                        coalesce(
                            int_order_items_summary.total_order_amount,
                            0
                        ) - coalesce(
                            int_order_payments_summary.total_payment_received, 0
                        ),
                        2
                    )
                )
            )
            > 0.01
        then true
        else false
    end as payment_mismatch_flag,

    int_order_reviews_summary.avg_review_score,
    int_order_reviews_summary.total_responded_review_count,
    case
        when int_order_reviews_summary.total_responded_review_count > 1
        then true
        else false
    end as has_multiple_reviews,

    int_order_reviews_summary.latest_review_score,

    case
        when int_order_reviews_summary.avg_review_score >= 4
        then 'HIGH_SCORE'
        when int_order_reviews_summary.avg_review_score <= 2
        then 'LOW_SCORE'
        when int_order_reviews_summary.avg_review_score is null
        then null
        else 'NEUTRAL_SCORE'
    end as customer_sentiment,

    greatest(
        int_order_header_base.load_ts_utc,
        coalesce(
            int_order_items_summary.max_load_ts_utc, int_order_header_base.load_ts_utc
        ),
        coalesce(
            int_order_payments_summary.max_load_ts_utc,
            int_order_header_base.load_ts_utc
        ),
        coalesce(
            int_order_reviews_summary.max_load_ts_utc, int_order_header_base.load_ts_utc
        )
    ) as load_ts_utc,
    {# int_order_header_base.load_ts_utc, #}
    int_order_header_base.record_source
from int_order_header_base
left join
    {{ ref("int_order_items_summary") }} int_order_items_summary
    on int_order_items_summary.order_id = int_order_header_base.order_id
left join
    {{ ref("int_order_payments_summary") }} int_order_payments_summary
    on int_order_payments_summary.order_id = int_order_header_base.order_id
left join
    {{ ref("int_order_reviews_summary") }} int_order_reviews_summary
    on int_order_reviews_summary.order_id = int_order_header_base.order_id
