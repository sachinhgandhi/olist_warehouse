with
    geol_int as (
        select
            geo_dist.zip_code_prefix,
            geo_dist.state_code,
            br_st.state_name,
            br_st.region_name,
            geo_dist.city_name,
            geo_dist.record_source,
            geo_dist.lat,
            geo_dist.lng
        from {{ ref("int_geolocations") }}
    )
select
    geo_dist.zip_code_prefix,
    geo_dist.state_code,
    br_st.state_name,
    br_st.region_name,
    geo_dist.city_name,
    geo_dist.record_source,
    geo_dist.lat,
    geo_dist.lng
from geol_int
