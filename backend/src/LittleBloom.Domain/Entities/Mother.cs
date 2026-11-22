namespace LittleBloom.Domain.Entities;

/// <summary>A mother in a PHM area. Sync entity name: "mother".</summary>
public class Mother : SyncEntity
{
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public int Age { get; set; }
    public string Address { get; set; } = string.Empty;
    public string AreaId { get; set; } = string.Empty;
    public bool IsPregnant { get; set; }
    public int? GestationWeeks { get; set; }
    public DateOnly? DueDate { get; set; }
}
