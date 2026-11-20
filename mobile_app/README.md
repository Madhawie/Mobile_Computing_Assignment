# Little Bloom – mobile app (Flutter)

Offline-first Android app for mothers, PHMs and the MOH office.
Package name: `little_bloom`. Plan: `docs/architecture/frontend-plan.md`.

## Run

```bash
flutter pub get
flutter run        # with an Android emulator running
flutter test
```

The emulator reaches the backend on the Mac at `10.0.2.2`.

## Folder structure (MVVM + Repository)

```
lib/
  main.dart                 entry point
  app/                      root widget, router, providers
  core/
    constants/              base URL, app-wide values
    network/                API client (counts bytes sent/received)
    storage/                sqflite database helper and schema
    sync/                   sync engine, strategies S1 / S2 / S3, outbox
    theme/                  colours and fonts
  data/
    models/                 Mother, MaternalVisit, Child, GrowthMeasurement, ...
    repositories/           read/write SQLite, write outbox on every change
  features/
    common/                 splash, sign-in, settings, help, notifications
    parent/                 mother screens (home, growth, vaccines, advice, ...)
    phm/                    midwife screens (register, growth record, sync, ...)
    moh/                    MOH office screens (dashboard, reports, staff, ...)
  shared/widgets/           reusable widgets
  l10n/                     English, Sinhala, Tamil strings
test/unit/                  unit tests (models, outbox, sync)
```

Flow: Screen (View) → ViewModel (Provider) → Repository → SQLite ↔ Sync service ↔ REST API.
