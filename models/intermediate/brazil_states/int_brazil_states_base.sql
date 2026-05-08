with
    states_ref as (
        select state_code, state_name, region_name from {{ ref("ref_brazil_states") }}
    )
select state_code, state_name, region_name
from states_ref
