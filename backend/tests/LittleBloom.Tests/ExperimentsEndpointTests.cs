using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace LittleBloom.Tests;

public class ExperimentsEndpointTests : IClassFixture<TestApiFactory>
{
    private readonly HttpClient _client;

    public ExperimentsEndpointTests(TestApiFactory factory) => _client = factory.CreateClient();

    [Theory]
    [InlineData("GET", "/api/experiments/stats")]
    [InlineData("POST", "/api/experiments/reset")]
    [InlineData("GET", "/api/experiments/sync-log.csv")]
    public async Task Experiment_endpoints_need_a_signed_in_admin(string method, string path)
    {
        var response = await _client.SendAsync(new HttpRequestMessage(new HttpMethod(method), path));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("UNAUTHORIZED", problem.GetProperty("code").GetString());
    }
}
