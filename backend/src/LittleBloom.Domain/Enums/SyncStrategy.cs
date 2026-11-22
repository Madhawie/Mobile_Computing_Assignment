namespace LittleBloom.Domain.Enums;

/// <summary>
/// The three sync strategies compared in the experiments.
/// The phone sends which one it uses in every push, so one server can serve all three.
/// </summary>
public enum SyncStrategy
{
    /// <summary>Full sync: phone sends every record; last upload wins.</summary>
    S1 = 1,

    /// <summary>Delta sync: phone sends only changed records; last upload wins.</summary>
    S2 = 2,

    /// <summary>Versioned delta: only changed records plus versions; server detects and merges conflicts.</summary>
    S3 = 3,
}
