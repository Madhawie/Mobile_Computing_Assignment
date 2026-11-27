using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LittleBloom.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateSequence(
                name: "ChangeSeq");

            migrationBuilder.CreateTable(
                name: "Children",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MotherId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Sex = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    DateOfBirth = table.Column<DateOnly>(type: "date", nullable: false),
                    BirthWeightKg = table.Column<double>(type: "float", nullable: false),
                    BornAt = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    ChdrNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    Version = table.Column<int>(type: "int", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Deleted = table.Column<bool>(type: "bit", nullable: false),
                    ChangeSeq = table.Column<long>(type: "bigint", nullable: false),
                    ScopeAreaId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Children", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Conflicts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Entity = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RecordId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ScopeAreaId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Kind = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    FieldsJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ResolvedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ResolvedBy = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Resolution = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Conflicts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "GrowthMeasurements",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChildId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MeasuredOn = table.Column<DateOnly>(type: "date", nullable: false),
                    WeightKg = table.Column<double>(type: "float", nullable: false),
                    HeightCm = table.Column<double>(type: "float", nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    Version = table.Column<int>(type: "int", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Deleted = table.Column<bool>(type: "bit", nullable: false),
                    ChangeSeq = table.Column<long>(type: "bigint", nullable: false),
                    ScopeAreaId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GrowthMeasurements", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "MaternalVisits",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MotherId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    VisitDate = table.Column<DateOnly>(type: "date", nullable: false),
                    GestationWeeks = table.Column<int>(type: "int", nullable: false),
                    WeightKg = table.Column<double>(type: "float", nullable: false),
                    BpSystolic = table.Column<int>(type: "int", nullable: false),
                    BpDiastolic = table.Column<int>(type: "int", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    NextVisit = table.Column<DateOnly>(type: "date", nullable: true),
                    Version = table.Column<int>(type: "int", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Deleted = table.Column<bool>(type: "bit", nullable: false),
                    ChangeSeq = table.Column<long>(type: "bigint", nullable: false),
                    ScopeAreaId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MaternalVisits", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Mothers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Age = table.Column<int>(type: "int", nullable: false),
                    Address = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    AreaId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    IsPregnant = table.Column<bool>(type: "bit", nullable: false),
                    GestationWeeks = table.Column<int>(type: "int", nullable: true),
                    DueDate = table.Column<DateOnly>(type: "date", nullable: true),
                    Version = table.Column<int>(type: "int", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Deleted = table.Column<bool>(type: "bit", nullable: false),
                    ChangeSeq = table.Column<long>(type: "bigint", nullable: false),
                    ScopeAreaId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Mothers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "OtpRequests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CodeHash = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Attempts = table.Column<int>(type: "int", nullable: false),
                    UsedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OtpRequests", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ProcessedOperations",
                columns: table => new
                {
                    OperationId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Entity = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RecordId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    NewVersion = table.Column<int>(type: "int", nullable: true),
                    ConflictId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ProcessedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProcessedOperations", x => x.OperationId);
                });

            migrationBuilder.CreateTable(
                name: "RecordHistory",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Entity = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RecordId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Version = table.Column<int>(type: "int", nullable: false),
                    ChangedFields = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    SnapshotJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Strategy = table.Column<string>(type: "nvarchar(5)", maxLength: 5, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecordHistory", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "RefreshTokens",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TokenHash = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    RevokedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RefreshTokens", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SyncLogs",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    At = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Endpoint = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    Strategy = table.Column<string>(type: "nvarchar(5)", maxLength: 5, nullable: true),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NetworkProfile = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: true),
                    RecordsIn = table.Column<int>(type: "int", nullable: false),
                    RecordsOut = table.Column<int>(type: "int", nullable: false),
                    Applied = table.Column<int>(type: "int", nullable: false),
                    Duplicates = table.Column<int>(type: "int", nullable: false),
                    Merged = table.Column<int>(type: "int", nullable: false),
                    Flagged = table.Column<int>(type: "int", nullable: false),
                    Rejected = table.Column<int>(type: "int", nullable: false),
                    RequestBytes = table.Column<long>(type: "bigint", nullable: false),
                    ResponseBytes = table.Column<long>(type: "bigint", nullable: false),
                    DurationMs = table.Column<int>(type: "int", nullable: false),
                    StatusCode = table.Column<int>(type: "int", nullable: false),
                    Success = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SyncLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Role = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    AreaId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    MohId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    MotherId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Vaccinations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChildId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Vaccine = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Dose = table.Column<int>(type: "int", nullable: false),
                    GivenOn = table.Column<DateOnly>(type: "date", nullable: false),
                    BatchNo = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    Version = table.Column<int>(type: "int", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Deleted = table.Column<bool>(type: "bit", nullable: false),
                    ChangeSeq = table.Column<long>(type: "bigint", nullable: false),
                    ScopeAreaId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Vaccinations", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Children_ChangeSeq",
                table: "Children",
                column: "ChangeSeq");

            migrationBuilder.CreateIndex(
                name: "IX_Children_MotherId",
                table: "Children",
                column: "MotherId");

            migrationBuilder.CreateIndex(
                name: "IX_Children_ScopeAreaId_ChangeSeq",
                table: "Children",
                columns: new[] { "ScopeAreaId", "ChangeSeq" });

            migrationBuilder.CreateIndex(
                name: "IX_Conflicts_ScopeAreaId_Status",
                table: "Conflicts",
                columns: new[] { "ScopeAreaId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_GrowthMeasurements_ChangeSeq",
                table: "GrowthMeasurements",
                column: "ChangeSeq");

            migrationBuilder.CreateIndex(
                name: "IX_GrowthMeasurements_ChildId",
                table: "GrowthMeasurements",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_GrowthMeasurements_ScopeAreaId_ChangeSeq",
                table: "GrowthMeasurements",
                columns: new[] { "ScopeAreaId", "ChangeSeq" });

            migrationBuilder.CreateIndex(
                name: "IX_MaternalVisits_ChangeSeq",
                table: "MaternalVisits",
                column: "ChangeSeq");

            migrationBuilder.CreateIndex(
                name: "IX_MaternalVisits_MotherId",
                table: "MaternalVisits",
                column: "MotherId");

            migrationBuilder.CreateIndex(
                name: "IX_MaternalVisits_ScopeAreaId_ChangeSeq",
                table: "MaternalVisits",
                columns: new[] { "ScopeAreaId", "ChangeSeq" });

            migrationBuilder.CreateIndex(
                name: "IX_Mothers_ChangeSeq",
                table: "Mothers",
                column: "ChangeSeq");

            migrationBuilder.CreateIndex(
                name: "IX_Mothers_Phone",
                table: "Mothers",
                column: "Phone");

            migrationBuilder.CreateIndex(
                name: "IX_Mothers_ScopeAreaId_ChangeSeq",
                table: "Mothers",
                columns: new[] { "ScopeAreaId", "ChangeSeq" });

            migrationBuilder.CreateIndex(
                name: "IX_OtpRequests_Phone_CreatedAt",
                table: "OtpRequests",
                columns: new[] { "Phone", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_RecordHistory_Entity_RecordId_Version",
                table: "RecordHistory",
                columns: new[] { "Entity", "RecordId", "Version" });

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_TokenHash",
                table: "RefreshTokens",
                column: "TokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_UserId",
                table: "RefreshTokens",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_SyncLogs_At",
                table: "SyncLogs",
                column: "At");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Phone",
                table: "Users",
                column: "Phone",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Vaccinations_ChangeSeq",
                table: "Vaccinations",
                column: "ChangeSeq");

            migrationBuilder.CreateIndex(
                name: "IX_Vaccinations_ChildId",
                table: "Vaccinations",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_Vaccinations_ScopeAreaId_ChangeSeq",
                table: "Vaccinations",
                columns: new[] { "ScopeAreaId", "ChangeSeq" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Children");

            migrationBuilder.DropTable(
                name: "Conflicts");

            migrationBuilder.DropTable(
                name: "GrowthMeasurements");

            migrationBuilder.DropTable(
                name: "MaternalVisits");

            migrationBuilder.DropTable(
                name: "Mothers");

            migrationBuilder.DropTable(
                name: "OtpRequests");

            migrationBuilder.DropTable(
                name: "ProcessedOperations");

            migrationBuilder.DropTable(
                name: "RecordHistory");

            migrationBuilder.DropTable(
                name: "RefreshTokens");

            migrationBuilder.DropTable(
                name: "SyncLogs");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "Vaccinations");

            migrationBuilder.DropSequence(
                name: "ChangeSeq");
        }
    }
}
