with
    source_data as (
        select seller_id, seller_zip_code_prefix, seller_city, seller_state, load_ts
        from {{ source("olist_source_data", "raw_sellers") }}
    ),
    renamed as (
        select
            seller_id as seller_id,  -- TEXT 
            trim(seller_zip_code_prefix)::varchar as zip_code_prefix,  -- TEXT
            translate(
                lower(trim(seller_city)),
                'áàãâäéèêëíìîïóòõôöúùûüç',
                'aaaaaeeeeiiiiooooouuuuc'
            ) as city_name,  -- TEXT
            upper(trim(seller_state)) as state_code,  -- TEXT
            load_ts::timestamp_ntz as load_ts_utc,  -- TIMESTAMP_NTZ
            'olist_source_data.raw_sellers' as record_source,
            {{
                dbt_utils.generate_surrogate_key(
                    ["seller_id", "zip_code_prefix", "city_name", "state_code"]
                )
            }} as seller_hdiff
        from source_data
    )
select *
from renamed
