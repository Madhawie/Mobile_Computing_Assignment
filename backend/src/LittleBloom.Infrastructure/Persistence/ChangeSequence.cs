using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace LittleBloom.Infrastructure.Persistence;

/// <summary>
/// Gives out change numbers from the SQL Server SEQUENCE. Every write to a synced record
/// takes one, and GET /sync/pull returns rows with a number above the phone's cursor.
/// </summary>
public static class ChangeSequence
{
    /// <summary>Next number, taken inside the current transaction (if there is one).</summary>
    public static async Task<long> NextChangeSeqAsync(this AppDbContext db, CancellationToken ct = default)
    {
        var connection = db.Database.GetDbConnection();
        await using var command = connection.CreateCommand();
        command.CommandText = $"SELECT NEXT VALUE FOR dbo.{AppDbContext.ChangeSequence}";
        command.Transaction = db.Database.CurrentTransaction?.GetDbTransaction();
        if (connection.State != ConnectionState.Open) await connection.OpenAsync(ct);
        return Convert.ToInt64(await command.ExecuteScalarAsync(ct));
    }

    /// <summary>
    /// Reserves <paramref name="count"/> numbers in one call (sp_sequence_get_range) and returns the
    /// first; the caller uses first, first + 1, ... Much faster than one call per row when seeding
    /// thousands of records, and the numbers are still unique and in order.
    /// </summary>
    public static async Task<long> ReserveChangeSeqRangeAsync(this AppDbContext db, int count, CancellationToken ct = default)
    {
        if (count < 1) throw new ArgumentOutOfRangeException(nameof(count), "count must be at least 1.");

        var connection = db.Database.GetDbConnection();
        await using var command = connection.CreateCommand();
        command.CommandText =
            "DECLARE @first sql_variant; " +
            $"EXEC sys.sp_sequence_get_range @sequence_name = N'dbo.{AppDbContext.ChangeSequence}', " +
            "@range_size = @count, @range_first_value = @first OUTPUT; " +
            "SELECT CAST(@first AS bigint);";

        var size = command.CreateParameter();
        size.ParameterName = "@count";
        size.Value = (long)count;
        command.Parameters.Add(size);

        command.Transaction = db.Database.CurrentTransaction?.GetDbTransaction();
        if (connection.State != ConnectionState.Open) await connection.OpenAsync(ct);
        return Convert.ToInt64(await command.ExecuteScalarAsync(ct));
    }
}
