with
    cust_int as (
        select
            customer_id,
            customer_unique_id,
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
        from {{ ref("int_customers_base") }}
        where is_current_record = true
    )
select
    customer_id,
    customer_unique_id,
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
from cust_int
