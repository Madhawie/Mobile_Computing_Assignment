namespace LittleBloom.Domain.Entities;

/// <summary>A child under 5 (the digital CHDR). Sync entity name: "child".</summary>
public class Child : SyncEntity
{
    public Guid MotherId { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>"boy" or "girl" (decides the blue or pink CHDR growth chart).</summary>
    public string Sex { get; set; } = string.Empty;

    public DateOnly DateOfBirth { get; set; }
    public double BirthWeightKg { get; set; }
    public string? BornAt { get; set; }
    public string? ChdrNumber { get; set; }
}
