with activity_types as (

    select distinct
        activity_type
    from {{ ref('fct_activities') }}
    where distance_km > 0

),

activity_summary as (

    select
        activity_type,

        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(elevation_gain_m) as total_elevation_gain_m,
        sum(moving_time_hours) as total_moving_time_hours,
        sum(calories) as total_calories,
        max(distance_km) as longest_activity_km

    from {{ ref('fct_activities') }}
    where distance_km > 0
    group by 1

),

final as (

    select
        at.activity_type,

        coalesce(a.activity_count, 0) as activity_count,
        coalesce(round(a.total_distance_km, 2), 0) as total_distance_km,
        coalesce(round(a.total_elevation_gain_m, 0), 0) as total_elevation_gain_m,
        coalesce(round(a.total_moving_time_hours, 2), 0) as total_moving_time_hours,
        coalesce(round(a.total_calories, 0), 0) as total_calories,

        case
            when coalesce(a.total_distance_km, 0) > 0
                then round((a.total_moving_time_hours * 60) / a.total_distance_km, 2)
        end as avg_pace_min_per_km,

        round(a.longest_activity_km, 2) as longest_activity_km

    from activity_types at
    left join activity_summary a
        on at.activity_type = a.activity_type

)

select *
from final