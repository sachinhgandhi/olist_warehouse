{% snapshot snsh_customers %}

    {{
        config(
            unique_key="customer_id",
            strategy="check",
            check_cols=["customer_hdiff"],
            invalidate_hard_deletes=true,
        )
    }}

    select *
    from {{ ref("stg_customers") }}

{% endsnapshot %}
