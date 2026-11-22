using LittleBloom.Application.Auth;
using Microsoft.Extensions.Logging;

namespace LittleBloom.Infrastructure.Sms;

/// <summary>
/// Development SMS sender: writes the code to the server console instead of sending an SMS.
/// Free, and no real phone numbers are needed. A real gateway would implement IOtpSender too.
/// </summary>
public class LogOtpSender : IOtpSender
{
    private readonly ILogger<LogOtpSender> _logger;

    public LogOtpSender(ILogger<LogOtpSender> logger) => _logger = logger;

    public Task SendAsync(string phone, string code, CancellationToken ct = default)
    {
        _logger.LogWarning("DEV SMS to {Phone}: your Little Bloom code is {Code}", phone, code);
        return Task.CompletedTask;
    }
}
