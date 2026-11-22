using LittleBloom.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace LittleBloom.Infrastructure;

/// <summary>
/// Registers everything the Infrastructure layer provides, so Program.cs needs one line.
/// </summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, string connectionString)
    {
        // No EnableRetryOnFailure: push uses its own transactions, and EF's retry strategy
        // does not allow that. The phone already retries a failed batch (api.md section 10).
        services.AddDbContext<AppDbContext>(options => options.UseSqlServer(connectionString));

        return services;
    }
}
