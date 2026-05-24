with
    source_data as (
        select
            payment_type_code,
            payment_type_name,
            payment_category,
            is_installment_supported,
            payment_description
        from {{ ref("seed_payment_types") }}
    ),
    renamed as (
        select
            payment_type_code as payment_type_code,  -- TEXT
            payment_type_name as payment_type_name,  -- TEXT
            payment_category as payment_category,  -- TEXT
            is_installment_supported::boolean as is_installment_supported,  -- BOOLEAN
            payment_description as payment_description  -- TEXT
        from source_data
    )
select *
from renamed
