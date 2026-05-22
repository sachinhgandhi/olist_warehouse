{# with
    fct_orders_accum_snap as (
        select
            order_id,
            order_purchase_at,
            avg_review_score,
            total_responded_review_count,
            has_multiple_reviews,
            latest_review_score,
            customer_sentiment

        from {{ ref("fct_orders_accum_snap") }}
        where is_delivered = true and is_valid_order = true
    ) #}
