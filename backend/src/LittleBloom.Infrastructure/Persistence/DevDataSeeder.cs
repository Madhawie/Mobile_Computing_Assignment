using LittleBloom.Domain.Entities;
using LittleBloom.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace LittleBloom.Infrastructure.Persistence;

/// <summary>
/// Development only: adds made-up staff so you can sign in straight away.
/// Synthetic data only. No SMS is sent; the code appears in the console, or use 000000.
/// </summary>
public static class DevDataSeeder
{
    public const string MohId = "glg";

    public static async Task SeedAsync(AppDbContext db, ILogger logger, CancellationToken ct = default)
    {
        if (!await db.Database.CanConnectAsync(ct))
        {
            logger.LogWarning("Database not reachable; dev users not seeded. Check the connection string and run 'dotnet ef database update'.");
            return;
        }

        if (await db.Users.AnyAsync(ct)) return; // already seeded

        var now = DateTime.UtcNow;
        db.Users.AddRange(
            Staff("+94700000001", "Dev Admin", UserRole.Admin, null, now),
            Staff("+94700000002", "Dev PHM East", UserRole.Phm, "glg-east", now),
            Staff("+94700000003", "Dev PHM West", UserRole.Phm, "glg-west", now),
            Staff("+94700000004", "Dev Supervisor", UserRole.Supervisor, null, now));

        await db.SaveChangesAsync(ct);
        logger.LogInformation("Seeded 4 dev staff accounts (+94700000001 to +94700000004).");
    }

    private static User Staff(string phone, string name, UserRole role, string? areaId, DateTime now) => new()
    {
        Id = Guid.NewGuid(),
        Phone = phone,
        Name = name,
        Role = role,
        AreaId = areaId,
        MohId = MohId,
        IsActive = true,
        CreatedAt = now,
    };
}
