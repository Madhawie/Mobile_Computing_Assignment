namespace LittleBloom.Domain.Entities;

/// <summary>
/// A one-time SMS code that was sent. Only a hash of the code is stored,
/// so someone reading the database cannot sign in with it.
/// </summary>
public class OtpRequest
{
    public Guid Id { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string CodeHash { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }

    /// <summary>Wrong guesses so far. Locked after 5.</summary>
    public int Attempts { get; set; }

    /// <summary>Set once the code was used, so it cannot be used twice.</summary>
    public DateTime? UsedAt { get; set; }
}
