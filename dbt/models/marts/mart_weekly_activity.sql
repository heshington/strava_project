with date_weeks as (

    select distinct
        date_trunc('week', date_day)::date as week_start_date
    from {{ ref('dim_date') }}

),

activity_types as (

    select distinct
        activity_type
    from {{ ref('fct_activities') }}
    where distance_km > 0

),

weekly_activity as (

    select
        date_trunc('week', activity_date)::date as week_start_date,
        activity_type,

        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(elevation_gain_m) as total_elevation_gain_m,
        sum(moving_time_hours) as total_moving_time_hours,
        sum(calories) as total_calories

    from {{ ref('fct_activities') }}
    where distance_km > 0
    group by 1, 2

),

final as (

    select
        to_char(dw.week_start_date, 'YYYYMMDD')::integer as week_start_date_key,
        dw.week_start_date,
        (dw.week_start_date + interval '6 days')::date as week_end_date,
        at.activity_type,

        coalesce(wa.activity_count, 0) as activity_count,
        coalesce(round(wa.total_distance_km, 2), 0) as total_distance_km,
        coalesce(round(wa.total_elevation_gain_m, 2), 0) as total_elevation_gain_m,
        coalesce(round(wa.total_moving_time_hours, 2), 0) as total_moving_time_hours,
        coalesce(round(wa.total_calories, 0), 0) as total_calories,

        case
            when coalesce(wa.total_distance_km, 0) > 0
                then round((wa.total_moving_time_hours * 60) / wa.total_distance_km, 2)
        end as avg_pace_min_per_km

    from date_weeks dw
    cross join activity_types at
    left join weekly_activity wa
        on dw.week_start_date = wa.week_start_date
        and at.activity_type = wa.activity_type

)

select *
from final