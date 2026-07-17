with calendar_weeks as (

    select distinct
        date_trunc('week', date_day)::date as week_start_date
    from {{ ref('dim_date') }}

),

weekly_runs as (

    select
        date_trunc('week', activity_date)::date as week_start_date,

        count(*) as run_count,
        sum(distance_km) as total_distance_km,
        sum(moving_time_hours) as total_moving_time_hours,
        sum(elevation_gain_m) as total_elevation_gain_m,
        sum(calories) as total_calories,

        sum(elevation_gain_m) / nullif(sum(distance_km), 0) as elevation_gain_per_km,

        avg(pace_min_per_km) as avg_pace_min_per_km,
        avg(average_heart_rate) as avg_heart_rate,

        max(distance_km) as longest_run_km,
        max(elevation_gain_m) as biggest_climb_m

    from {{ ref('fct_activities') }}
    where is_run
    group by 1

),

weekly_with_calendar as (

    select
        cw.week_start_date,
        wr.run_count,
        wr.total_distance_km,
        wr.total_moving_time_hours,
        wr.total_elevation_gain_m,
        wr.total_calories,
        wr.elevation_gain_per_km,
        wr.avg_pace_min_per_km,
        wr.avg_heart_rate,
        wr.longest_run_km,
        wr.biggest_climb_m
    from calendar_weeks cw
    left join weekly_runs wr
        on cw.week_start_date = wr.week_start_date

),

with_rolling as (

    select
        week_start_date,
        coalesce(run_count, 0) as run_count,
        coalesce(total_distance_km, 0) as total_distance_km,
        coalesce(total_moving_time_hours, 0) as total_moving_time_hours,
        coalesce(total_elevation_gain_m, 0) as total_elevation_gain_m,
        coalesce(total_calories, 0) as total_calories,
        elevation_gain_per_km,
        avg_pace_min_per_km,
        avg_heart_rate,
        longest_run_km,
        biggest_climb_m,

        avg(coalesce(total_distance_km, 0)) over (
        order by week_start_date
        rows between 3 preceding and current row
    ) as rolling_4wk_distance_km,
    avg(coalesce(total_distance_km, 0)) over (
        order by week_start_date
        rows between 7 preceding and current row
    ) as rolling_8wk_distance_km
        from weekly_with_calendar

),

final as (

    select
        to_char(week_start_date, 'YYYYMMDD')::integer as week_start_date_key,
        week_start_date,
        (week_start_date + interval '6 days')::date as week_end_date,

        run_count,

        round(total_distance_km, 2) as total_distance_km,
        round(total_moving_time_hours, 2) as total_moving_time_hours,
        round(total_elevation_gain_m, 2) as total_elevation_gain_m,
        round(elevation_gain_per_km, 2) as elevation_gain_per_km,
        round(total_calories, 0) as total_calories,

        round(avg_pace_min_per_km, 2) as avg_pace_min_per_km,
        round(avg_heart_rate, 0) as avg_heart_rate,

        round(longest_run_km, 2) as longest_run_km,
        round(biggest_climb_m, 2) as biggest_climb_m,

        round(rolling_4wk_distance_km, 2) as rolling_4wk_distance_km,
        round(rolling_8wk_distance_km, 2) as rolling_8wk_distance_km

    from with_rolling

)

select *
from final