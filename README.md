# Offline-First Maternal Health Records for Public Health Midwives

MCS4302 Mobile Computing — Group Project (UCSC, MSc in Computer Science)

## Problem

Public Health Midwives (PHMs) in Sri Lanka record maternal home visits in villages with
weak or no mobile signal. A Public Health Nursing Sister (PHNS) may update the same mother's
record at the clinic. The app must:

- work fully **offline**,
- **sync efficiently** on poor networks (2G/3G),
- **never silently lose or overwrite** health data when two people edit the same record.

The project designs, implements and **experimentally compares three sync strategies**.

> All data in this project is synthetic (generated with Python Faker). No real patient data is used.

## Sync strategies compared

| | S1 Full sync (baseline) | S2 Delta sync | S3 Versioned delta (proposed) |
|---|---|---|---|
| Sends | All records every time | Only records changed since last sync | Only changed records + version numbers |
| Conflict rule | Last upload wins | Last upload wins | Server checks version; mismatch = conflict |
| On conflict | Other edit silently lost | Other edit silently lost | Field-level merge; older value saved in history and flagged |

All strategies use an **idempotent outbox**: every change has a unique `operation_id`, so
retries after a dropped connection never create duplicates.

## Architecture

```
 Android Emulator                     Mac host
┌──────────────────────┐        ┌─────────────┐        ┌──────────────────────┐
│ Flutter app          │        │  Toxiproxy  │        │ FastAPI backend      │
│  - SQLite (sqflite)  │ <────> │  delay /    │ <────> │  /sync/push          │
│  - outbox            │ 10.0.2.2  bandwidth / │        │  /sync/pull?since=   │
│  - sync engine S1-S3 │        │  conn. cuts │        │  conflict resolver   │
└──────────────────────┘        └─────────────┘        │  SQLite + history    │
                                                       └──────────────────────┘
```

## Repository structure (planned)

```
mobile_app/    Flutter app (PHM / PHNS roles, offline records, sync engine)
backend/       FastAPI server, conflict resolver, tests
experiments/   experiment runner, Faker data generator, second-device simulator, plot scripts
data/          raw experiment CSVs
results/       graphs and summary tables
docs/          API contract (api.md), design notes, report material
```

## Experiments

| Exp | Vary | Measure |
|---|---|---|
| E1 Data volume | 50 / 500 / 5000 records × S1–S3 | Sync time, bytes |
| E2 Amount changed | 1% / 10% / 50% edited | Sync time, bytes |
| E3 Network | 4G / 3G / 2G (Toxiproxy) | Sync time |
| E4 Connection drops | Cut every 2 / 5 / 10 s | Records lost, duplicates, retries, time |
| E5 Concurrent edits | 10 / 50 / 100 conflicting edits | Conflicts detected, updates lost, merge time |
| E6 Security (optional) | HTTP vs HTTPS + JWT | Time and byte overhead |

Each run is repeated 5 times; results report mean, median and p95.

## Tech stack

Flutter/Dart, sqflite, connectivity_plus, Python 3, FastAPI, uvicorn, SQLite, Toxiproxy,
Faker, pandas, matplotlib, Android Emulator, Android Profiler, Wireshark.

## Limitations

Emulator on Apple M4 is faster than real budget phones; Toxiproxy is not a real cellular
network; no battery measurements; single local server; synthetic data only.

## Team

| Name | Student ID |
|---|---|
| _TBD_ | _TBD_ |
| _TBD_ | _TBD_ |

## Status

🚧 Project setup — implementation in progress.
