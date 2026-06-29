with runs as (

    select *
    from {{ ref('fct_activities') }}
    where is_run

),

shoe_usage as (

    select
        coalesce(activity_gear, 'Unknown') as activity_gear,

        count(*) as run_count,
        min(activity_date) as first_run_date,
        max(activity_date) as latest_run_date,

        sum(distance_km) as total_distance_km,
        sum(elevation_gain_m) as total_elevation_gain_m,
        sum(moving_time_hours) as total_moving_time_hours,

        avg(pace_min_per_km) as avg_pace_min_per_km,
        avg(average_heart_rate) as avg_heart_rate,

        max(distance_km) as longest_run_km

    from runs
    group by 1

)

select
    activity_gear,
    run_count,
    first_run_date,
    latest_run_date,

    round(total_distance_km, 2) as total_distance_km,
    round(total_elevation_gain_m, 2) as total_elevation_gain_m,
    round(total_moving_time_hours, 2) as total_moving_time_hours,

    round(avg_pace_min_per_km, 2) as avg_pace_min_per_km,
    round(avg_heart_rate, 0) as avg_heart_rate,
    round(longest_run_km, 2) as longest_run_km

from shoe_usage
order by total_distance_km desc