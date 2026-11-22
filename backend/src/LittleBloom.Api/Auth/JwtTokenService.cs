using System.Text;
using LittleBloom.Application.Auth;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace LittleBloom.Api.Auth;

/// <summary>
/// Creates the signed access token. The claims are what the server later uses to decide
/// what the user may sync (api.md section 9.5): sub, role, areaId, mohId, motherId.
/// HMAC-SHA256 with one secret key: the server both signs and checks, so no key pair is needed.
/// </summary>
public class JwtTokenService : ITokenService
{
    private readonly JwtOptions _options;

    public JwtTokenService(JwtOptions options) => _options = options;

    public static SymmetricSecurityKey CreateKey(string signingKey) => new(Encoding.UTF8.GetBytes(signingKey));

    public string CreateAccessToken(UserDto user, TimeSpan lifetime)
    {
        var claims = new Dictionary<string, object>
        {
            [ClaimNames.Sub] = user.Id.ToString(),
            [ClaimNames.Role] = user.Role,
            [ClaimNames.MohId] = user.MohId,
            [ClaimNames.Name] = user.Name,
        };
        if (user.AreaId is not null) claims[ClaimNames.AreaId] = user.AreaId;
        if (user.MotherId is not null) claims[ClaimNames.MotherId] = user.MotherId.Value.ToString();

        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = _options.Issuer,
            Audience = _options.Audience,
            Claims = claims,
            IssuedAt = DateTime.UtcNow,
            Expires = DateTime.UtcNow.Add(lifetime),
            SigningCredentials = new SigningCredentials(CreateKey(_options.SigningKey), SecurityAlgorithms.HmacSha256),
        };

        return new JsonWebTokenHandler().CreateToken(descriptor);
    }
}

/// <summary>Claim names inside the JWT. Short names, same as in api.md.</summary>
public static class ClaimNames
{
    public const string Sub = "sub";
    public const string Role = "role";
    public const string Name = "name";
    public const string AreaId = "areaId";
    public const string MohId = "mohId";
    public const string MotherId = "motherId";
}
