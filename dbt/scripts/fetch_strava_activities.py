import json
import os
import re
from pathlib import Path

import requests
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / ".env"
OUTPUT_PATH = BASE_DIR / "strava_api_activities.json"

load_dotenv(ENV_PATH)

CLIENT_ID = os.getenv("STRAVA_CLIENT_ID")
CLIENT_SECRET = os.getenv("STRAVA_CLIENT_SECRET")
REFRESH_TOKEN = os.getenv("STRAVA_REFRESH_TOKEN")

AFTER_EPOCH = 1782148097


def update_refresh_token(new_refresh_token: str) -> None:
    env_text = ENV_PATH.read_text()

    env_text = re.sub(
        r"STRAVA_REFRESH_TOKEN=.*",
        f"STRAVA_REFRESH_TOKEN={new_refresh_token}",
        env_text,
    )

    ENV_PATH.write_text(env_text)


def refresh_access_token() -> str:
    response = requests.post(
        "https://www.strava.com/oauth/token",
        data={
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "refresh_token": REFRESH_TOKEN,
            "grant_type": "refresh_token",
        },
        timeout=30,
    )

    response.raise_for_status()
    token_response = response.json()

    update_refresh_token(token_response["refresh_token"])

    return token_response["access_token"]


def fetch_activities(access_token: str) -> list[dict]:
    activities = []
    page = 1

    while True:
        response = requests.get(
            "https://www.strava.com/api/v3/athlete/activities",
            headers={"Authorization": f"Bearer {access_token}"},
            params={
                "after": AFTER_EPOCH,
                "page": page,
                "per_page": 200,
            },
            timeout=30,
        )

        response.raise_for_status()
        batch = response.json()

        if not batch:
            break

        activities.extend(batch)
        print(f"Fetched page {page}: {len(batch)} activities")

        page += 1

    return activities


def main() -> None:
    if not CLIENT_ID or not CLIENT_SECRET or not REFRESH_TOKEN:
        raise ValueError("Missing Strava credentials in .env")

    access_token = refresh_access_token()
    activities = fetch_activities(access_token)

    with open(OUTPUT_PATH, "w") as f:
        json.dump(activities, f, indent=2)

    print(f"\nSaved {len(activities)} activities to {OUTPUT_PATH}")
    print("Updated STRAVA_REFRESH_TOKEN in .env")


if __name__ == "__main__":
    main()