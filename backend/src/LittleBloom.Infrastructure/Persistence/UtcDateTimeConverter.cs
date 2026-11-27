using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace LittleBloom.Infrastructure.Persistence;

/// <summary>
/// Every time the server stores is UTC (api.md section 2), but SQL Server datetime2 keeps no time zone,
/// so EF Core reads values back as "Unspecified" and the JSON would show "2026-11-20T08:15:30" without "Z".
/// The phone would then read it as Sri Lanka time, 5 h 30 min off.
/// This converter marks every value read from the database as UTC, so the API writes the "Z".
///
/// Writing: a Local time is converted to UTC. An Unspecified time is NOT shifted
/// (ToUniversalTime would treat it as the PC's local time and move it by +5:30 here).
/// </summary>
public sealed class UtcDateTimeConverter : ValueConverter<DateTime, DateTime>
{
    public UtcDateTimeConverter()
        : base(
            v => v.Kind == DateTimeKind.Local ? v.ToUniversalTime() : v,  // to the database
            v => DateTime.SpecifyKind(v, DateTimeKind.Utc))               // from the database
    {
    }
}
