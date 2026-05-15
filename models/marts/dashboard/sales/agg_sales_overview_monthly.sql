{{ config(materialized="table") }}

with
    orders_fct as (
        select
            order_key,
            order_id,
            order_purchase_at,

            is_delivered,
            is_cancelled,
            is_unavailable,
            is_open_order,
            is_valid_order,

            total_product_quantity,
            total_product_amount,
            total_freight_amount,
            total_order_amount

        from {{ ref("fct_orders_accum_snap") }}
    ),
    monthly_sales as (

        select
            date_trunc('month', orders_fct.order_purchase_at)::date as month_start_date,
            to_char(orders_fct.order_purchase_at, 'YYYY-MM') as year_month,
            year(orders_fct.order_purchase_at) as year_number,
            month(orders_fct.order_purchase_at) as month_number,

            count(
                distinct case
                    when orders_fct.is_valid_order then orders_fct.order_id
                end
            ) as valid_order_count,

            sum(
                case
                    when orders_fct.is_valid_order
                    then orders_fct.total_order_amount
                    else 0
                end
            ) as booked_revenue,

            count(
                distinct case when orders_fct.is_delivered then orders_fct.order_id end
            ) as delivered_order_count,

            sum(
                case
                    when orders_fct.is_delivered
                    then orders_fct.total_order_amount
                    else 0
                end
            ) as delivered_revenue,

            sum(
                case
                    when orders_fct.is_valid_order
                    then orders_fct.total_product_amount
                    else 0
                end
            ) as product_revenue,

            sum(
                case
                    when orders_fct.is_valid_order
                    then orders_fct.total_freight_amount
                    else 0
                end
            ) as freight_revenue,

            (
                sum(
                    case
                        when orders_fct.is_valid_order
                        then orders_fct.total_freight_amount
                        else 0
                    end
                ) / nullif(
                    sum(
                        case
                            when orders_fct.is_valid_order
                            then orders_fct.total_order_amount
                            else 0
                        end
                    ),
                    0
                )
            ) as freight_pct,

            sum(
                case
                    when orders_fct.is_valid_order
                    then orders_fct.total_product_quantity
                    else 0
                end
            ) as total_product_quantity,

            round(
                (
                    sum(
                        case
                            when orders_fct.is_valid_order
                            then orders_fct.total_product_amount
                            else 0
                        end
                    ) / nullif(
                        sum(
                            case
                                when orders_fct.is_valid_order
                                then orders_fct.total_product_quantity
                                else 0
                            end
                        ),
                        0
                    )
                ),
                2
            ) as average_item_value,

            round(
                (
                    sum(
                        case
                            when orders_fct.is_valid_order
                            then orders_fct.total_order_amount
                            else 0
                        end
                    ) / nullif(
                        count(
                            distinct case
                                when orders_fct.is_valid_order then orders_fct.order_id
                            end
                        ),
                        0
                    )
                ),
                2
            ) as average_order_value

        from orders_fct
        group by
            date_trunc('month', orders_fct.order_purchase_at)::date,
            to_char(orders_fct.order_purchase_at, 'YYYY-MM'),
            year(orders_fct.order_purchase_at),
            month(orders_fct.order_purchase_at)
    ),
    final as (
        select
            monthly_sales.*,
            lag(booked_revenue) over (
                order by month_start_date
            ) as previous_month_booked_revenue,

            round(
                (
                    (
                        booked_revenue
                        - lag(booked_revenue) over (order by month_start_date)
                    )
                    / nullif(lag(booked_revenue) over (order by month_start_date), 0)
                ),
                2
            ) as booked_revenue_growth_pct
        from monthly_sales
    )
select *
from final
