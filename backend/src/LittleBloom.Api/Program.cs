// Entry point of the Little Bloom API: registers services, then sets up the request pipeline.
using System.Security.Cryptography;
using LittleBloom.Api.Auth;
using LittleBloom.Api.Errors;
using LittleBloom.Application.Auth;
using LittleBloom.Application.Common;
using LittleBloom.Infrastructure;
using LittleBloom.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// ---------- Services

builder.Services.AddOpenApi(); // /openapi/v1.json in Development, handy for Postman

// Errors as RFC 7807 ProblemDetails with our "code" (api.md section 10).
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<AppExceptionHandler>();

builder.Services.AddControllers().ConfigureApiBehaviorOptions(o =>
{
    // Bad JSON or a missing field → 400 VALIDATION_FAILED, same shape as every other error.
    o.InvalidModelStateResponseFactory = context =>
    {
        var problem = new ValidationProblemDetails(context.ModelState) { Status = 400, Title = "Validation failed" };
        problem.Extensions["code"] = ErrorCodes.ValidationFailed;
        return new BadRequestObjectResult(problem) { ContentTypes = { "application/problem+json" } };
    };
});

// SQL Server. Windows Authentication, so the connection string holds no password.
// Change "Server=" in appsettings.json if SSMS connects with another server name.
var connectionString = builder.Configuration.GetConnectionString("LittleBloom") ?? string.Empty;
builder.Services.AddInfrastructure(connectionString);

// Sign-in settings.
var authOptions = builder.Configuration.GetSection("Auth").Get<AuthOptions>() ?? new AuthOptions();
builder.Services.AddSingleton(authOptions);

var jwtOptions = builder.Configuration.GetSection("Jwt").Get<JwtOptions>() ?? new JwtOptions();
var generatedKey = string.IsNullOrWhiteSpace(jwtOptions.SigningKey);
if (generatedKey)
{
    // No key configured: make a random one. Works, but every restart signs everyone out.
    jwtOptions.SigningKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
}
builder.Services.AddSingleton(jwtOptions);
builder.Services.AddSingleton<ITokenService, JwtTokenService>();

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.MapInboundClaims = false; // keep "sub", "role" ... as they are in the token
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtOptions.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = JwtTokenService.CreateKey(jwtOptions.SigningKey),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1),
            RoleClaimType = ClaimNames.Role,
            NameClaimType = ClaimNames.Sub,
        };
        o.Events = new JwtBearerEvents
        {
            // 401 with TOKEN_EXPIRED (phone calls /refresh) or UNAUTHORIZED (phone asks to sign in).
            OnChallenge = async context =>
            {
                context.HandleResponse();
                var expired = context.AuthenticateFailure is SecurityTokenExpiredException;
                await AppExceptionHandler.WriteProblemAsync(context.HttpContext, 401,
                    expired ? ErrorCodes.TokenExpired : ErrorCodes.Unauthorized,
                    expired ? "Token expired" : "Sign-in required");
            },
            // 403 FORBIDDEN: signed in, but the role may not do this (e.g. a mother pushing).
            OnForbidden = context => AppExceptionHandler.WriteProblemAsync(context.HttpContext, 403,
                ErrorCodes.Forbidden, "Your role may not do this"),
        };
    });
builder.Services.AddAuthorization();

// ---------- Pipeline

var app = builder.Build();

if (generatedKey)
{
    app.Logger.LogWarning("Jwt:SigningKey is not set, using a random key. Tokens stop working after a restart.");
}

// Development: add made-up staff accounts so sign-in works right away (appsettings.Development.json).
if (app.Configuration.GetValue<bool>("Seed:DevUsers"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await DevDataSeeder.SeedAsync(db, app.Logger);
}

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseAuthentication();
app.UseAuthorization();

// Lets the phone (and us) check that the server is reachable before syncing.
// No sign-in needed: it returns no patient data.
app.MapGet("/api/health", () => Results.Ok(new HealthResponse("ok", DateTime.UtcNow)))
   .WithName("Health")
   .AllowAnonymous();

app.MapControllers();

app.Run();

/// <summary>Body of GET /api/health. Serialised as {"status":"ok","serverTime":"...Z"}.</summary>
public record HealthResponse(string Status, DateTime ServerTime);

// Top-level statements create a hidden Program class.
// Declaring it public lets the test project start the API in memory (WebApplicationFactory<Program>).
public partial class Program { }
