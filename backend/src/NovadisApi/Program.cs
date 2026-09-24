using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using NovadisApi.Data;
using NovadisApi.Middleware;
using NovadisApi.Models;
using NovadisApi.Services;
using NovadisApi.Services.Auth;
using NovadisApi.Services.Email;
using NovadisApi.Services.Export;
using NovadisApi.Services.Maintenance;
using NovadisApi.Services.Storage;
using Serilog;
using Serilog.Events;
using System.Globalization;
using System.Text;
using System.Threading.RateLimiting;
using NovadisApi.Authorization;

// Traite les DateTime sans Kind comme UTC — compatibilité SQL Server → PostgreSQL
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

// Charger les variables d'environnement depuis le fichier .env (secrets)
var envPath = Path.Combine(Directory.GetCurrentDirectory(), ".env");
if (File.Exists(envPath))
{
    foreach (var line in File.ReadAllLines(envPath))
    {
        if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#')) continue;
        var separatorIndex = line.IndexOf('=');
        if (separatorIndex <= 0) continue;
        var key = line[..separatorIndex].Trim();
        var value = line[(separatorIndex + 1)..].Trim();
        Environment.SetEnvironmentVariable(key, value);
    }
}

// Recharger la configuration pour inclure les variables d'environnement
builder.Configuration.AddEnvironmentVariables();

// ========================================
// 1️⃣ CONFIGURATION DE LA BASE DE DONNÉES
// ========================================
builder.Services.AddDbContext<NovadisDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions => npgsqlOptions.EnableRetryOnFailure(
            maxRetryCount: 3,
            maxRetryDelay: TimeSpan.FromSeconds(5),
            errorCodesToAdd: null
        )
    )
);

// ========================================
// 2️⃣ CONFIGURATION JWT
// ========================================
var jwtSecretKey = builder.Configuration["Jwt:SecretKey"] 
    ?? throw new InvalidOperationException("JWT SecretKey not configured");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero // Pas de tolérance sur l'expiration
    };

    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            if (context.Exception.GetType() == typeof(SecurityTokenExpiredException))
            {
                context.Response.Headers.Append("Token-Expired", "true");
            }
            return Task.CompletedTask;
        }
    };
});

// Une policy par capacité, générée depuis la table Capabilities (source unique).
builder.Services.AddAuthorization(options =>
{
    foreach (var (capability, roles) in Capabilities.RolesByCapability)
        options.AddPolicy(capability, policy => policy.RequireRole(roles));
});

// ========================================
// 3️⃣ CONFIGURATION CORS
// ========================================
var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? Array.Empty<string>();
var isDev = builder.Environment.IsDevelopment();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowMobileApp", policy =>
    {
        policy.SetIsOriginAllowed(origin =>
        {
            if (string.IsNullOrEmpty(origin)) return false;

            // Origines configurées (prod + dev fixes)
            if (allowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase))
                return true;

            // En développement : autoriser tout localhost/127.0.0.1/IP locale (port aléatoire de Flutter)
            if (isDev && Uri.TryCreate(origin, UriKind.Absolute, out var uri))
            {
                var host = uri.Host;
                if (host == "localhost" || host == "127.0.0.1") return true;
                if (host.StartsWith("192.168.") || host.StartsWith("10.")) return true;
            }

            // Pas de joker *.vercel.app : n'importe quel compte Vercel obtiendrait un canal
            // authentifié vers l'API. Une preview à autoriser s'ajoute explicitement
            // dans Cors:AllowedOrigins (variable d'environnement Cors__AllowedOrigins__N).

            return false;
        })
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials()
        .WithExposedHeaders("Token-Expired", "Content-Disposition",
            "X-Total-Count", "X-Page", "X-Page-Size", "X-Total-Pages");
    });
});

// ========================================
// 3️⃣b RATE LIMITING (anti brute-force OTP)
// ========================================
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    // Requêtes / minute / IP sur les endpoints d'auth (20 en dev, 5 en prod)
    var authPermitLimit = isDev ? 20 : 5;
    options.AddPolicy("AuthPolicy", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = authPermitLimit,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            }));

    // Limite globale de protection (100 req/min/IP)
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            }));
});

// ========================================
// 4️⃣ INJECTION DES SERVICES
// ========================================
builder.Services.AddMemoryCache();

// Services d'authentification
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<ICodeGeneratorService, CodeGeneratorService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<ISiteSummaryService, SiteSummaryService>();
builder.Services.AddScoped<NovadisApi.Services.Stats.IGlobalStatsService, NovadisApi.Services.Stats.GlobalStatsService>();
builder.Services.AddScoped<IXlsxExportService, XlsxExportService>();

// Stockage des exports (filesystem local, MinIO-ready)
builder.Services.AddSingleton<IObjectStorageService, LocalFileObjectStorage>();

// Gestionnaire d'exceptions global
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

// Purge RGPD automatique (BackgroundService quotidien)
builder.Services.AddHostedService<DataRetentionService>();

// Services métier (à ajouter plus tard)
// builder.Services.AddScoped<ICRIService, CRIService>();
// builder.Services.AddScoped<IUserService, UserService>();

// ========================================
// 5️⃣ CONFIGURATION SWAGGER
// ========================================
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Novadis CRI API",
        Version = "v1",
        Description = "API de gestion des Comptes Rendus d'Intervention",
        Contact = new OpenApiContact
        {
            Name = "Novadis Support",
            Email = "support@novadis.fr"
        }
    });

    // Configuration pour JWT dans Swagger
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    // Swashbuckle 10 / Microsoft.OpenApi 2 : référence au schéma via le document.
    c.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = []
    });
});

// ========================================
// 6️⃣ CONFIGURATION DES LOGS (Serilog : console + fichier rotatif)
// ========================================
var logsDir = Path.Combine(Directory.GetCurrentDirectory(), "logs");
Directory.CreateDirectory(logsDir);
Directory.CreateDirectory(Path.Combine(Directory.GetCurrentDirectory(), "uploads", "cri-photos"));

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.AspNetCore.Hosting.Diagnostics", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.EntityFrameworkCore", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "NovadisApi")
    .Enrich.WithProperty("Environment", builder.Environment.EnvironmentName)
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
    .WriteTo.File(
        path: Path.Combine(logsDir, "novadis-.log"),
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,                  // Rétention RGPD : 30 jours
        fileSizeLimitBytes: 50 * 1024 * 1024,        // 50 Mo / fichier
        rollOnFileSizeLimit: true,
        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
    .WriteTo.Logger(lc => lc
        .Filter.ByIncludingOnly(e => e.Level >= LogEventLevel.Error)
        .WriteTo.File(
            path: Path.Combine(logsDir, "errors-.log"),
            rollingInterval: RollingInterval.Day,
            retainedFileCountLimit: 90,
            outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}"))
    .CreateLogger();

builder.Host.UseSerilog();

// ========================================
// 7️⃣ CONFIGURATION RÉSEAU & HEALTH CHECKS
// ========================================
// ✅ Forcer l'écoute sur toutes les interfaces pour l'accès réseau local
builder.WebHost.UseUrls("http://0.0.0.0:5200");

// ✅ Ajouter les health checks
builder.Services.AddHealthChecks();

var app = builder.Build();

// Gestionnaire d'exceptions global (DOIT être en premier)
app.UseExceptionHandler();

// Forwarded headers (Cloudflare/IIS) pour récupérer la vraie IP cliente
var forwardedOptions = new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
};
forwardedOptions.KnownProxies.Clear();
app.UseForwardedHeaders(forwardedOptions);

// Headers de sécurité standards
app.Use(async (context, next) =>
{
    var headers = context.Response.Headers;
    headers["X-Content-Type-Options"] = "nosniff";
    headers["X-Frame-Options"] = "DENY";
    headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
    if (app.Environment.IsProduction())
    {
        headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains";
    }
    await next.Invoke();
});

// Request logging Serilog (compact, log seulement les requêtes >400ms ou en erreur)
app.UseSerilogRequestLogging(opts =>
{
    opts.MessageTemplate = "HTTP {RequestMethod} {RequestPath} → {StatusCode} en {Elapsed:0}ms";
    opts.GetLevel = (ctx, elapsed, ex) =>
        ex != null ? LogEventLevel.Error :
        ctx.Response.StatusCode >= 500 ? LogEventLevel.Error :
        ctx.Response.StatusCode >= 400 ? LogEventLevel.Warning :
        elapsed > 1000 ? LogEventLevel.Warning :
        LogEventLevel.Debug;  // Debug = filtré par MinimumLevel.Information
    opts.EnrichDiagnosticContext = (diagCtx, httpCtx) =>
    {
        diagCtx.Set("UserId", httpCtx.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anon");
    };
});

// ========================================
// 8️⃣ MIDDLEWARE PIPELINE
// ========================================

// Swagger : seulement en développement
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Novadis CRI API v1");
        c.RoutePrefix = string.Empty;
    });
}

// HTTPS Redirection (Cloudflare termine TLS mais on force le scheme)
if (app.Environment.IsProduction())
{
    app.UseHttpsRedirection();
}

// ✅ Activer CORS (AVANT UseAuthorization)
app.UseCors("AllowMobileApp");

// Rate limiting (après CORS, avant Auth) — désactivé en Test pour ne pas bloquer les tests
if (!app.Environment.IsEnvironment("Test"))
    app.UseRateLimiter();

// Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

// Controllers
app.MapControllers();

// ✅ Endpoint de santé
app.MapHealthChecks("/api/health");

// ========================================
// 9️⃣ MIGRATION AUTOMATIQUE
// ========================================
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();

    try
    {
        if (dbContext.Database.IsRelational())
        {
            app.Logger.LogInformation("Applying pending database migrations...");
            dbContext.Database.Migrate();
            app.Logger.LogInformation("Database migrations applied successfully");
        }
        else
        {
            app.Logger.LogInformation("Non-relational provider detected (tests) — skipping migrations");
        }
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "An error occurred while migrating the database");
        throw;
    }
}

// ========================================
// 🔟 IMPORT DES SITES CSV (au démarrage)
// ========================================
if (!app.Environment.IsEnvironment("Test"))
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    try
    {
        // Créer la table Sites si elle n'existe pas
        dbContext.Database.ExecuteSqlRaw(@"
            CREATE TABLE IF NOT EXISTS ""Sites"" (
                ""Numero"" integer NOT NULL PRIMARY KEY,
                ""NomDuSite"" character varying(500) NOT NULL,
                ""Adresse"" character varying(500) NULL,
                ""Ville"" character varying(255) NULL,
                ""CodePostal"" character varying(20) NULL,
                ""Pays"" character varying(100) NULL,
                ""ResponsableDorigine"" character varying(255) NULL,
                ""DateDeCreation"" timestamp with time zone NULL
            );
            CREATE INDEX IF NOT EXISTS ""IX_Sites_NomDuSite"" ON ""Sites""(""NomDuSite"");
            CREATE INDEX IF NOT EXISTS ""IX_Sites_Ville"" ON ""Sites""(""Ville"");
            CREATE INDEX IF NOT EXISTS ""IX_Sites_CodePostal"" ON ""Sites""(""CodePostal"");");

        // Importer le CSV seulement si la table est vide
        var siteCount = dbContext.Sites.Count();
        if (siteCount == 0)
        {
            var csvPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..",
                "Liste Sites NovaDIS - extract Gx 20260318.csv");
            if (!File.Exists(csvPath))
                csvPath = Path.Combine(Directory.GetCurrentDirectory(),
                    "Liste Sites NovaDIS - extract Gx 20260318.csv");

            if (File.Exists(csvPath))
            {
                var lines = File.ReadAllLines(csvPath, Encoding.Latin1);
                var imported = 0;
                for (int i = 1; i < lines.Length; i++)
                {
                    var line = lines[i].Trim();
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    var fields = line.Split(';');
                    if (fields.Length < 8 || !int.TryParse(fields[0].Trim(), out var numero)) continue;

                    dbContext.Sites.Add(new Site
                    {
                        Numero = numero,
                        NomDuSite = fields[1].Trim(),
                        Adresse = string.IsNullOrWhiteSpace(fields[2].Trim()) ? null : fields[2].Trim(),
                        Ville = string.IsNullOrWhiteSpace(fields[3].Trim()) ? null : fields[3].Trim(),
                        CodePostal = string.IsNullOrWhiteSpace(fields[4].Trim()) ? null : fields[4].Trim(),
                        Pays = string.IsNullOrWhiteSpace(fields[5].Trim()) ? null : fields[5].Trim(),
                        ResponsableDorigine = string.IsNullOrWhiteSpace(fields[6].Trim()) ? null : fields[6].Trim(),
                        DateDeCreation = DateTime.TryParseExact(fields[7].Trim(), "dd/MM/yyyy",
                            CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null
                    });
                    imported++;
                }
                dbContext.SaveChanges();
                logger.LogInformation("Imported {Count} sites from CSV", imported);
            }
            else
            {
                logger.LogWarning("CSV file not found, skipping site import");
            }
        }
        else
        {
            logger.LogInformation("Sites table already contains {Count} entries, skipping import", siteCount);
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error during site import");
    }
}

// ========================================
// 🔟 DÉMARRAGE
// ========================================
try
{
    app.Logger.LogInformation("Novadis CRI API starting...");
    app.Logger.LogInformation("Environment: {Environment}", app.Environment.EnvironmentName);
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "API a planté au démarrage");
    throw;
}
finally
{
    Log.CloseAndFlush();
}

public partial class Program {}
