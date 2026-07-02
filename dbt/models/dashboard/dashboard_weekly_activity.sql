select

    week_start_date_key,

    week_start_date,

    week_end_date,

    activity_type,

    activity_count,

    total_distance_km,

    total_elevation_gain_m,

    total_moving_time_hours,

    total_calories,

    avg_pace_min_per_km,

    extract(year from week_start_date)::integer as activity_year,

    extract(month from week_start_date)::integer as activity_month_number

from {{ ref('mart_weekly_activity') }}