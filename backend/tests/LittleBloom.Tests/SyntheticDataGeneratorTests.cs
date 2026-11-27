using LittleBloom.Application.Experiments;
using LittleBloom.Application.Sync;

namespace LittleBloom.Tests;

public class SyntheticDataGeneratorTests
{
    private static readonly DateTime Now = new(2026, 11, 27, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Makes_the_requested_number_of_records()
    {
        var data = SyntheticDataGenerator.Generate(new SeedRequest(50, "glg-east"), Now);

        Assert.Equal(50, data.Mothers.Count);
        Assert.Equal(100, data.MaternalVisits.Count);     // 2 per mother
        Assert.Equal(50, data.Children.Count);            // 1 per mother
        Assert.Equal(150, data.GrowthMeasurements.Count); // 3 per child
        Assert.Equal(100, data.Vaccinations.Count);       // 2 per child
        Assert.Equal(450, data.Count);
    }

    [Fact]
    public void Same_seed_gives_exactly_the_same_data()
    {
        var a = SyntheticDataGenerator.Generate(new SeedRequest(20, "glg-east", Seed: 7), Now);
        var b = SyntheticDataGenerator.Generate(new SeedRequest(20, "glg-east", Seed: 7), Now);
        var c = SyntheticDataGenerator.Generate(new SeedRequest(20, "glg-east", Seed: 8), Now);

        Assert.Equal(a.All.Select(r => r.Id), b.All.Select(r => r.Id));
        Assert.Equal(a.Mothers.Select(m => m.FullName), b.Mothers.Select(m => m.FullName));
        Assert.NotEqual(a.Mothers[0].Id, c.Mothers[0].Id);
    }

    [Fact]
    public void Every_record_passes_the_server_validation()
    {
        var data = SyntheticDataGenerator.Generate(new SeedRequest(300, "glg-east", Seed: 3), Now);

        foreach (var record in data.All)
            Assert.Null(RecordValidator.FirstInvalidField(record));
    }

    [Fact]
    public void Children_and_visits_point_to_generated_parents()
    {
        var data = SyntheticDataGenerator.Generate(new SeedRequest(30, "glg-east"), Now);
        var motherIds = data.Mothers.Select(m => m.Id).ToHashSet();
        var childIds = data.Children.Select(c => c.Id).ToHashSet();

        Assert.All(data.MaternalVisits, v => Assert.Contains(v.MotherId, motherIds));
        Assert.All(data.Children, c => Assert.Contains(c.MotherId, motherIds));
        Assert.All(data.GrowthMeasurements, g => Assert.Contains(g.ChildId, childIds));
        Assert.All(data.Vaccinations, v => Assert.Contains(v.ChildId, childIds));
        Assert.All(data.Mothers, m => Assert.Equal("glg-east", m.AreaId));
        Assert.Equal(data.Count, data.All.Select(r => r.Id).Distinct().Count()); // no duplicate ids
    }
}
