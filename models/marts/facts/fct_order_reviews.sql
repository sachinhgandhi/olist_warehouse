{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="order_review_key",
        transient=false,
        on_schema_change="append_new_columns",
    )
}}

with
    order_reviews_int as (
        select
            order_review_key,
            review_id,
            order_id,
            review_score,
            review_comment_title,
            review_comment_message,
            has_review_answer,
            creation_date_key,
            review_creation_at,
            has_customer_responded,
            answer_date_key,
            review_answer_at,
            review_response_day,
            review_sentiment_category,
            load_ts_utc,
            record_source
        from {{ ref("int_order_reviews_base") }}

        {% if is_incremental() %}
            where
                load_ts_utc >= (
                    select coalesce(max(load_ts_utc), '1900-01-01'::timestamp_ntz)
                    from {{ this }}
                )
        {% endif %}
    )
select
    order_review_key,
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    has_review_answer,
    creation_date_key,
    review_creation_at,
    has_customer_responded,
    answer_date_key,
    review_answer_at,
    review_response_day,
    review_sentiment_category,
    load_ts_utc,
    record_source
from order_reviews_int
