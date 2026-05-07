with
    source_data as (
        select state_code, state_name, region_name from {{ ref("seed_brazil_states") }}
    ),
    renamed as (
        select
            state_code as state_code,  -- TEXT
            state_name as state_name,  -- TEXT
            region_name as region_name  -- TEXT
        from source_data
    )
select *
from renamed
