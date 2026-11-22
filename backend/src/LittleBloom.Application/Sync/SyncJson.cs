using System.Text.Json;
using System.Text.Json.Nodes;

namespace LittleBloom.Application.Sync;

/// <summary>
/// One JSON setting for all sync code: camelCase names, dates as "2026-11-20".
/// Records are turned into JSON objects so that the conflict rules can work field by field
/// for all five record types with the same code.
/// </summary>
public static class SyncJson
{
    public static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web);

    /// <summary>Fields every record has. They are bookkeeping, not data a person edits.</summary>
    public static readonly IReadOnlySet<string> MetaFields =
        new HashSet<string>(StringComparer.Ordinal) { "id", "version", "updatedAt", "deviceId", "deleted" };

    public static JsonObject ToJson(object entity, Type type) =>
        JsonSerializer.SerializeToNode(entity, type, Options)!.AsObject();

    public static object? FromJson(JsonObject json, Type type) =>
        json.Deserialize(type, Options);
}
