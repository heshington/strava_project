import json
from datetime import datetime
from pathlib import Path

import psycopg2
import yaml

BASE_DIR = Path(__file__).resolve().parent.parent
PROFILES_PATH = BASE_DIR / "profiles.yml"
INPUT_PATH = BASE_DIR / "strava_api_activities.json"

DBT_PROFILE_NAME = "strava_dbt"
DBT_TARGET = "dev"


def get_dbt_profile() -> dict:
    with open(PROFILES_PATH, "r") as file:
        profiles = yaml.safe_load(file)

    return profiles[DBT_PROFILE_NAME]["outputs"][DBT_TARGET]


def get_connection():
    profile = get_dbt_profile()

    return psycopg2.connect(
        host=profile["host"],
        port=profile["port"],
        dbname=profile["dbname"],
        user=profile["user"],
        password=profile["password"],
    )


def format_strava_date(value: str | None) -> str | None:
    if value is None:
        return None

    dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return dt.strftime("%b %-d, %Y, %-I:%M:%S %p")


def get_existing_activity_ids(cursor) -> set[int]:
    cursor.execute('select "Activity ID" from raw.strava_activities')

    return {row[0] for row in cursor.fetchall()}


def map_activity(activity: dict) -> dict:
    distance_m = activity.get("distance")
    moving_time = activity.get("moving_time")
    elapsed_time = activity.get("elapsed_time")

    average_speed = None
    if distance_m and moving_time:
        average_speed = distance_m / moving_time

    average_elapsed_speed = None
    if distance_m and elapsed_time:
        average_elapsed_speed = distance_m / elapsed_time

    return {
        "Activity ID": activity.get("id"),
        "Activity Date": format_strava_date(activity.get("start_date_local")),
        "Activity Name": activity.get("name"),
        "Activity Type": activity.get("type"),
        "Activity Description": None,

        "Distance": round(distance_m / 1000, 2) if distance_m is not None else None,
        "Distance_1": distance_m,

        "Elapsed Time": elapsed_time,
        "Moving Time": moving_time,

        "Elevation Gain": activity.get("total_elevation_gain"),
        "Elevation Loss": None,
        "Elevation Low": None,
        "Elevation High": None,

        "Average Speed": average_speed,
        "Max Speed": activity.get("max_speed"),

        "Average Heart Rate": activity.get("average_heartrate"),
        "Max Heart Rate": activity.get("max_heartrate"),
        "Relative Effort": activity.get("suffer_score"),

        "Calories": activity.get("calories"),

        "Activity Gear": activity.get("gear_id"),
        "Filename": "strava_api",

        "Commute": activity.get("commute"),
        "Flagged": 1.0 if activity.get("flagged") else 0.0,
        "From Upload": 1.0 if activity.get("manual") else 0.0,

        "Average Grade": activity.get("average_grade"),
        "Max Grade": activity.get("max_grade"),
        "Grade Adjusted Distance": None,
        "Average Grade Adjusted Pace": None,

        "Average Elapsed Speed": average_elapsed_speed,
        "Dirt Distance": None,
        "Total Steps": None,
        "Carbon Saved": None,

        "Competition": None,
        "Long Run": None,
    }


def insert_activity(cursor, row: dict) -> None:
    columns = list(row.keys())
    values = list(row.values())

    column_sql = ", ".join(f'"{column}"' for column in columns)
    placeholder_sql = ", ".join(["%s"] * len(columns))

    cursor.execute(
        f"""
        insert into raw.strava_activities ({column_sql})
        values ({placeholder_sql})
        """,
        values,
    )


def main() -> None:
    with open(INPUT_PATH, "r") as file:
        activities = json.load(file)

    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            existing_ids = get_existing_activity_ids(cursor)

            inserted_count = 0
            skipped_count = 0

            for activity in activities:
                activity_id = activity.get("id")

                if activity_id in existing_ids:
                    skipped_count += 1
                    continue

                row = map_activity(activity)
                insert_activity(cursor, row)

                existing_ids.add(activity_id)
                inserted_count += 1

        conn.commit()

        print(f"Inserted {inserted_count} activities")
        print(f"Skipped {skipped_count} existing activities")

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    main()