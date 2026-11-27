using LittleBloom.Api.Metrics;

namespace LittleBloom.Tests;

public class MeasurementTests : IClassFixture<TestApiFactory>
{
    private readonly HttpClient _client;

    public MeasurementTests(TestApiFactory factory) => _client = factory.CreateClient();

    [Fact]
    public async Task Every_response_carries_the_server_time_header()
    {
        var response = await _client.GetAsync("/api/health");

        Assert.True(response.Headers.TryGetValues(MeasurementMiddleware.ServerTimeHeader, out var values));
        Assert.True(long.TryParse(values!.Single(), out var ms));
        Assert.True(ms >= 0);
    }

    [Fact]
    public async Task Counting_stream_counts_every_byte_written()
    {
        using var inner = new MemoryStream();
        var counter = new CountingStream(inner);

        counter.Write(new byte[10], 0, 10);
        await counter.WriteAsync(new byte[5].AsMemory());
        counter.Write(new byte[3].AsSpan());

        Assert.Equal(18, counter.BytesWritten);
        Assert.Equal(18, inner.Length);
    }
}
