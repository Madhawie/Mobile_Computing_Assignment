# Connecting the app to the .NET API

How to run the phone app against the real backend instead of the Python mock.
The API runs on the partner's Windows PC (SQL Server lives there). The emulator and the
real Android phone run on Madhawie's Mac. All of them must be on the **same Wi-Fi**.

## 1. Windows PC: open the API to the Wi-Fi

By default the API listens on `localhost` only, so other devices cannot reach it.

```powershell
# PowerShell as Administrator, once: allow port 5000 through Windows Firewall
New-NetFirewallRule -DisplayName "Little Bloom API" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow

# Each time: listen on every network card, Development settings (dev code 000000, dev staff)
cd backend
dotnet run --project src/LittleBloom.Api --launch-profile http --urls http://0.0.0.0:5000

# The PC's Wi-Fi address (IPv4 Address of the Wi-Fi adapter), e.g. 192.168.1.20
ipconfig
```

## 2. Mac: check the API speaks the app's contract

```bash
python3 experiments/scripts/api_check.py --base http://192.168.1.20:5000
```

The script signs in the dev PHM (`+94700000002`, code `000000`) on two devices and runs
22 checks. Together they cover push, duplicate retry, pull and paging, S3 flagged and merged
conflicts, conflict review, S2 lost update, tombstones, rejections, batch limit and refresh
token rotation.
Everything should be PASS. It creates synthetic test mothers in area `glg-east`.

## 3. Run the app against it

```bash
cd mobile_app
# Emulator or real phone on the same Wi-Fi: use the PC's address, not 10.0.2.2
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000
```

`10.0.2.2` only reaches the Mac the emulator runs on. Use it only when the API itself runs on the Mac.

Sign in as staff with `+94700000002` and code `000000`, then set a PIN.

## 4. Two-device test (PHM in the field + clinic)

1. Sign in on the emulator **and** on the real phone with `+94700000002`.
   Each phone has its own `deviceId` and its own refresh token.
2. On one phone, add a mother, then press **Send now** on the Sync tab.
   On the other phone, press **Send now** too: the mother appears there (pull).
3. Turn on airplane mode on phone A. On both phones, change the same field of that mother.
4. On phone B, send. Turn phone A back online: it sends by itself after about 3 s.
   With S3, phone A shows the conflict on **Check a record** with both values.
5. Check the server's `record_history` table: the older value is still there.

## Known differences found on Day 15

| Topic | What the .NET API does | What the app does |
|---|---|---|
| Times | SQL Server `datetime2` keeps no zone, so EF Core reads it back as `Unspecified` and JSON shows `2026-11-20T08:15:30.1234567` with no `Z`. | Reads a time with no zone as **UTC** (`parseTimestamp`). Without this, S1 would move `updatedAt` 5 h 30 min back on every sync in Sri Lanka. |
| Access token | 12 h; then 401 `TOKEN_EXPIRED`. | Calls `/api/auth/refresh` once and sends the same request again. |
| Refresh token | Works once (rotation), 30 days. | Only one refresh at a time on the phone. The new pair is saved at once. A 401 on refresh means sign in by SMS again; records and outbox stay. |
| Nulls | Left out of the JSON (`WhenWritingNull`). | Missing optional fields read as `null`. |

Suggested backend change (backend owner decides): store and read every `DateTime` as UTC,
so the API sends the `Z` itself, e.g. in `AppDbContext.ConfigureConventions`:

```csharp
configurationBuilder.Properties<DateTime>().HaveConversion<UtcDateTimeConverter>();
// UtcDateTimeConverter : ValueConverter<DateTime, DateTime>(
//     v => v.ToUniversalTime(), v => DateTime.SpecifyKind(v, DateTimeKind.Utc))
```

One edge case remains open. A refresh can succeed on the server while its answer is lost (the signal drops).
The old refresh token is then spent, so the phone must sign in by SMS again. A short grace
period for the previous refresh token on the server would avoid this.
