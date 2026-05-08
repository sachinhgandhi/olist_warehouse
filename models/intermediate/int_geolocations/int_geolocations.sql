with
    geolocation_distinct as (
        select
            geol.state_code,
            geol.city_name,
            geol.zip_code_prefix,
            geol.record_source,
            avg(geol.lat) as avg_lat,
            avg(geol.lng) as avg_lng
        from {{ ref("stg_geolocations") }} as geol
        group by
            geol.state_code, geol.city_name, geol.zip_code_prefix, geol.record_source
    )
select
    geo_dist.state_code,
    br_st.state_name,
    br_st.region_name,
    geo_dist.city_name,
    geo_dist.zip_code_prefix,
    geo_dist.record_source,
    geo_dist.avg_lat as lat,
    geo_dist.avg_lng as lng
from geolocation_distinct geo_dist
inner join
    {{ ref("ref_brazil_states") }} as br_st on geo_dist.state_code = br_st.state_code
order by geo_dist.state_code, geo_dist.city_name, geo_dist.zip_code_prefix
