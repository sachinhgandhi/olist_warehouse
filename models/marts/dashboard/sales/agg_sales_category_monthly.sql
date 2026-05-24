{{ config(materialized="table") }}

with
    order_items_enriched as (
        select
            fct_order_items.order_id,

            fct_orders_accum_snap.order_purchase_at,
            fct_orders_accum_snap.is_valid_order,
            fct_orders_accum_snap.is_delivered,

            fct_order_items.product_id,
            dim_products_history.product_category_name_english,
            dim_products_history.product_category_name,

            fct_order_items.product_price,
            fct_order_items.freight_value,
            fct_order_items.total_line_amount,
            fct_order_items.quantity
        from {{ ref("fct_order_items") }} as fct_order_items
        inner join
            {{ ref("fct_orders_accum_snap") }} as fct_orders_accum_snap
            on fct_order_items.order_id = fct_orders_accum_snap.order_id

        left join
            {{ ref("dim_products_history") }} as dim_products_history
            on dim_products_history.product_id = fct_order_items.product_id
            and fct_orders_accum_snap.order_purchase_at
            >= dim_products_history.dbt_valid_from
            and fct_orders_accum_snap.order_purchase_at
            < coalesce(dim_products_history.dbt_valid_to, '9999-12-31'::timestamp_ntz)
    ),
    monthly as (
        select
            date_trunc('month', order_items_enriched.order_purchase_at)::date
            as month_start_date,
            to_char(order_items_enriched.order_purchase_at, 'YYYY-MM') as year_month,
            year(order_items_enriched.order_purchase_at) as year_number,
            month(order_items_enriched.order_purchase_at) as month_number,
            order_items_enriched.product_category_name_english,
            order_items_enriched.product_category_name,

            sum(
                case
                    when order_items_enriched.is_valid_order
                    then order_items_enriched.product_price
                    else 0
                end
            ) as product_revenue,

            sum(
                case
                    when order_items_enriched.is_valid_order
                    then order_items_enriched.freight_value
                    else 0
                end
            ) as freight_revenue,

            sum(
                case
                    when order_items_enriched.is_valid_order
                    then order_items_enriched.total_line_amount
                    else 0
                end
            ) as total_booked_revenue,

            sum(
                case
                    when order_items_enriched.is_valid_order
                    then order_items_enriched.quantity
                    else 0
                end
            ) as total_product_quantity,

            count(
                distinct case
                    when order_items_enriched.is_valid_order
                    then order_items_enriched.order_id
                end
            ) as booked_order_count,

            round(
                (
                    sum(
                        case
                            when order_items_enriched.is_valid_order
                            then order_items_enriched.product_price
                            else 0
                        end
                    ) / nullif(
                        sum(
                            case
                                when order_items_enriched.is_valid_order
                                then order_items_enriched.quantity
                                else 0
                            end
                        ),
                        0
                    )
                ),
                4
            ) as average_item_value

        from order_items_enriched
        group by
            date_trunc('month', order_items_enriched.order_purchase_at)::date,
            to_char(order_items_enriched.order_purchase_at, 'YYYY-MM'),
            year(order_items_enriched.order_purchase_at),
            month(order_items_enriched.order_purchase_at),
            order_items_enriched.product_category_name_english,
            order_items_enriched.product_category_name
    ),
    final as (
        select
            monthly.*,

            round(freight_revenue / nullif(total_booked_revenue, 0), 2) as freight_pct,

            dense_rank() over (
                partition by monthly.month_start_date
                order by monthly.product_revenue desc
            ) as category_revenue_rank,

            round(
                (
                    product_revenue / nullif(
                        sum(monthly.product_revenue) over (
                            partition by month_start_date
                        ),
                        0
                    )
                ),
                4
            ) as category_revenue_share_pct

        from monthly
    )
select *
from final
