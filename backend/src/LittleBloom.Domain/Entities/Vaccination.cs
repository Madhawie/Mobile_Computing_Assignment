namespace LittleBloom.Domain.Entities;

/// <summary>One vaccine dose given to a child. Sync entity name: "vaccination".</summary>
public class Vaccination : SyncEntity
{
    public Guid ChildId { get; set; }

    /// <summary>Vaccine code, e.g. "BCG", "Pentavalent", "MMR".</summary>
    public string Vaccine { get; set; } = string.Empty;

    public int Dose { get; set; }
    public DateOnly GivenOn { get; set; }
    public string? BatchNo { get; set; }
}
