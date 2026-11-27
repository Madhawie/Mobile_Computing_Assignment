#!/usr/bin/env python3
"""Run-control for experiments against the real .NET API (Development server only).

Signs in as the dev admin (+94700000001, code 000000) and calls /api/experiments/*
(api.md section 12). Python standard library only.

Examples (from the repo root, server running on port 5000):
    python3 experiments/scripts/server_admin.py reset
    python3 experiments/scripts/server_admin.py seed --mothers 500 --area glg-east
    python3 experiments/scripts/server_admin.py stats
    python3 experiments/scripts/server_admin.py csv --out experiments/data/e1_server_log.csv

Synthetic data only.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from littlebloom_client import ADMIN_PHONE, ApiError, Client  # noqa: E402


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", default="http://localhost:5000")
    sub = parser.add_subparsers(dest="command", required=True)

    reset = sub.add_parser("reset", help="empty synced data before a run")
    reset.add_argument("--keep-log", action="store_true", help="keep the server sync log of earlier runs")

    seed = sub.add_parser("seed", help="insert synthetic records on the server")
    seed.add_argument("--mothers", type=int, required=True)
    seed.add_argument("--area", default="glg-east")
    seed.add_argument("--seed", type=int, default=42)

    sub.add_parser("stats", help="record counts, conflicts and sync log summary")

    csv = sub.add_parser("csv", help="download the server sync log as CSV")
    csv.add_argument("--out", required=True)
    csv.add_argument("--since", help="only rows at or after this UTC time, e.g. 2026-11-27T10:00:00Z")

    args = parser.parse_args(argv)
    client = Client(args.base_url)

    try:
        client.sign_in(ADMIN_PHONE, device_id="server-admin")

        if args.command == "reset":
            result = client.request("POST", "/api/experiments/reset", query={"keepSyncLog": str(args.keep_log).lower()})
            print(json.dumps(result, indent=2))
            print("Remember to clear the app's local data before the next run.")
        elif args.command == "seed":
            result = client.request("POST", "/api/experiments/seed",
                                    {"mothers": args.mothers, "areaId": args.area, "seed": args.seed})
            print(json.dumps(result, indent=2))
        elif args.command == "stats":
            print(json.dumps(client.request("GET", "/api/experiments/stats"), indent=2))
        elif args.command == "csv":
            data = client.request("GET", "/api/experiments/sync-log.csv", query={"since": args.since}, raw=True)
            os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
            with open(args.out, "wb") as f:
                f.write(data)
            rows = max(data.count(b"\n") - 1, 0)  # minus the header line
            print(f"Saved {rows} rows to {args.out}")
    except ApiError as err:
        print(f"Error: {err}", file=sys.stderr)
        if err.status == 404:
            print("Is the server running in Development (Experiments:Enabled = true)?", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
