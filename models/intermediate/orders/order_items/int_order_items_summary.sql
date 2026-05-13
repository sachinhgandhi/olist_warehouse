{{ config(materialized="table") }}

with
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

            max(oib.shipping_limit_at) as max_shipping_limit_at,
            max(oib.load_ts_utc) as max_load_ts_utc

        from {{ ref("int_order_items_base") }} oib
        inner join {{ ref("int_products_base") }} prd on oib.product_id = prd.product_id
        inner join
            {{ ref("int_order_header_base") }} order_base
            on order_base.order_id = oib.order_id
        where
            order_base.order_purchase_at >= prd.dbt_valid_from
            and order_base.order_purchase_at
            < coalesce(prd.dbt_valid_to, '9999-12-31'::timestamp_ntz)
        group by oib.order_id
    )
select
    order_items_base.order_id,

    order_items_base.total_seller_count,
    order_items_base.distinct_seller_count,

    order_items_base.total_product_count,
    order_items_base.distinct_product_count,

    order_items_base.distinct_product_category_count,

    order_items_base.total_product_quantity,
    order_items_base.total_product_amount,
    order_items_base.total_freight_amount,
    order_items_base.total_order_amount,

    order_items_base.max_shipping_limit_at,
    order_items_base.max_load_ts_utc

from order_items_base
