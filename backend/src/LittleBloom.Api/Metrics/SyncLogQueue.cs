using System.Threading.Channels;
using LittleBloom.Domain.Entities;
using LittleBloom.Infrastructure.Persistence;

namespace LittleBloom.Api.Metrics;

/// <summary>
/// In-memory queue of sync log rows. Requests only add to it (no database write while the phone
/// waits), and <see cref="SyncLogWriter"/> saves them in the background. This keeps the logging
/// itself out of the sync times we measure.
/// </summary>
public sealed class SyncLogQueue
{
    private readonly Channel<SyncLog> _channel = Channel.CreateBounded<SyncLog>(
        new BoundedChannelOptions(10_000) { FullMode = BoundedChannelFullMode.DropWrite });

    public ChannelReader<SyncLog> Reader => _channel.Reader;

    /// <summary>Never blocks. If 10 000 rows are already waiting, the new row is dropped.</summary>
    public void Enqueue(SyncLog entry) => _channel.Writer.TryWrite(entry);
}

/// <summary>Background service that saves queued sync log rows in batches.</summary>
public sealed class SyncLogWriter : BackgroundService
{
    private const int BatchSize = 200;

    private readonly SyncLogQueue _queue;
    private readonly IServiceScopeFactory _scopes;
    private readonly ILogger<SyncLogWriter> _logger;

    public SyncLogWriter(SyncLogQueue queue, IServiceScopeFactory scopes, ILogger<SyncLogWriter> logger)
    {
        _queue = queue;
        _scopes = scopes;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (await _queue.Reader.WaitToReadAsync(stoppingToken))
        {
            var batch = new List<SyncLog>();
            while (batch.Count < BatchSize && _queue.Reader.TryRead(out var row)) batch.Add(row);

            try
            {
                using var scope = _scopes.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                db.SyncLogs.AddRange(batch);
                await db.SaveChangesAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // Losing a log row must never break syncing; just report it.
                _logger.LogWarning(ex, "Could not save {Count} sync log rows", batch.Count);
            }
        }
    }
}
