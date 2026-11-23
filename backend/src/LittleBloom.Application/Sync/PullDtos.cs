using System.Text.Json.Nodes;

namespace LittleBloom.Application.Sync;

// Response of GET /api/sync/pull?since=<cursor>&limit=500 (api.md section 5).

/// <summary>One record that changed on the server after the phone's cursor.</summary>
public record PulledChange(string Entity, JsonObject Record);

/// <param name="Cursor">Store this and send it as "since" next time.</param>
/// <param name="HasMore">True = call again with the new cursor; more changes are waiting.</param>
public record PullResponse(List<PulledChange> Changes, long Cursor, bool HasMore);

public static class PullLimits
{
    public const int DefaultLimit = 500;
    public const int MaxLimit = 1000;
}
