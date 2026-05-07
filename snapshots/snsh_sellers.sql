{% snapshot snsh_sellers %}

    {{
        config(
            unique_key="seller_id",
            strategy="check",
            check_cols=["seller_hdiff"],
            invalidate_hard_deletes=true,
        )
    }}

    select *
    from {{ ref("stg_sellers") }}
{% endsnapshot %}
