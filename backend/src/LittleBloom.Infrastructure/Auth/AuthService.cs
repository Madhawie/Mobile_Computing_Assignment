using System.Security.Cryptography;
using System.Text;
using LittleBloom.Application.Auth;
using LittleBloom.Application.Common;
using LittleBloom.Domain.Entities;
using LittleBloom.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LittleBloom.Infrastructure.Auth;

/// <summary>
/// Phone number + SMS code sign-in (api.md section 9).
/// 1. RequestOtp: check the number is registered, send a 6-digit code, store only its hash.
/// 2. VerifyOtp: check the code, then issue an access token (JWT, 12 h) and a refresh token (30 days).
/// 3. Refresh: swap a refresh token for new tokens. The old refresh token is revoked (rotation).
/// </summary>
public class AuthService : IAuthService
{
    private const int MaxCodeAttempts = 5;
    private const string DevCode = "000000";

    private readonly AppDbContext _db;
    private readonly IOtpSender _sender;
    private readonly ITokenService _tokens;
    private readonly AuthOptions _options;

    public AuthService(AppDbContext db, IOtpSender sender, ITokenService tokens, AuthOptions options)
    {
        _db = db;
        _sender = sender;
        _tokens = tokens;
        _options = options;
    }

    public async Task<OtpRequestResponse> RequestOtpAsync(string phone, CancellationToken ct = default)
    {
        var normalized = PhoneNumber.Normalize(phone);
        if (normalized.Length == 0)
            throw new AppException(400, ErrorCodes.ValidationFailed, "Phone number is required.");

        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Phone == normalized, ct);
        if (user is null || !user.IsActive)
            throw new AppException(404, ErrorCodes.PhoneNotRegistered, "This phone number is not registered.");

        // Simple rate limit, so nobody can make the server send hundreds of SMS.
        var since = DateTime.UtcNow.AddMinutes(-10);
        var recent = await _db.OtpRequests.CountAsync(o => o.Phone == normalized && o.CreatedAt > since, ct);
        if (recent >= _options.MaxOtpRequestsPer10Min)
            throw new AppException(429, ErrorCodes.TooManyRequests, "Too many codes requested. Try again later.")
            {
                RetryAfterSeconds = 600,
            };

        var request = new OtpRequest
        {
            Id = Guid.NewGuid(),
            Phone = normalized,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddSeconds(_options.OtpLifetimeSeconds),
        };
        var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        request.CodeHash = Hash(request.Id + ":" + code);

        _db.OtpRequests.Add(request);
        await _db.SaveChangesAsync(ct);
        await _sender.SendAsync(normalized, code, ct);

        return new OtpRequestResponse(request.Id, _options.OtpLifetimeSeconds);
    }

    public async Task<AuthResponse> VerifyOtpAsync(OtpVerifyBody body, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(body.Code) || string.IsNullOrWhiteSpace(body.DeviceId))
            throw new AppException(400, ErrorCodes.ValidationFailed, "code and deviceId are required.");

        var request = await _db.OtpRequests.FirstOrDefaultAsync(o => o.Id == body.OtpRequestId, ct);
        if (request is null || request.UsedAt is not null || request.ExpiresAt < DateTime.UtcNow
            || request.Attempts >= MaxCodeAttempts)
            throw new AppException(401, ErrorCodes.Unauthorized, "The code has expired or is not valid. Request a new one.");

        var correct = FixedTimeEquals(request.CodeHash, Hash(request.Id + ":" + body.Code))
                      || (_options.AcceptDevCode && body.Code == DevCode);
        if (!correct)
        {
            request.Attempts++;
            await _db.SaveChangesAsync(ct);
            throw new AppException(401, ErrorCodes.Unauthorized, "Wrong code.");
        }

        request.UsedAt = DateTime.UtcNow; // a code works only once

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Phone == request.Phone && u.IsActive, ct)
                   ?? throw new AppException(401, ErrorCodes.Unauthorized, "This account is blocked.");

        return await IssueTokensAsync(user, body.DeviceId, ct);
    }

    public async Task<AuthResponse> RefreshAsync(RefreshBody body, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(body.RefreshToken))
            throw new AppException(401, ErrorCodes.Unauthorized, "Refresh token is required.");

        var hash = Hash(body.RefreshToken);
        var token = await _db.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == hash, ct);
        if (token is null || token.RevokedAt is not null || token.ExpiresAt < DateTime.UtcNow
            || token.DeviceId != body.DeviceId)
            throw new AppException(401, ErrorCodes.Unauthorized, "Please sign in again.");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == token.UserId && u.IsActive, ct)
                   ?? throw new AppException(401, ErrorCodes.Unauthorized, "This account is blocked.");

        token.RevokedAt = DateTime.UtcNow; // rotation: each refresh token works once
        return await IssueTokensAsync(user, body.DeviceId, ct);
    }

    private async Task<AuthResponse> IssueTokensAsync(User user, string deviceId, CancellationToken ct)
    {
        var dto = ToDto(user);
        var lifetime = TimeSpan.FromMinutes(_options.AccessTokenMinutes);
        var accessToken = _tokens.CreateAccessToken(dto, lifetime);

        // The phone keeps the plain token in secure storage; the server keeps only its hash.
        var refreshPlain = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
            .Replace('+', '-').Replace('/', '_').TrimEnd('=');
        _db.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = Hash(refreshPlain),
            DeviceId = deviceId,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(_options.RefreshTokenDays),
        });
        await _db.SaveChangesAsync(ct);

        return new AuthResponse(accessToken, (int)lifetime.TotalSeconds, refreshPlain, dto);
    }

    public static UserDto ToDto(User u) =>
        new(u.Id, u.Role.ToString().ToLowerInvariant(), u.Name, u.AreaId, u.MohId, u.MotherId);

    private static string Hash(string value) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));

    // Compares in constant time, so the response time does not leak how much of the code was right.
    private static bool FixedTimeEquals(string a, string b) =>
        CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(a), Encoding.UTF8.GetBytes(b));
}
