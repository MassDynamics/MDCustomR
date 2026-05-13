"""
Deploy MDCustomR to the Mass Dynamics platform via the API.

Usage:
    # From the repo root, with a .env file containing MD_AUTH_TOKEN and MD_API_BASE_URL:
    source .venv/bin/activate
    python .notes/deploy_api.py
"""

import json
import os
import time

import requests
from dotenv import load_dotenv

load_dotenv()

# ── Config ────────────────────────────────────────────────────────────────────

BASE_URL  = os.environ["MD_API_BASE_URL"].rstrip("/")
API_TOKEN = os.environ["MD_AUTH_TOKEN"]
print(f"BASE_URL: {BASE_URL}")
# print(f"API_TOKEN: {API_TOKEN}")

# IMAGE     = "243488295326.dkr.ecr.ap-southeast-2.amazonaws.com/md_custom_r:0.1.8-188"
# IMAGE     = "arn:aws:ecr:ap-southeast-2:840442538684:repository/test_md_custom_r_flow:0.1.8-1"
IMAGE     = "840442538684.dkr.ecr.ap-southeast-2.amazonaws.com/test_md_custom_r_flow:0.1.8-1"

JOB_NAME  = "Custom R Transform Intensities"
RUN_TYPE  = "INTENSITY"
FLOW      = "input_transform_intensities"
FLOW_PKG  = "md_custom_r.process_r"

# ── Helpers ───────────────────────────────────────────────────────────────────

HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Accept": "application/vnd.md-v2+json",
    "Content-Type": "application/json",
}


def wait_for_deploy(location: str, poll_interval: int = 5) -> dict:
    url = BASE_URL.replace("/api", "") + location
    print(f"Polling: {url}")
    while True:
        r = requests.get(url, headers=HEADERS)
        if r.status_code == 201:
            return r.json()
        elif r.status_code == 202:
            print("  ... still deploying")
            time.sleep(poll_interval)
        else:
            r.raise_for_status()


# ── Deploy ────────────────────────────────────────────────────────────────────

payload = {
    "name": JOB_NAME,
    "run_type": RUN_TYPE,
    "public": False,
    "job_deploy_request": {
        "image": IMAGE,
        "flow_package": FLOW_PKG,
        "flow": FLOW,
    },
}
print(f"Payload: {json.dumps(payload, indent=2)}")

print(f"Deploying '{JOB_NAME}' to {BASE_URL} ...")
print(f"  image:        {IMAGE}")
print(f"  flow_package: {FLOW_PKG}")
print(f"  flow:         {FLOW}")
print()

resp = requests.post(f"{BASE_URL}/jobs/create_or_update", headers=HEADERS, json=payload)
job = '{}'
if resp.status_code == 201:
    job = resp.json()
    print("Deployed immediately.")
elif resp.status_code == 202:
    location = resp.headers.get("Location")
    if not location:
        raise RuntimeError("Got 202 but no Location header in response.")
    job = wait_for_deploy(location)
    print("Deployment complete.")
else:
    print(f"Error {resp.status_code}: {resp.text}")
    resp.raise_for_status()

print()
print("Job details:")
print(job)
