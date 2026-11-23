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
}
