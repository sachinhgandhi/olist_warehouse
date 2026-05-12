with
    states_int as (
        select state_code, state_name, region_name
        from {{ ref("int_brazil_states_base") }}
    )
select state_code, state_name, region_name
from states_int
