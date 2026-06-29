with date_spine as (

    select generate_series(
        (select min(activity_date) from {{ ref('stg_strava__activities') }}),
        (select max(activity_date) from {{ ref('stg_strava__activities') }}),
        interval '1 day'
    )::date as date_day

),

final as (

    select
        to_char(date_day, 'YYYYMMDD')::integer as date_key,
        date_day,

        extract(year from date_day)::integer as year,
        extract(quarter from date_day)::integer as quarter,
        extract(month from date_day)::integer as month_number,
        to_char(date_day, 'Month') as month_name,
        to_char(date_day, 'Mon') as month_short,

        extract(week from date_day)::integer as week_number,
        extract(day from date_day)::integer as day_of_month,
        extract(isodow from date_day)::integer as day_of_week_number,
        to_char(date_day, 'Day') as day_name,

        extract(isodow from date_day) in (6, 7) as is_weekend,
        to_char(date_day, 'Mon YYYY') as month_year

    from date_spine

)

select *
from final