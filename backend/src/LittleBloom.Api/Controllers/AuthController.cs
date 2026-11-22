using LittleBloom.Application.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LittleBloom.Api.Controllers;

/// <summary>
/// Sign-in endpoints (api.md section 9). The only endpoints that work without a token.
/// The controller only translates HTTP to the service; the rules live in AuthService.
/// </summary>
[ApiController]
[Route("api/auth")]
[AllowAnonymous]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;

    public AuthController(IAuthService auth) => _auth = auth;

    /// <summary>Send a 6-digit code to a registered phone. 202, or 404 PHONE_NOT_REGISTERED.</summary>
    [HttpPost("otp/request")]
    public async Task<ActionResult<OtpRequestResponse>> RequestOtp(OtpRequestBody body, CancellationToken ct)
        => Accepted(await _auth.RequestOtpAsync(body.Phone, ct));

    /// <summary>Check the code and sign in. Returns access token, refresh token and the user.</summary>
    [HttpPost("otp/verify")]
    public async Task<ActionResult<AuthResponse>> VerifyOtp(OtpVerifyBody body, CancellationToken ct)
        => Ok(await _auth.VerifyOtpAsync(body, ct));

    /// <summary>Swap a refresh token for new tokens (when the access token expired).</summary>
    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> Refresh(RefreshBody body, CancellationToken ct)
        => Ok(await _auth.RefreshAsync(body, ct));
}
