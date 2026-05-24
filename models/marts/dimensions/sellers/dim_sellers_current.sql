with
    seller_int as (
        select
            seller_id,
            zip_code_prefix,
            city_name,
            state_code,
            state_name,
            region_name,
            load_ts_utc,
            record_source,
            dbt_valid_from,
            dbt_valid_to,
            is_current_record
        from {{ ref("int_sellers_base") }}
        where is_current_record = true
    )
select
    seller_id,
    zip_code_prefix,
    city_name,
    state_code,
    state_name,
    region_name,
    load_ts_utc,
    record_source,
    dbt_valid_from,
    dbt_valid_to,
    is_current_record
from seller_int
