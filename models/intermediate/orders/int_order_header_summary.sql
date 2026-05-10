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
    ),
    order_items_base as (
        select
            oib.order_id,

            count(oib.seller_id) as total_seller_count,
            count(distinct oib.seller_id) as distinct_seller_count,

            count(oib.product_id) as total_product_count,
            count(distinct oib.product_id) as distinct_product_count,

            count(
                distinct prd.product_category_name
            ) as distinct_product_category_count,

            sum(oib.quantity) as total_product_quantity,
            sum(oib.product_price) as total_product_amount,
            sum(oib.freight_value) as total_freight_amount,
            sum(oib.total_line_amount) as total_order_amount,

            max(oib.shipping_limit_at) as max_shipping_limit_at

        from {{ ref("int_order_items_base") }} oib
        inner join {{ ref("int_products_base") }} prd on oib.product_id = prd.product_id
        group by oib.order_id
    ),
    order_payments_base as (
        select
            order_id,
            count(payment_sequential) as payment_record_count,
            avg(payment_installments) as average_installments,
            max(payment_installments) as max_installments,
            sum(payment_amount) as total_payment_received
        from {{ ref("int_order_payments_base") }}
        group by order_id
    ),
    review_score_row_number as (
        select
            order_id,
            review_score,
            row_number() over (
                partition by order_id order by review_answer_at desc
            ) as rn
        from {{ ref("int_order_reviews_base") }}
        where has_customer_responded = true
    ),
    order_reviews_base as (
        select
            ord_review.order_id,
            avg(ord_review.review_score) as avg_review_score,
            count(
                iff(ord_review.has_customer_responded, 1, null)
            ) as total_repsonded_review_count,
            max(review_score_row_number.review_score) as latest_review_score
        from {{ ref("int_order_reviews_base") }} ord_review
        left join
            review_score_row_number
            on ord_review.order_id = review_score_row_number.order_id
        where review_score_row_number.rn = 1
        group by ord_review.order_id
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
                days,
                order_header_base_int.order_purchase_at,
                order_header_base_int.order_approved_at
            )
        else null
    end as diff_between_purchase_approved_days,

    order_header_base_int.carrier_handoff_date_key,
    order_header_base_int.order_handed_to_carrier_at,
    order_header_base_int.is_handed_to_carrier,
    case
        when
            order_header_base_int.is_approved
            and order_header_base_int.is_handed_to_carrier
        then
            datediff(
                days,
                order_header_base_int.order_approved_at,
                order_header_base_int.order_handed_to_carrier_at
            )
        else null
    end as diff_between_approved_carrier_del_days,

    order_header_base_int.customer_delivery_date_key,
    order_header_base_int.order_delivered_customer_at,
    order_header_base_int.is_delivered,

    case
        when
            order_header_base_int.is_handed_to_carrier
            and order_header_base_int.is_delivered
        then
            datediff(
                days,
                order_header_base_int.order_handed_to_carrier_at,
                order_header_base_int.order_delivered_customer_at
            )
        else null
    end as diff_between_carrier_customer_del_days,

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
                        days,
                        order_header_base_int.order_estimated_delivery_at,
                        order_header_base_int.order_delivered_customer_at
                    )
                    > 0
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
            datediff(
                days,
                order_header_base_int.order_estimated_delivery_at,
                order_header_base_int.order_delivered_customer_at
            )
        else null
    end as late_delivery_days,

    case
        when order_header_base_int.is_delivered
        then
            datediff(
                days,
                order_header_base_int.order_purchase_at,
                order_header_base_int.order_delivered_customer_at
            )
        else null
    end as total_delivery_days,

    case
        when
            order_header_base_int.is_open_order
            and datediff(days, order_estimated_delivery_at, current_timestamp()) > 0
        then true
        else false
    end as is_open_past_estimated_delivery,

    order_items_base.distinct_seller_count,
    case
        when order_items_base.distinct_seller_count > 1 then true else false
    end as has_multiple_sellers,

    case
        when
            order_items_base.distinct_seller_count = 1
            and datediff(
                days,
                order_items_base.max_shipping_limit_at,
                order_header_base_int.order_handed_to_carrier_at
            )
            > 0
        then false
        else true
    end as is_seller_handoff_on_time,

    order_items_base.total_product_count,
    order_items_base.distinct_product_count,
    case
        when order_items_base.distinct_product_count > 0 then true else false
    end as has_mulitple_products,

    order_items_base.distinct_product_category_count,
    case
        when order_items_base.distinct_product_category_count > 0 then true else false
    end as has_mulitple_categories,

    order_items_base.total_product_quantity,
    order_items_base.total_product_amount,
    order_items_base.total_freight_amount,
    order_items_base.total_order_amount,

    order_payments_base.payment_record_count,
    order_payments_base.average_installments,
    order_payments_base.max_installments,
    order_payments_base.total_payment_received,

    order_items_base.total_order_amount
    - order_payments_base.total_payment_received as payment_reconciliation_diff,

    case
        when
            (
                order_items_base.total_order_amount
                - order_payments_base.total_payment_received
            )
            != 0
        then true
        else false
    end as payment_mismatch_flag,

    order_reviews_base.avg_review_score,
    order_reviews_base.total_repsonded_review_count,
    case
        when order_reviews_base.total_repsonded_review_count > 0 then true else false
    end as has_mulitple_reviews,

    order_reviews_base.latest_review_score,

    case
        when order_reviews_base.avg_review_score >= 4
        then 'HIGH_SCORE'
        when order_reviews_base.avg_review_score <= 4
        then 'LOW_SCORE'
        else 'NEUTRAL_SCORE'
    end as customer_sentiment,

    order_header_base_int.load_ts_utc,
    order_header_base_int.record_source
from order_header_base_int
left join order_items_base on order_items_base.order_id = order_header_base_int.order_id
left join
    order_payments_base on order_payments_base.order_id = order_header_base_int.order_id
left join
    order_reviews_base on order_reviews_base.order_id = order_header_base_int.order_id
