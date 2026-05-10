{{ config(materialized="table") }}

with
    order_header_staging as (
        select
            order_id,
            customer_id,
            order_status_code,
            order_purchase_at,
            order_approved_at,
            order_handed_to_carrier_at,
            order_delivered_customer_at,
            order_estimated_delivery_at,
            load_ts_utc,
            record_source
        from {{ ref("stg_order_header") }}
    ),
    order_items_base as (
        select
            oib.order_id,

            count(oib.seller_id) as total_seller_count,
            count(distinct oib.seller_id) as distinct_seller_count,

            count(oib.product_id) as total_product_count,
            count(distinct oib.product_id) as distinct_product_count,

            count(distinct prd.product_category_name) as distinct_product_category_count

        from {{ ref("int_order_items_base") }} oib
        inner join {{ ref("int_products_base") }} prd on oib.product_id = prd.product_id
        group by oib.order_id
    )
select
    order_header_staging.order_id,
    order_header_staging.customer_id,

    order_header_staging.order_status_code,
    ord_st.order_status_name,
    ord_st.order_status_category,

    {{ get_date_key_format(date_value="order_header_staging.order_purchase_at") }}
    as purchase_date_key,
    order_header_staging.order_purchase_at,

    {{ get_date_key_format(date_value="order_header_staging.order_approved_at") }}
    as approved_date_key,
    order_header_staging.order_approved_at,
    case
        when order_header_staging.order_approved_at is not null
        then
            datediff(
                days,
                order_header_staging.order_purchase_at,
                order_header_staging.order_approved_at
            )
        else null
    end as diff_between_purchase_approved_days,

    {{
        get_date_key_format(
            date_value="order_header_staging.order_handed_to_carrier_at"
        )
    }} as carrier_handoff_date_key,
    order_header_staging.order_handed_to_carrier_at,
    case
        when
            order_header_staging.order_approved_at is not null
            and order_header_staging.order_handed_to_carrier_at is not null
        then
            datediff(
                days,
                order_header_staging.order_approved_at,
                order_header_staging.order_handed_to_carrier_at
            )
        else null
    end as diff_between_approved_carrier_del_days,

    {{
        get_date_key_format(
            date_value="order_header_staging.order_delivered_customer_at"
        )
    }} as customer_delivery_date_key,
    order_header_staging.order_delivered_customer_at,

    case
        when order_header_staging.order_delivered_customer_at is not null
        then true
        else false
    end as has_delivered,

    case
        when
            order_header_staging.order_handed_to_carrier_at is not null
            and order_header_staging.order_delivered_customer_at is not null
        then
            datediff(
                days,
                order_header_staging.order_handed_to_carrier_at,
                order_header_staging.order_delivered_customer_at
            )
        else null
    end as diff_between_carrier_customer_del_days,

    {{
        get_date_key_format(
            date_value="order_header_staging.order_estimated_delivery_at"
        )
    }} as estimated_delivery_date_key,
    order_header_staging.order_estimated_delivery_at,

    case
        when
            order_header_staging.order_estimated_delivery_at is not null
            and order_header_staging.order_delivered_customer_at is not null
        then
            case
                when
                    datediff(
                        days,
                        order_header_staging.order_estimated_delivery_at,
                        order_header_staging.order_delivered_customer_at
                    )
                    > 0
                then false
                else true
            end
        else null
    end as is_delivered_on_time,

    case
        when
            order_header_staging.order_estimated_delivery_at is not null
            and order_header_staging.order_delivered_customer_at is not null
        then
            datediff(
                days,
                order_header_staging.order_estimated_delivery_at,
                order_header_staging.order_delivered_customer_at
            )
            order_items_base.distinct_seller_count,
            case
                when order_items_base.distinct_seller_count > 1 then true else false
            end as has_multiple_sellers,

            order_items_base.total_product_count,
            order_items_base.distinct_product_count,
            case
                when order_items_base.distinct_product_count > 0 then true else false
            end as has_mulitple_products,

            order_items_base.distinct_product_category_count,
            case
                when order_items_base.distinct_product_category_count > 0
                then true
                else false
            end as has_mulitple_categories,

            order_header_staging.load_ts_utc,
            order_header_staging.record_source
        from order_header_staging
        left join
            {{ ref("ref_order_status") }} ord_st
            on order_header_staging.order_status_code = ord_st.order_status_code
        left join
            order_items_base
            on order_items_base.order_id = order_header_staging.order_id
