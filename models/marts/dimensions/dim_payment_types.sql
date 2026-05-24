with
    pay_types_int as (
        select
            payment_type_code,
            payment_type_name,
            payment_category,
            is_installment_supported,
            payment_description
        from {{ ref("int_payment_types_base") }}
    )
select
    payment_type_code,
    payment_type_name,
    payment_category,
    is_installment_supported,
    payment_description
from pay_types_int
