namespace LittleBloom.Domain.Entities;

/// <summary>
/// One row per sync request the server handled (push or pull). The server-side half of the
/// experiment data: the phone writes its own sync_log (total time, bytes on the wire), and the two
/// are matched by device, time and network profile. Server time + network time = total time.
/// </summary>
public class SyncLog
{
    public long Id { get; set; }
    public DateTime At { get; set; }

    /// <summary>"push" or "pull".</summary>
    public string Endpoint { get; set; } = string.Empty;

    /// <summary>S1, S2 or S3 (from the push body, or the X-Sync-Strategy header on a pull).</summary>
    public string? Strategy { get; set; }

    public Guid? UserId { get; set; }
    public string? DeviceId { get; set; }

    /// <summary>From the X-Network-Profile header: 4G, 3G, 2G or none.</summary>
    public string? NetworkProfile { get; set; }

    /// <summary>Changes received (push) — the "records sent" of the experiment.</summary>
    public int RecordsIn { get; set; }

    /// <summary>Records returned (pull).</summary>
    public int RecordsOut { get; set; }

    // Push outcome counts
    public int Applied { get; set; }
    public int Duplicates { get; set; }
    public int Merged { get; set; }
    public int Flagged { get; set; }
    public int Rejected { get; set; }

    /// <summary>Request body size (Content-Length).</summary>
    public long RequestBytes { get; set; }

    /// <summary>Response body size as written by the server.</summary>
    public long ResponseBytes { get; set; }

    /// <summary>Time inside the server, same value as the X-Server-Time-Ms header (plus serialisation).</summary>
    public int DurationMs { get; set; }

    public int StatusCode { get; set; }
    public bool Success { get; set; }
}
