import json
from datetime import datetime, timezone


def _iso_now() -> str:
    """Return current time in ISO 8601 format with UTC timezone."""
    return datetime.now(timezone.utc).isoformat()


def _build_latency_response() -> dict:
    """
    Return dummy but realistic per-region latency data.
    Values are in milliseconds and meant to look plausible,
    not to reflect real measurements.
    """
    regions = [
        {
            "regionCode": "us-east-1",
            "regionName": "US East (N. Virginia)",
            "sslHandshakeMs": {"min": 210.3, "avg": 245.8, "max": 290.1},
            "timeToFirstByteMs": {"min": 410.2, "avg": 465.7, "max": 520.4},
        },
        {
            "regionCode": "us-east-2",
            "regionName": "US East (Ohio)",
            "sslHandshakeMs": {"min": 220.9, "avg": 255.3, "max": 305.0},
            "timeToFirstByteMs": {"min": 430.4, "avg": 478.6, "max": 535.2},
        },
        {
            "regionCode": "us-west-1",
            "regionName": "US West (N. California)",
            "sslHandshakeMs": {"min": 260.5, "avg": 295.1, "max": 340.7},
            "timeToFirstByteMs": {"min": 480.0, "avg": 525.3, "max": 590.8},
        },
        {
            "regionCode": "us-west-2",
            "regionName": "US West (Oregon)",
            "sslHandshakeMs": {"min": 230.2, "avg": 260.9, "max": 310.4},
            "timeToFirstByteMs": {"min": 440.7, "avg": 490.2, "max": 548.9},
        },
        {
            "regionCode": "eu-west-1",
            "regionName": "EU (Ireland)",
            "sslHandshakeMs": {"min": 270.1, "avg": 305.4, "max": 355.2},
            "timeToFirstByteMs": {"min": 500.3, "avg": 548.1, "max": 610.0},
        },
        {
            "regionCode": "eu-central-1",
            "regionName": "EU (Frankfurt)",
            "sslHandshakeMs": {"min": 280.0, "avg": 315.9, "max": 365.6},
            "timeToFirstByteMs": {"min": 510.8, "avg": 560.4, "max": 625.9},
        },
        {
            "regionCode": "ap-southeast-1",
            "regionName": "Asia Pacific (Singapore)",
            "sslHandshakeMs": {"min": 320.7, "avg": 355.0, "max": 405.8},
            "timeToFirstByteMs": {"min": 560.9, "avg": 615.3, "max": 685.0},
        },
        {
            "regionCode": "ap-northeast-1",
            "regionName": "Asia Pacific (Tokyo)",
            "sslHandshakeMs": {"min": 315.4, "avg": 350.2, "max": 400.1},
            "timeToFirstByteMs": {"min": 555.2, "avg": 605.7, "max": 675.3},
        },
        {
            "regionCode": "sa-east-1",
            "regionName": "South America (São Paulo)",
            "sslHandshakeMs": {"min": 340.0, "avg": 380.5, "max": 430.2},
            "timeToFirstByteMs": {"min": 590.1, "avg": 645.8, "max": 710.4},
        },
    ]

    return {
        "generatedAt": _iso_now(),
        "windowSeconds": 900,  # pretend "last 15 minutes"
        "regions": regions,
    }


def _build_health_response() -> dict:
    """
    Return dummy per-region health checker status.
    A couple of regions are marked unhealthy with 403-style messages.
    """
    regions = [
        {
            "regionCode": "us-east-1",
            "regionName": "US East (N. Virginia)",
            "ip": "15.177.10.101",
            "status": "HEALTHY",
            "httpStatusCode": 200,
            "message": "OK",
        },
        {
            "regionCode": "us-east-2",
            "regionName": "US East (Ohio)",
            "ip": "15.177.11.102",
            "status": "HEALTHY",
            "httpStatusCode": 200,
            "message": "OK",
        },
        {
            "regionCode": "us-west-1",
            "regionName": "US West (N. California)",
            "ip": "15.177.20.103",
            "status": "UNHEALTHY",
            "httpStatusCode": 403,
            "message": "HTTP Status Code 403, Forbidden. Resolved IP: 3.169.173.80",
        },
        {
            "regionCode": "us-west-2",
            "regionName": "US West (Oregon)",
            "ip": "15.177.22.113",
            "status": "UNHEALTHY",
            "httpStatusCode": 403,
            "message": "HTTP Status Code 403, Forbidden. Resolved IP: 54.230.114.39",
        },
        {
            "regionCode": "eu-west-1",
            "regionName": "EU (Ireland)",
            "ip": "15.177.30.104",
            "status": "HEALTHY",
            "httpStatusCode": 200,
            "message": "OK",
        },
        {
            "regionCode": "eu-central-1",
            "regionName": "EU (Frankfurt)",
            "ip": "15.177.31.105",
            "status": "HEALTHY",
            "httpStatusCode": 200,
            "message": "OK",
        },
        {
            "regionCode": "ap-southeast-1",
            "regionName": "Asia Pacific (Singapore)",
            "ip": "15.177.40.106",
            "status": "HEALTHY",
            "httpStatusCode": 200,
            "message": "OK",
        },
        {
            "regionCode": "ap-northeast-1",
            "regionName": "Asia Pacific (Tokyo)",
            "ip": "15.177.42.131",
            "status": "UNHEALTHY",
            "httpStatusCode": 403,
            "message": "HTTP Status Code 403, Forbidden. Resolved IP: 18.172.185.51",
        },
        {
            "regionCode": "sa-east-1",
            "regionName": "South America (São Paulo)",
            "ip": "15.177.50.107",
            "status": "HEALTHY",
            "httpStatusCode": 200,
            "message": "OK",
        },
    ]

    return {
        "generatedAt": _iso_now(),
        "regions": regions,
    }


def lambda_handler(event, context):
    """
    Single Lambda entrypoint that handles two logical endpoints:

    - GET /status/latency
    - GET /status/health-checkers

    For now, everything is dummy data with a stable, well-defined JSON shape.
    """
    path = event.get("rawPath") or event.get("path") or ""

    if path.endswith("/status/latency"):
        body = _build_latency_response()
        status_code = 200
    elif path.endswith("/status/health-checkers"):
        body = _build_health_response()
        status_code = 200
    else:
        # Fallback for unknown paths routed to this Lambda
        body = {
            "message": "Not found",
            "path": path,
        }
        status_code = 404

    return {
    "statusCode": 200,
    "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://chris-nelson.dev",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS"
    },
    "body": json.dumps(body)
}

