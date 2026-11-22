using System.Globalization;
using System.Text.Json.Nodes;
using LittleBloom.Application.Sync;

namespace LittleBloom.Tests;

/// <summary>
/// One test per S3 rule (api.md section 6). Scenario in all tests: the PHM (phone) and the
/// clinic (server, PHNS) both edit the same growth measurement while the PHM is offline.
/// </summary>
public class ConflictResolverTests
{
    private const string Early = "2026-11-20T08:00:00Z";
    private const string Late = "2026-11-20T09:00:00Z";

    private static JsonObject Growth(double weight, string? notes, string updatedAt, bool deleted = false, string device = "emu-phm-01") =>
        JsonNode.Parse($$"""
        {
          "id": "b51d0000-0000-0000-0000-000000000001",
          "version": 3,
          "updatedAt": "{{updatedAt}}",
          "deviceId": "{{device}}",
          "deleted": {{(deleted ? "true" : "false")}},
          "childId": "77aa0000-0000-0000-0000-000000000001",
          "measuredOn": "2026-11-20",
          "weightKg": {{weight.ToString(CultureInfo.InvariantCulture)}},
          "heightCm": null,
          "notes": {{(notes is null ? "null" : $"\"{notes}\"")}}
        }
        """)!.AsObject();

    private static ResolveResult Resolve(
        JsonObject server, int serverVersion, string[] serverChanged,
        JsonObject phone, int baseVersion, string[] phoneChanged, bool phoneDeletes = false) =>
        ConflictResolver.Resolve(new ResolveInput(server, serverVersion, serverChanged, phone, baseVersion, phoneChanged, phoneDeletes));

    [Fact]
    public void Rule1_no_one_else_changed_it_phone_record_is_applied()
    {
        var server = Growth(7.0, null, Early);
        var phone = Growth(7.4, "ate well", Late);

        var r = Resolve(server, 3, [], phone, baseVersion: 3, ["weightKg", "notes"]);

        Assert.Equal(ResolveOutcome.Applied, r.Outcome);
        Assert.Equal(7.4, r.Merged["weightKg"]!.GetValue<double>());
        Assert.Equal("ate well", r.Merged["notes"]!.GetValue<string>());
        Assert.Empty(r.Conflicts);
    }

    [Fact]
    public void Rule2a_different_fields_changed_both_edits_are_kept()
    {
        // Clinic changed notes (v3 → v4) while the phone, still on v3, changed the weight.
        var server = Growth(7.0, "referred to clinic", Early, device: "emu-phns-01");
        var phone = Growth(7.4, null, Late);

        var r = Resolve(server, 4, ["notes"], phone, baseVersion: 3, ["weightKg"]);

        Assert.Equal(ResolveOutcome.Merged, r.Outcome);
        Assert.Equal(7.4, r.Merged["weightKg"]!.GetValue<double>());                     // phone's edit
        Assert.Equal("referred to clinic", r.Merged["notes"]!.GetValue<string>());        // clinic's edit
        Assert.Empty(r.Conflicts);
        Assert.Contains("weightKg", r.ChangedFields);
    }

    [Fact]
    public void Rule2b_same_field_newer_phone_edit_wins_and_clinic_value_is_saved()
    {
        var server = Growth(7.1, null, Early, device: "emu-phns-01");
        var phone = Growth(7.4, null, Late);

        var r = Resolve(server, 4, ["weightKg"], phone, baseVersion: 3, ["weightKg"]);

        Assert.Equal(ResolveOutcome.Flagged, r.Outcome);
        Assert.Equal("sameField", r.Kind);
        Assert.Equal(7.4, r.Merged["weightKg"]!.GetValue<double>());
        var c = Assert.Single(r.Conflicts);
        Assert.Equal("weightKg", c.Field);
        Assert.Equal(7.1, c.Lost!.GetValue<double>());   // never lost: kept for review
        Assert.Equal("server", c.LostSide);
    }

    [Fact]
    public void Rule2b_same_field_newer_clinic_edit_wins_and_phone_value_is_saved()
    {
        var server = Growth(7.1, null, Late, device: "emu-phns-01");
        var phone = Growth(7.4, null, Early);

        var r = Resolve(server, 4, ["weightKg"], phone, baseVersion: 3, ["weightKg"]);

        Assert.Equal(ResolveOutcome.Flagged, r.Outcome);
        Assert.Equal(7.1, r.Merged["weightKg"]!.GetValue<double>());
        var c = Assert.Single(r.Conflicts);
        Assert.Equal(7.4, c.Lost!.GetValue<double>());
        Assert.Equal("phone", c.LostSide);
    }

    [Fact]
    public void Same_field_changed_to_the_same_value_is_not_a_conflict()
    {
        var server = Growth(7.4, null, Early, device: "emu-phns-01");
        var phone = Growth(7.4, null, Late);

        var r = Resolve(server, 4, ["weightKg"], phone, baseVersion: 3, ["weightKg"]);

        Assert.Equal(ResolveOutcome.Merged, r.Outcome);
        Assert.Empty(r.Conflicts);
    }

    [Fact]
    public void Rule3_phone_deletes_but_clinic_updated_record_is_kept()
    {
        var server = Growth(7.1, "checked at clinic", Late, device: "emu-phns-01");
        var phone = Growth(7.0, null, Early, deleted: true);

        var r = Resolve(server, 4, ["notes"], phone, baseVersion: 3, [], phoneDeletes: true);

        Assert.Equal(ResolveOutcome.Flagged, r.Outcome);
        Assert.Equal("deleteVsUpdate", r.Kind);
        Assert.False(r.Merged["deleted"]!.GetValue<bool>());
        Assert.Equal("checked at clinic", r.Merged["notes"]!.GetValue<string>());
    }

    [Fact]
    public void Rule3_phone_updates_but_clinic_deleted_record_comes_back()
    {
        var server = Growth(7.0, null, Early, deleted: true, device: "emu-phns-01");
        var phone = Growth(7.4, null, Late);

        var r = Resolve(server, 4, ["deleted"], phone, baseVersion: 3, ["weightKg"]);

        Assert.Equal(ResolveOutcome.Flagged, r.Outcome);
        Assert.Equal("deleteVsUpdate", r.Kind);
        Assert.False(r.Merged["deleted"]!.GetValue<bool>());
        Assert.Equal(7.4, r.Merged["weightKg"]!.GetValue<double>());
    }

    [Fact]
    public void Delete_without_any_clash_is_applied_as_a_delete()
    {
        var server = Growth(7.0, null, Early);
        var phone = Growth(7.0, null, Late, deleted: true);

        var r = Resolve(server, 3, [], phone, baseVersion: 3, [], phoneDeletes: true);

        Assert.Equal(ResolveOutcome.Applied, r.Outcome);
        Assert.True(r.Merged["deleted"]!.GetValue<bool>());
    }

    [Fact]
    public void Rule4_base_zero_but_record_exists_differing_fields_are_flagged()
    {
        var server = Growth(7.1, null, Early, device: "emu-phns-01");
        var phone = Growth(7.4, null, Late);

        var r = Resolve(server, 1, ["*"], phone, baseVersion: 0, []);

        Assert.Equal(ResolveOutcome.Flagged, r.Outcome);
        Assert.Contains(r.Conflicts, c => c.Field == "weightKg");
    }

    [Fact]
    public void No_edit_is_ever_silently_lost()
    {
        // Every value that does not end up in the record must appear in Conflicts.
        var server = Growth(7.1, "clinic note", Late, device: "emu-phns-01");
        var phone = Growth(7.4, "phm note", Early);

        var r = Resolve(server, 5, ["weightKg", "notes"], phone, baseVersion: 3, ["weightKg", "notes"]);

        foreach (var field in new[] { "weightKg", "notes" })
        {
            var phoneKept = JsonNode.DeepEquals(r.Merged[field], phone[field]);
            var savedInConflict = r.Conflicts.Any(c => c.Field == field && JsonNode.DeepEquals(c.Lost, phone[field]));
            Assert.True(phoneKept || savedInConflict, $"phone value of {field} was lost");
        }
    }
}
