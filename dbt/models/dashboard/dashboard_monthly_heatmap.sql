with dates as (

    select distinct
        extract(year from date_day)::integer as activity_year,
        extract(month from date_day)::integer as activity_month_number,
        date_trunc('month', date_day)::date as month_start_date,
        trim(to_char(date_day, 'Month')) as month_label
    from {{ ref('dim_date') }}

),

monthly_activity as (

    select
        activity_year,
        activity_month_number,
        sum(activity_count) as activity_count,
        sum(total_distance_km) as total_distance_km,
        sum(total_relative_effort) as total_relative_effort
    from {{ ref('dashboard_activity_heatmap') }}
    group by 1, 2

),

final as (

    select
        d.activity_year,
        d.activity_month_number,
        d.month_start_date,
        d.month_label,

        coalesce(m.activity_count, 0) as activity_count,
        coalesce(m.total_distance_km, 0) as total_distance_km,
        coalesce(m.total_relative_effort, 0) as total_relative_effort,

        case
            when coalesce(m.total_relative_effort, 0) = 0 then 0
            when coalesce(m.total_relative_effort, 0) <= 100 then 1
            when coalesce(m.total_relative_effort, 0) <= 300 then 2
            when coalesce(m.total_relative_effort, 0) <= 600 then 3
            when coalesce(m.total_relative_effort, 0) <= 1000 then 4
            else 5
        end as effort_bucket

    from dates d
    left join monthly_activity m
        on d.activity_year = m.activity_year
       and d.activity_month_number = m.activity_month_number

)

select *
from final
order by
    activity_year,
    activity_month_number