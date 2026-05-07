{% snapshot snap_customers %}

    {{
        config(
            unique_key="customer_id",
            strategy="check",
            check_cols=["customer_hdiff"],
            invalidate_hard_deletes=true,
        )
    }}

    select
        customer_id,
        customer_unique_id,
        zip_code_prefix,
        city_name,
        state_code,
        load_ts_utc,
        record_source,
        customer_hdiff
    from {{ ref("stg_customers") }}

{% endsnapshot %}
