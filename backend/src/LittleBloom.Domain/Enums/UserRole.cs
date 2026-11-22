namespace LittleBloom.Domain.Enums;

/// <summary>Who is signed in. Decides what they may pull and push (api.md section 9.5).</summary>
public enum UserRole
{
    Mother = 1,
    Phm = 2,
    Supervisor = 3,
    Admin = 4,
}
