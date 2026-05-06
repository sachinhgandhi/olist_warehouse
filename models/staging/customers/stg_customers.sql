with
    source_data as (
        select
            customer_id,
            customer_unique_id,
            customer_zip_code,
            customer_city,
            customer_state,
            load_ts
        from {{ source("olist_source_data", "raw_customers") }}
    ),
    renamed as (
        select
            customer_id as customer_id,  -- TEXT
            customer_unique_id as customer_unique_id,  -- TEXT
            trim(customer_zip_code) as zip_code_prefix,  -- TEXT
            lower(trim(customer_city)) as city_name,  -- TEXT
            upper(trim(customer_state)) as state_code,  -- TEXT
            load_ts::timestamp_ntz as load_ts_utc,  -- TIMESTAMP_NTZ
            'olist_source_data.raw_customers' as record_source
        from source_data
    )
select *
from renamed
