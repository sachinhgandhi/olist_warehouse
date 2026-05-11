with
    order_reviews_staging as (
        select
            review_id,
            order_id,
            review_score,
            review_comment_title,
            review_comment_message,
            review_creation_at,
            review_answer_at,
            load_ts_utc,
            record_source
        from {{ ref("stg_order_reviews") }}
    ),
    review_comm as (
        select
            order_id,
            case
                when
                    review_comment_title is not null
                    or review_comment_message is not null
                then true
                else false
            end as has_review_answer
        from order_reviews_staging
    )
select
    {{
        dbt_utils.generate_surrogate_key(
            ["order_reviews_staging.order_id", "review_id"]
        )
    }} as order_review_key,
    review_id,
    order_reviews_staging.order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_comm.has_review_answer,

    {{ get_date_key(date_value="review_creation_at") }} as creation_date_key,
    review_creation_at,

    case
        when review_answer_at is null then false else true
    end as has_customer_responded,

    case
        when review_answer_at is null
        then null
        else {{ get_date_key(date_value="review_answer_at") }}
    end as answer_date_key,

    review_answer_at,

    case
        when review_answer_at is null
        then null
        else datediff('day', review_creation_at, review_answer_at)
    end as review_response_day,

    case
        when review_comm.has_review_answer
        then
            case
                when review_score >= 4
                then 'HIGH_SCORE'
                when review_score <= 2
                then 'LOW_SCORE'
                else 'NEUTRAL_SCORE'
            end
        else null
    end as review_sentiment_category,

    load_ts_utc,
    record_source

from order_reviews_staging
left join review_comm on order_reviews_staging.order_id = review_comm.order_id
