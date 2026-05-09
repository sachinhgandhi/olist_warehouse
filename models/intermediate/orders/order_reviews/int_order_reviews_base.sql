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
    )
select
    {{ dbt_utils.generate_surrogate_key(["order_id", "review_id"]) }}
    as order_review_key,
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    case
        when review_comment_title is not null or review_comment_message is not null
        then true
        else false
    end as has_review_comment,
    to_number(to_char(review_creation_at, 'YYYYMMDD')) as creation_date_key,
    review_creation_at,
    case
        when review_answer_at is null
        then null
        else to_number(to_char(review_answer_at, 'YYYYMMDD'))
    end as answer_date_key,
    review_answer_at,
    case
        when review_answer_at is null
        then null
        else datediff('day', review_creation_at, review_answer_at)
    end as review_response_days,
    case
        when has_review_comment
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
