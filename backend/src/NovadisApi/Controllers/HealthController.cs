using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Authorization;

namespace NovadisApi.Controllers
{
    /// <summary>
    /// Controller pour vérifier la santé de l'API
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    [Authorize]
    public class HealthController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ILogger<HealthController> _logger;

        public HealthController(
            NovadisDbContext context,
            ILogger<HealthController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Liveness probe : l'API tourne (pas de check DB).
        /// </summary>
        [HttpGet("live")]
        [AllowAnonymous]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult Live() => Ok(new { status = "alive", timestamp = DateTime.UtcNow });

        /// <summary>
        /// Readiness publique, pour le monitoring externe et le smoke test du déploiement :
        /// mêmes contrôles que <see cref="Get"/> (base, disque) mais ne renvoie que
        /// <c>{ status, degraded }</c> — aucune donnée d'infrastructure. 503 si une
        /// dépendance est indisponible. La liveness (<c>/live</c>) reste la sonde de
        /// redémarrage Docker : elle répond 200 même base injoignable.
        /// </summary>
        [HttpGet("ready")]
        [AllowAnonymous]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
        public async Task<IActionResult> Ready()
        {
            var probe = await ProbeDependenciesAsync(countUsers: false);
            var body = new { status = probe.Healthy ? "ready" : "unavailable", degraded = probe.Degraded };
            return probe.Healthy ? Ok(body) : StatusCode(StatusCodes.Status503ServiceUnavailable, body);
        }

        /// <summary>
        /// Readiness probe enrichie : DB, latence, espace disque, mémoire.
        /// </summary>
        [HttpGet]
        [Authorize(Policy = Capabilities.SystemAdmin)]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
        public async Task<IActionResult> Get()
        {
            var probe = await ProbeDependenciesAsync(countUsers: true);
            var checks = new Dictionary<string, object>();
            var allHealthy = probe.Healthy;

            // 1️⃣ DB connectivité + latence
            checks["database"] = new
            {
                status = probe.DbOk ? "healthy" : "unhealthy",
                latencyMs = probe.DbLatencyMs,
                degraded = probe.Degraded,
                usersCount = probe.UserCount
            };

            // 2️⃣ Espace disque (drive courant)
            checks["disk"] = probe.FreeGb is double freeGb && probe.TotalGb is double totalGb
                ? new
                {
                    status = probe.DiskOk ? "healthy" : "critical",
                    freeGb = Math.Round(freeGb, 2),
                    totalGb = Math.Round(totalGb, 2),
                    usedPct = Math.Round(100 - (freeGb / totalGb * 100), 1)
                }
                : new { status = "unknown" };

            // 3️⃣ Mémoire process
            var proc = System.Diagnostics.Process.GetCurrentProcess();
            checks["memory"] = new
            {
                workingSetMb = Math.Round(proc.WorkingSet64 / 1024.0 / 1024.0, 1),
                privateMb = Math.Round(proc.PrivateMemorySize64 / 1024.0 / 1024.0, 1),
                threads = proc.Threads.Count,
                uptimeMinutes = Math.Round((DateTime.Now - proc.StartTime).TotalMinutes, 1)
            };

            var response = new
            {
                status = allHealthy ? "healthy" : "degraded",
                checks,
                api = new
                {
                    version = "1.0.0",
                    environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production",
                    machine = Environment.MachineName
                },
                timestamp = DateTime.UtcNow
            };

            return allHealthy ? Ok(response) : StatusCode(StatusCodes.Status503ServiceUnavailable, response);
        }

        private sealed record DependencyProbe(
            bool DbOk, long DbLatencyMs, int? UserCount, bool DiskOk, double? FreeGb, double? TotalGb)
        {
            public bool Healthy => DbOk && DiskOk;
            public bool Degraded => DbLatencyMs > 500;
        }

        /// <summary>
        /// Contrôles communs à <see cref="Get"/> et <see cref="Ready"/>. Connexion bornée à
        /// 5 s : une base injoignable doit donner un 503 rapide, pas un délai d'attente
        /// côté moniteur. Espace disque illisible = non bloquant (statut « unknown »).
        /// </summary>
        private async Task<DependencyProbe> ProbeDependenciesAsync(bool countUsers)
        {
            var sw = System.Diagnostics.Stopwatch.StartNew();
            bool dbOk;
            int? userCount = null;
            try
            {
                using var cts = CancellationTokenSource.CreateLinkedTokenSource(HttpContext.RequestAborted);
                cts.CancelAfter(TimeSpan.FromSeconds(5));
                dbOk = await _context.Database.CanConnectAsync(cts.Token);
                if (dbOk && countUsers) userCount = await _context.Users.CountAsync(cts.Token);
            }
            catch (Exception ex)
            {
                dbOk = false;
                _logger.LogWarning(ex, "Health: DB unreachable");
            }
            sw.Stop();

            double? freeGb = null, totalGb = null;
            var diskOk = true;
            try
            {
                var drive = new DriveInfo(Path.GetPathRoot(Directory.GetCurrentDirectory()) ?? "C:\\");
                freeGb = drive.AvailableFreeSpace / 1024.0 / 1024.0 / 1024.0;
                totalGb = drive.TotalSize / 1024.0 / 1024.0 / 1024.0;
                diskOk = freeGb > 1.0;  // Seuil : 1 Go libre minimum
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Health: espace disque illisible");
            }

            return new DependencyProbe(dbOk, sw.ElapsedMilliseconds, userCount, diskOk, freeGb, totalGb);
        }

        /// <summary>
        /// Statistiques détaillées de la base de données
        /// </summary>
        [HttpGet("stats")]
        [Authorize(Policy = Capabilities.SystemAdmin)]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> GetStats()
        {
            try
            {
                var stats = new
                {
                    users = await _context.Users.CountAsync(),
                    criForms = await _context.CRIForms.CountAsync(),
                    photos = await _context.CRIPhotos.CountAsync(),
                    auditLogs = await _context.AuditLogs.CountAsync(),
                    criByStatus = await _context.CRIForms
                        .GroupBy(c => c.Status)
                        .Select(g => new { status = g.Key, count = g.Count() })
                        .ToListAsync(),
                    timestamp = DateTime.UtcNow
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to fetch stats");
                return StatusCode(500, new { error = "Statistiques indisponibles." });
            }
        }
    }
}
