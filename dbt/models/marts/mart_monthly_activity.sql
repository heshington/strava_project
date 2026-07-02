with date_months as (

    select distinct
        date_trunc('month', date_day)::date as month_start_date
    from {{ ref('dim_date') }}

),

activity_types as (

    select distinct
        activity_type
    from {{ ref('fct_activities') }}
    where distance_km > 0

),

monthly_activity as (

    select
        date_trunc('month', activity_date)::date as month_start_date,
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
        to_char(dm.month_start_date, 'YYYYMMDD')::integer as month_start_date_key,
        dm.month_start_date,
        (dm.month_start_date + interval '1 month - 1 day')::date as month_end_date,
        at.activity_type,

        coalesce(ma.activity_count, 0) as activity_count,
        coalesce(round(ma.total_distance_km, 2), 0) as total_distance_km,
        coalesce(round(ma.total_elevation_gain_m, 2), 0) as total_elevation_gain_m,
        coalesce(round(ma.total_moving_time_hours, 2), 0) as total_moving_time_hours,
        coalesce(round(ma.total_calories, 0), 0) as total_calories,

        case
            when coalesce(ma.total_distance_km, 0) > 0
                then round((ma.total_moving_time_hours * 60) / ma.total_distance_km, 2)
        end as avg_pace_min_per_km

    from date_months dm
    cross join activity_types at
    left join monthly_activity ma
        on dm.month_start_date = ma.month_start_date
        and at.activity_type = ma.activity_type

)

select *
from final