with dates as (

    select
        date_day as activity_date,
        extract(year from date_day)::integer as activity_year,
        extract(month from date_day)::integer as activity_month_number,
        extract(week from date_day)::integer as activity_week_number,
        extract(isodow from date_day)::integer as activity_day_of_week_number,
        trim(to_char(date_day, 'Day')) as activity_day_name
    from {{ ref('dim_date') }}

),

activities as (

    select *
    from {{ ref('fct_activities') }}
    where activity_type in ('Run', 'Walk')

),

daily_activity as (

    select
        activity_date,

        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(moving_time_hours) as total_moving_time_hours,
        sum(elevation_gain_m) as total_elevation_gain_m,
        sum(calories) as total_calories,
        sum(coalesce(relative_effort, 0)) as total_relative_effort

    from activities
    group by 1

),

final as (

    select
        d.activity_date,
        d.activity_year,
        d.activity_month_number,
        d.activity_week_number,
        d.activity_day_of_week_number,
        d.activity_day_name,

        coalesce(da.activity_count, 0) as activity_count,
        coalesce(round(da.total_distance_km, 2), 0) as total_distance_km,
        coalesce(round(da.total_moving_time_hours, 2), 0) as total_moving_time_hours,
        coalesce(round(da.total_elevation_gain_m, 0), 0) as total_elevation_gain_m,
        coalesce(round(da.total_calories, 0), 0) as total_calories,
        coalesce(da.total_relative_effort, 0) as total_relative_effort,
        date_trunc('week', d.activity_date)::date as week_start_date,
        d.activity_year || '-' || lpad(d.activity_week_number::text, 2, '0') as year_week,
    case
        when coalesce(da.total_relative_effort, 0) = 0 then 0
        when coalesce(da.total_relative_effort, 0) <= 10 then 1
        when coalesce(da.total_relative_effort, 0) <= 40 then 2
        when coalesce(da.total_relative_effort, 0) <= 90 then 3
        when coalesce(da.total_relative_effort, 0) <= 150 then 4
        else 5
    end as effort_bucket

    from dates d
    left join daily_activity da
        on d.activity_date = da.activity_date

)

select *
from final