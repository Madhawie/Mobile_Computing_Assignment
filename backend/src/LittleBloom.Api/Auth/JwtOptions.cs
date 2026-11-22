namespace LittleBloom.Api.Auth;

/// <summary>JWT settings from the "Jwt" section. The signing key is NOT in git (see backend/README.md).</summary>
public class JwtOptions
{
    public string Issuer { get; set; } = "little-bloom-api";
    public string Audience { get; set; } = "little-bloom-app";

    /// <summary>At least 32 characters. Set with: dotnet user-secrets set "Jwt:SigningKey" "...".</summary>
    public string SigningKey { get; set; } = string.Empty;
}
