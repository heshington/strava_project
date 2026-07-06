import os
import requests
from urllib.parse import urlencode
from dotenv import load_dotenv
from pathlib import Path

env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

CLIENT_ID = os.getenv("STRAVA_CLIENT_ID")
CLIENT_SECRET = os.getenv("STRAVA_CLIENT_SECRET")

if not CLIENT_ID or not CLIENT_SECRET:
    raise ValueError("Missing STRAVA_CLIENT_ID or STRAVA_CLIENT_SECRET in dbt/.env")

params = {
    "client_id": CLIENT_ID,
    "redirect_uri": "http://localhost/exchange_token",
    "response_type": "code",
    "approval_prompt": "force",
    "scope": "read,activity:read_all",
}

auth_url = "https://www.strava.com/oauth/authorize?" + urlencode(params)

print("\nOpen this URL in your browser:\n")
print(auth_url)
print("\nAfter authorising, Strava will redirect you to localhost.")
print("Copy the `code=` value from the browser URL and paste it below.\n")

code = input("Paste code here: ").strip()

response = requests.post(
    "https://www.strava.com/oauth/token",
    data={
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "code": code,
        "grant_type": "authorization_code",
    },
    timeout=30,
)

response.raise_for_status()
tokens = response.json()

print("\nSuccess. Add this to dbt/.env:\n")
print(f"STRAVA_REFRESH_TOKEN={tokens['refresh_token']}")