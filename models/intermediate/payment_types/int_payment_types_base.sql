with
    payment_types_ref as (
        select
            payment_type_code,
            payment_type_name,
            payment_category,
            is_installment_supported,
            payment_description
        from {{ ref("ref_payment_types") }}
    )
select
    payment_type_code,
    payment_type_name,
    payment_category,
    is_installment_supported,
    payment_description
from payment_types_ref
