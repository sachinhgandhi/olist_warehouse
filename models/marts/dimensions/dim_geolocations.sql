with
    geol_int as (
        select
            zip_code_prefix,
            state_code,
            state_name,
            region_name,
            city_name,
            record_source,
            lat,
            lng
        from {{ ref("int_geolocations") }}
    )
select
    zip_code_prefix,
    state_code,
    state_name,
    region_name,
    city_name,
    record_source,
    lat,
    lng
from geol_int
