namespace LittleBloom.Domain.Entities;

/// <summary>One weight (and optional height) check of a child. Sync entity name: "growthMeasurement".</summary>
public class GrowthMeasurement : SyncEntity
{
    public Guid ChildId { get; set; }
    public DateOnly MeasuredOn { get; set; }
    public double WeightKg { get; set; }
    public double? HeightCm { get; set; }
    public string? Notes { get; set; }
}
