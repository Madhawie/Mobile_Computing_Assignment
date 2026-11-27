using System.Diagnostics;
using System.Globalization;
using LittleBloom.Domain.Entities;

namespace LittleBloom.Api.Metrics;

/// <summary>
/// Measurement for the experiments (api.md section 8), on every request:
///   - X-Server-Time-Ms response header: time spent inside the server until the response starts.
///     The phone subtracts it from its total time to get the network time.
/// On /api/sync/push and /api/sync/pull it also builds a SyncLog row (the controller adds the
/// counts), measures the request and response sizes, and queues the row for saving.
/// </summary>
public sealed class MeasurementMiddleware
{
    public const string ServerTimeHeader = "X-Server-Time-Ms";
    public const string NetworkProfileHeader = "X-Network-Profile";
    public const string StrategyHeader = "X-Sync-Strategy";
    public const string DeviceIdHeader = "X-Device-Id";

    private static readonly HashSet<string> KnownProfiles = new(StringComparer.OrdinalIgnoreCase) { "4G", "3G", "2G", "none" };

    private readonly RequestDelegate _next;

    public MeasurementMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext http, SyncLogQueue queue)
    {
        var timer = Stopwatch.StartNew();
        http.Response.OnStarting(() =>
        {
            http.Response.Headers[ServerTimeHeader] = timer.ElapsedMilliseconds.ToString(CultureInfo.InvariantCulture);
            return Task.CompletedTask;
        });

        var entry = StartSyncLog(http);
        if (entry is null)
        {
            await _next(http); // not a sync request: only the timing header
            return;
        }

        var originalBody = http.Response.Body;
        var counter = new CountingStream(originalBody);
        http.Response.Body = counter;
        try
        {
            await _next(http);
            entry.StatusCode = http.Response.StatusCode;
            entry.Success = http.Response.StatusCode < 400;
        }
        catch
        {
            entry.StatusCode = StatusCodes.Status500InternalServerError;
            entry.Success = false;
            throw;
        }
        finally
        {
            http.Response.Body = originalBody;
            entry.DurationMs = (int)timer.ElapsedMilliseconds;
            entry.RequestBytes = http.Request.ContentLength ?? 0;
            entry.ResponseBytes = counter.BytesWritten;
            queue.Enqueue(entry);
        }
    }

    /// <summary>A new log row for push/pull, stored in HttpContext.Items for the controller; null otherwise.</summary>
    private static SyncLog? StartSyncLog(HttpContext http)
    {
        var path = http.Request.Path.Value ?? string.Empty;
        var endpoint = path.EndsWith("/api/sync/push", StringComparison.OrdinalIgnoreCase) ? "push"
            : path.EndsWith("/api/sync/pull", StringComparison.OrdinalIgnoreCase) ? "pull"
            : null;
        if (endpoint is null) return null;

        var profile = http.Request.Headers[NetworkProfileHeader].ToString();
        var strategy = http.Request.Headers[StrategyHeader].ToString();
        var device = http.Request.Headers[DeviceIdHeader].ToString();

        var entry = new SyncLog
        {
            At = DateTime.UtcNow,
            Endpoint = endpoint,
            NetworkProfile = KnownProfiles.Contains(profile) ? profile.ToUpperInvariant().Replace("NONE", "none") : null,
            Strategy = string.IsNullOrWhiteSpace(strategy) ? null : strategy.Trim().ToUpperInvariant(),
            DeviceId = string.IsNullOrWhiteSpace(device) ? null : Truncate(device.Trim(), 100),
        };
        SyncLogItem.Set(http, entry);
        return entry;
    }

    private static string Truncate(string value, int max) => value.Length <= max ? value : value[..max];
}

/// <summary>Passes the current request's SyncLog row from the middleware to the controller.</summary>
public static class SyncLogItem
{
    private const string Key = "LittleBloom.SyncLog";

    public static void Set(HttpContext http, SyncLog entry) => http.Items[Key] = entry;

    public static SyncLog? Get(HttpContext http) => http.Items.TryGetValue(Key, out var value) ? value as SyncLog : null;
}
