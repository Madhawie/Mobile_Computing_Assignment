// Entry point of the Little Bloom API.
// Day 1: only a health check. Database, auth and sync endpoints are added in later steps.

var builder = WebApplication.CreateBuilder(args);

// Describes the API at /openapi/v1.json (Development only), handy for Postman.
builder.Services.AddOpenApi();

// Error responses use the RFC 7807 ProblemDetails format (see docs/architecture/api.md, section 10).
builder.Services.AddProblemDetails();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Lets the phone (and us) check that the server is reachable before syncing.
// No sign-in needed: it returns no patient data.
app.MapGet("/api/health", () => Results.Ok(new HealthResponse("ok", DateTime.UtcNow)))
   .WithName("Health");

app.Run();

/// <summary>Body of GET /api/health. Serialised as {"status":"ok","serverTime":"...Z"}.</summary>
public record HealthResponse(string Status, DateTime ServerTime);

// Top-level statements create a hidden Program class.
// Declaring it public lets the test project start the API in memory (WebApplicationFactory<Program>).
public partial class Program { }
