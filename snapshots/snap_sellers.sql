{% snapshot snap_sellers %}

    {{
        config(
            unique_key="seller_id",
            strategy="check",
            check_cols=["seller_hdiff"],
            invalidate_hard_deletes=true,
        )
    }}

    select
        seller_id,
        zip_code_prefix,
        city_name,
        state_code,
        load_ts_utc,
        record_source,
        seller_hdiff,
    from {{ ref("stg_sellers") }}
{% endsnapshot %}
