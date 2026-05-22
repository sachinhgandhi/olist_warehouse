{{ config(materialized="table") }}

with
    orders as (
        select
            order_id,
            customer_id,

            is_delivered,
            is_open_order,
            is_cancelled,
            is_unavailable,
            is_valid_order,

            total_product_amount,
            total_freight_amount,
            total_order_amount,

            order_purchase_at,

            total_delivery_days,
            is_delivered_on_time,
            late_delivery_days,

            avg_review_score,
            payment_mismatch_flag,
            payment_reconciliation_diff

        from {{ ref("fct_orders_accum_snap") }}
    ),
    cust as (
        select
            customer_id,
            customer_unique_id,
            zip_code_prefix,
            city_name,
            state_code,
            state_name,
            region_name,
            dbt_valid_from,
            dbt_valid_to,
            is_current_record
        from {{ ref("dim_customers_history") }}
    ),
    order_cust as (
        select
            orders.order_id,

            orders.customer_id,
            cust.customer_unique_id,
            cust.zip_code_prefix,
            cust.city_name,
            cust.state_code,
            cust.state_name,
            cust.region_name,

            orders.is_delivered,
            orders.is_open_order,
            orders.is_cancelled,
            orders.is_unavailable,
            orders.is_valid_order,

            orders.total_product_amount,
            orders.total_freight_amount,
            orders.total_order_amount,

            orders.order_purchase_at,

            orders.total_delivery_days,
            orders.is_delivered_on_time,
            orders.late_delivery_days,

            orders.avg_review_score,
            orders.payment_mismatch_flag,
            orders.payment_reconciliation_diff

        from orders
        left join
            cust
            on orders.customer_id = cust.customer_id
            and orders.order_purchase_at >= cust.dbt_valid_from
            and orders.order_purchase_at
            < coalesce(cust.dbt_valid_to, '9999-12-31'::timestamp_ntz)
    ),
    monthly as (

        select

            date_trunc('month', order_purchase_at)::date as month_start_date,
            {{
                get_date_key(
                    date_value="date_trunc('month', order_purchase_at)::date"
                )
            }} as month_start_date_key,
            to_char(order_cust.order_purchase_at, 'YYYY-MM') as year_month,
            year(order_cust.order_purchase_at) as year_number,
            month(order_cust.order_purchase_at) as month_number,

            count(distinct order_cust.order_id) as gross_order_count,
            sum(order_cust.total_order_amount)::number(18, 2) as gross_revenue,

            count(
                distinct case
                    when order_cust.is_valid_order then order_cust.order_id
                end
            ) as valid_order_count,

            sum(
                case
                    when order_cust.is_valid_order
                    then order_cust.total_order_amount
                    else 0
                end
            )::number(18, 2) as booked_revenue,

            count(
                distinct case
                    when order_cust.is_delivered = true then order_cust.order_id
                end
            ) as delivered_order_count,

            sum(
                case
                    when order_cust.is_delivered
                    then order_cust.total_order_amount
                    else 0
                end
            )::number(18, 2) as delivered_revenue,

            count(
                distinct case
                    when order_cust.is_cancelled = true then order_cust.order_id
                end
            ) as cancelled_order_count,

            count(
                distinct case
                    when order_cust.is_unavailable = true then order_cust.order_id
                end
            ) as unavailable_order_count,

            count(
                distinct case
                    when order_cust.is_open_order = true then order_cust.order_id
                end
            ) as open_order_count,

            count(
                distinct case
                    when order_cust.is_valid_order then order_cust.customer_unique_id
                end
            ) as unique_customer_count,

            round(
                (
                    sum(
                        case
                            when order_cust.is_valid_order
                            then order_cust.total_order_amount
                            else 0
                        end
                    ) / nullif(
                        count(
                            distinct case
                                when order_cust.is_valid_order then order_id
                            end
                        ),
                        0
                    )
                ),
                4
            ) as average_order_value,

            avg(
                case
                    when order_cust.is_delivered then order_cust.total_delivery_days
                end
            ) as average_delivery_days,

            round(
                case
                    when
                        count(
                            distinct case when order_cust.is_delivered then order_id end
                        )
                        = 0
                    then null
                    else
                        count(
                            distinct
                            case
                                when
                                    order_cust.is_delivered
                                    and order_cust.is_delivered_on_time = false
                                then order_id
                            end
                        ) / nullif(
                            count(
                                distinct case
                                    when order_cust.is_delivered then order_id
                                end
                            ),
                            0
                        )
                end,
                4
            ) as late_delivery_rate,

            avg(
                case
                    when order_cust.is_delivered and order_cust.late_delivery_days > 0
                    then order_cust.late_delivery_days
                end
            ) as average_late_days,

            avg(
                case when order_cust.is_valid_order then order_cust.avg_review_score end
            ) as average_review_score,

            count(
                distinct case
                    when order_cust.is_valid_order and order_cust.payment_mismatch_flag
                    then order_id
                end
            ) as payment_mismatch_order_count

        from order_cust
        group by
            date_trunc('month', order_purchase_at)::date,
            {{
                get_date_key(
                    date_value="date_trunc('month', order_purchase_at)::date"
                )
            }},
            to_char(order_cust.order_purchase_at, 'YYYY-MM'),
            year(order_cust.order_purchase_at),
            month(order_cust.order_purchase_at)
    ),
    final as (
        select
            monthly.*,

            lag(booked_revenue) over (order by month_start_date)::number(
                18, 2
            ) as previous_month_booked_revenue,

            round(
                (booked_revenue - lag(booked_revenue) over (order by month_start_date))
                / nullif(lag(booked_revenue) over (order by month_start_date), 0),
                4
            ) as booked_revenue_growth_pct
        from monthly
    )
select *
from final
