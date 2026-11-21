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
