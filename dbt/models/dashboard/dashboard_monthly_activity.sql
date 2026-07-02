select

    month_start_date_key,

    month_start_date,

    month_end_date,

    activity_type,

    activity_count,

    total_distance_km,

    total_elevation_gain_m,

    total_moving_time_hours,

    total_calories,

    avg_pace_min_per_km,

    extract(year from month_start_date)::integer as activity_year,

    extract(month from month_start_date)::integer as activity_month_number,

    to_char(month_start_date, 'Mon YYYY') as month_label

from {{ ref('mart_monthly_activity') }}