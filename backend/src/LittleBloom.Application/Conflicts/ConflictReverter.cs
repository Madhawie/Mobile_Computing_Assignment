using System.Text.Json.Nodes;

namespace LittleBloom.Application.Conflicts;

/// <summary>
/// "Keep previous": puts the values that lost an S3 conflict back into the record.
/// Pure function on JSON, so it is unit-tested without a database.
/// </summary>
public static class ConflictReverter
{
    /// <param name="record">The record as it is now (camelCase JSON).</param>
    /// <param name="fields">Conflict.FieldsJson: [{ "field": ..., "lost": ... }].</param>
    /// <returns>A copy of the record with each conflicting field set to its lost value.</returns>
    public static JsonObject WriteBackLostValues(JsonObject record, JsonArray fields)
    {
        var result = record.DeepClone().AsObject();

        foreach (var item in fields.OfType<JsonObject>())
        {
            var field = item["field"]?.GetValue<string>();
            if (string.IsNullOrEmpty(field)) continue;
            result[field] = item["lost"]?.DeepClone();
        }

        return result;
    }

    /// <summary>The field names a conflict touched, for the history row.</summary>
    public static IEnumerable<string> FieldNames(JsonArray fields) =>
        fields.OfType<JsonObject>()
              .Select(i => i["field"]?.GetValue<string>())
              .Where(f => !string.IsNullOrEmpty(f))
              .Select(f => f!);
}
