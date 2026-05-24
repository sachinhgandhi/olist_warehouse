with
    source_data as (
        select
            review_id,
            order_id,
            review_score,
            review_comment_title,
            review_comment_message,
            review_creation_date,
            review_answer_timestamp,
            load_ts
        from {{ source("olist_source_data", "raw_order_reviews") }}
    ),
    renamed as (
        select
            trim(review_id)::varchar as review_id,  -- TEXT
            order_id as order_id,  -- TEXT
            review_score::number as review_score,  -- NUMBER
            review_comment_title as review_comment_title,  -- TEXT
            review_comment_message as review_comment_message,  -- TEXT
            review_creation_date::timestamp_ntz as review_creation_at,  -- TIMESTAMP_NTZ
            review_answer_timestamp::timestamp_ntz as review_answer_at,  -- TIMESTAMP_NTZ
            load_ts::timestamp_ntz as load_ts_utc,  -- TIMESTAMP_LTZ
            'olist_source_data.raw_order_reviews' as record_source
        from source_data
    )
select *
from renamed
