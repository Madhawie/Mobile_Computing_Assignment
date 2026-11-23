using System.Text.Json.Nodes;
using LittleBloom.Application.Conflicts;

namespace LittleBloom.Tests;

public class ConflictReverterTests
{
    [Fact]
    public void Keep_previous_writes_the_lost_value_back()
    {
        var record = JsonNode.Parse("""{ "id": "x", "weightKg": 7.4, "notes": "phm" }""")!.AsObject();
        var fields = JsonNode.Parse("""[{ "field": "weightKg", "kept": 7.4, "lost": 7.1, "lostSide": "server" }]""")!.AsArray();

        var result = ConflictReverter.WriteBackLostValues(record, fields);

        Assert.Equal(7.1, result["weightKg"]!.GetValue<double>());
        Assert.Equal("phm", result["notes"]!.GetValue<string>());   // untouched field stays
        Assert.Equal(7.4, record["weightKg"]!.GetValue<double>());  // original not changed
    }

    [Fact]
    public void Keep_previous_on_delete_vs_update_deletes_the_record()
    {
        var record = JsonNode.Parse("""{ "id": "x", "deleted": false }""")!.AsObject();
        var fields = JsonNode.Parse("""[{ "field": "deleted", "kept": false, "lost": true }]""")!.AsArray();

        var result = ConflictReverter.WriteBackLostValues(record, fields);

        Assert.True(result["deleted"]!.GetValue<bool>());
    }

    [Fact]
    public void Field_names_lists_every_conflicting_field()
    {
        var fields = JsonNode.Parse("""[{ "field": "weightKg" }, { "field": "notes" }]""")!.AsArray();

        Assert.Equal(new[] { "weightKg", "notes" }, ConflictReverter.FieldNames(fields));
    }
}
