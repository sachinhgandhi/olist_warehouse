with
    date_spine as (
        {{-
            dbt_utils.date_spine(
                datepart="day",
                start_date="to_date('2016-01-01')",
                end_date="to_date('2020-12-31')",
            )
        -}}
    )
select
    {{ get_date_key(date_value="date_day") }} as date_key,
    date_day as full_date,

    dayofmonth(date_day)::integer as day_of_month,
    month(date_day)::integer as month_num,
    year(date_day)::integer as year_num,

    dayofweek(date_day)::integer as day_of_week,
    dayname(date_day) as day_name,
    monthname(date_day) as month_name,

    week(date_day)::integer as week_number,
    case when dayofweek(date_day) = 0 then true else false end as is_week_start,
    case when dayofweek(date_day) = 6 then true else false end as is_week_end,

    case when dayofweek(date_day) in (0, 6) then true else false end as is_weekend,

    current_date = date_day as is_current_date,

    last_day(date_day, 'month') as month_end_date,
    last_day(date_day, 'year') as year_end_date,

    case
        when date_day = date_trunc('month', date_day) then true else false
    end as is_month_start,
    case
        when date_day = last_day(date_day, 'month') then true else false
    end as is_month_end,

    quarter(date_day) as quarter_number,
    case
        when date_day = date_trunc('quarter', date_day) then true else false
    end as is_quarter_start,
    case
        when date_day = last_day(date_day, 'quarter') then true else false
    end as is_quarter_end

from date_spine
