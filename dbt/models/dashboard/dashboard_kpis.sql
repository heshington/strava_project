with activities as (

    select *
    from {{ ref('fct_activities') }}
    where distance_km > 0

),

final as (

    select
        extract(year from activity_date)::integer as activity_year,
        date_trunc('month', activity_date)::date as month_start_date,
        activity_type,

        count(*) as activity_count,
        round(sum(distance_km), 2) as total_distance_km,
        round(sum(elevation_gain_m), 0) as total_elevation_gain_m,
        round(sum(moving_time_hours), 2) as total_moving_time_hours,
        round(sum(calories), 0) as total_calories,

        case
            when sum(distance_km) > 0
                then round((sum(moving_time_hours) * 60) / sum(distance_km), 2)
        end as avg_pace_min_per_km,

        round(max(distance_km), 2) as longest_activity_km

    from activities
    group by 1, 2, 3

)

select *
from final