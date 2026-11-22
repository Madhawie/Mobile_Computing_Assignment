using System.Diagnostics;
using System.Text.Json;
using LittleBloom.Application.Common;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace LittleBloom.Api.Errors;

/// <summary>
/// Turns any exception into a ProblemDetails response with our "code" (api.md section 10):
/// AppException keeps its status and code; anything else becomes 500 SERVER_ERROR
/// (the phone retries those with backoff).
/// </summary>
public class AppExceptionHandler : IExceptionHandler
{
    private readonly ILogger<AppExceptionHandler> _logger;

    public AppExceptionHandler(ILogger<AppExceptionHandler> logger) => _logger = logger;

    public async ValueTask<bool> TryHandleAsync(HttpContext http, Exception exception, CancellationToken ct)
    {
        int status;
        string code, title;

        if (exception is AppException app)
        {
            (status, code, title) = (app.StatusCode, app.Code, app.Message);
            if (app.RetryAfterSeconds is int seconds)
                http.Response.Headers.RetryAfter = seconds.ToString();
        }
        else
        {
            (status, code, title) = (500, ErrorCodes.ServerError, "Server error");
            _logger.LogError(exception, "Unhandled error on {Path}", http.Request.Path);
        }

        await WriteProblemAsync(http, status, code, title, ct);
        return true;
    }

    /// <summary>Also used by the JWT events for 401 and 403.</summary>
    public static Task WriteProblemAsync(HttpContext http, int status, string code, string title, CancellationToken ct = default)
    {
        var problem = new ProblemDetails { Type = "about:blank", Title = title, Status = status };
        problem.Extensions["code"] = code;
        problem.Extensions["traceId"] = Activity.Current?.Id ?? http.TraceIdentifier;

        http.Response.StatusCode = status;
        return http.Response.WriteAsJsonAsync(problem, (JsonSerializerOptions?)null, "application/problem+json", ct);
    }
}
