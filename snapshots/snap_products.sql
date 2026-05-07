{% snapshot snap_products %}

    {{
        config(
            unique_key="product_id",
            strategy="check",
            check_cols=["product_hdiff"],
            invalidate_hard_deletes=true,
        )
    }}

    select
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        load_ts_utc,
        record_source,
        product_hdiff
    from {{ ref("stg_products") }}

{% endsnapshot %}
