{% snapshot snsh_products %}

    {{
        config(
            unique_key="product_id",
            strategy="check",
            check_cols=["product_hdiff"],
            invalidate_hard_deletes=true,
        )
    }}

    select *
    from {{ ref("stg_products") }}

{% endsnapshot %}
