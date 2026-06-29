with activities as (

    select *
    from {{ ref('fct_activities') }}
    where is_run

),

weekly as (

    select
        date_trunc('week', activity_date)::date as week_start_date,

        count(*) as run_count,
        sum(distance_km) as total_distance_km,
        sum(elevation_gain_m) as total_elevation_gain_m,
        sum(moving_time_hours) as total_moving_time_hours,
        sum(calories) as total_calories,

        avg(pace_min_per_km) as avg_pace_min_per_km,
        avg(average_heart_rate) as avg_heart_rate,
        max(distance_km) as longest_run_km,
        max(elevation_gain_m) as biggest_climb_m

    from activities
    group by 1

),

final as (

    select
        to_char(week_start_date, 'YYYYMMDD')::integer as week_start_date_key,
        
        week_start_date,
        (week_start_date + interval '6 days')::date as week_end_date,
        run_count,
        round(total_distance_km, 2) as total_distance_km,
        round(total_elevation_gain_m, 2) as total_elevation_gain_m,
        round(total_moving_time_hours, 2) as total_moving_time_hours,
        round(total_calories, 0) as total_calories,

        round(avg_pace_min_per_km, 2) as avg_pace_min_per_km,
        round(avg_heart_rate, 0) as avg_heart_rate,
        round(longest_run_km, 2) as longest_run_km,
        round(biggest_climb_m, 2) as biggest_climb_m

    from weekly

)

select *
from final