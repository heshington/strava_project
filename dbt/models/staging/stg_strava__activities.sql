with source as (

    select *
    from {{ source('raw', 'strava_activities') }}

),

renamed as (

    select
        "Activity ID"::bigint as activity_id,
        to_timestamp("Activity Date", 'Mon DD, YYYY, HH12:MI:SS AM') as activity_datetime,

        "Activity Name" as activity_name,
        "Activity Type" as activity_type,
        "Activity Description" as activity_description,

        "Distance"::numeric as distance_km,
        "Distance_1"::numeric as distance_m,

        "Elapsed Time"::integer as elapsed_time_seconds,
        "Moving Time"::integer as moving_time_seconds,

        "Elevation Gain"::numeric as elevation_gain_m,
        "Elevation Loss"::numeric as elevation_loss_m,
        "Elevation Low"::numeric as elevation_low_m,
        "Elevation High"::numeric as elevation_high_m,

        "Average Speed"::numeric as average_speed_mps,
        ("Average Speed"::numeric * 3.6) as average_speed_kmh,

        "Max Speed"::numeric as max_speed_mps,
        ("Max Speed"::numeric * 3.6) as max_speed_kmh,

        "Average Heart Rate"::numeric as average_heart_rate,
        "Max Heart Rate"::numeric as max_heart_rate,
        "Relative Effort"::integer as relative_effort,

        "Calories"::numeric as calories,

        "Activity Gear" as activity_gear,
        "Filename" as source_filename,

        "Commute"::boolean as is_commute,
        ("Flagged" = 1) as is_flagged,
        ("From Upload" = 1) as is_from_upload,

        "Average Grade"::numeric as average_grade,
        "Max Grade"::numeric as max_grade,
        "Grade Adjusted Distance"::numeric as grade_adjusted_distance_m,
        "Average Grade Adjusted Pace"::numeric as average_grade_adjusted_pace,

        "Average Elapsed Speed"::numeric as average_elapsed_speed_mps,
        ("Average Elapsed Speed"::numeric * 3.6) as average_elapsed_speed_kmh,

        "Dirt Distance"::numeric as dirt_distance_m,
        "Total Steps"::numeric as total_steps,
        "Carbon Saved"::numeric as carbon_saved,

        "Competition" as competition,
        "Long Run" as long_run

    from source

),

final as (

    select
        *,
        activity_datetime::date as activity_date,
        date_trunc('week', activity_datetime)::date as activity_week,
        date_trunc('month', activity_datetime)::date as activity_month,
        extract(year from activity_datetime)::integer as activity_year,
        extract(month from activity_datetime)::integer as activity_month_number,
        extract(dow from activity_datetime)::integer as activity_day_of_week_number

    from renamed

)

select *
from final