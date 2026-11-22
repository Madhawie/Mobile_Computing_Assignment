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
`Server=localhost;Database=LittleBloom;Trusted_Connection=True;TrustServerCertificate=True`.
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

## Rules
- No passwords, keys or connection strings in git. Put local values in `appsettings.Development.local.json`
  (ignored by git) or in `dotnet user-secrets`.
- Synthetic data only. Never real mothers, children or phone numbers.
