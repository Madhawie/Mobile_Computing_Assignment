# Frontend development plan (20 days)

Owner: Madhawie (Flutter, `mobile_app/`).
Each day is one goal with tasks that fit in a day, plus the commits to make
(2–4 small commits a day so the Git history shows steady work).

Choices: **Provider** (MVVM ViewModels), **sqflite**, **go_router**, **http**, **connectivity_plus**.
Sync and experiments come before the mother and MOH screens, because that is where most marks are.

## Week 1 – Foundation

| Day | Goal | Tasks | Commits |
|---|---|---|---|
| 1 | Setup | Install Flutter + Android Studio + emulator (Pixel, Android 14). In `mobile_app/` run `flutter create --project-name little_bloom .`. Add packages. Create the folders (`core/`, `data/`, `features/` …). | `chore(mobile): create flutter project` · `chore(mobile): add core packages` · `chore(mobile): set up folder structure` |
| 2 | API contract (with partner) | Write `docs/architecture/api.md`: login, `POST /api/sync/push`, `GET /api/sync/pull?since=`, JSON shape, `version`, `operation_id`, error codes. Agree it together. | `docs: add sync API contract` · `docs: add auth and error responses` |
| 3 | Data models | Dart models: Mother, MaternalVisit, Child, GrowthMeasurement, Vaccination, OutboxEntry, SyncLog with `toJson`/`fromJson`/`toMap`. Unit tests. | `feat(mobile): add record models` · `test(mobile): model serialization tests` |
| 4 | Theme + shared widgets | Colours (PHM mint, mother lavender, MOH butter, boy blue, girl pink), Nunito / Noto fonts, buttons, cards, inputs, bottom nav. l10n set-up (en / si / ta ARB). | `feat(mobile): add app theme and fonts` · `feat(mobile): add shared widgets` · `feat(mobile): set up localization` |
| 5 | Local database | sqflite schema: mothers, maternal_visits, children, growth, vaccinations, outbox, sync_log, meta (last_sync). DB helper + migrations. Tests on an in-memory DB. | `feat(mobile): add sqlite schema` · `feat(mobile): add database helper` · `test(mobile): database tests` |

## Week 2 – Offline-first core

| Day | Goal | Tasks | Commits |
|---|---|---|---|
| 6 | Repositories + outbox | Every create / update / soft delete in one transaction: save record, `version++`, `is_dirty=1`, outbox row with UUID `operation_id`. | `feat(mobile): add repositories with outbox` · `feat(mobile): soft delete with tombstones` · `test(mobile): outbox written on every change` |
| 7 | API client + mock server | `ApiClient` (base URL `10.0.2.2`, timeouts, counts bytes sent / received). Small mock server `experiments/scripts/mock_server.py` that follows the contract, so frontend work is not blocked by the backend. | `feat(mobile): add api client` · `exp: add mock sync server` |
| 8 | Navigation + sign-in | go_router. Language → Who are you? → mother phone + SMS code (mocked) → PHM / MOH PIN. Store token and PIN hash securely. Role decides the home screen. | `feat(mobile): add routing` · `feat(mobile): language and role screens` · `feat(mobile): PIN and OTP sign-in` |
| 9 | PHM screens 1 | Today, area register (mothers / children list + search), mother detail. ViewModels read from repositories. | `feat(mobile): PHM today screen` · `feat(mobile): area register` · `feat(mobile): mother detail` |
| 10 | PHM screens 2 | Add mother, add child (low birth weight flag), record growth (green / orange / red zone), pregnancy visit (BP warning), vaccination. All saved offline. | `feat(mobile): add mother and child forms` · `feat(mobile): record growth with zones` · `feat(mobile): antenatal visit form` |

## Week 3 – Sync engine (core of the project)

| Day | Goal | Tasks | Commits |
|---|---|---|---|
| 11 | S3 push | Send outbox in batches with versions; remove confirmed entries, keep unconfirmed; retry with backoff. | `feat(mobile): S3 versioned push` · `feat(mobile): retry with backoff` · `test(mobile): retries never duplicate` |
| 12 | Pull + conflicts | `pull?since=`, apply server changes, respect tombstones, store conflicts. "Check a record" screen. | `feat(mobile): pull and apply changes` · `feat(mobile): conflict review screen` · `test(mobile): tombstones not resurrected` |
| 13 | S1 + S2 + logging | S1 full and S2 delta behind one `SyncStrategy` interface. Every sync writes `sync_log`: strategy, record count, changed count, bytes, ms, network, result, conflicts, duplicates. | `feat(mobile): add S1 and S2 strategies` · `feat(mobile): sync logging` · `test(mobile): strategy selection` |
| 14 | Connectivity | connectivity_plus: auto-sync when the connection returns. Sync screen (pending count, Send now, auto-send switch). | `feat(mobile): auto sync on reconnect` · `feat(mobile): sync screen` |
| 15 | Real backend | Switch from mock to the .NET API, fix contract mismatches, JWT login. Test with 2 emulators (PHM + clinic). | `feat(mobile): connect to .NET API` · `fix(mobile): align with API contract` · `feat(mobile): JWT auth` |

## Week 4 – Remaining screens, experiments, finish

| Day | Goal | Tasks | Commits |
|---|---|---|---|
| 16 | Mother screens | Home, child record + growth chart (fl_chart), vaccine card (dates from date of birth), food advice (JSON asset), my pregnancy + 1990 call. | `feat(mobile): mother home` · `feat(mobile): growth chart` · `feat(mobile): vaccine card and food advice` |
| 17 | MOH screens | Overview, mothers list, add mother / child (reuse forms), monthly report. Staff tab only for admins. | `feat(mobile): MOH overview` · `feat(mobile): MOH mothers and reports` · `feat(mobile): admin staff screen` |
| 18 | Experiment tooling | Hidden tester screen: pick strategy, run N times, export `sync_log` as CSV. Load Faker data (50 / 500 / 5000 records). Toxiproxy profiles (4G / 3G / 2G). | `exp: tester settings screen` · `exp: csv export of sync log` · `exp: seed data loader` |
| 19 | Run experiments + profiling | Run E1–E3 five times each, save CSVs to `experiments/data/`, capture Android Profiler CPU / memory. Fix bugs found. | `exp: E1 data volume results` · `exp: E2 and E3 results` · `fix(mobile): …` |
| 20 | Polish + demo | Widget tests, Sinhala / Tamil strings, demo data, `mobile_app/README.md`, record demo clips, build APK. | `test(mobile): widget tests` · `feat(mobile): sinhala and tamil text` · `docs: mobile app readme` |

## Daily rules

- One branch per feature (e.g. `feature/mobile-outbox`); pull request every 1–2 days, reviewed and merged by the partner.
- At least two small commits a day with the prefixes above.
- Never commit the `.db` file, tokens or real phone numbers.

## Dependencies on the backend

| By day | Needed from backend |
|---|---|
| 2 | `api.md` agreed |
| 15 | Working `/api/sync/push`, `/api/sync/pull` and login on the .NET API |
| 19 | Server running with Toxiproxy in front for the experiments |

If the backend is late, the Day 7 mock server keeps frontend work moving.

**Optional AI feature** (children to watch): only after Day 20, or instead of Day 17 if time is short.
