using LittleBloom.Domain.Enums;

namespace LittleBloom.Domain.Entities;

/// <summary>
/// Anyone who can sign in. Nobody signs up: staff are added by the MOH admin,
/// mothers get an account when a PHM adds them (their phone number is the login).
/// </summary>
public class User
{
    public Guid Id { get; set; }

    /// <summary>Login, in +94 format. Unique.</summary>
    public string Phone { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;
    public UserRole Role { get; set; }

    /// <summary>PHM area (PHM only).</summary>
    public string? AreaId { get; set; }

    /// <summary>MOH division (all staff, and mothers through their area).</summary>
    public string MohId { get; set; } = string.Empty;

    /// <summary>The mother's own record (mother only).</summary>
    public Guid? MotherId { get; set; }

    /// <summary>False = blocked by the admin (e.g. lost phone).</summary>
    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }
}
