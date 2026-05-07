with
    source_data as (
        select
            order_status_code,
            order_status_name,
            order_status_category,
            is_active_order,
            is_completed_order,
            is_cancelled_order,
            is_booked_revenue_eligible,
            is_delivered_revenue_eligible,
            display_sequence,
            status_description
        from {{ ref("seed_order_status") }}
    ),
    renamed as (
        select
            order_status_code as order_status_code,
            order_status_name as order_status_name,
            order_status_category as order_status_category,
            is_active_order::boolean as is_active_order,
            is_completed_order::boolean as is_completed_order,
            is_cancelled_order::boolean as is_cancelled_order,
            is_booked_revenue_eligible::boolean as is_booked_revenue_eligible,
            is_delivered_revenue_eligible::boolean as is_delivered_revenue_eligible,
            display_sequence::number as display_sequence,
            status_description as status_description
        from source_data
    )
select *
from renamed
