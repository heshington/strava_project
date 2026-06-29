with activities as (

    select *
    from {{ ref('stg_strava__activities') }}

),

final as (

    select
        activity_id,
        to_char(activity_date, 'YYYYMMDD')::integer as activity_date_key,
        activity_date,
        activity_datetime,

        activity_name,
        activity_type,
        activity_description,

        distance_km,
        distance_m,
        elapsed_time_seconds,
        moving_time_seconds,
        moving_time_hours,
        elapsed_time_hours,

        pace_min_per_km,
        average_speed_kmh,
        average_speed_mps,
        max_speed_kmh,
        max_speed_mps,

        elevation_gain_m,
        elevation_loss_m,
        elevation_gain_per_km,

        average_heart_rate,
        max_heart_rate,
        relative_effort,
        calories,

        activity_gear,
        source_filename,

        is_run,
        is_walk,
        is_strength,
        is_commute,
        is_flagged,
        is_from_upload

    from activities

)

select *
from final