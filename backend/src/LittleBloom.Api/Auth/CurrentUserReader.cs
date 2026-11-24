using System.Security.Claims;
using LittleBloom.Application.Common;
using LittleBloom.Application.Sync;
using LittleBloom.Domain.Enums;

namespace LittleBloom.Api.Auth;

/// <summary>Turns the JWT claims of the signed-in user into a SyncUser (who, which role, which area).</summary>
public static class CurrentUserReader
{
    public static SyncUser Read(ClaimsPrincipal principal)
    {
        string? Claim(string name) => principal.FindFirst(name)?.Value;

        if (!Guid.TryParse(Claim(ClaimNames.Sub), out var userId)
            || !Enum.TryParse<UserRole>(Claim(ClaimNames.Role), ignoreCase: true, out var role))
            throw new AppException(401, ErrorCodes.Unauthorized, "Token is missing user details.");

        Guid? motherId = Guid.TryParse(Claim(ClaimNames.MotherId), out var m) ? m : null;
        return new SyncUser(userId, role, Claim(ClaimNames.AreaId), Claim(ClaimNames.MohId) ?? string.Empty, motherId);
    }
}
