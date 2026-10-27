import json
import sys
from pathlib import Path

path = Path(
    sys.argv[1] if len(sys.argv) > 1
    else "tests/cloudtrail/sample-events.jsonl"
)

required = {
    "eventTime", "eventSource", "eventName",
    "awsRegion", "userIdentity"
}

events = []
errors = []

for number, line in enumerate(path.read_text().splitlines(), 1):
    if not line.strip():
        continue

    try:
        event = json.loads(line)
    except json.JSONDecodeError as exc:
        errors.append(f"Line {number}: invalid JSON: {exc}")
        continue

    missing = required - event.keys()
    if missing:
        errors.append(
            f"Line {number}: missing fields: {', '.join(sorted(missing))}"
        )
        continue

    if not isinstance(event["userIdentity"], dict):
        errors.append(f"Line {number}: userIdentity must be an object")
        continue

    events.append(event)

print(f"Valid events: {len(events)}")
print(f"Errors: {len(errors)}")

for error in errors:
    print(f"FAIL: {error}")

print("\nEvents:")
for event in events:
    identity = event["userIdentity"]
    actor = identity.get("userName") or identity.get("arn") or identity.get("type")
    print(
        f"{event['eventTime']} | {event['eventSource']} | "
        f"{event['eventName']} | actor={actor}"
    )

if errors or not events:
    sys.exit(1)

print("\nPASS: all events have valid JSON and required fields.")
