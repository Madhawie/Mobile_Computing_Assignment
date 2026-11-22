namespace LittleBloom.Application.Auth;

/// <summary>Sign-in with phone number + SMS code, and token refresh (api.md section 9).</summary>
public interface IAuthService
{
    Task<OtpRequestResponse> RequestOtpAsync(string phone, CancellationToken ct = default);

    Task<AuthResponse> VerifyOtpAsync(OtpVerifyBody body, CancellationToken ct = default);

    Task<AuthResponse> RefreshAsync(RefreshBody body, CancellationToken ct = default);
}

/// <summary>Sends the SMS code. In development it only writes the code to the server log.</summary>
public interface IOtpSender
{
    Task SendAsync(string phone, string code, CancellationToken ct = default);
}

/// <summary>Creates the signed JWT access token. Implemented in the Api layer.</summary>
public interface ITokenService
{
    string CreateAccessToken(UserDto user, TimeSpan lifetime);
}
