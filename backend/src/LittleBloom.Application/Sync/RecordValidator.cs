using LittleBloom.Domain.Entities;

namespace LittleBloom.Application.Sync;

/// <summary>
/// Sanity checks before a record is saved. Returns the camelCase name of the first bad field,
/// or null when the record is fine. A bad record is rejected alone (INVALID_FIELD); the rest of the batch continues.
/// The limits are wide on purpose: they catch typing mistakes, not unusual but real values.
/// </summary>
public static class RecordValidator
{
    public static string? FirstInvalidField(SyncEntity record)
    {
        if (record.Version < 1) return "version";
        if (string.IsNullOrWhiteSpace(record.DeviceId)) return "deviceId";

        return record switch
        {
            Mother m => string.IsNullOrWhiteSpace(m.FullName) ? "fullName"
                : string.IsNullOrWhiteSpace(m.Phone) ? "phone"
                : (m.Age is < 10 or > 70) ? "age"
                : string.IsNullOrWhiteSpace(m.AreaId) ? "areaId"
                : (m.GestationWeeks is < 0 or > 45) ? "gestationWeeks"
                : null,

            MaternalVisit v => v.MotherId == Guid.Empty ? "motherId"
                : (v.GestationWeeks is < 0 or > 45) ? "gestationWeeks"
                : (v.WeightKg is <= 20.0 or > 250.0) ? "weightKg"
                : (v.BpSystolic is < 50 or > 260) ? "bpSystolic"
                : (v.BpDiastolic is < 30 or > 180) ? "bpDiastolic"
                : v.BpDiastolic >= v.BpSystolic ? "bpDiastolic"
                : null,

            Child c => c.MotherId == Guid.Empty ? "motherId"
                : string.IsNullOrWhiteSpace(c.Name) ? "name"
                : (c.Sex is not ("boy" or "girl")) ? "sex"
                : (c.BirthWeightKg is <= 0.3 or > 7.0) ? "birthWeightKg"
                : null,

            GrowthMeasurement g => g.ChildId == Guid.Empty ? "childId"
                : (g.WeightKg is <= 0.3 or > 40.0) ? "weightKg"
                : (g.HeightCm is <= 20.0 or > 140.0) ? "heightCm"
                : null,

            Vaccination x => x.ChildId == Guid.Empty ? "childId"
                : string.IsNullOrWhiteSpace(x.Vaccine) ? "vaccine"
                : (x.Dose is < 1 or > 10) ? "dose"
                : null,

            _ => null,
        };
    }
}
