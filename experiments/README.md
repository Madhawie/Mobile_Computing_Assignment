# Experiments

Scripts and data for comparing the sync strategies S1 / S2 / S3 (E1–E6).
**Synthetic data only.** Never put real patient data in this folder.

| Folder | Holds |
|---|---|
| `scripts/` | Mock server, experiment runner, data generator, plots |
| `data/` | Raw CSV exported from the app's `sync_log` (one file per experiment) |
| `results/` | Graphs and tables used in the report |

## Checking the real API

`scripts/api_check.py` sends the app's exact JSON to a running API as two devices and prints
PASS / WARN / FAIL per check (see `docs/architecture/connecting.md`):

```bash
python3 experiments/scripts/api_check.py --base http://<windows-pc-ip>:5000
python3 experiments/scripts/api_check.py --base http://localhost:5000 --mock   # against the mock
```

## Mock sync server

A small Python server that follows `docs/architecture/api.md`, so the app can be
tested before the .NET pull endpoint exists. Standard library only.

```bash
python3 experiments/scripts/mock_server.py            # listens on 0.0.0.0:5000
python3 experiments/scripts/mock_server.py --port 5050 --no-auth --delay-ms 200
python3 -m unittest experiments/scripts/test_mock_server.py -v
```

- From the Android emulator the Mac is `http://10.0.2.2:5000`.
- Sign in with the dev staff numbers (`+94700000002` = PHM) and code `000000`.
- `POST /mock/reset` empties the data between runs; `GET /mock/stats` shows counts and conflicts.
- It keeps data in memory only, and is not a replacement for the .NET API in the final results.
