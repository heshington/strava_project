with runs as (

    select *
    from {{ ref('fct_activities') }}
    where is_run

),

weekly_runs as (

    select
        date_trunc('week', activity_date)::date as week_start_date,

        count(*) as run_count,
        round(sum(distance_km), 2) as total_distance_km,
        round(sum(moving_time_hours), 2) as total_moving_time_hours,
        round(sum(elevation_gain_m), 2) as total_elevation_gain_m,
        round(sum(calories), 0) as total_calories,

        round(avg(pace_min_per_km), 2) as avg_pace_min_per_km,
        round(avg(average_heart_rate), 0) as avg_heart_rate,
        max(distance_km) as longest_run_km,
        max(elevation_gain_m) as biggest_climb_m,
        round(
            sum(elevation_gain_m) / nullif(sum(distance_km), 0),
            2
        ) as elevation_gain_per_km,
        round(
            avg(pace_min_per_km) + (
                (sum(elevation_gain_m) / nullif(sum(distance_km), 0)) * 0.01
            ),
            2
        ) as terrain_adjusted_pace,
        round(
            avg(average_heart_rate) / nullif(avg(pace_min_per_km), 0),
            2
        ) as heart_rate_to_pace_ratio,
        round(
            avg(average_heart_rate) / nullif(
                avg(pace_min_per_km) + (
                    (sum(elevation_gain_m) / nullif(sum(distance_km), 0)) * 0.01
                ),
                0
            ),
            2
        ) as terrain_adjusted_hr_pace_ratio

    from runs
    group by 1

),

with_rolling as (

    select
        week_start_date,
        run_count,
        total_distance_km,
        total_moving_time_hours,
        total_elevation_gain_m,
        total_calories,
        avg_pace_min_per_km,
        avg_heart_rate,
        longest_run_km,
        biggest_climb_m,
        elevation_gain_per_km,
        terrain_adjusted_pace,
        heart_rate_to_pace_ratio,
        terrain_adjusted_hr_pace_ratio,

        avg(avg_pace_min_per_km) over (
            order by week_start_date
            rows between 3 preceding and current row
        ) as rolling_4wk_avg_pace_min_per_km,

        avg(avg_pace_min_per_km) over (
            order by week_start_date
            rows between 7 preceding and current row
        ) as rolling_8wk_avg_pace_min_per_km,

        avg(avg_heart_rate) over (
            order by week_start_date
            rows between 3 preceding and current row
        ) as rolling_4wk_avg_heart_rate,

        avg(avg_heart_rate) over (
            order by week_start_date
            rows between 7 preceding and current row
        ) as rolling_8wk_avg_heart_rate,

        avg(heart_rate_to_pace_ratio) over (
            order by week_start_date
            rows between 3 preceding and current row
        ) as rolling_4wk_heart_rate_to_pace_ratio,

        avg(heart_rate_to_pace_ratio) over (
            order by week_start_date
            rows between 7 preceding and current row
        ) as rolling_8wk_heart_rate_to_pace_ratio,

        avg(terrain_adjusted_hr_pace_ratio) over (
            order by week_start_date
            rows between 3 preceding and current row
        ) as rolling_4wk_terrain_adjusted_hr_pace_ratio,

        avg(terrain_adjusted_hr_pace_ratio) over (
            order by week_start_date
            rows between 7 preceding and current row
        ) as rolling_8wk_terrain_adjusted_hr_pace_ratio
            from weekly_runs

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
        round(total_calories, 0) as total_calories,
        round(avg_pace_min_per_km, 2) as avg_pace_min_per_km,
        round(avg_heart_rate, 0) as avg_heart_rate,
        round(longest_run_km, 2) as longest_run_km,
        round(biggest_climb_m, 2) as biggest_climb_m,
        round(elevation_gain_per_km, 2) as elevation_gain_per_km,
        round(terrain_adjusted_pace, 2) as terrain_adjusted_pace,
        round(rolling_4wk_avg_pace_min_per_km, 2) as rolling_4wk_avg_pace_min_per_km,
        round(rolling_8wk_avg_pace_min_per_km, 2) as rolling_8wk_avg_pace_min_per_km,
        round(rolling_4wk_avg_heart_rate, 0) as rolling_4wk_avg_heart_rate,
        round(rolling_8wk_avg_heart_rate, 0) as rolling_8wk_avg_heart_rate,
        round(heart_rate_to_pace_ratio, 2) as heart_rate_to_pace_ratio,
        round(terrain_adjusted_hr_pace_ratio, 2) as terrain_adjusted_hr_pace_ratio,
        round(rolling_4wk_heart_rate_to_pace_ratio, 2) as rolling_4wk_heart_rate_to_pace_ratio,
        round(rolling_8wk_heart_rate_to_pace_ratio, 2) as rolling_8wk_heart_rate_to_pace_ratio,
        round(rolling_4wk_terrain_adjusted_hr_pace_ratio, 2) as rolling_4wk_terrain_adjusted_hr_pace_ratio,
        round(rolling_8wk_terrain_adjusted_hr_pace_ratio, 2) as rolling_8wk_terrain_adjusted_hr_pace_ratio,

        round(avg_pace_min_per_km - lag(avg_pace_min_per_km) over (order by week_start_date), 2) as pace_change_vs_previous_week,
        round(avg_heart_rate - lag(avg_heart_rate) over (order by week_start_date), 0) as heart_rate_change_vs_previous_week

    from with_rolling

)

select *
from final
