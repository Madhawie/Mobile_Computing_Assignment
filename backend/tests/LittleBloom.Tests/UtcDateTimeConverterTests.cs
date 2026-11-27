using System.Text.Json;
using LittleBloom.Infrastructure.Persistence;

namespace LittleBloom.Tests;

public class UtcDateTimeConverterTests
{
    private readonly UtcDateTimeConverter _converter = new();

    [Fact]
    public void Value_read_from_the_database_is_marked_utc_and_serialised_with_z()
    {
        var fromDb = new DateTime(2026, 11, 20, 8, 15, 30, DateTimeKind.Unspecified);

        var read = (DateTime)_converter.ConvertFromProvider(fromDb)!;

        Assert.Equal(DateTimeKind.Utc, read.Kind);
        Assert.Equal(fromDb.Ticks, read.Ticks);                       // same clock time, only the kind changes
        Assert.EndsWith("Z\"", JsonSerializer.Serialize(read));      // "2026-11-20T08:15:30Z"
    }

    [Fact]
    public void Utc_and_unspecified_values_are_stored_unchanged()
    {
        var utc = new DateTime(2026, 11, 20, 8, 15, 30, DateTimeKind.Utc);
        var unspecified = new DateTime(2026, 11, 20, 8, 15, 30, DateTimeKind.Unspecified);

        Assert.Equal(utc.Ticks, ((DateTime)_converter.ConvertToProvider(utc)!).Ticks);
        Assert.Equal(unspecified.Ticks, ((DateTime)_converter.ConvertToProvider(unspecified)!).Ticks); // not shifted by +5:30
    }

    [Fact]
    public void Local_value_is_converted_to_utc_before_storing()
    {
        var local = new DateTime(2026, 11, 20, 13, 45, 30, DateTimeKind.Local);

        var stored = (DateTime)_converter.ConvertToProvider(local)!;

        Assert.Equal(local.ToUniversalTime().Ticks, stored.Ticks);
    }
}
