namespace LittleBloom.Application.Staff;

// Bodies of /api/staff (api.md section 9.6). Admin only.

public record StaffDto(Guid Id, string Name, string Phone, string Role, string? AreaId, bool IsActive, DateTime CreatedAt);

/// <param name="Role">"phm" or "supervisor".</param>
/// <param name="AreaId">Required for a PHM, e.g. "glg-east" (must belong to the admin's MOH division).</param>
public record CreateStaffBody(string Name, string Phone, string Role, string? AreaId);

/// <param name="RevokedDevices">How many signed-in phones were signed out.</param>
public record RevokeStaffResponse(Guid Id, int RevokedDevices);
