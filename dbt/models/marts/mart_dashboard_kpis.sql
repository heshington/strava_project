with activities as (

    select *
    from {{ ref('fct_activities') }}
    where is_run

),

final as (

    select
        count(*) as total_runs,
        round(sum(distance_km), 2) as total_distance_km,
        round(sum(elevation_gain_m), 0) as total_elevation_gain_m,
        round(sum(moving_time_hours), 2) as total_moving_time_hours,
        round(sum(calories), 0) as total_calories,

        round(
            (sum(moving_time_hours) * 60) / nullif(sum(distance_km), 0),
            2
        ) as avg_pace_min_per_km,

        round(max(distance_km), 2) as longest_run_km

    from activities

)

select *
from final