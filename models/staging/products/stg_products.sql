with
    source_data as (
        select
            product_id,
            product_category_name,
            product_name_lenght,
            product_description_lenght,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm,
            load_ts
        from {{ source("olist_source_data", "raw_product") }}
    ),
    renamed as (
        select
            product_id as product_id,  -- TEXT
            lower(trim(product_category_name)) as product_category_name,  -- TEXT
            product_name_lenght::number as product_name_length,  -- NUMBER
            product_description_lenght::number as product_description_length,  -- NUMBER
            product_photos_qty::number as product_photos_qty,  -- NUMBER
            product_weight_g::number as product_weight_g,  -- NUMBER
            product_length_cm::number as product_length_cm,  -- NUMBER
            product_height_cm::number as product_height_cm,  -- NUMBER
            product_width_cm::number as product_width_cm,  -- NUMBER
            load_ts::timestamp_ntz as load_ts_utc,  -- TIMESTAMP_NTZ
            'olist_source_data.raw_product' as record_source,
            {{
                dbt_utils.generate_surrogate_key(
                    [
                        "product_id",
                        "product_category_name",
                        "product_name_length",
                        "product_description_length",
                        "product_photos_qty",
                        "product_weight_g",
                        "product_length_cm",
                        "product_height_cm",
                        "product_width_cm",
                    ]
                )
            }} as product_hdiff
        from source_data
    )
select *
from renamed
