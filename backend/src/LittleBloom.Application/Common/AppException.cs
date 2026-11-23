namespace LittleBloom.Application.Common;

/// <summary>
/// An error the client should see, with the HTTP status and the "code" from api.md section 10.
/// The Api layer turns it into a ProblemDetails response, so services never deal with HTTP directly.
/// </summary>
public class AppException : Exception
{
    public int StatusCode { get; }
    public string Code { get; }

    /// <summary>Seconds the client should wait (sent as the Retry-After header), for 429.</summary>
    public int? RetryAfterSeconds { get; init; }

    public AppException(int statusCode, string code, string message) : base(message)
    {
        StatusCode = statusCode;
        Code = code;
    }
}

/// <summary>Error codes shared by the server and the phone (api.md section 10).</summary>
public static class ErrorCodes
{
    public const string ValidationFailed = "VALIDATION_FAILED";
    public const string TokenExpired = "TOKEN_EXPIRED";
    public const string Unauthorized = "UNAUTHORIZED";
    public const string Forbidden = "FORBIDDEN";
    public const string PhoneNotRegistered = "PHONE_NOT_REGISTERED";
    public const string BatchTooLarge = "BATCH_TOO_LARGE";
    public const string TooManyRequests = "TOO_MANY_REQUESTS";
    public const string ServerError = "SERVER_ERROR";
    public const string ServerBusy = "SERVER_BUSY";
    public const string NotFound = "NOT_FOUND";
    public const string AlreadyResolved = "ALREADY_RESOLVED";
    public const string PhoneAlreadyRegistered = "PHONE_ALREADY_REGISTERED";

    // Per-change errors inside a push response
    public const string UnknownEntity = "UNKNOWN_ENTITY";
    public const string InvalidField = "INVALID_FIELD";
    public const string ParentNotFound = "PARENT_NOT_FOUND";
    public const string OutOfArea = "OUT_OF_AREA";
}
