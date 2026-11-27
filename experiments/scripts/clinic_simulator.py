#!/usr/bin/env python3
"""Second device for experiment E5 (concurrent edits): the PHNS / supervisor at the clinic.

The PHM's phone (emulator) edits records while offline. This script plays the clinic,
which edits the SAME records on the server in the meantime. When the phone syncs, the
server sees two edits of one record:
    S1 / S2  -> last upload wins, one edit is silently lost
    S3       -> conflict detected; merged (different fields) or flagged (same field)

Steps:
    1. sign in as the dev supervisor (+94700000004, code 000000)
    2. pull everything in the MOH division
    3. pick N records of one type (same --seed = same records) and change one field
    4. push those edits with the chosen strategy, in batches of 200
    5. print a summary (and optionally append it to a CSV for pandas)

Example (server on port 5000, phone already pulled the data):
    python3 experiments/scripts/clinic_simulator.py --count 50 --strategy S3 \\
        --entity growthMeasurement --field weightKg --csv experiments/data/e5_clinic.csv

Python standard library only. Synthetic data only.
"""
import argparse
import csv
import json
import os
import random
import sys
import time
import uuid
from collections import Counter
from typing import Any, Dict, Iterable, List

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from littlebloom_client import SUPERVISOR_PHONE, ApiError, Client, utc_now_iso  # noqa: E402

MAX_PUSH = 200  # api.md section 4
DEVICE_ID = "emu-phns-01"

# Fields the clinic may change, per record type, and how to change them.
EDITABLE = {
    "growthMeasurement": ["weightKg", "heightCm", "notes"],
    "maternalVisit": ["weightKg", "bpSystolic", "notes"],
    "child": ["name", "chdrNumber"],
    "mother": ["address", "gestationWeeks"],
    "vaccination": ["batchNo"],
}


def edit_value(field: str, old: Any, rng: random.Random, n: int) -> Any:
    """A new, still-valid value for `field` that is different from `old`."""
    if field in ("weightKg", "heightCm"):
        base = float(old) if isinstance(old, (int, float)) else 10.0
        return round(base + rng.choice([-1, 1]) * rng.uniform(0.1, 0.5), 1)
    if field == "bpSystolic":
        return int(old) + 2 if isinstance(old, int) and old < 200 else 120
    if field == "gestationWeeks":
        return int(old) + 1 if isinstance(old, int) and old < 42 else 20
    if field == "chdrNumber":
        return f"CHDR-CLINIC-{n:05d}"
    return f"Clinic edit {n}"  # notes, name, address, batchNo


def build_change(record: Dict[str, Any], entity: str, field: str, rng: random.Random, n: int,
                 now_iso: str, device_id: str = DEVICE_ID) -> Dict[str, Any]:
    """One outbox change editing `field`, based on the version the clinic just pulled."""
    data = dict(record)
    data[field] = edit_value(field, record.get(field), rng, n)
    data["updatedAt"] = now_iso
    data["deviceId"] = device_id
    return {
        "operationId": str(uuid.uuid4()),
        "entity": entity,
        "op": "upsert",
        "recordId": record["id"],
        "baseVersion": record["version"],
        "changedFields": [field],
        "data": data,
    }


def pick_records(changes: Iterable, entity: str, count: int, seed: int) -> List[Dict[str, Any]]:
    """`count` live records of `entity`, chosen the same way for the same seed."""
    records = sorted((r for e, r in changes if e == entity and not r.get("deleted")), key=lambda r: r["id"])
    if count > len(records):
        raise ValueError(f"only {len(records)} {entity} records on the server, asked for {count}")
    return random.Random(seed).sample(records, count)


def batches(items: List[Any], size: int = MAX_PUSH) -> Iterable[List[Any]]:
    for start in range(0, len(items), size):
        yield items[start:start + size]


def summarize(results: List[Dict[str, Any]]) -> Dict[str, int]:
    counts = Counter(r["status"] for r in results)
    return {s: counts.get(s, 0) for s in ("applied", "duplicate", "conflictMerged", "conflictFlagged", "rejected")}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", default="http://localhost:5000")
    parser.add_argument("--count", type=int, required=True, help="records to edit (E5: 10 / 50 / 100)")
    parser.add_argument("--strategy", choices=["S1", "S2", "S3"], required=True)
    parser.add_argument("--entity", choices=sorted(EDITABLE), default="growthMeasurement")
    parser.add_argument("--field", help="field to change (default: first editable field of the entity)")
    parser.add_argument("--seed", type=int, default=1, help="same seed = same records chosen")
    parser.add_argument("--network-profile", default="4G")
    parser.add_argument("--run-id", default=None, help="label stored in the CSV row")
    parser.add_argument("--csv", help="append the summary to this CSV file")
    args = parser.parse_args(argv)

    field = args.field or EDITABLE[args.entity][0]
    if field not in EDITABLE[args.entity]:
        parser.error(f"--field for {args.entity} must be one of {EDITABLE[args.entity]}")

    client = Client(args.base_url, network_profile=args.network_profile, device_id=DEVICE_ID, strategy=args.strategy)
    try:
        client.sign_in(SUPERVISOR_PHONE, device_id=DEVICE_ID)
        pulled, _ = client.pull_all()
        targets = pick_records(pulled, args.entity, args.count, args.seed)

        rng = random.Random(args.seed)
        now = utc_now_iso()
        changes = [build_change(r, args.entity, field, rng, i + 1, now) for i, r in enumerate(targets)]

        started = time.perf_counter()
        results: List[Dict[str, Any]] = []
        for chunk in batches(changes):
            results.extend(client.push(DEVICE_ID, args.strategy, chunk)["results"])
        elapsed_ms = round((time.perf_counter() - started) * 1000)
    except (ApiError, ValueError) as err:
        print(f"Error: {err}", file=sys.stderr)
        return 1

    summary = {
        "run_id": args.run_id or f"{args.strategy}-{args.entity}-{field}-{args.count}",
        "at": now,
        "strategy": args.strategy,
        "entity": args.entity,
        "field": field,
        "edited": len(changes),
        "push_ms": elapsed_ms,
        **summarize(results),
    }
    print(json.dumps(summary, indent=2))

    if args.csv:
        new_file = not os.path.exists(args.csv)
        os.makedirs(os.path.dirname(os.path.abspath(args.csv)), exist_ok=True)
        with open(args.csv, "a", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=list(summary))
            if new_file:
                writer.writeheader()
            writer.writerow(summary)
    return 0


if __name__ == "__main__":
    sys.exit(main())
