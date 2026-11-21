# Sync API contract (draft v0.1)

**Status:** draft by Madhawie (frontend). To be agreed with the backend owner.
Once agreed, this file is the single source of truth between `mobile_app/` and `backend/`.
Any change goes through a pull request that both of us approve.

## 1. Conventions

| Item | Rule |
|---|---|
| Base URL | `http://<host>:<port>/api`. The Android emulator reaches the Mac at `10.0.2.2`. Port to be agreed (placeholder `5000`). |
| Format | JSON, UTF-8. Property names in **camelCase** (ASP.NET Core default). Local SQLite columns stay snake_case; the app maps between them. |
| Ids | UUID v4, **generated on the device** when the record is created, so a record has the same id offline and on the server. |
| Time | ISO-8601 in UTC, e.g. `2026-11-20T08:15:30Z`. Dates without time (`dateOfBirth`, `measuredOn`) are `YYYY-MM-DD`. |
| Auth | `Authorization: Bearer <JWT>` on every request except `/api/auth/*` (section 9). |
| Versioning | Breaking changes add `/api/v2`; this draft is v1. |

## 2. Common record fields

Every synced record has these fields as well as its own:

| Field | Type | Who sets it | Meaning |
|---|---|---|---|
| `id` | uuid | device | Primary key. Never changes. |
| `version` | int | device +1 on each local edit, server on apply | Used by S3 to detect conflicts. Starts at 1. |
| `updatedAt` | datetime | device | Time of the last edit (device clock). Used only to pick the newest value in a same-field conflict. |
| `deviceId` | string | device | Which phone made the last edit. |
| `deleted` | bool | device | Soft delete (tombstone). Deleted records still sync, so a pull never brings them back. |

`is_dirty` exists **only on the phone** and is never sent.

## 3. Entities (the `entity` value and its `data` fields)

| `entity` | Fields (as well as section 2) |
|---|---|
| `mother` | `fullName`, `phone`, `age`, `address`, `areaId`, `isPregnant`, `gestationWeeks?`, `dueDate?` |
| `maternalVisit` | `motherId`, `visitDate`, `gestationWeeks`, `weightKg`, `bpSystolic`, `bpDiastolic`, `notes?`, `nextVisit?` |
| `child` | `motherId`, `name`, `sex` (`boy`/`girl`), `dateOfBirth`, `birthWeightKg`, `bornAt?`, `chdrNumber?` |
| `growthMeasurement` | `childId`, `measuredOn`, `weightKg`, `heightCm?`, `notes?` |
| `vaccination` | `childId`, `vaccine`, `dose`, `givenOn`, `batchNo?` |

`?` = optional (may be `null`). Blood pressure is two numbers rather than a `"120/80"` string, so the server can check it.

## 4. Push – `POST /api/sync/push`

The phone sends its outbox in order (oldest first), at most **200 changes per request**.
Parents are sent before children (a mother before her child), because the outbox keeps the order they were created in.

### Request
```json
{
  "deviceId": "emu-phm-01",
  "strategy": "S3",
  "batchId": "6a1c…",
  "changes": [
    {
      "operationId": "0f8e2c1a-…",
      "entity": "growthMeasurement",
      "op": "upsert",
      "recordId": "b51d…",
      "baseVersion": 3,
      "changedFields": ["weightKg", "notes"],
      "data": {
        "id": "b51d…", "version": 4, "updatedAt": "2026-11-20T08:15:30Z",
        "deviceId": "emu-phm-01", "deleted": false,
        "childId": "77aa…", "measuredOn": "2026-11-20", "weightKg": 7.4, "heightCm": null, "notes": "ate well"
      }
    }
  ]
}
```

| Field | Meaning |
|---|---|
| `operationId` | UUID made when the outbox row was written. **The idempotency key**: the same change retried keeps the same id. |
| `op` | `upsert` (create or update) or `delete` (sets `deleted = true`). |
| `baseVersion` | The server version the edit started from (`0` for a new record). Only S3 uses it. |
| `changedFields` | Fields edited since `baseVersion`. Only S3 uses it, for field-level merge. |
| `data` | The full record after the edit. |

### What each strategy sends and how the server applies it

| | S1 Full | S2 Delta | S3 Versioned delta |
|---|---|---|---|
| `changes` holds | **every** local record of the user's scope | only outbox entries | only outbox entries |
| `baseVersion`, `changedFields` | ignored | ignored | checked |
| Server rule | overwrite (last upload wins) | overwrite (last upload wins) | section 6 |

The `strategy` field tells the server which rule to use, so all three can be measured against the same server.

### Response `200 OK`
```json
{
  "results": [
    { "operationId": "0f8e2c1a-…", "status": "applied", "recordId": "b51d…", "newVersion": 4 },
    { "operationId": "91b0…", "status": "conflictMerged", "recordId": "c2e9…", "newVersion": 7,
      "record": { "…merged record…": "" } },
    { "operationId": "a3f4…", "status": "conflictFlagged", "recordId": "d8c1…", "newVersion": 9,
      "conflictId": "5e2d…", "record": { "…": "" } },
    { "operationId": "e7c2…", "status": "rejected", "recordId": "f001…", "error": { "code": "PARENT_NOT_FOUND" } }
  ],
  "serverTime": "2026-11-20T08:15:31Z",
  "cursor": 18452
}
```

| `status` | Meaning | Phone does |
|---|---|---|
| `applied` | Saved. | Delete outbox row, set `version = newVersion`, `is_dirty = 0`. |
| `duplicate` | This `operationId` was already processed (a retry). Same result as the first time. | Same as `applied`. |
| `conflictMerged` | S3: edits touched different fields; merged. | Delete outbox row, replace local record with `record`. |
| `conflictFlagged` | S3: same field edited on both sides; newest kept, older value saved in `record_history`. | Delete outbox row, replace local record, show it on "Check a record". |
| `rejected` | Invalid change (see section 10). | Keep outbox row marked failed; do not retry automatically. |

If the request fails as a whole (timeout, connection dropped, 5xx), the phone keeps **all** rows and sends them again later.
Rows that were applied before the drop come back as `duplicate`, so retries never create copies (experiment E4).

## 5. Pull – `GET /api/sync/pull?since=<cursor>&limit=500`

`since` is a **server change number**, not a time.
Every write on the server takes the next number from one counter (`change_seq`).
The phone stores the `cursor` from the last pull and sends it back.
A number is used instead of a timestamp because phone clocks are often wrong, and two writes in the same millisecond would make a timestamp cursor skip one.

- S1 always calls with `since=0` (download everything).
- S2 and S3 use the stored cursor.
- The server returns only records in the user's scope (section 9).

### Response `200 OK`
```json
{
  "changes": [
    { "entity": "child", "record": { "id": "77aa…", "version": 2, "deleted": false, "…": "" } },
    { "entity": "mother", "record": { "id": "12cd…", "version": 5, "deleted": true, "…": "" } }
  ],
  "cursor": 18460,
  "hasMore": false
}
```

The phone repeats the call with the new `cursor` until `hasMore` is `false`.

Applying a pulled record on the phone:
- If the local copy is **not dirty**, replace it (including tombstones: `deleted = true` stays deleted).
- If the local copy **is dirty**, keep the local edit; it will be pushed and the server resolves it.

**Order of a sync:** push first, then pull. This way the pull already contains the server's merge results.

## 6. Conflict rules for S3 (server side)

Let `serverVersion` be the current version on the server.

1. `baseVersion == serverVersion`: no conflict. Apply, `version = serverVersion + 1`, `applied`.
2. `baseVersion < serverVersion`: someone else changed it. Compare the phone's `changedFields` with the fields changed on the server since `baseVersion` (from `record_history`):
   - **No shared field:** merge both, `version + 1`, `conflictMerged`.
   - **Shared field:** for each shared field keep the value with the newer `updatedAt`. Save the losing value in `record_history` (never lost). Create a `conflict` row. Return `conflictFlagged`.
3. **Delete vs update:** the update wins, the record stays (`deleted = false`), returned as `conflictFlagged` so a person checks it.
4. `baseVersion == 0` and the id already exists: treated as rule 2 (two devices cannot make the same UUID by chance, so this only happens on a retry of a create, which idempotency already covers).

S1 and S2 skip these rules and always overwrite. That is what experiment E5 measures: S1/S2 lose updates, S3 loses none.

## 7. Conflict review

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/conflicts?status=open` | Flagged conflicts in the user's scope, with both values. |
| `POST` | `/api/conflicts/{id}/resolve` | Body `{ "keep": "current" \| "previous" }`. `previous` writes the older value back as a new version. |

## 8. Measurement headers (for the experiments)

| Header | Direction | Meaning |
|---|---|---|
| `X-Network-Profile` | request | `4G`, `3G`, `2G`, `none`, so server logs can be matched to the phone's log. |
| `X-Server-Time-Ms` | response | Time the server spent on the request. Lets us split total time into network and server time. |

The phone counts bytes sent and received itself (body + headers) and writes them to `sync_log`.

## 9. Auth and roles

Nobody signs up. Mothers are added by a PHM or the MOH office; staff are added by the MOH office admin.
Every sign-in starts with the phone number and a one-time SMS code (OTP).

### 9.1 Request a code – `POST /api/auth/otp/request`
```json
{ "phone": "+94764823310" }
```
`202 Accepted`:
```json
{ "otpRequestId": "c41e…", "expiresInSeconds": 300 }
```
Unknown number: `404` with code `PHONE_NOT_REGISTERED` (the app shows "Ask your midwife to add it").
In development no SMS is sent: the server logs the code, or accepts `000000`. Never use real phone numbers in tests.

### 9.2 Verify the code – `POST /api/auth/otp/verify`
```json
{ "otpRequestId": "c41e…", "code": "482913", "deviceId": "emu-phm-01" }
```
`200 OK`:
```json
{
  "accessToken": "eyJ…",
  "expiresIn": 43200,
  "refreshToken": "r-9f2…",
  "user": { "id": "u-17…", "role": "phm", "name": "N. Kumari", "areaId": "glg-east", "mohId": "glg", "motherId": null }
}
```

### 9.3 Refresh – `POST /api/auth/refresh`
Body `{ "refreshToken": "r-9f2…", "deviceId": "emu-phm-01" }`, same response as 9.2.
Access token lives 12 h, refresh token 30 days.

### 9.4 Staff PIN (works offline)
- After the first OTP sign-in on a phone, PHM and MOH staff set a 4-digit PIN.
- **The PIN never goes to the server.** The phone stores only a salted hash of it, plus the tokens in secure storage.
- Opening the app later: the PIN unlocks the stored tokens. With no signal the PHM can still work offline; tokens are refreshed at the next sync.
- Forgot PIN: sign in again with OTP. The admin can block a lost phone by revoking its refresh token.

### 9.5 JWT claims and what each role may sync

| Claim | Meaning |
|---|---|
| `sub` | user id |
| `role` | `mother`, `phm`, `supervisor`, `admin` |
| `areaId` | PHM area (PHM only) |
| `mohId` | MOH division (all staff) |
| `motherId` | the mother's record (mother only) |

| Role | Pull returns | Push allowed |
|---|---|---|
| `mother` | her own record, her children and their growth / vaccines / visits | no (read-only, `403`) |
| `phm` | everything in her `areaId` | create / update / delete in her `areaId` |
| `supervisor` | everything in the MOH division | update in the MOH division (clinic edits) |
| `admin` | everything in the MOH division | as supervisor, plus staff accounts (9.6) |

### 9.6 Staff accounts (admin only)

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/staff` | List staff in the MOH division |
| `POST` | `/api/staff` | Body `{ "name", "phone", "role": "phm" \| "supervisor", "areaId" }` |
| `POST` | `/api/staff/{id}/revoke` | Block the account's devices (lost phone) |

Mothers are created through normal sync (`entity: "mother"`), so a PHM can add one offline.
The server creates the mother's login from `phone` when the record arrives.

## 10. Errors

Whole-request errors use ASP.NET Core **ProblemDetails** (RFC 7807) with an extra `code`:
```json
{ "type": "about:blank", "title": "Token expired", "status": 401, "code": "TOKEN_EXPIRED", "traceId": "00-…" }
```

| HTTP | `code` | When | Phone does |
|---|---|---|---|
| 400 | `VALIDATION_FAILED` | Bad JSON or missing field in the request itself | Log, do not retry |
| 401 | `TOKEN_EXPIRED` | Access token too old | Call `/api/auth/refresh`, then retry once |
| 401 | `UNAUTHORIZED` | No or bad token, refresh failed | Ask the user to sign in with OTP |
| 403 | `FORBIDDEN` | Role may not do this (e.g. mother pushes) | Log, do not retry |
| 404 | `PHONE_NOT_REGISTERED` | OTP for an unknown number | Show "Ask your midwife" |
| 413 | `BATCH_TOO_LARGE` | More than 200 changes in one push | Split the batch and resend |
| 429 | `TOO_MANY_REQUESTS` | Too many OTP requests | Wait `Retry-After` seconds |
| 500 | `SERVER_ERROR` | Bug on the server | Retry with backoff |
| 503 | `SERVER_BUSY` | Server or DB unavailable | Retry with backoff |

**Per-change errors** inside a `200` push response (`status: "rejected"`), so one bad record does not block the rest:

| `code` | When |
|---|---|
| `UNKNOWN_ENTITY` | `entity` is not one of section 3 |
| `INVALID_FIELD` | A value fails a check (e.g. weight ≤ 0); `error.field` names it |
| `PARENT_NOT_FOUND` | A child or visit points to a mother or child the server does not have |
| `OUT_OF_AREA` | The record is outside the user's `areaId` / `mohId` |

**Retry rule (phone):** network error, timeout, 5xx → retry the same batch with exponential backoff (1 s, 2 s, 4 s … max 60 s), same `operationId`s.
4xx → never retry automatically. Each attempt is written to `sync_log` (`retries`, result, error code).

## 11. Open questions for the backend

1. Port number and whether HTTPS is on by default (E6 compares both).
2. Is 200 changes per push and 500 per pull a good limit for SQL Server?
3. Does `record_history` store the whole old row, or one row per changed field?
4. For S1, should the server also delete server records the phone did not send? (Proposed: no, never delete without a tombstone.)
