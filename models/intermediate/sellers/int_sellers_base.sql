with
    sel_snap as (
        select
            seller_id,
            zip_code_prefix,
            city_name,
            state_code,
            load_ts_utc,
            record_source,
            dbt_valid_from,
            dbt_valid_to
        from {{ ref("snap_sellers") }}
    )
select
    sel_snap.seller_id,
    sel_snap.zip_code_prefix,
    sel_snap.city_name,
    sel_snap.state_code,
    braz_states.state_name,
    braz_states.region_name,
    sel_snap.load_ts_utc,
    sel_snap.record_source,
    sel_snap.dbt_valid_from,
    sel_snap.dbt_valid_to,
    case
        when sel_snap.dbt_valid_to is null then true else false
    end as is_current_record
from sel_snap
left join
    {{ ref("ref_brazil_states") }} braz_states
    on sel_snap.state_code = braz_states.state_code
