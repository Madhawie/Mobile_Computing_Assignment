using LittleBloom.Application.Sync;
using LittleBloom.Domain.Entities;
using LittleBloom.Domain.Enums;

namespace LittleBloom.Tests;

public class RecordValidatorTests
{
    private static GrowthMeasurement ValidGrowth() => new()
    {
        Id = Guid.NewGuid(),
        Version = 1,
        DeviceId = "emu-phm-01",
        UpdatedAt = DateTime.UtcNow,
        ChildId = Guid.NewGuid(),
        MeasuredOn = new DateOnly(2026, 11, 20),
        WeightKg = 7.4,
    };

    [Fact]
    public void Valid_record_has_no_invalid_field()
    {
        Assert.Null(RecordValidator.FirstInvalidField(ValidGrowth()));
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(55)]
    public void Impossible_child_weight_is_rejected(double weight)
    {
        var g = ValidGrowth();
        g.WeightKg = weight;
        Assert.Equal("weightKg", RecordValidator.FirstInvalidField(g));
    }

    [Fact]
    public void Diastolic_not_below_systolic_is_rejected()
    {
        var v = new MaternalVisit
        {
            Version = 1, DeviceId = "d", MotherId = Guid.NewGuid(),
            GestationWeeks = 20, WeightKg = 60, BpSystolic = 80, BpDiastolic = 90,
        };
        Assert.Equal("bpDiastolic", RecordValidator.FirstInvalidField(v));
    }

    [Fact]
    public void Sex_must_be_boy_or_girl()
    {
        var c = new Child { Version = 1, DeviceId = "d", MotherId = Guid.NewGuid(), Name = "A", Sex = "male", BirthWeightKg = 3.1 };
        Assert.Equal("sex", RecordValidator.FirstInvalidField(c));
    }
}

public class SyncUserTests
{
    [Fact]
    public void Phm_covers_only_her_own_area()
    {
        var phm = new SyncUser(Guid.NewGuid(), UserRole.Phm, "glg-east", "glg", null);
        Assert.True(phm.CoversArea("glg-east"));
        Assert.False(phm.CoversArea("glg-west"));
    }

    [Fact]
    public void Supervisor_covers_every_area_of_her_moh_division()
    {
        var sup = new SyncUser(Guid.NewGuid(), UserRole.Supervisor, null, "glg", null);
        Assert.True(sup.CoversArea("glg-east"));
        Assert.True(sup.CoversArea("glg-west"));
        Assert.False(sup.CoversArea("mtr-north"));
    }

    [Fact]
    public void Mother_covers_no_area_for_writing()
    {
        var mother = new SyncUser(Guid.NewGuid(), UserRole.Mother, null, "glg", Guid.NewGuid());
        Assert.False(mother.CoversArea("glg-east"));
    }
}
