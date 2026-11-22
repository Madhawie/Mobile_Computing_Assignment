using System.Text.Json.Nodes;

namespace LittleBloom.Application.Sync;

/// <summary>What the S3 resolver decided for one change.</summary>
public enum ResolveOutcome
{
    /// <summary>Nobody else changed the record since the phone's base version (rule 1).</summary>
    Applied,

    /// <summary>Someone else changed it, but different fields: both edits kept (rule 2a).</summary>
    Merged,

    /// <summary>Same field changed on both sides, or delete vs update: newest kept, other saved, person checks (rules 2b, 3).</summary>
    Flagged,
}

/// <summary>One field where two edits disagreed. Kept = value now in the record, Lost = value saved for review.</summary>
public record FieldConflict(string Field, JsonNode? Kept, JsonNode? Lost, string LostSide);

/// <summary>The resolver's answer. Merged is the record to save (without version; the caller sets it).</summary>
public record ResolveResult(
    ResolveOutcome Outcome,
    JsonObject Merged,
    IReadOnlyList<string> ChangedFields,
    IReadOnlyList<FieldConflict> Conflicts,
    string? Kind);

/// <summary>Input for one S3 decision. All records are JSON objects with camelCase fields.</summary>
/// <param name="Server">Current server copy.</param>
/// <param name="ServerVersion">Its version.</param>
/// <param name="ServerChangedSinceBase">Fields the server changed after BaseVersion (from RecordHistory). "*" = all.</param>
/// <param name="Incoming">The phone's record after its edit.</param>
/// <param name="BaseVersion">Server version the phone's edit started from.</param>
/// <param name="IncomingChangedFields">Fields the phone edited. Empty = every data field.</param>
/// <param name="IncomingIsDelete">The phone deleted the record.</param>
public record ResolveInput(
    JsonObject Server,
    int ServerVersion,
    IReadOnlyCollection<string> ServerChangedSinceBase,
    JsonObject Incoming,
    int BaseVersion,
    IReadOnlyCollection<string> IncomingChangedFields,
    bool IncomingIsDelete);

/// <summary>
/// S3 "versioned delta" conflict rules (api.md section 6). Pure logic: no database, no HTTP,
/// so every rule is unit-tested on its own (tests/ConflictResolverTests.cs).
///
/// Rule 1  baseVersion == serverVersion → no conflict, take the phone's record.
/// Rule 2  baseVersion &lt; serverVersion  → someone else saved first. Compare the fields:
///         2a no shared field → merge both edits.
///         2b shared field    → keep the value with the newer updatedAt, save the other, flag.
/// Rule 3  delete vs update  → the update wins, the record stays (deleted = false), flag.
/// Rule 4  baseVersion 0 but the record exists → same as rule 2 (every server field counts as changed).
///
/// S1/S2 skip all this and overwrite, which is exactly the "lost update" experiment E5 measures.
/// </summary>
public static class ConflictResolver
{
    private const string Deleted = "deleted";
    private const string UpdatedAt = "updatedAt";
    private const string DeviceId = "deviceId";
    private const string Server = "server";
    private const string Phone = "phone";

    public static ResolveResult Resolve(ResolveInput input)
    {
        var incomingFields = DataFields(input.Incoming, input.IncomingChangedFields);

        // Rule 1 (and a phone that claims a newer base than the server, which can only mean nothing changed here).
        if (input.BaseVersion >= input.ServerVersion)
        {
            var taken = Clone(input.Incoming);
            if (input.IncomingIsDelete) taken[Deleted] = true;
            return new ResolveResult(ResolveOutcome.Applied, taken,
                ChangedVersus(input.Server, taken), [], null);
        }

        var serverAll = input.ServerChangedSinceBase.Contains("*");
        var serverFields = serverAll
            ? DataFields(input.Server, [])
            : new HashSet<string>(input.ServerChangedSinceBase.Where(f => !SyncJson.MetaFields.Contains(f)), StringComparer.Ordinal);

        var serverDeleted = IsDeleted(input.Server);
        var phoneNewer = UpdatedAtOf(input.Incoming) > UpdatedAtOf(input.Server);

        // Rule 3a: the phone deletes, but someone else updated the record since → keep the record.
        if (input.IncomingIsDelete && serverFields.Count > 0 && !serverDeleted)
        {
            var kept = Clone(input.Server);
            kept[Deleted] = false;
            return new ResolveResult(ResolveOutcome.Flagged, kept, [],
                [new FieldConflict(Deleted, false, true, Phone)], "deleteVsUpdate");
        }

        var merged = Clone(input.Server);
        var conflicts = new List<FieldConflict>();

        foreach (var field in incomingFields)
        {
            var phoneValue = input.Incoming[field];
            var serverValue = input.Server[field];

            if (!serverFields.Contains(field) || JsonNode.DeepEquals(phoneValue, serverValue))
            {
                merged[field] = phoneValue?.DeepClone(); // only the phone changed it, or both chose the same value
                continue;
            }

            // Rule 2b: both changed the same field to different values. Newest edit wins; the other is kept for review.
            if (phoneNewer)
            {
                merged[field] = phoneValue?.DeepClone();
                conflicts.Add(new FieldConflict(field, phoneValue?.DeepClone(), serverValue?.DeepClone(), Server));
            }
            else
            {
                conflicts.Add(new FieldConflict(field, serverValue?.DeepClone(), phoneValue?.DeepClone(), Phone));
            }
        }

        // Rule 3b: the phone updates a record someone else deleted → the update wins, the record comes back.
        string? kind = conflicts.Count > 0 ? "sameField" : null;
        if (serverDeleted && !input.IncomingIsDelete)
        {
            merged[Deleted] = false;
            conflicts.Add(new FieldConflict(Deleted, false, true, Server));
            kind = "deleteVsUpdate";
        }

        // A delete that did not clash with any update (rule 3a returned earlier if it did).
        if (input.IncomingIsDelete) merged[Deleted] = true;

        // Bookkeeping fields: newest edit time, and the phone that just synced.
        merged[UpdatedAt] = (phoneNewer ? input.Incoming[UpdatedAt] : input.Server[UpdatedAt])?.DeepClone();
        merged[DeviceId] = input.Incoming[DeviceId]?.DeepClone();

        var outcome = conflicts.Count > 0 ? ResolveOutcome.Flagged : ResolveOutcome.Merged;
        return new ResolveResult(outcome, merged, ChangedVersus(input.Server, merged), conflicts, kind);
    }

    /// <summary>The data fields to look at: the phone's list, or every non-bookkeeping field when the list is empty.</summary>
    private static HashSet<string> DataFields(JsonObject record, IReadOnlyCollection<string> listed)
    {
        var fields = listed.Count > 0 ? listed : record.Select(p => p.Key).ToList();
        return new HashSet<string>(fields.Where(f => !SyncJson.MetaFields.Contains(f) && record.ContainsKey(f)),
            StringComparer.Ordinal);
    }

    /// <summary>Data fields whose value differs between two versions (stored in RecordHistory.ChangedFields).</summary>
    private static List<string> ChangedVersus(JsonObject before, JsonObject after)
    {
        var changed = after
            .Where(p => !SyncJson.MetaFields.Contains(p.Key) && !JsonNode.DeepEquals(p.Value, before[p.Key]))
            .Select(p => p.Key)
            .ToList();

        if (IsDeleted(before) != IsDeleted(after)) changed.Add(Deleted);
        return changed;
    }

    private static bool IsDeleted(JsonObject record) => record[Deleted]?.GetValue<bool>() == true;

    private static DateTime UpdatedAtOf(JsonObject record) =>
        record[UpdatedAt]?.GetValue<DateTime>() ?? DateTime.MinValue;

    private static JsonObject Clone(JsonObject o) => o.DeepClone().AsObject();
}
