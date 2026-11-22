using System.Net;
using System.Net.Http.Json;

namespace LittleBloom.Tests;

// Starts the real API in memory (no network port, no database) and calls it like the phone would.
public class HealthEndpointTests : IClassFixture<TestApiFactory>
{
    private readonly HttpClient _client;

    public HealthEndpointTests(TestApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Health_returns_200_and_status_ok()
    {
        var response = await _client.GetAsync("/api/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<HealthResponse>();
        Assert.NotNull(body);
        Assert.Equal("ok", body.Status);
    }

    [Fact]
    public async Task Otp_request_with_empty_phone_returns_400_problem()
    {
        // An empty phone fails validation before any database call, so no SQL Server is needed.
        var response = await _client.PostAsync("/api/auth/otp/request", JsonContent.Create(new { phone = "" }));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
    }
}
