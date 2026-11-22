namespace LittleBloom.Domain.Enums;

public enum ConflictStatus
{
    /// <summary>Waiting for a person to check it ("Check a record" screen).</summary>
    Open = 1,

    /// <summary>A person chose which value to keep.</summary>
    Resolved = 2,
}
