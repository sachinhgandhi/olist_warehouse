{{ config(materialized="table") }}

with
    order_header_base_int as (
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

            load_ts_utc,
            record_source
        from {{ ref("int_order_header_base") }}
    )
select
    order_header_base_int.order_key,
    order_header_base_int.order_id,
    order_header_base_int.customer_id,

    order_header_base_int.order_status_code,
    order_header_base_int.order_status_name,
    order_header_base_int.order_status_category,

    order_header_base_int.purchase_date_key,
    order_header_base_int.order_purchase_at,
    order_header_base_int.is_purchased,

    order_header_base_int.approved_date_key,
    order_header_base_int.order_approved_at,
    order_header_base_int.is_approved,
    case
        when order_header_base_int.is_approved
        then
            datediff(
                day,
                order_header_base_int.order_purchase_at,
                order_header_base_int.order_approved_at
            )
        else null
    end as diff_between_purchase_approved_day,

    order_header_base_int.carrier_handoff_date_key,
    order_header_base_int.order_handed_to_carrier_at,
    order_header_base_int.is_handed_to_carrier,
    case
        when
            order_header_base_int.is_approved
            and order_header_base_int.is_handed_to_carrier
        then
            datediff(
                day,
                order_header_base_int.order_approved_at,
                order_header_base_int.order_handed_to_carrier_at
            )
        else null
    end as diff_between_approved_carrier_del_day,

    order_header_base_int.customer_delivery_date_key,
    order_header_base_int.order_delivered_customer_at,
    order_header_base_int.is_delivered,

    case
        when
            order_header_base_int.is_handed_to_carrier
            and order_header_base_int.is_delivered
        then
            datediff(
                day,
                order_header_base_int.order_handed_to_carrier_at,
                order_header_base_int.order_delivered_customer_at
            )
        else null
    end as diff_between_carrier_customer_del_day,

    order_header_base_int.estimated_delivery_date_key,
    order_header_base_int.order_estimated_delivery_at,

    order_header_base_int.is_cancelled,
    order_header_base_int.is_unavailable,
    order_header_base_int.is_open_order,

    case
        when
            order_header_base_int.order_estimated_delivery_at is not null
            and order_header_base_int.is_delivered
        then
            case
                when
                    datediff(
                        day,
                        order_header_base_int.order_estimated_delivery_at,
                        order_header_base_int.order_delivered_customer_at
                    )
                    > 1
                then false
                else true
            end
        else null
    end as is_delivered_on_time,

    case
        when
            order_header_base_int.order_estimated_delivery_at is not null
            and order_header_base_int.is_delivered
        then
            greatest(
                datediff(
                    day,
                    order_header_base_int.order_estimated_delivery_at,
                    order_header_base_int.order_delivered_customer_at
                ),
                0
            )
        else null
    end as late_delivery_day,

    case
        when order_header_base_int.is_delivered
        then
            datediff(
                day,
                order_header_base_int.order_purchase_at,
                order_header_base_int.order_delivered_customer_at
            )
        else null
    end as total_delivery_day,

    case
        when
            order_header_base_int.is_open_order
            and datediff(day, order_estimated_delivery_at, current_timestamp()) > 1
        then true
        else false
    end as is_open_past_estimated_delivery,

    order_items_base.distinct_seller_count,
    case
        when order_items_base.distinct_seller_count > 1 then true else false
    end as has_multiple_sellers,

    case
        when order_items_base.distinct_seller_count = 1
        then
            case
                when
                    datediff(
                        day,
                        order_items_base.max_shipping_limit_at,
                        order_header_base_int.order_handed_to_carrier_at
                    )
                    > 0
                then false
                else true
            end
        else null
    end as is_seller_handoff_on_time,

    order_items_base.total_product_count,
    order_items_base.distinct_product_count,
    case
        when order_items_base.distinct_product_count > 1 then true else false
    end as has_multiple_products,

    order_items_base.distinct_product_category_count,
    case
        when order_items_base.distinct_product_category_count > 1 then true else false
    end as has_multiple_categories,

    order_items_base.total_product_quantity,
    order_items_base.total_product_amount,
    order_items_base.total_freight_amount,
    order_items_base.total_order_amount,

    order_payments_base.payment_record_count,
    order_payments_base.average_installments,
    order_payments_base.max_installments,
    order_payments_base.total_payment_received,

    coalesce(order_items_base.total_order_amount, 0) - coalesce(
        order_payments_base.total_payment_received, 0
    ) as payment_reconciliation_diff,

    case
        when
            (
                abs(
                    round(
                        coalesce(order_items_base.total_order_amount, 0)
                        - coalesce(order_payments_base.total_payment_received, 0),
                        2
                    )
                )
            )
            > 0.01
        then true
        else false
    end as payment_mismatch_flag,

    order_reviews_base.avg_review_score,
    order_reviews_base.total_repsonded_review_count,
    case
        when order_reviews_base.total_repsonded_review_count > 1 then true else false
    end as has_multiple_reviews,

    order_reviews_base.latest_review_score,

    case
        when order_reviews_base.avg_review_score >= 4
        then 'HIGH_SCORE'
        when order_reviews_base.avg_review_score <= 2
        then 'LOW_SCORE'
        when order_reviews_base.avg_review_score is null
        then null
        else 'NEUTRAL_SCORE'
    end as customer_sentiment,

    order_header_base_int.load_ts_utc,
    order_header_base_int.record_source
from order_header_base_int
left join
    {{ ref("int_order_items_summary") }} order_items_base
    on order_items_base.order_id = order_header_base_int.order_id
left join
    {{ ref("int_order_payments_summary") }} order_payments_base
    on order_payments_base.order_id = order_header_base_int.order_id
left join
    {{ ref("int_order_reviews_summary") }} order_reviews_base
    on order_reviews_base.order_id = order_header_base_int.order_id
