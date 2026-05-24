with
    source_data as (
        select
            geolocation_zip_code_prefix,
            geolocation_lat,
            geolocation_lng,
            geolocation_city,
            geolocation_state,
            load_ts
        from {{ source("olist_source_data", "raw_geolocation") }}
    ),
    renamed as (
        select
            trim(geolocation_zip_code_prefix)::varchar as zip_code_prefix,
            geolocation_lat::float as lat,
            geolocation_lng::float as lng,
            translate(
                lower(trim(geolocation_city)),
                'áàãâäéèêëíìîïóòõôöúùûüç',
                'aaaaaeeeeiiiiooooouuuuc'
            ) as city_name,
            upper(trim(geolocation_state)) as state_code,
            load_ts::timestamp_ntz as load_ts_utc,
            'olist_source_data.raw_geolocation' as record_source
        from source_data

    )
select *
from renamed
