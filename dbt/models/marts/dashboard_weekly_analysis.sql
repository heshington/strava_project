with activities as (

    select
        activity_id,
        activity_name,
        activity_type,
        activity_description,
        activity_date,
        activity_datetime,

        date_trunc('year', activity_date)::date as year_start_date,
        date_trunc('month', activity_date)::date as month_start_date,
        date_trunc('week', activity_date)::date as week_start_date,
        (date_trunc('week', activity_date) + interval '6 days')::date as week_end_date,
       dense_rank() over (
            partition by
            extract(year from activity_date)::integer,
            extract(month from activity_date)::integer
            order by
            date_trunc('week', activity_date)::date
        ) as week_of_month,
        to_char(date_trunc('week', activity_date)::date, 'Mon DD') as week_label,
        extract(year from activity_date)::integer as activity_year,
        extract(month from activity_date)::integer as activity_month_number,
        extract(week from activity_date)::integer as activity_week_number,
        extract(isodow from activity_date)::integer as activity_day_of_week_number,
        to_char(activity_date, 'FMDay') as day_name,
        to_char(activity_date, 'Mon') as month_name,
        extract(quarter from activity_date)::integer as quarter,
        extract(isodow from activity_date) in (6, 7) as is_weekend,

        distance_km,
        moving_time_seconds,
        moving_time_hours,
        elevation_gain_m,
        pace_min_per_km,
        relative_effort,
        calories,
        average_heart_rate,
        max_heart_rate,

        activity_gear,
        is_run,
        is_walk,
        is_strength

    from {{ ref('fct_activities') }}

)

select *
from activities