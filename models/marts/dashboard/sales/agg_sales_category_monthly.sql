{{ config(materialized="table") }}

with
    order_fct as (
        select order_key, order_id, order_purchase_at, is_valid_order
        from {{ ref("fct_orders_accum_snap") }}
    ),
    order_items_fct as (
        select
            oitem.order_id,
            order_fct.order_purchase_at,
            oitem.product_id,
            oitem.product_price,
            oitem.freight_value,
            oitem.total_line_amount,
            oitem.quantity
        from {{ ref("fct_order_items") }} as oitem
        inner join order_fct on oitem.order_id = order_fct.order_id
    ),
    order_items_prd as (
        select
            order_items_fct.order_id,
            order_items_fct.product_id,
            prd.product_category_name_english,
            prd.product_category_name,
            order_items_fct.product_price,
            order_items_fct.freight_value,
            order_items_fct.total_line_amount,
            order_items_fct.quantity
        from order_items_fct
        left join
            {{ ref("dim_products_history") }} as prd
            on order_items_fct.product_id = prd.product_id
            and order_items_fct.order_purchase_at >= prd.dbt_valid_from
            and order_items_fct.order_purchase_at
            < coalesce(prd.dbt_valid_from, '2999:12:31'::timestamp_ntz)
    ),
    monthly as (
        select
            date_trunc('month', order_fct.order_purchase_at)::date as month_start_date,
            to_char(order_fct.order_purchase_at, 'YYYY-MM') as year_month,
            year(order_fct.order_purchase_at) as year_number,
            month(order_fct.order_purchase_at) as month_number,
            order_items_prd.product_category_name_english,
            order_items_prd.product_category_name
        from order_fct
        left join order_items_prd on order_fct.order_id = order_items_prd.order_id
        group by
            date_trunc('month', order_fct.order_purchase_at)::date,
            to_char(order_fct.order_purchase_at, 'YYYY-MM'),
            year(order_fct.order_purchase_at),
            month(order_fct.order_purchase_at),
            order_items_prd.product_category_name_english,
            order_items_prd.product_category_name

    )
