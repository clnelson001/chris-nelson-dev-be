import json
import os
import boto3
from datetime import datetime

cloudwatch = boto3.client("cloudwatch")
ALARM_NAME = os.environ["ALARM_NAME"]


def lambda_handler(event, context):
    resp = cloudwatch.describe_alarms(AlarmNames=[ALARM_NAME])
    alarms = resp.get("MetricAlarms", [])

    if not alarms:
        status = "UNKNOWN"
        reason = "Alarm not found"
        updated = None
    else:
        alarm = alarms[0]
        status = alarm.get("StateValue", "UNKNOWN")  # OK, ALARM, INSUFFICIENT_DATA
        reason = alarm.get("StateReason", "")
        updated_ts = alarm.get("StateUpdatedTimestamp")
        if isinstance(updated_ts, datetime):
            updated = updated_ts.isoformat()
        else:
            updated = None

    body = {
        "status": status,
        "reason": reason,
        "updated": updated,
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }
