with
    geolocation_distinct as (
        select
            geol.zip_code_prefix,
            geol.state_code,
            geol.city_name,
            max(geol.record_source) as record_source,
            avg(geol.lat) as lat,
            avg(geol.lng) as lng
        from {{ ref("stg_geolocations") }} as geol
        group by geol.zip_code_prefix, geol.state_code, geol.city_name
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
from geolocation_distinct geo_dist
left join
    {{ ref("ref_brazil_states") }} as br_st on geo_dist.state_code = br_st.state_code
order by geo_dist.state_code, geo_dist.city_name, geo_dist.zip_code_prefix
