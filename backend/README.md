# Little Bloom – Backend API

ASP.NET Core (.NET 10) API that the Flutter app syncs with.
The contract between app and server is [`docs/architecture/api.md`](../docs/architecture/api.md).

## Projects (Clean Architecture)

| Project | Holds | References |
|---|---|---|
| `LittleBloom.Domain` | Entities and enums | nothing |
| `LittleBloom.Application` | Sync and auth use cases, S1/S2/S3 rules, DTOs, interfaces | Domain |
| `LittleBloom.Infrastructure` | SQL Server (EF Core), SMS/OTP sender, export | Application |
| `LittleBloom.Api` | Web host, endpoints, auth middleware | Application, Infrastructure |
| `tests/LittleBloom.Tests` | xUnit unit and integration tests | Api |

Dependencies point inwards: the Domain knows nothing about the database or HTTP,
so the conflict rules can be unit-tested without either.

## Requirements
- .NET 10 SDK
- SQL Server 2025 (Developer or Express) and SSMS to view the data (from the database step onwards)

## Database (SQL Server)

The connection string is in `src/LittleBloom.Api/appsettings.json`:
`Server=localhost\SQLEXPRESS02;Database=LittleBloom;Trusted_Connection=True;TrustServerCertificate=True`
(SQL Server Express, instance `SQLEXPRESS02`).
It uses Windows Authentication, so it contains no password. If SSMS connects with another
server name (for example `localhost\SQLEXPRESS`), change `Server=` to match.

Tables are created from `AppDbContext` with EF Core migrations:
```bash
dotnet tool install --global dotnet-ef        # once per PC
cd backend
dotnet ef migrations add InitialCreate -p src/LittleBloom.Infrastructure -s src/LittleBloom.Api -o Persistence/Migrations
dotnet ef database update -p src/LittleBloom.Infrastructure -s src/LittleBloom.Api
```
Run `migrations add <Name>` again after every change to an entity, and commit the generated files.
Open SSMS → `LittleBloom` → Tables to see the result.

| Table | Purpose |
|---|---|
| `Mothers`, `MaternalVisits`, `Children`, `GrowthMeasurements`, `Vaccinations` | Health records synced with the phones |
| `ProcessedOperations` | Every `operationId` already handled, so a retried change is not saved twice |
| `RecordHistory` | A copy of the record after every change, so no old value is ever lost |
| `Conflicts` | S3 conflicts waiting for a person to check |
| sequence `ChangeSeq` | Change number given to every write; the pull cursor |

## Sign-in (development)

Nobody signs up. In Development the server adds four made-up staff accounts on start
(`appsettings.Development.json` → `Seed:DevUsers`):

| Phone | Role | Area |
|---|---|---|
| `+94700000001` | admin | MOH `glg` |
| `+94700000002` | phm | `glg-east` |
| `+94700000003` | phm | `glg-west` |
| `+94700000004` | supervisor | MOH `glg` |

1. `POST /api/auth/otp/request` with `{ "phone": "+94700000002" }` → `otpRequestId`.
   No SMS is sent: the code is printed in the server console.
2. `POST /api/auth/otp/verify` with `{ "otpRequestId": "...", "code": "000000", "deviceId": "postman" }`
   (`000000` works in Development only) → `accessToken`.
3. Send `Authorization: Bearer <accessToken>` on every other request.

JWT signing key: without one the server makes a random key at start (tokens die on restart).
Set a fixed one outside git, once per PC:
```bash
cd backend/src/LittleBloom.Api
dotnet user-secrets set "Jwt:SigningKey" "<any random text of 32+ characters>"
```

## Endpoints so far

| Method | Path | Who |
|---|---|---|
| GET | `/api/health` | anyone |
| POST | `/api/auth/otp/request`, `/api/auth/otp/verify`, `/api/auth/refresh` | anyone |
| POST | `/api/sync/push` | PHM, supervisor, admin (mother → 403) |
| GET | `/api/sync/pull?since=0&limit=500` | every signed-in user, own scope only |
| GET | `/api/conflicts?status=open` | staff |
| POST | `/api/conflicts/{id}/resolve` | staff |
| GET, POST | `/api/staff`, `/api/staff/{id}/revoke` | admin |
| POST, GET | `/api/experiments/reset`, `/seed`, `/stats`, `/sync-log.csv` | admin, Development only |

`src/LittleBloom.Api/LittleBloom.Api.http` has a ready request for each of these: open it in
Visual Studio and click **Send request** (sign-in first; the token is reused automatically).

## Run
```bash
cd backend
dotnet build
dotnet run --project src/LittleBloom.Api --launch-profile http
```
Check it: open http://localhost:5000/api/health, expected `{"status":"ok","serverTime":"…Z"}`.

The Android emulator reaches this server at `http://10.0.2.2:5000/api`.

## Test
```bash
cd backend
dotnet test
```

## Experiments with the real server

Every response has `X-Server-Time-Ms`; every push and pull is also written to the `SyncLogs` table
(api.md section 8). Scripts in `experiments/scripts/` (Python standard library only) drive a run:

```bash
# before each run: empty the server (and clear the app's data on the emulator)
python3 experiments/scripts/server_admin.py reset

# E1 data volume: put 50 / 500 / 5000 synthetic mothers on the server, then let the app sync
python3 experiments/scripts/server_admin.py seed --mothers 500 --area glg-east

# E5 concurrent edits: while the PHM emulator edits the same records offline,
# the "clinic" edits them on the server; then the emulator syncs
python3 experiments/scripts/clinic_simulator.py --count 50 --strategy S3 \
    --entity growthMeasurement --field weightKg --csv experiments/data/e5_clinic.csv

# after the run: server-side numbers
python3 experiments/scripts/server_admin.py stats
python3 experiments/scripts/server_admin.py csv --out experiments/data/e1_server_log.csv
```

Python tests for the scripts: `python3 -m unittest experiments/scripts/test_clinic_simulator.py -v`.

## Rules
- No passwords, keys or connection strings in git. Put local values in `appsettings.Development.local.json`
  (ignored by git) or in `dotnet user-secrets`.
- Synthetic data only. Never real mothers, children or phone numbers.
