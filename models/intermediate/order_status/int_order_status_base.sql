with
    order_status_ref as (
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
        from {{ ref("ref_order_status") }}
    )
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
from order_status_ref
