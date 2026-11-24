using LittleBloom.Application.Auth;
using LittleBloom.Application.Common;
using LittleBloom.Application.Staff;
using LittleBloom.Application.Sync;
using LittleBloom.Domain.Entities;
using LittleBloom.Domain.Enums;
using LittleBloom.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LittleBloom.Infrastructure.Staff;

/// <summary>
/// Staff accounts (api.md section 9.6). Nobody signs up: the MOH admin adds PHMs and supervisors
/// of her own division. "Revoke" signs out every phone of that person (lost phone): their refresh
/// tokens stop working, so the phone cannot get a new access token at the next sync.
/// </summary>
public class StaffService : IStaffService
{
    private readonly AppDbContext _db;

    public StaffService(AppDbContext db) => _db = db;

    public async Task<List<StaffDto>> ListAsync(SyncUser admin, CancellationToken ct = default)
    {
        EnsureAdmin(admin);

        var staff = await _db.Users.AsNoTracking()
            .Where(u => u.MohId == admin.MohId && u.Role != UserRole.Mother)
            .OrderBy(u => u.Role).ThenBy(u => u.Name)
            .ToListAsync(ct);

        return staff.Select(ToDto).ToList();
    }

    public async Task<StaffDto> CreateAsync(SyncUser admin, CreateStaffBody body, CancellationToken ct = default)
    {
        EnsureAdmin(admin);

        if (string.IsNullOrWhiteSpace(body.Name))
            throw new AppException(400, ErrorCodes.ValidationFailed, "name is required.");

        var role = body.Role?.ToLowerInvariant() switch
        {
            "phm" => UserRole.Phm,
            "supervisor" => UserRole.Supervisor,
            _ => throw new AppException(400, ErrorCodes.ValidationFailed, "role must be \"phm\" or \"supervisor\"."),
        };

        string? areaId = null;
        if (role == UserRole.Phm)
        {
            areaId = body.AreaId?.Trim().ToLowerInvariant();
            if (string.IsNullOrEmpty(areaId) || !areaId.StartsWith(admin.MohId + "-"))
                throw new AppException(400, ErrorCodes.ValidationFailed,
                    $"A PHM needs an areaId of this MOH division, e.g. \"{admin.MohId}-east\".");
        }

        var phone = PhoneNumber.Normalize(body.Phone);
        if (phone.Length < 10)
            throw new AppException(400, ErrorCodes.ValidationFailed, "phone is not a valid number.");
        if (await _db.Users.AnyAsync(u => u.Phone == phone, ct))
            throw new AppException(409, ErrorCodes.PhoneAlreadyRegistered, "This phone number already has an account.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Phone = phone,
            Name = body.Name.Trim(),
            Role = role,
            AreaId = areaId,
            MohId = admin.MohId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync(ct);

        return ToDto(user);
    }

    public async Task<RevokeStaffResponse> RevokeAsync(SyncUser admin, Guid staffId, CancellationToken ct = default)
    {
        EnsureAdmin(admin);

        var staff = await _db.Users.FirstOrDefaultAsync(u => u.Id == staffId && u.MohId == admin.MohId, ct)
                    ?? throw new AppException(404, ErrorCodes.NotFound, "Staff member not found in your division.");

        var tokens = await _db.RefreshTokens
            .Where(t => t.UserId == staff.Id && t.RevokedAt == null)
            .ToListAsync(ct);

        var now = DateTime.UtcNow;
        foreach (var token in tokens) token.RevokedAt = now;
        await _db.SaveChangesAsync(ct);

        return new RevokeStaffResponse(staff.Id, tokens.Count);
    }

    private static void EnsureAdmin(SyncUser user)
    {
        if (user.Role != UserRole.Admin)
            throw new AppException(403, ErrorCodes.Forbidden, "Only the MOH admin manages staff.");
    }

    private static StaffDto ToDto(User u) =>
        new(u.Id, u.Name, u.Phone, u.Role.ToString().ToLowerInvariant(), u.AreaId, u.IsActive, u.CreatedAt);
}
