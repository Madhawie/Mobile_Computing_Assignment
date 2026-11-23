using LittleBloom.Application.Sync;
using LittleBloom.Domain.Entities;

namespace LittleBloom.Tests;

public class PullPagerTests
{
    private static readonly EntityInfo MotherInfo = EntityRegistry.Find("mother")!;
    private static readonly EntityInfo ChildInfo = EntityRegistry.Find("child")!;

    private static PullCandidate M(long seq) => new(MotherInfo, new Mother
    {
        Id = Guid.NewGuid(), Version = 1, DeviceId = "d", ChangeSeq = seq, FullName = "x", Phone = "+94700000000", Age = 25, AreaId = "glg-east",
    });

    private static PullCandidate C(long seq) => new(ChildInfo, new Child
    {
        Id = Guid.NewGuid(), Version = 1, DeviceId = "d", ChangeSeq = seq, MotherId = Guid.NewGuid(), Name = "y", Sex = "girl", BirthWeightKg = 3,
    });

    [Fact]
    public void Rows_from_all_tables_come_back_in_change_order()
    {
        var page = PullPager.Page([C(5), M(2), C(3), M(9)], since: 0, limit: 10);

        Assert.Equal(new[] { "mother", "child", "child", "mother" }, page.Changes.Select(c => c.Entity));
        Assert.Equal(9, page.Cursor);
        Assert.False(page.HasMore);
    }

    [Fact]
    public void Full_page_sets_cursor_to_last_row_and_has_more()
    {
        var page = PullPager.Page([M(1), M(2), C(3), C(4)], since: 0, limit: 3);

        Assert.Equal(3, page.Changes.Count);
        Assert.Equal(3, page.Cursor);
        Assert.True(page.HasMore);
    }

    [Fact]
    public void Nothing_new_keeps_the_cursor()
    {
        var page = PullPager.Page([M(4)], since: 4, limit: 10);

        Assert.Empty(page.Changes);
        Assert.Equal(4, page.Cursor);
        Assert.False(page.HasMore);
    }

    [Fact]
    public void Server_only_fields_are_not_sent_to_the_phone()
    {
        var page = PullPager.Page([M(7)], since: 0, limit: 10);
        var record = page.Changes.Single().Record;

        Assert.False(record.ContainsKey("changeSeq"));
        Assert.False(record.ContainsKey("scopeAreaId"));
        Assert.True(record.ContainsKey("fullName"));
    }
}
