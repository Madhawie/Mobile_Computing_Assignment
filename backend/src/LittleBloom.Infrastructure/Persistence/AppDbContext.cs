using LittleBloom.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LittleBloom.Infrastructure.Persistence;

/// <summary>
/// EF Core view of the SQL Server database. Each DbSet is one table.
/// Tables are created from this class by migrations (see backend/README.md).
/// </summary>
public class AppDbContext : DbContext
{
    /// <summary>Name of the SQL Server SEQUENCE that gives every write its change number.</summary>
    public const string ChangeSequence = "ChangeSeq";

    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    // Health records (synced with the phones)
    public DbSet<Mother> Mothers => Set<Mother>();
    public DbSet<MaternalVisit> MaternalVisits => Set<MaternalVisit>();
    public DbSet<Child> Children => Set<Child>();
    public DbSet<GrowthMeasurement> GrowthMeasurements => Set<GrowthMeasurement>();
    public DbSet<Vaccination> Vaccinations => Set<Vaccination>();

    // Sync bookkeeping (server only)
    public DbSet<ProcessedOperation> ProcessedOperations => Set<ProcessedOperation>();
    public DbSet<RecordHistory> RecordHistory => Set<RecordHistory>();
    public DbSet<Conflict> Conflicts => Set<Conflict>();

    // Sign-in
    public DbSet<User> Users => Set<User>();
    public DbSet<OtpRequest> OtpRequests => Set<OtpRequest>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        // One counter for all writes. A number, not a timestamp, so the pull cursor never skips
        // two writes made in the same millisecond and does not depend on phone clocks (api.md section 5).
        b.HasSequence<long>(ChangeSequence).StartsAt(1).IncrementsBy(1);

        ConfigureSyncEntity<Mother>(b);
        ConfigureSyncEntity<MaternalVisit>(b);
        ConfigureSyncEntity<Child>(b);
        ConfigureSyncEntity<GrowthMeasurement>(b);
        ConfigureSyncEntity<Vaccination>(b);

        b.Entity<Mother>(e =>
        {
            e.Property(x => x.FullName).HasMaxLength(200);
            e.Property(x => x.Phone).HasMaxLength(20);
            e.Property(x => x.Address).HasMaxLength(500);
            e.Property(x => x.AreaId).HasMaxLength(50);
            e.HasIndex(x => x.Phone);
        });

        b.Entity<MaternalVisit>(e =>
        {
            e.Property(x => x.Notes).HasMaxLength(2000);
            e.HasIndex(x => x.MotherId);
        });

        b.Entity<Child>(e =>
        {
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.Sex).HasMaxLength(10);
            e.Property(x => x.BornAt).HasMaxLength(200);
            e.Property(x => x.ChdrNumber).HasMaxLength(50);
            e.HasIndex(x => x.MotherId);
        });

        b.Entity<GrowthMeasurement>(e =>
        {
            e.Property(x => x.Notes).HasMaxLength(2000);
            e.HasIndex(x => x.ChildId);
        });

        b.Entity<Vaccination>(e =>
        {
            e.Property(x => x.Vaccine).HasMaxLength(50);
            e.Property(x => x.BatchNo).HasMaxLength(50);
            e.HasIndex(x => x.ChildId);
        });

        b.Entity<ProcessedOperation>(e =>
        {
            e.HasKey(x => x.OperationId);
            e.Property(x => x.OperationId).ValueGeneratedNever();
            e.Property(x => x.Entity).HasMaxLength(50);
            e.Property(x => x.DeviceId).HasMaxLength(100);
            e.Property(x => x.Status).HasMaxLength(30);
        });

        b.Entity<RecordHistory>(e =>
        {
            e.ToTable("RecordHistory");
            e.Property(x => x.Entity).HasMaxLength(50);
            e.Property(x => x.ChangedFields).HasMaxLength(1000);
            e.Property(x => x.DeviceId).HasMaxLength(100);
            e.Property(x => x.Strategy).HasMaxLength(5);
            e.HasIndex(x => new { x.Entity, x.RecordId, x.Version });
        });

        b.Entity<Conflict>(e =>
        {
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Entity).HasMaxLength(50);
            e.Property(x => x.ScopeAreaId).HasMaxLength(50);
            e.Property(x => x.Kind).HasMaxLength(30);
            e.Property(x => x.Resolution).HasMaxLength(20);
            e.Property(x => x.Status).HasConversion<string>().HasMaxLength(20);
            e.HasIndex(x => new { x.ScopeAreaId, x.Status });
        });

        b.Entity<User>(e =>
        {
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Phone).HasMaxLength(20);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.Role).HasConversion<string>().HasMaxLength(20);
            e.Property(x => x.AreaId).HasMaxLength(50);
            e.Property(x => x.MohId).HasMaxLength(50);
            e.HasIndex(x => x.Phone).IsUnique(); // the phone number is the login
        });

        b.Entity<OtpRequest>(e =>
        {
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Phone).HasMaxLength(20);
            e.Property(x => x.CodeHash).HasMaxLength(100);
            e.HasIndex(x => new { x.Phone, x.CreatedAt });
        });

        b.Entity<RefreshToken>(e =>
        {
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.TokenHash).HasMaxLength(100);
            e.Property(x => x.DeviceId).HasMaxLength(100);
            e.HasIndex(x => x.TokenHash).IsUnique();
            e.HasIndex(x => x.UserId);
        });
    }

    /// <summary>Settings shared by the five synced tables.</summary>
    private static void ConfigureSyncEntity<T>(ModelBuilder b) where T : SyncEntity
    {
        b.Entity<T>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever(); // the phone makes the UUID, never the database

            // UPDATE ... WHERE Version = <version we read>. If another device saved in between,
            // nothing matches, EF throws, and PushService retries the change with the newest version.
            e.Property(x => x.Version).IsConcurrencyToken();
            e.Property(x => x.DeviceId).HasMaxLength(100);
            e.Property(x => x.ScopeAreaId).HasMaxLength(50);

            // Pull = "rows in my area with ChangeSeq > cursor, in ChangeSeq order", so index exactly that.
            e.HasIndex(x => new { x.ScopeAreaId, x.ChangeSeq });
            e.HasIndex(x => x.ChangeSeq);
        });
    }
}
