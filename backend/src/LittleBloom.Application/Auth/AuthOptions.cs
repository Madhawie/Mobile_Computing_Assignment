namespace LittleBloom.Application.Auth;

/// <summary>Sign-in settings, read from the "Auth" section of appsettings.json.</summary>
public class AuthOptions
{
    /// <summary>Access token lifetime. 12 h, so a PHM can work a full day offline.</summary>
    public int AccessTokenMinutes { get; set; } = 720;

    public int RefreshTokenDays { get; set; } = 30;

    public int OtpLifetimeSeconds { get; set; } = 300;

    /// <summary>Maximum code requests per phone in 10 minutes (stops SMS spam).</summary>
    public int MaxOtpRequestsPer10Min { get; set; } = 5;

    /// <summary>Development only: accept "000000" as a valid code. Must be false in production.</summary>
    public bool AcceptDevCode { get; set; }
}
