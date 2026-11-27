# Architecture (draft)

To be finalised. Current direction:

## Mobile – MVVM + Repository, offline-first
```
Screen (View)  ->  ViewModel (state)  ->  Repository  ->  Local DB (SQLite)  <-> Sync service <-> REST API
```
- Every PHM entry is saved to the phone's local database first, then queued for sync.
- The sync service uploads the queue when a connection is available and pulls area updates.
- One Flutter app; the signed-in role (parent, PHM, MOH) decides which screens are shown.

## Backend – Clean Architecture (ASP.NET Core)
```
Api (controllers)  ->  Application (services, DTOs)  ->  Domain (entities)
                                   ^
                    Infrastructure (SQL Server via EF Core, SMS gateway, eRHMIS/DHIS2 export)
```

What lives where (backend):

| Layer | Main parts |
|---|---|
| Domain | 5 health records on a shared `SyncEntity` base (id, version, updatedAt, deviceId, deleted); `ProcessedOperation`, `RecordHistory`, `Conflict`, `SyncLog`; users and tokens |
| Application | `ConflictResolver` (S3 rules, pure logic), `RecordValidator`, `PullPager`, `ConflictReverter`, `SyntheticDataGenerator`, DTOs and service interfaces |
| Infrastructure | `PushService`, `PullService`, `ConflictService`, `StaffService`, `AuthService`, `ExperimentService`, `AppDbContext` + `ChangeSeq` sequence |
| Api | Controllers, JWT sign-in, ProblemDetails errors, `MeasurementMiddleware` + background `SyncLogWriter` |

One push, step by step (S3):
```
phone outbox ──POST /sync/push──▶ PushService, for each change in order:
   operationId already in ProcessedOperations?  yes → "duplicate" (retry after a dropped connection)
   valid values, parent exists, user's area?    no  → "rejected" (only this change)
   baseVersion == server version?               yes → apply ("applied")
                                                no  → ConflictResolver: merge different fields,
                                                      flag same field (newest kept, other in Conflicts)
   record + RecordHistory + ProcessedOperation saved in ONE transaction, new ChangeSeq number
phone ◀──GET /sync/pull?since=cursor── rows with ChangeSeq > cursor in the user's scope
```
Why it is safe on a bad network: a change is either fully saved (and its operationId remembered) or not at
all, so a retry can never duplicate or lose it. Why no edit is lost under S3: the version check catches
every concurrent edit, and a losing value is kept in `Conflicts` and `RecordHistory` until a person decides.

## Open decisions
- State management package (Riverpod or Provider)
- Local database package (sqflite or drift)
- SMS gateway provider
- Hosting for the API and SQL Server
