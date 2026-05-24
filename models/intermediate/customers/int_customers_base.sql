with
    cust_snap as (
        select
            customer_id,
            customer_unique_id,
            zip_code_prefix,
            city_name,
            state_code,
            load_ts_utc,
            record_source,
            dbt_valid_from,
            dbt_valid_to
        from {{ ref("snap_customers") }}
    )
select
    cust_snap.customer_id,
    cust_snap.customer_unique_id,
    cust_snap.zip_code_prefix,
    cust_snap.city_name,
    cust_snap.state_code,
    braz_states.state_name,
    braz_states.region_name,
    cust_snap.load_ts_utc,
    cust_snap.record_source,
    cust_snap.dbt_valid_from,
    cust_snap.dbt_valid_to,
    case
        when cust_snap.dbt_valid_to is null then true else false
    end as is_current_record
from cust_snap
left join
    {{ ref("ref_brazil_states") }} as braz_states
    on cust_snap.state_code = braz_states.state_code
