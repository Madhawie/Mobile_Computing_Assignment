using LittleBloom.Application.Sync;

namespace LittleBloom.Application.Staff;

/// <summary>MOH admin adds PHMs and supervisors and can block a lost phone.</summary>
public interface IStaffService
{
    Task<List<StaffDto>> ListAsync(SyncUser admin, CancellationToken ct = default);

    Task<StaffDto> CreateAsync(SyncUser admin, CreateStaffBody body, CancellationToken ct = default);

    Task<RevokeStaffResponse> RevokeAsync(SyncUser admin, Guid staffId, CancellationToken ct = default);
}
