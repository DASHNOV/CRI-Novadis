using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Attributes;
using NovadisApi.Data;

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
        /// Readiness probe enrichie : DB, latence, espace disque, mémoire.
        /// </summary>
        [HttpGet]
        [RoleAuthorize("Admin")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
        public async Task<IActionResult> Get()
        {
            var checks = new Dictionary<string, object>();
            var allHealthy = true;

            // 1️⃣ DB connectivité + latence
            var sw = System.Diagnostics.Stopwatch.StartNew();
            bool dbOk;
            int? userCount = null;
            try
            {
                dbOk = await _context.Database.CanConnectAsync();
                if (dbOk) userCount = await _context.Users.CountAsync();
            }
            catch (Exception ex)
            {
                dbOk = false;
                _logger.LogWarning(ex, "Health: DB unreachable");
            }
            sw.Stop();
            allHealthy &= dbOk;
            checks["database"] = new
            {
                status = dbOk ? "healthy" : "unhealthy",
                latencyMs = sw.ElapsedMilliseconds,
                degraded = sw.ElapsedMilliseconds > 500,
                usersCount = userCount
            };

            // 2️⃣ Espace disque (drive courant)
            try
            {
                var drive = new DriveInfo(Path.GetPathRoot(Directory.GetCurrentDirectory()) ?? "C:\\");
                var freeGb = drive.AvailableFreeSpace / 1024.0 / 1024.0 / 1024.0;
                var totalGb = drive.TotalSize / 1024.0 / 1024.0 / 1024.0;
                var diskOk = freeGb > 1.0;  // Seuil : 1 Go libre minimum
                allHealthy &= diskOk;
                checks["disk"] = new
                {
                    status = diskOk ? "healthy" : "critical",
                    freeGb = Math.Round(freeGb, 2),
                    totalGb = Math.Round(totalGb, 2),
                    usedPct = Math.Round(100 - (freeGb / totalGb * 100), 1)
                };
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Health: espace disque illisible");
                checks["disk"] = new { status = "unknown" };
            }

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

        /// <summary>
        /// Statistiques détaillées de la base de données
        /// </summary>
        [HttpGet("stats")]
        [RoleAuthorize("Admin")]
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
