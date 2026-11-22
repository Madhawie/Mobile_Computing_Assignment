using LittleBloom.Domain.Enums;

namespace LittleBloom.Application.Sync;

/// <summary>The signed-in user doing the sync, taken from the JWT claims.</summary>
public record SyncUser(Guid UserId, UserRole Role, string? AreaId, string MohId, Guid? MotherId)
{
    /// <summary>
    /// Can this user see or change records of this PHM area?
    /// Area ids are "&lt;mohId&gt;-&lt;name&gt;" (e.g. "glg-east"), so MOH staff match by prefix.
    /// </summary>
    public bool CoversArea(string areaId) => Role switch
    {
        UserRole.Phm => string.Equals(AreaId, areaId, StringComparison.OrdinalIgnoreCase),
        UserRole.Supervisor or UserRole.Admin => areaId.StartsWith(MohId + "-", StringComparison.OrdinalIgnoreCase),
        _ => false,
    };
}
