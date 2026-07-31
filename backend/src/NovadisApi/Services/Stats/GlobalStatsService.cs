using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;

namespace NovadisApi.Services.Stats;

public sealed class GlobalStatsService : IGlobalStatsService
{
    private static readonly string[] MonthNames =
        { "", "Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc" };

    private readonly NovadisDbContext _context;

    public GlobalStatsService(NovadisDbContext context)
    {
        _context = context;
    }

    public async Task<GlobalStatsDto> GetGlobalStatsAsync(int? periodDays, CancellationToken ct = default)
    {
        var baseQuery = FilterByPeriod(_context.CRIForms, periodDays);

        var stats = new GlobalStatsDto
        {
            TotalCeMois = await baseQuery.CountAsync(ct),
            TotalSignes = await baseQuery.CountAsync(c => c.ClientSignature != null, ct),
            TotalEnAttente = await baseQuery.CountAsync(c => c.ClientSignature == null, ct),
            TechniciensActifs = await baseQuery.Select(c => c.TechnicianId).Distinct().CountAsync(ct),
            DureeMoyenneMinutes = await baseQuery
                .Where(c => c.DureeMinutes != null && c.DureeMinutes > 0)
                .AverageAsync(c => (double?)c.DureeMinutes, ct),
            TotalProjets = await baseQuery.CountAsync(c => c.InterventionType == "Project", ct),
            TotalServices = await baseQuery.CountAsync(c => c.InterventionType == "Service", ct),
            TotalResolu = await baseQuery.CountAsync(c => c.ResolutionStatus == "resolu", ct),
            TotalNonResolu = await baseQuery.CountAsync(
                c => c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu", ct),
            TotalRecurrenceRequise = await baseQuery.CountAsync(c => c.AdditionalInterventionRequired == true, ct)
        };

        var villeStats = await baseQuery
            .Where(c => c.Ville != null)
            .GroupBy(c => c.Ville!)
            .Select(g => new { Ville = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Count)
            .Take(10)
            .ToListAsync(ct);
        stats.RepartitionParVille = villeStats.ToDictionary(v => v.Ville, v => v.Count);

        return stats;
    }

    public async Task<IReadOnlyList<CRIWithTechnicianDto>> GetAllCRIsWithTechnicianAsync(
        Guid? technicienId, string filter, string? searchId, CancellationToken ct = default)
    {
        var query = _context.CRIForms
            .Include(c => c.Technician)
            .Include(c => c.Site)
            .Include(c => c.Client)
            .AsQueryable();

        if (technicienId.HasValue)
            query = query.Where(c => c.TechnicianId == technicienId.Value);

        if (!string.IsNullOrWhiteSpace(searchId) && Guid.TryParse(searchId, out var searchGuid))
            query = query.Where(c => c.Id == searchGuid);

        query = filter.ToLower() switch
        {
            "signed" => query.Where(c => c.ClientSignature != null),
            "pending" => query.Where(c => c.ClientSignature == null),
            _ => query
        };

        return await query
            .OrderByDescending(c => c.CreatedAt)
            .Select(c => new CRIWithTechnicianDto
            {
                Id = c.Id,
                TechnicianId = c.TechnicianId,
                InterventionType = c.InterventionType,
                Category = c.Category,
                InterventionDate = c.InterventionDate,
                ClientName = c.ClientName,
                ClientAddress = c.ClientAddress,
                ClientSite = c.ClientSite,
                ClientPhone = c.ClientPhone,
                ClientEmail = c.ClientEmail,
                WorkDescription = c.WorkDescription,
                MaterialsUsed = c.MaterialsUsed,
                Duration = c.Duration,
                Status = c.Status,
                Data = c.Data,
                TechnicianSignature = c.TechnicianSignature,
                ClientSignature = c.ClientSignature,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt,
                SubmittedAt = c.SubmittedAt,
                HeureDebut = c.HeureDebut,
                HeureFin = c.HeureFin,
                DureeMinutes = c.DureeMinutes,
                Ville = c.Ville,
                CodePostal = c.CodePostal,
                Pays = c.Pays,
                ClientContact = c.ClientContact,
                TicketNumber = c.TicketNumber,
                ResolutionStatus = c.ResolutionStatus,
                AdditionalInterventionRequired = c.AdditionalInterventionRequired,
                ProjectName = c.ProjectName,
                ProjectNumber = c.ProjectNumber,
                ProjectPhase = c.ProjectPhase,
                ProjectStatus = c.ProjectStatus,
                SiteID = c.SiteID,
                SiteNom = c.Site != null ? c.Site.NomDuSite : null,
                ClientID = c.ClientID,
                ClientRaisonSociale = c.Client != null ? c.Client.RaisonSociale : null,
                TechnicianFirstName = c.Technician != null ? c.Technician.FirstName ?? "" : "",
                TechnicianLastName = c.Technician != null ? c.Technician.LastName ?? "" : "",
                TechnicianEmail = c.Technician != null ? c.Technician.Email : ""
            })
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<TechnicianActivityDto>> GetTechnicianActivityAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var sevenDaysAgo = now.AddDays(-7);
        var thirtyDaysAgo = now.AddDays(-30);

        return await _context.Users
            .Where(u => u.IsActive && (u.Role == "Technician" || u.Role == "Technicien" || u.Role == "Admin"))
            .Select(u => new TechnicianActivityDto
            {
                Id = u.Id,
                FirstName = u.FirstName ?? "",
                LastName = u.LastName ?? "",
                NbCriTotal = u.CRIForms.Count,
                NbCri7j = u.CRIForms.Count(c => c.CreatedAt >= sevenDaysAgo),
                NbCri30j = u.CRIForms.Count(c => c.CreatedAt >= thirtyDaysAgo)
            })
            .OrderByDescending(a => a.NbCri30j)
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<DailyActivityDto>> GetActivityChartDataAsync(CancellationToken ct = default)
    {
        var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

        return await _context.CRIForms
            .Where(c => c.CreatedAt >= sevenDaysAgo)
            .GroupBy(c => c.CreatedAt.Date)
            .Select(g => new DailyActivityDto { Jour = g.Key, Nb = g.Count() })
            .OrderBy(d => d.Jour)
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<UserDto>> GetTechniciansAsync(CancellationToken ct = default)
    {
        return await _context.Users
            .Where(u => u.IsActive)
            .OrderBy(u => u.LastName)
            .ThenBy(u => u.FirstName)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Email = u.Email,
                FirstName = u.FirstName ?? "",
                LastName = u.LastName ?? "",
                Role = u.Role,
                IsActive = u.IsActive,
                LastLoginAt = u.LastLoginAt
            })
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<SiteStatsDto>> GetStatsBySiteAsync(int? periodDays, CancellationToken ct = default)
    {
        var baseQuery = FilterByPeriod(_context.CRIForms, periodDays);

        var criList = await baseQuery
            .Include(c => c.Site)
            .Where(c => c.ClientSite != null && c.ClientSite != "")
            .Select(c => new
            {
                c.SiteID,
                SiteNom = c.Site != null ? c.Site.NomDuSite : c.ClientSite!,
                SiteVille = c.Site != null ? c.Site.Ville : c.Ville,
                ClientNom = c.Client != null ? c.Client.RaisonSociale : c.ClientName,
                c.InterventionType,
                c.Category,
                c.DureeMinutes,
                c.ResolutionStatus,
                c.AdditionalInterventionRequired,
                c.TechnicianId,
                c.InterventionDate
            })
            .ToListAsync(ct);

        return criList
            .GroupBy(c => c.SiteNom)
            .Select(g =>
            {
                var total = g.Count();
                var resolu = g.Count(c => c.ResolutionStatus == "resolu");
                var nonResolu = g.Count(c => c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu");
                var recurrence = g.Count(c => c.AdditionalInterventionRequired == true);

                var topCategorie = g
                    .Where(c => !string.IsNullOrEmpty(c.Category))
                    .GroupBy(c => c.Category)
                    .OrderByDescending(cg => cg.Count())
                    .FirstOrDefault();

                var repartitionCat = g
                    .Where(c => !string.IsNullOrEmpty(c.Category))
                    .GroupBy(c => c.Category)
                    .ToDictionary(cg => cg.Key!, cg => cg.Count());

                return new SiteStatsDto
                {
                    SiteID = g.First().SiteID,
                    SiteNom = g.Key,
                    ClientNom = g.First().ClientNom,
                    Ville = g.First().SiteVille,
                    TotalInterventions = total,
                    DureeMoyenneMinutes = g.Where(c => c.DureeMinutes > 0)
                        .Select(c => (double?)c.DureeMinutes).DefaultIfEmpty().Average(),
                    TotalServices = g.Count(c => c.InterventionType == "Service"),
                    TotalProjets = g.Count(c => c.InterventionType == "Project"),
                    TotalResolu = resolu,
                    TotalNonResolu = nonResolu,
                    TotalRecurrenceRequise = recurrence,
                    TauxRecurrence = total > 0 ? Math.Round((double)recurrence / total * 100, 1) : 0,
                    TopCategorie = topCategorie?.Key,
                    TopCategorieCount = topCategorie?.Count() ?? 0,
                    DerniereIntervention = g.Max(c => c.InterventionDate),
                    TechniciensDistincts = g.Select(c => c.TechnicianId).Distinct().Count(),
                    RepartitionParCategorie = repartitionCat.Count > 0 ? repartitionCat : null
                };
            })
            .OrderByDescending(s => s.TotalInterventions)
            .ToList();
    }

    public async Task<IReadOnlyList<TechnicianDetailedStatsDto>> GetStatsByTechnicianAsync(int? periodDays, CancellationToken ct = default)
    {
        var baseQuery = FilterByPeriod(_context.CRIForms, periodDays);

        var criList = await baseQuery
            .Include(c => c.Technician)
            .Select(c => new
            {
                c.TechnicianId,
                TechPrenom = c.Technician != null ? c.Technician.FirstName ?? "" : "",
                TechNom = c.Technician != null ? c.Technician.LastName ?? "" : "",
                c.InterventionType,
                c.Category,
                c.DureeMinutes,
                c.ResolutionStatus,
                c.AdditionalInterventionRequired,
                SiteNom = c.ClientSite ?? "",
                ClientNom = c.ClientName ?? "",
                c.InterventionDate
            })
            .ToListAsync(ct);

        return criList
            .GroupBy(c => c.TechnicianId)
            .Select(g =>
            {
                var total = g.Count();
                var resolu = g.Count(c => c.ResolutionStatus == "resolu");
                var nonResolu = g.Count(c => c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu");
                var recurrence = g.Count(c => c.AdditionalInterventionRequired == true);

                var durees = g.Where(c => c.DureeMinutes > 0).Select(c => c.DureeMinutes ?? 0).ToList();
                var totalHeures = durees.Sum() / 60.0;

                var topSites = g
                    .Where(c => !string.IsNullOrEmpty(c.SiteNom))
                    .GroupBy(c => c.SiteNom)
                    .OrderByDescending(sg => sg.Count())
                    .Take(5)
                    .Select(sg => sg.Key)
                    .ToList();

                var repartitionType = new Dictionary<string, int>();
                var services = g.Count(c => c.InterventionType == "Service");
                var projets = g.Count(c => c.InterventionType == "Project");
                if (services > 0) repartitionType["Service"] = services;
                if (projets > 0) repartitionType["Projet"] = projets;

                var categories = g
                    .Where(c => !string.IsNullOrEmpty(c.Category))
                    .GroupBy(c => c.Category)
                    .ToDictionary(cg => cg.Key!, cg => cg.Count());
                foreach (var cat in categories)
                    repartitionType[cat.Key] = cat.Value;

                var first = g.First();
                return new TechnicianDetailedStatsDto
                {
                    Id = g.Key,
                    Prenom = first.TechPrenom,
                    Nom = first.TechNom,
                    TotalInterventions = total,
                    SitesDistincts = g.Where(c => !string.IsNullOrEmpty(c.SiteNom)).Select(c => c.SiteNom).Distinct().Count(),
                    ClientsDistincts = g.Where(c => !string.IsNullOrEmpty(c.ClientNom)).Select(c => c.ClientNom).Distinct().Count(),
                    DureeMoyenneMinutes = durees.Count > 0 ? Math.Round(durees.Average(), 1) : null,
                    TotalHeures = Math.Round(totalHeures, 1),
                    TotalServices = services,
                    TotalProjets = projets,
                    TotalResolu = resolu,
                    TotalNonResolu = nonResolu,
                    TotalRecurrenceRequise = recurrence,
                    DerniereIntervention = g.Max(c => c.InterventionDate),
                    TopSites = topSites,
                    RepartitionParType = repartitionType.Count > 0 ? repartitionType : null
                };
            })
            .OrderByDescending(t => t.TotalInterventions)
            .ToList();
    }

    public async Task<DistributionStatsDto> GetDistributionStatsAsync(int? periodDays, CancellationToken ct = default)
    {
        var baseQuery = FilterByPeriod(_context.CRIForms, periodDays);

        var criList = await baseQuery
            .Include(c => c.Technician)
            .Select(c => new
            {
                SiteNom = c.ClientSite ?? "(non renseigné)",
                c.Category,
                c.InterventionType,
                c.ResolutionStatus,
                c.DureeMinutes,
                c.Ville,
                TechNom = c.Technician != null
                    ? (c.Technician.FirstName ?? "") + " " + (c.Technician.LastName ?? "")
                    : "Inconnu",
                c.InterventionDate
            })
            .ToListAsync(ct);

        var result = new DistributionStatsDto
        {
            CategorieParSite = criList
                .Where(c => !string.IsNullOrEmpty(c.Category) && c.SiteNom != "(non renseigné)")
                .GroupBy(c => new { c.SiteNom, c.Category })
                .Select(g => new CrossTabEntry
                {
                    Ligne = g.Key.SiteNom,
                    Colonne = g.Key.Category!,
                    Valeur = g.Count()
                })
                .OrderByDescending(e => e.Valeur)
                .Take(100)
                .ToList(),

            TechnicienParSite = criList
                .Where(c => c.SiteNom != "(non renseigné)")
                .GroupBy(c => new { c.SiteNom, c.TechNom })
                .Select(g => new CrossTabEntry
                {
                    Ligne = g.Key.SiteNom,
                    Colonne = g.Key.TechNom,
                    Valeur = g.Count()
                })
                .OrderByDescending(e => e.Valeur)
                .Take(100)
                .ToList(),

            EvolutionMensuelle = criList
                .GroupBy(c => new { c.InterventionDate.Year, c.InterventionDate.Month })
                .Select(g => new EvolutionMensuelleEntry
                {
                    Annee = g.Key.Year,
                    Mois = g.Key.Month,
                    Label = $"{MonthNames[g.Key.Month]} {g.Key.Year}",
                    TotalInterventions = g.Count(),
                    Services = g.Count(c => c.InterventionType == "Service"),
                    Projets = g.Count(c => c.InterventionType == "Project"),
                    Resolu = g.Count(c => c.ResolutionStatus == "resolu"),
                    DureeMoyenneMinutes = g.Where(c => c.DureeMinutes > 0)
                        .Select(c => (double?)c.DureeMinutes).DefaultIfEmpty().Average()
                })
                .OrderBy(e => e.Annee).ThenBy(e => e.Mois)
                .ToList(),

            RepartitionParVille = criList
                .Where(c => !string.IsNullOrEmpty(c.Ville))
                .GroupBy(c => c.Ville!)
                .ToDictionary(g => g.Key, g => g.Count())
                .OrderByDescending(kv => kv.Value)
                .Take(20)
                .ToDictionary(kv => kv.Key, kv => kv.Value),

            RepartitionParCategorie = criList
                .Where(c => !string.IsNullOrEmpty(c.Category))
                .GroupBy(c => c.Category!)
                .ToDictionary(g => g.Key, g => g.Count())
                .OrderByDescending(kv => kv.Value)
                .ToDictionary(kv => kv.Key, kv => kv.Value)
        };

        return result;
    }

    private static IQueryable<CRIForm> FilterByPeriod(IQueryable<CRIForm> query, int? periodDays)
    {
        if (periodDays.HasValue && periodDays.Value > 0)
        {
            var startDate = DateTime.UtcNow.AddDays(-periodDays.Value);
            query = query.Where(c => c.InterventionDate >= startDate);
        }
        return query;
    }
}
