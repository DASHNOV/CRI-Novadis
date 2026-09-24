using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Services.Email;

namespace NovadisApi.Tests;

public class NovadisWebApplicationFactory : WebApplicationFactory<Program>
{
    // Guid généré UNE SEULE FOIS par instance de factory.
    // Si on utilisait Guid.NewGuid() dans le lambda de ConfigureServices,
    // EF Core l'appellerait à chaque création de DbContext → chaque scope
    // obtiendrait une DB différente et les données du seeder seraient invisibles
    // aux requêtes HTTP.
    private readonly string _dbName = "TestDb_" + Guid.NewGuid();

    public NovadisWebApplicationFactory()
    {
        // Définir les variables d'environnement AVANT que le host ne soit construit,
        // car Program.cs lit Jwt:SecretKey via builder.Configuration avant que
        // ConfigureAppConfiguration ne soit appliqué.
        Environment.SetEnvironmentVariable("Jwt:SecretKey", "test-secret-key-minimum-32-characters-long-for-hmac");
        Environment.SetEnvironmentVariable("Jwt:Issuer", "test-issuer");
        Environment.SetEnvironmentVariable("Jwt:Audience", "test-audience");
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Indique à ASP.NET Core qu'on est en environnement de test
        builder.UseEnvironment("Test");

        builder.ConfigureServices(services =>
        {
            // 1. Supprimer l'enregistrement Npgsql existant. Depuis EF Core 9, la configuration
            //    du fournisseur vit aussi dans IDbContextOptionsConfiguration<T> : retirer les
            //    seules options laissait UseNpgsql actif à côté d'InMemory (« two providers »).
            services.RemoveAll<DbContextOptions<NovadisDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<NovadisDbContext>>();
            
            // 2. Le remplacement par une base en mémoire, unique par instance de factory
            services.AddDbContext<NovadisDbContext>(options =>
                options.UseInMemoryDatabase(_dbName));
            
            // 3. Remplacer le service email par un faux qui ne fait rien
            var emailDescriptor = services.SingleOrDefault(d => d.ServiceType == typeof(IEmailService));
            if (emailDescriptor != null)
                services.Remove(emailDescriptor);

            services.AddScoped<IEmailService, FakeEmailService>();
        });
    }
}

// Service email factice — ne fait rien, n'envoie aucun vrai email
public class FakeEmailService : IEmailService
{
    public Task SendAuthCodeEmailAsync(string toEmail, string code, string magicLink) => Task.CompletedTask;
    public Task SendWelcomeEmailAsync(string toEmail, string firstName) => Task.CompletedTask;
    public Task SendEmailAsync(string toEmail, string subject, string htmlBody) => Task.CompletedTask;
}