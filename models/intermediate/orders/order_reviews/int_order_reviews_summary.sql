{{ config(materialized="table") }}

with
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
            ) as total_responded_review_count,
            max(review_score_row_number.review_score) as latest_review_score,
            max(ord_review.load_ts_utc) as max_load_ts_utc

        from {{ ref("int_order_reviews_base") }} ord_review
        left join
            review_score_row_number
            on ord_review.order_id = review_score_row_number.order_id
            and review_score_row_number.rn = 1
        group by ord_review.order_id
    )
select
    order_reviews_base.order_id,
    order_reviews_base.avg_review_score,
    order_reviews_base.total_responded_review_count,
    order_reviews_base.latest_review_score,
    order_reviews_base.max_load_ts_utc
from order_reviews_base
