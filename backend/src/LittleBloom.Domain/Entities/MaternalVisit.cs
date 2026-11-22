namespace LittleBloom.Domain.Entities;

/// <summary>A PHM home visit to a pregnant mother. Sync entity name: "maternalVisit".</summary>
public class MaternalVisit : SyncEntity
{
    public Guid MotherId { get; set; }
    public DateOnly VisitDate { get; set; }
    public int GestationWeeks { get; set; }
    public double WeightKg { get; set; }

    // Two numbers instead of "120/80" so the server can check them.
    public int BpSystolic { get; set; }
    public int BpDiastolic { get; set; }

    public string? Notes { get; set; }
    public DateOnly? NextVisit { get; set; }
}
