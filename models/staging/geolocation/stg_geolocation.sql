with
    src_data as (
        select
            geolocation_zip_code_prefix as zip_code,
            geolocation_lat as lat,
            geolocation_lng as lng,
            geolocation_city as city_name,
            geolocation_state as state_code,
            load_ts as load_ts_utc,
            "Source_Data.olist_source_data" as record_source
        from {{ source("olist_source_data", "raw_geolocation") }}
    ),
    default_rec as (
        select
            "-1" as zip_code,
            "Missing" as lat,
            "Missing" as lng,
            "Missing" as city_name,
            "Missing" as state_code,
            "1900-01-01" as load_ts_utc,
            "System.DefaultKey" as record_source
    ),
    merge_data as (
        Select * from src_data
        union all
        Select * from default_rec
    )
select * from merge_data
