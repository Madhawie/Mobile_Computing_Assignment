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

## Open decisions
- State management package (Riverpod or Provider)
- Local database package (sqflite or drift)
- SMS gateway provider
- Hosting for the API and SQL Server
