with activities as (

    select *
    from {{ ref('fct_activities') }}

),

monthly_mix as (

    select
        date_trunc('month', activity_date)::date as month_start_date,
        activity_type,

        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(moving_time_hours) as total_moving_time_hours,
        sum(calories) as total_calories

    from activities
    group by 1, 2

)

select
    to_char(month_start_date, 'YYYYMMDD')::integer as month_start_date_key,
    month_start_date,
    activity_type,

    activity_count,
    round(total_distance_km, 2) as total_distance_km,
    round(total_moving_time_hours, 2) as total_moving_time_hours,
    round(total_calories, 0) as total_calories

from monthly_mix