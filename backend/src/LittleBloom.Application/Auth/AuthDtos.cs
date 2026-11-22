namespace LittleBloom.Application.Auth;

// Request and response bodies of /api/auth/* (api.md section 9). Serialised in camelCase.

public record OtpRequestBody(string Phone);

public record OtpRequestResponse(Guid OtpRequestId, int ExpiresInSeconds);

public record OtpVerifyBody(Guid OtpRequestId, string Code, string DeviceId);

public record RefreshBody(string RefreshToken, string DeviceId);

public record UserDto(Guid Id, string Role, string Name, string? AreaId, string MohId, Guid? MotherId);

public record AuthResponse(string AccessToken, int ExpiresIn, string RefreshToken, UserDto User);
