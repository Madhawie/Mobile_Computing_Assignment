using LittleBloom.Domain.Entities;

namespace LittleBloom.Application.Sync;

/// <summary>A candidate row for a pull page: which table it came from and the record.</summary>
public record PullCandidate(EntityInfo Info, SyncEntity Record);

/// <summary>
/// Builds one pull page from the five tables.
/// Each table gives its first (limit + 1) rows after the cursor, in ChangeSeq order.
/// Merging those and taking the first <c>limit</c> by ChangeSeq gives exactly the same page
/// as one query over all tables would, because no table can add a row that sorts earlier.
/// The extra row tells us whether another page is waiting (HasMore).
/// </summary>
public static class PullPager
{
    public static PullResponse Page(IEnumerable<PullCandidate> candidates, long since, int limit)
    {
        var ordered = candidates
            .Where(c => c.Record.ChangeSeq > since)
            .OrderBy(c => c.Record.ChangeSeq)
            .ToList();

        var page = ordered.Take(limit).ToList();
        var cursor = page.Count > 0 ? page[^1].Record.ChangeSeq : since;

        var changes = page
            .Select(c => new PulledChange(c.Info.Name, SyncJson.ToJson(c.Record, c.Info.ClrType)))
            .ToList();

        return new PullResponse(changes, cursor, HasMore: ordered.Count > limit);
    }
}
