{{ config(materialized="table") }}

with
    fct_orders_accum_snap as (
        select
            order_id,
            order_purchase_at,
            order_handed_to_carrier_at,
            order_delivered_customer_at,
            is_delivered,
            order_estimated_delivery_at,
            is_delivered_on_time,
            late_delivery_days,
            total_delivery_days,
            has_multiple_sellers,
            is_seller_handoff_on_time,
            is_open_past_estimated_delivery,
            is_open_order
        from {{ ref("fct_orders_accum_snap") }}
        where is_valid_order = true
    ),
    monthly as (

        select
            date_trunc('month', order_purchase_at)::date as month_start_date,
            to_char(order_purchase_at, 'YYYY-MM') as year_month,
            year(order_purchase_at) as year_number,
            month(order_purchase_at) as month_number,

            count(
                distinct case when is_delivered then order_id end
            ) as delivered_order_count,

            count(
                distinct case
                    when is_delivered and is_delivered_on_time = true then order_id
                end
            ) as on_time_delivered_order_count,

            count(
                distinct case
                    when is_delivered and is_delivered_on_time = false then order_id
                end
            ) as late_delivery_order_count,

            count(
                distinct case
                    when is_delivered and has_multiple_sellers = false then order_id
                end
            ) as delivered_order_count_single_seller,

            avg(
                case when is_delivered then total_delivery_days else null end
            ) as average_delivery_days,

            avg(
                case
                    when
                        is_delivered
                        and is_delivered_on_time = false
                        and late_delivery_days > 0
                    then late_delivery_days
                    else null
                end
            ) as average_late_days,

            count(
                distinct case
                    when is_delivered = false and is_open_order then order_id
                end
            ) as open_order_count,

            count(
                distinct case when is_open_past_estimated_delivery then order_id end
            ) as open_past_estimated_delivery_count,

            count(
                distinct case
                    when
                        has_multiple_sellers = false
                        and is_seller_handoff_on_time = true
                    then order_id
                end
            ) as seller_handoff_on_time_count,

            count(
                distinct case
                    when
                        has_multiple_sellers = false
                        and is_seller_handoff_on_time = false
                    then order_id
                end
            ) as seller_handoff_not_on_time_count

        from fct_orders_accum_snap
        group by
            date_trunc('month', order_purchase_at)::date,
            to_char(order_purchase_at, 'YYYY-MM'),
            year(order_purchase_at),
            month(order_purchase_at)
    ),
    final as (
        select
            monthly.*,

            round(
                (late_delivery_order_count / nullif(delivered_order_count, 0)), 4
            ) as late_delivery_rate,

            round(
                (
                    seller_handoff_on_time_count
                    / nullif(delivered_order_count_single_seller, 0)
                ),
                4
            ) as seller_handoff_on_time_rate
        from monthly
    )
select *
from final
