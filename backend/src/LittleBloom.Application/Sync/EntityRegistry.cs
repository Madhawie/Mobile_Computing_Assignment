using LittleBloom.Domain.Entities;

namespace LittleBloom.Application.Sync;

/// <summary>Facts about one synced record type.</summary>
/// <param name="Name">The "entity" value in the API, e.g. "growthMeasurement".</param>
/// <param name="ParentType">The record this one belongs to (null for mother).</param>
/// <param name="ParentIdOf">Reads the parent id from a record, e.g. a child's MotherId.</param>
public record EntityInfo(string Name, Type ClrType, Type? ParentType, Func<SyncEntity, Guid>? ParentIdOf);

/// <summary>
/// The five record types the phone may sync (api.md section 3).
/// A child or visit belongs to a mother, a growth check or vaccine to a child.
/// The area of every record comes from its mother, so "PHM sees only her area" works for all of them.
/// </summary>
public static class EntityRegistry
{
    private static readonly Dictionary<string, EntityInfo> ByName = new(StringComparer.Ordinal)
    {
        ["mother"] = new("mother", typeof(Mother), null, null),
        ["maternalVisit"] = new("maternalVisit", typeof(MaternalVisit), typeof(Mother), e => ((MaternalVisit)e).MotherId),
        ["child"] = new("child", typeof(Child), typeof(Mother), e => ((Child)e).MotherId),
        ["growthMeasurement"] = new("growthMeasurement", typeof(GrowthMeasurement), typeof(Child), e => ((GrowthMeasurement)e).ChildId),
        ["vaccination"] = new("vaccination", typeof(Vaccination), typeof(Child), e => ((Vaccination)e).ChildId),
    };

    public static IEnumerable<EntityInfo> All => ByName.Values;

    public static EntityInfo? Find(string? name) =>
        name is not null && ByName.TryGetValue(name, out var info) ? info : null;

    public static EntityInfo ForType(Type type) => ByName.Values.First(i => i.ClrType == type);
}
