namespace LittleBloom.Domain.Entities;

/// <summary>
/// Long-lived token (30 days) that gets a new access token without another SMS code.
/// One per phone. Stored as a hash. Revoking it blocks that phone (lost-phone case).
/// </summary>
public class RefreshToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public string DeviceId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}
