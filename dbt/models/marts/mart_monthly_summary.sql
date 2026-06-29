with activities as (

    select *
    from {{ ref('fct_activities') }}

),

monthly as (

    select
        date_trunc('month', activity_date)::date as month_start_date,

        count(*) as activity_count,
        count(*) filter (where is_run) as run_count,
        count(*) filter (where is_walk) as walk_count,
        count(*) filter (where is_strength) as strength_count,

        sum(distance_km) as total_distance_km,
        sum(distance_km) filter (where is_run) as run_distance_km,
        sum(distance_km) filter (where is_walk) as walk_distance_km,

        sum(elevation_gain_m) as total_elevation_gain_m,
        sum(moving_time_hours) as total_moving_time_hours,
        sum(calories) as total_calories,

        avg(pace_min_per_km) filter (where is_run) as avg_run_pace_min_per_km,
        avg(average_heart_rate) filter (where is_run) as avg_run_heart_rate

    from activities
    group by 1

)

select
    to_char(month_start_date, 'YYYYMMDD')::integer as month_start_date_key,
    month_start_date,
    (month_start_date + interval '1 month - 1 day')::date as month_end_date,

    activity_count,
    run_count,
    walk_count,
    strength_count,

    round(total_distance_km, 2) as total_distance_km,
    round(run_distance_km, 2) as run_distance_km,
    round(walk_distance_km, 2) as walk_distance_km,
    round(total_elevation_gain_m, 2) as total_elevation_gain_m,
    round(total_moving_time_hours, 2) as total_moving_time_hours,
    round(total_calories, 0) as total_calories,

    round(avg_run_pace_min_per_km, 2) as avg_run_pace_min_per_km,
    round(avg_run_heart_rate, 0) as avg_run_heart_rate

from monthly