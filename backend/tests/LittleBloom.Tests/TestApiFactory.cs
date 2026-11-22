using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace LittleBloom.Tests;

/// <summary>
/// Starts the API in memory for tests, in the "Testing" environment, so
/// appsettings.Development.json is not loaded (no dev seeding, no SQL Server needed).
/// </summary>
public class TestApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
    }
}
