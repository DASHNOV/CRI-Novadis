using System.Text.RegularExpressions;
using ClosedXML.Excel;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;

namespace NovadisApi.Services.Export
{
    public enum ExportPeriod { Day, Week, Month, Year }

    public enum ExportDetailLevel { Full, Summary }

    public record PeriodRange(DateTime StartUtc, DateTime EndUtcExclusive, string Label);

    public interface IXlsxExportService
    {
        Task<(byte[] Bytes, string Filename)?> GenerateSingleCriAsync(Guid criId, Guid requesterId, bool isAdmin);
        Task<(byte[] Bytes, string Filename)> GeneratePeriodAsync(ExportPeriod period, DateTime referenceDate, Guid requesterId, bool isAdmin, ExportDetailLevel detailLevel = ExportDetailLevel.Full);
    }

    /// <summary>
    /// Génère des classeurs Excel (XLSX) professionnels pour les CRI.
    /// Utilise ClosedXML pour un rendu pro (entêtes, styles, autofilter, freeze).
    /// </summary>
    public class XlsxExportService : IXlsxExportService
    {
        private readonly NovadisDbContext _db;

        // Palette Novadis
        private static readonly XLColor HeaderBg = XLColor.FromHtml("#1A1A1A");
        private static readonly XLColor HeaderFg = XLColor.FromHtml("#FFFFFF");
        private static readonly XLColor AccentBg = XLColor.FromHtml("#8BB8E8");
        private static readonly XLColor ZebraBg = XLColor.FromHtml("#F5F6F8");
        private static readonly XLColor LabelBg = XLColor.FromHtml("#EEF1F5");
        private static readonly XLColor SuccessBg = XLColor.FromHtml("#DCEEDC");
        private static readonly XLColor SuccessFg = XLColor.FromHtml("#2E7D32");
        private static readonly XLColor WarningBg = XLColor.FromHtml("#FFF3CD");
        private static readonly XLColor WarningFg = XLColor.FromHtml("#8A6D3B");
        private static readonly XLColor DangerBg = XLColor.FromHtml("#F8D7DA");
        private static readonly XLColor DangerFg = XLColor.FromHtml("#B02A37");
        private static readonly XLColor NeutralBg = XLColor.FromHtml("#E4E7EC");
        private static readonly XLColor NeutralFg = XLColor.FromHtml("#5A6472");
        private static readonly XLColor GoldBg = XLColor.FromHtml("#FFD700");
        private static readonly XLColor SilverBg = XLColor.FromHtml("#D9D9D9");
        private static readonly XLColor BronzeBg = XLColor.FromHtml("#E6B17E");
        private static readonly XLColor TopFiveBg = XLColor.FromHtml("#FFF6D9");

        public XlsxExportService(NovadisDbContext db)
        {
            _db = db;
        }

        // ──────────────────────────────────────────────────────────
        // Export d'un CRI unique
        // ──────────────────────────────────────────────────────────
        public async Task<(byte[] Bytes, string Filename)?> GenerateSingleCriAsync(Guid criId, Guid requesterId, bool isAdmin)
        {
            var cri = await _db.CRIForms
                .Include(c => c.Technician)
                .Include(c => c.Site)
                .Include(c => c.Client)
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.Id == criId);

            if (cri == null) return null;
            if (!isAdmin && cri.TechnicianId != requesterId) return null;

            using var wb = new XLWorkbook();
            BuildCriDetailSheet(wb, cri);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);

            var typeLabel = string.IsNullOrWhiteSpace(cri.InterventionType) ? "cri" : cri.InterventionType.ToLowerInvariant();
            var filename = $"novadis-{typeLabel}-{cri.InterventionDate:yyyyMMdd}-{cri.Id.ToString()[..8]}.xlsx";
            return (ms.ToArray(), filename);
        }

        private static void BuildCriDetailSheet(XLWorkbook wb, CRIForm cri)
        {
            var ws = wb.Worksheets.Add("Détail CRI");
            ws.ShowGridLines = false;

            // Bandeau titre
            var title = ws.Range("A1:D1").Merge();
            title.Value = cri.InterventionType == "Service" ? "Compte-rendu d'intervention — Service" : "Compte-rendu d'intervention — Projet";
            title.Style.Font.FontSize = 16;
            title.Style.Font.Bold = true;
            title.Style.Font.FontColor = HeaderFg;
            title.Style.Fill.BackgroundColor = HeaderBg;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Left;
            ws.Row(1).Height = 28;

            if (cri.Status == "Draft")
            {
                var banner = ws.Range("A2:D2").Merge();
                banner.Value = "⚠ BROUILLON — CRI NON VALIDÉ";
                banner.Style.Font.Bold = true;
                banner.Style.Font.FontColor = DangerFg;
                banner.Style.Fill.BackgroundColor = DangerBg;
                banner.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                ws.Row(2).Height = 18;
            }

            // Bloc identifiant + date
            var row = 3;
            ws.Cell(row, 1).Value = "Identifiant"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.Id.ToString();
            ws.Cell(row, 3).Value = "Statut"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.Status;
            row++;

            ws.Cell(row, 1).Value = "Date intervention"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.InterventionDate;
            ws.Cell(row, 2).Style.DateFormat.Format = "dd/MM/yyyy";
            ws.Cell(row, 3).Value = "Durée"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = FormatDuration(cri);
            row++;

            ws.Cell(row, 1).Value = "Heure début"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.HeureDebut.HasValue ? cri.HeureDebut.Value.ToString(@"hh\:mm") : "-";
            ws.Cell(row, 3).Value = "Heure fin"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.HeureFin.HasValue ? cri.HeureFin.Value.ToString(@"hh\:mm") : "-";
            row++;

            row++;
            SectionHeader(ws, row++, "Technicien");
            ws.Cell(row, 1).Value = "Nom"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.Technician != null
                ? $"{cri.Technician.FirstName} {cri.Technician.LastName}".Trim()
                : cri.TechnicianId.ToString();
            ws.Cell(row, 3).Value = "Email"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.Technician?.Email ?? "-";
            row += 2;

            SectionHeader(ws, row++, "Client");
            ws.Cell(row, 1).Value = "Nom"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.ClientName;
            ws.Cell(row, 3).Value = "Contact"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.ClientContact ?? "-";
            row++;
            ws.Cell(row, 1).Value = "Téléphone"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.ClientPhone ?? "-";
            ws.Cell(row, 3).Value = "Email"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.ClientEmail ?? "-";
            row++;
            ws.Cell(row, 1).Value = "Adresse"; StyleLabel(ws.Cell(row, 1));
            ws.Range(row, 2, row, 4).Merge().Value = FormatAddress(cri);
            row += 2;

            SectionHeader(ws, row++, "Site");
            ws.Cell(row, 1).Value = "Nom du site"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.Site?.NomDuSite ?? cri.ClientSite ?? "-";
            ws.Cell(row, 3).Value = "Numéro"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.Site?.Numero.ToString() ?? "-";
            row += 2;

            SectionHeader(ws, row++, "Intervention");
            ws.Cell(row, 1).Value = "Type"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.InterventionType;
            ws.Cell(row, 3).Value = "Catégorie"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.Category;
            row++;

            if (cri.InterventionType == "Service")
            {
                ws.Cell(row, 1).Value = "Numéro ticket"; StyleLabel(ws.Cell(row, 1));
                ws.Cell(row, 2).Value = cri.TicketNumber ?? "-";
                row++;
                ws.Cell(row, 1).Value = "Statut résolution"; StyleLabel(ws.Cell(row, 1));
                ws.Cell(row, 2).Value = cri.ResolutionStatus ?? "-";
                ws.Cell(row, 3).Value = "Nouvelle intervention"; StyleLabel(ws.Cell(row, 3));
                ws.Cell(row, 4).Value = cri.AdditionalInterventionRequired == true ? "Oui" : "Non";
                row++;
            }
            else if (cri.InterventionType == "Project" || cri.InterventionType == "Projet")
            {
                ws.Cell(row, 1).Value = "Nom projet"; StyleLabel(ws.Cell(row, 1));
                ws.Cell(row, 2).Value = cri.ProjectName ?? "-";
                ws.Cell(row, 3).Value = "Numéro projet"; StyleLabel(ws.Cell(row, 3));
                ws.Cell(row, 4).Value = cri.ProjectNumber ?? "-";
                row++;
                ws.Cell(row, 1).Value = "Phase"; StyleLabel(ws.Cell(row, 1));
                ws.Cell(row, 2).Value = cri.ProjectPhase ?? "-";
                ws.Cell(row, 3).Value = "Statut projet"; StyleLabel(ws.Cell(row, 3));
                ws.Cell(row, 4).Value = cri.ProjectStatus ?? "-";
                row++;
            }

            row++;
            SectionHeader(ws, row++, "Description des travaux");
            var descr = ws.Range(row, 1, row, 4).Merge();
            descr.Value = StripMarkdown(cri.WorkDescription) ?? "-";
            descr.Style.Alignment.WrapText = true;
            descr.Style.Alignment.Vertical = XLAlignmentVerticalValues.Top;
            ws.Row(row).Height = 60;
            row += 2;

            if (!string.IsNullOrWhiteSpace(cri.MaterialsUsed))
            {
                SectionHeader(ws, row++, "Matériel utilisé");
                var mat = ws.Range(row, 1, row, 4).Merge();
                mat.Value = cri.MaterialsUsed;
                mat.Style.Alignment.WrapText = true;
                mat.Style.Alignment.Vertical = XLAlignmentVerticalValues.Top;
                ws.Row(row).Height = 50;
                row += 2;
            }

            SectionHeader(ws, row++, "Métadonnées");
            ws.Cell(row, 1).Value = "Créé le"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.CreatedAt;
            ws.Cell(row, 2).Style.DateFormat.Format = "dd/MM/yyyy HH:mm";
            ws.Cell(row, 3).Value = "Soumis le"; StyleLabel(ws.Cell(row, 3));
            if (cri.SubmittedAt.HasValue)
            {
                ws.Cell(row, 4).Value = cri.SubmittedAt.Value;
                ws.Cell(row, 4).Style.DateFormat.Format = "dd/MM/yyyy HH:mm";
            }
            else
            {
                ws.Cell(row, 4).Value = "-";
            }

            ws.Column(1).Width = 22;
            ws.Column(2).Width = 42;
            ws.Column(3).Width = 22;
            ws.Column(4).Width = 42;

            ApplyPrintSetup(ws, landscape: false, repeatHeaderRow: false);
        }

        // ──────────────────────────────────────────────────────────
        // Export période (jour / semaine / mois / année)
        // ──────────────────────────────────────────────────────────
        public async Task<(byte[] Bytes, string Filename)> GeneratePeriodAsync(
            ExportPeriod period, DateTime referenceDate, Guid requesterId, bool isAdmin, ExportDetailLevel detailLevel = ExportDetailLevel.Full)
        {
            var range = ComputeRange(period, referenceDate);

            IQueryable<CRIForm> query = _db.CRIForms
                .Include(c => c.Technician)
                .Include(c => c.Site)
                .AsNoTracking()
                .Where(c => c.InterventionDate >= range.StartUtc && c.InterventionDate < range.EndUtcExclusive);

            if (!isAdmin)
            {
                query = query.Where(c => c.TechnicianId == requesterId);
            }

            var cris = await query.OrderBy(c => c.InterventionDate).ToListAsync();

            var previousRange = ComputePreviousRange(period, referenceDate);
            IQueryable<CRIForm> previousQuery = _db.CRIForms
                .AsNoTracking()
                .Where(c => c.InterventionDate >= previousRange.StartUtc && c.InterventionDate < previousRange.EndUtcExclusive);
            if (!isAdmin)
            {
                previousQuery = previousQuery.Where(c => c.TechnicianId == requesterId);
            }
            var previousCris = await previousQuery.ToListAsync();

            using var wb = new XLWorkbook();
            BuildCoverSheet(wb, cris, period, range, isAdmin, detailLevel);
            BuildSummarySheet(wb, cris, previousCris, period, range, isAdmin);
            if (detailLevel == ExportDetailLevel.Full)
            {
                BuildInterventionsSheet(wb, cris);
                if (cris.Count > 0)
                {
                    BuildBySiteSheet(wb, cris);
                    if (isAdmin)
                    {
                        BuildByTechnicianSheet(wb, cris);
                    }
                }
            }

            using var ms = new MemoryStream();
            wb.SaveAs(ms);

            var scope = isAdmin ? "global" : "personnel";
            var suffix = detailLevel == ExportDetailLevel.Summary ? "-resume" : "";
            var filename = $"novadis-{PeriodSlug(period)}-{scope}{suffix}-{range.StartUtc:yyyyMMdd}.xlsx";
            return (ms.ToArray(), filename);
        }

        private static byte[]? LoadLogoBytes()
        {
            var assembly = typeof(XlsxExportService).Assembly;
            using var stream = assembly.GetManifestResourceStream("NovadisApi.Resources.novadis_logo.png");
            if (stream == null) return null;
            using var ms = new MemoryStream();
            stream.CopyTo(ms);
            return ms.ToArray();
        }

        private static void BuildCoverSheet(XLWorkbook wb, List<CRIForm> cris, ExportPeriod period, PeriodRange range, bool isAdmin, ExportDetailLevel detailLevel)
        {
            var ws = wb.Worksheets.Add("Page de garde");
            ws.ShowGridLines = false;

            var logoBytes = LoadLogoBytes();
            if (logoBytes != null)
            {
                using var logoStream = new MemoryStream(logoBytes);
                ws.AddPicture(logoStream, "logo")
                    .MoveTo(ws.Cell(2, 2))
                    .WithSize(90, 90);
            }

            var title = ws.Range(5, 2, 6, 7).Merge();
            title.Value = detailLevel == ExportDetailLevel.Summary ? "RÉSUMÉ EXÉCUTIF CRI" : "RAPPORT CRI";
            title.Style.Font.FontSize = 26;
            title.Style.Font.Bold = true;
            title.Style.Font.FontColor = HeaderFg;
            title.Style.Fill.BackgroundColor = HeaderBg;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(5).Height = 30;
            ws.Row(6).Height = 30;

            var subtitle = ws.Range(7, 2, 7, 7).Merge();
            subtitle.Value = range.Label;
            subtitle.Style.Font.FontSize = 15;
            subtitle.Style.Font.FontColor = HeaderFg;
            subtitle.Style.Fill.BackgroundColor = AccentBg;
            subtitle.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            ws.Row(7).Height = 22;

            var row = 10;
            void Info(string label, string value)
            {
                ws.Cell(row, 2).Value = label; StyleLabel(ws.Cell(row, 2));
                var valueRange = ws.Range(row, 3, row, 6).Merge();
                valueRange.Value = value;
                valueRange.Style.Font.Bold = true;
                row++;
            }

            Info("Portée", isAdmin ? "Tous les techniciens" : "Mes CRI");
            Info("Généré le", DateTime.Now.ToString("dd/MM/yyyy HH:mm"));
            Info("Nombre de CRI inclus", cris.Count.ToString());
            var brouillons = cris.Count(c => c.Status == "Draft");
            if (brouillons > 0)
            {
                Info("Dont brouillons non validés", brouillons.ToString());
            }

            var footer = ws.Range(row + 2, 2, row + 2, 7).Merge();
            footer.Value = "Document confidentiel — usage interne — Novadis";
            footer.Style.Font.Italic = true;
            footer.Style.Font.FontColor = NeutralFg;
            footer.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

            ws.Column(2).Width = 22;
            ws.Column(3).Width = 20;
            ws.Column(4).Width = 20;
            ws.Column(5).Width = 20;
            ws.Column(6).Width = 20;
            ws.Column(7).Width = 20;

            ApplyPrintSetup(ws, landscape: false, repeatHeaderRow: false);
        }

        private static void BuildSummarySheet(XLWorkbook wb, List<CRIForm> cris, List<CRIForm> previousCris, ExportPeriod period, PeriodRange range, bool isAdmin)
        {
            var ws = wb.Worksheets.Add("Résumé");
            ws.ShowGridLines = false;

            var title = ws.Range("A1:D1").Merge();
            title.Value = $"Synthèse CRI — {range.Label}";
            title.Style.Font.FontSize = 16;
            title.Style.Font.Bold = true;
            title.Style.Font.FontColor = HeaderFg;
            title.Style.Fill.BackgroundColor = HeaderBg;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(1).Height = 28;

            var row = 3;
            ws.Cell(row, 1).Value = "Période"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = PeriodLabel(period);
            ws.Cell(row, 3).Value = "Portée"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = isAdmin ? "Tous les techniciens" : "Mes CRI";
            row++;

            ws.Cell(row, 1).Value = "Début"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = range.StartUtc;
            ws.Cell(row, 2).Style.DateFormat.Format = "dd/MM/yyyy";
            ws.Cell(row, 3).Value = "Fin"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = range.EndUtcExclusive.AddDays(-1);
            ws.Cell(row, 4).Style.DateFormat.Format = "dd/MM/yyyy";
            row += 2;

            SectionHeader(ws, row++, "Indicateurs clés");

            var total = cris.Count;
            var soumis = cris.Count(c => c.Status != "Draft");
            var brouillons = cris.Count(c => c.Status == "Draft");
            var services = cris.Count(c => c.InterventionType == "Service");
            var projets = total - services;
            var dureeTotale = cris.Sum(c => c.DureeMinutes ?? 0);
            var dureeMoyenne = total > 0 ? (double)dureeTotale / total / 60.0 : 0.0;
            var sites = cris.Select(c => c.Site?.NomDuSite ?? c.ClientSite ?? "").Where(s => !string.IsNullOrWhiteSpace(s)).Distinct().Count();
            var techniciens = cris.Select(c => c.TechnicianId).Distinct().Count();
            var resolus = cris.Count(c => c.ResolutionStatus == "resolu" || c.ProjectStatus == "termine");
            var tauxResolution = total > 0 ? Math.Round(resolus / (double)total * 100.0, 1) : 0.0;
            WriteKpi(ws, ref row, "Total CRI", total);
            WriteKpi(ws, ref row, "CRI soumis", soumis);
            WriteKpi(ws, ref row, "Brouillons", brouillons);
            WriteKpi(ws, ref row, "CRI Service", services);
            WriteKpi(ws, ref row, "CRI Projet", projets);
            WriteKpi(ws, ref row, "Durée totale (h)", Math.Round(dureeTotale / 60.0, 2));
            WriteKpi(ws, ref row, "Durée moyenne (h)", Math.Round(dureeMoyenne, 2));
            WriteKpi(ws, ref row, "Sites distincts", sites);
            if (isAdmin)
            {
                WriteKpi(ws, ref row, "Techniciens actifs", techniciens);
            }
            WriteKpi(ws, ref row, "Taux de résolution global (%)", tauxResolution, HighlightForRate(tauxResolution));

            row++;
            SectionHeader(ws, row++, "Évolution vs période précédente");

            var prevTotal = previousCris.Count;
            var prevDureeTotale = previousCris.Sum(c => c.DureeMinutes ?? 0);
            var prevResolus = previousCris.Count(c => c.ResolutionStatus == "resolu" || c.ProjectStatus == "termine");
            var prevTauxResolution = prevTotal > 0 ? Math.Round(prevResolus / (double)prevTotal * 100.0, 1) : 0.0;

            WriteTrendKpi(ws, ref row, "Nb interventions", total, prevTotal);
            WriteTrendKpi(ws, ref row, "Durée totale (h)", Math.Round(dureeTotale / 60.0, 2), Math.Round(prevDureeTotale / 60.0, 2));
            WriteTrendKpi(ws, ref row, "Taux de résolution (%)", tauxResolution, prevTauxResolution);

            row++;
            SectionHeader(ws, row++, "Répartition par catégorie");
            var categoryGroups = cris
                .GroupBy(c => string.IsNullOrWhiteSpace(c.Category) ? "(non renseignée)" : c.Category)
                .Select(g => (Label: g.Key, Count: g.Count()))
                .OrderByDescending(x => x.Count)
                .ToList();
            foreach (var (label, count) in categoryGroups)
            {
                var pct = total > 0 ? Math.Round(count / (double)total * 100.0, 1) : 0.0;
                WriteKpi(ws, ref row, label, $"{count} ({pct:0.#}%)");
            }
            if (categoryGroups.Count == 0)
            {
                ws.Cell(row, 1).Value = "Aucune donnée"; StyleLabel(ws.Cell(row, 1));
                row++;
            }

            ws.Column(1).Width = 26;
            ws.Column(2).Width = 22;
            ws.Column(3).Width = 26;
            ws.Column(4).Width = 26;

            var hasCharts = cris.Count > 0;
            if (hasCharts)
            {
                InsertCharts(ws, cris, period, range, services, projets);
            }

            ApplyPrintSetup(ws, landscape: hasCharts, repeatHeaderRow: false,
                lastColumnOverride: hasCharts ? 18 : null,
                lastRowOverride: hasCharts ? 80 : null);
        }

        private static void InsertCharts(IXLWorksheet ws, List<CRIForm> cris, ExportPeriod period, PeriodRange range, int services, int projets)
        {
            SectionHeader(ws, 3, "Graphiques");
            ws.Range(3, 6, 3, 10).Merge();

            var siteData = cris
                .GroupBy(c => c.Site?.NomDuSite ?? c.ClientSite ?? "(sans site)")
                .Select(g => (Label: g.Key, Value: (double)g.Count()))
                .OrderByDescending(x => x.Value)
                .Take(8)
                .ToList();
            if (siteData.Count > 0)
            {
                var bytes = ChartImageBuilder.BuildBarChart("Interventions par site (top 8)", siteData);
                using var ms = new MemoryStream(bytes);
                ws.AddPicture(ms, "chart-sites").MoveTo(ws.Cell(4, 6));
            }

            if (services > 0 || projets > 0)
            {
                var typeData = new List<(string Label, double Value)>();
                if (services > 0) typeData.Add(("Service", services));
                if (projets > 0) typeData.Add(("Projet", projets));
                var bytes = ChartImageBuilder.BuildPieChart("Répartition par type", typeData);
                using var ms = new MemoryStream(bytes);
                ws.AddPicture(ms, "chart-type").MoveTo(ws.Cell(24, 6));
            }

            var timelineData = BuildTimelineSeries(cris, period, range);
            if (timelineData.Count > 1)
            {
                var bytes = ChartImageBuilder.BuildLineChart("Évolution des interventions", timelineData);
                using var ms = new MemoryStream(bytes);
                ws.AddPicture(ms, "chart-timeline").MoveTo(ws.Cell(44, 6));
            }
        }

        private static List<(string Label, double Value)> BuildTimelineSeries(List<CRIForm> cris, ExportPeriod period, PeriodRange range)
        {
            var culture = System.Globalization.CultureInfo.GetCultureInfo("fr-FR");
            var result = new List<(string Label, double Value)>();

            if (period == ExportPeriod.Year)
            {
                var byMonth = cris.GroupBy(c => c.InterventionDate.Month).ToDictionary(g => g.Key, g => g.Count());
                for (var m = 1; m <= 12; m++)
                {
                    var label = culture.DateTimeFormat.GetAbbreviatedMonthName(m);
                    result.Add((label, byMonth.TryGetValue(m, out var count) ? count : 0));
                }
                return result;
            }

            var totalDays = Math.Max(1, (range.EndUtcExclusive - range.StartUtc).Days);
            var byDay = cris.GroupBy(c => c.InterventionDate.Date).ToDictionary(g => g.Key, g => g.Count());
            for (var i = 0; i < totalDays; i++)
            {
                var day = range.StartUtc.Date.AddDays(i);
                result.Add((day.ToString("dd/MM"), byDay.TryGetValue(day, out var count) ? count : 0));
            }
            return result;
        }

        private static void BuildInterventionsSheet(XLWorkbook wb, List<CRIForm> cris)
        {
            var ws = wb.Worksheets.Add("Interventions");

            string[] headers = {
                "Date", "Type", "Catégorie", "Numéro ticket/projet", "Statut",
                "Client", "Site", "Ville", "Technicien",
                "Durée (h)", "Heure début", "Heure fin", "Résolution", "Soumis le"
            };
            for (var i = 0; i < headers.Length; i++)
            {
                ws.Cell(1, i + 1).Value = headers[i];
            }
            StyleHeader(ws.Range(1, 1, 1, headers.Length));
            ws.SheetView.FreezeRows(1);

            var r = 2;
            foreach (var cri in cris)
            {
                if (r % 2 == 0)
                {
                    ws.Range(r, 1, r, headers.Length).Style.Fill.BackgroundColor = ZebraBg;
                }

                ws.Cell(r, 1).Value = cri.InterventionDate;
                ws.Cell(r, 1).Style.DateFormat.Format = "dd/MM/yyyy";
                ws.Cell(r, 2).Value = cri.InterventionType;
                ws.Cell(r, 3).Value = cri.Category;
                ws.Cell(r, 4).Value = cri.TicketNumber ?? cri.ProjectNumber ?? "-";
                ws.Cell(r, 5).Value = cri.Status;
                var statusBadge = BadgeForStatus(cri.Status);
                ws.Cell(r, 5).Style.Fill.BackgroundColor = statusBadge.Bg;
                ws.Cell(r, 5).Style.Font.FontColor = statusBadge.Fg;
                ws.Cell(r, 5).Style.Font.Bold = true;
                ws.Cell(r, 5).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                ws.Cell(r, 6).Value = cri.ClientName;
                ws.Cell(r, 7).Value = cri.Site?.NomDuSite ?? cri.ClientSite ?? "-";
                ws.Cell(r, 8).Value = cri.Ville ?? cri.Site?.Ville ?? "-";
                ws.Cell(r, 9).Value = cri.Technician != null
                    ? $"{cri.Technician.FirstName} {cri.Technician.LastName}".Trim()
                    : "-";
                ws.Cell(r, 10).Value = cri.DureeMinutes.HasValue ? Math.Round(cri.DureeMinutes.Value / 60.0, 2) : 0;
                ws.Cell(r, 11).Value = cri.HeureDebut?.ToString(@"hh\:mm") ?? "-";
                ws.Cell(r, 12).Value = cri.HeureFin?.ToString(@"hh\:mm") ?? "-";
                ws.Cell(r, 13).Value = cri.ResolutionStatus ?? cri.ProjectStatus ?? "-";
                var resolutionBadge = BadgeForResolution(cri.ResolutionStatus, cri.ProjectStatus);
                ws.Cell(r, 13).Style.Fill.BackgroundColor = resolutionBadge.Bg;
                ws.Cell(r, 13).Style.Font.FontColor = resolutionBadge.Fg;
                ws.Cell(r, 13).Style.Font.Bold = true;
                ws.Cell(r, 13).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                if (cri.SubmittedAt.HasValue)
                {
                    ws.Cell(r, 14).Value = cri.SubmittedAt.Value;
                    ws.Cell(r, 14).Style.DateFormat.Format = "dd/MM/yyyy HH:mm";
                }
                else
                {
                    ws.Cell(r, 14).Value = "-";
                }

                r++;
            }

            if (cris.Count == 0)
            {
                var empty = ws.Range(2, 1, 2, headers.Length).Merge();
                empty.Value = "Aucune intervention sur la période";
                empty.Style.Font.Italic = true;
                empty.Style.Font.FontColor = XLColor.FromHtml("#828AA0");
                empty.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            }
            else
            {
                var lastDataRow = r - 1;
                ws.Range(1, 1, lastDataRow, headers.Length).SetAutoFilter();

                var totalRow = r;
                var label = ws.Range(totalRow, 1, totalRow, 9).Merge();
                label.Value = $"TOTAL — {cris.Count} intervention(s)";
                label.Style.Font.Bold = true;
                label.Style.Font.FontColor = HeaderFg;
                label.Style.Fill.BackgroundColor = AccentBg;
                label.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;

                var totalDuree = ws.Cell(totalRow, 10);
                totalDuree.FormulaA1 = $"=SUM(J2:J{lastDataRow})";
                totalDuree.Style.NumberFormat.Format = "0.00";
                totalDuree.Style.Font.Bold = true;
                totalDuree.Style.Font.FontColor = HeaderFg;
                totalDuree.Style.Fill.BackgroundColor = AccentBg;

                ws.Range(totalRow, 11, totalRow, headers.Length).Style.Fill.BackgroundColor = AccentBg;
                ws.Row(totalRow).Height = 20;
                r++;
            }

            double[] widths = { 12, 12, 16, 18, 12, 22, 22, 16, 22, 12, 12, 12, 20, 18 };
            for (var i = 0; i < widths.Length; i++)
            {
                ws.Column(i + 1).Width = widths[i];
            }

            ApplyPrintSetup(ws, landscape: true, repeatHeaderRow: true);
        }

        private static void BuildBySiteSheet(XLWorkbook wb, List<CRIForm> cris)
        {
            var ws = wb.Worksheets.Add("Par site");

            string[] headers = { "Site", "Nb interventions", "Durée totale (h)", "Durée moyenne (h)", "Résolus", "Taux résolution (%)" };
            for (var i = 0; i < headers.Length; i++)
            {
                ws.Cell(1, i + 1).Value = headers[i];
            }
            StyleHeader(ws.Range(1, 1, 1, headers.Length));
            ws.SheetView.FreezeRows(1);

            var groups = cris
                .GroupBy(c => c.Site?.NomDuSite ?? c.ClientSite ?? "(sans site)")
                .Select(g =>
                {
                    var count = g.Count();
                    var totalMinutes = g.Sum(c => c.DureeMinutes ?? 0);
                    var resolus = g.Count(c => c.ResolutionStatus == "resolu" || c.ProjectStatus == "termine");
                    return new
                    {
                        Site = g.Key,
                        Count = count,
                        TotalHours = Math.Round(totalMinutes / 60.0, 2),
                        AvgHours = count > 0 ? Math.Round(totalMinutes / (double)count / 60.0, 2) : 0.0,
                        Resolus = resolus,
                        Taux = count > 0 ? Math.Round(resolus / (double)count * 100.0, 1) : 0.0,
                    };
                })
                .OrderByDescending(x => x.Count)
                .ToList();

            var r = 2;
            foreach (var g in groups)
            {
                if (r % 2 == 0)
                {
                    ws.Range(r, 1, r, headers.Length).Style.Fill.BackgroundColor = ZebraBg;
                }
                ws.Cell(r, 1).Value = g.Site;
                ws.Cell(r, 2).Value = g.Count;
                ws.Cell(r, 3).Value = g.TotalHours;
                ws.Cell(r, 4).Value = g.AvgHours;
                ws.Cell(r, 5).Value = g.Resolus;
                ws.Cell(r, 6).Value = g.Taux;
                var tauxBadge = HighlightForRate(g.Taux);
                ws.Cell(r, 6).Style.Fill.BackgroundColor = tauxBadge.Bg;
                ws.Cell(r, 6).Style.Font.FontColor = tauxBadge.Fg;
                ws.Cell(r, 6).Style.Font.Bold = true;
                ApplyRankBadge(ws.Cell(r, 1), r - 1);
                r++;
            }

            if (groups.Count > 0)
            {
                var lastDataRow = r - 1;
                ws.Range(1, 1, lastDataRow, headers.Length).SetAutoFilter();

                var totalRow = r;
                var totalCount = groups.Sum(g => g.Count);
                var totalHours = groups.Sum(g => g.TotalHours);
                var totalResolus = groups.Sum(g => g.Resolus);
                var totalTaux = totalCount > 0 ? Math.Round(totalResolus / (double)totalCount * 100.0, 1) : 0.0;

                var label = ws.Range(totalRow, 1, totalRow, 1);
                label.Value = "TOTAL";
                label.Style.Font.Bold = true;
                label.Style.Font.FontColor = HeaderFg;
                label.Style.Fill.BackgroundColor = AccentBg;

                ws.Cell(totalRow, 2).Value = totalCount;
                ws.Cell(totalRow, 3).Value = totalHours;
                ws.Cell(totalRow, 4).Value = totalCount > 0 ? Math.Round(totalHours / totalCount, 2) : 0.0;
                ws.Cell(totalRow, 5).Value = totalResolus;
                ws.Cell(totalRow, 6).Value = totalTaux;
                ws.Range(totalRow, 2, totalRow, headers.Length).Style.Fill.BackgroundColor = AccentBg;
                ws.Range(totalRow, 2, totalRow, headers.Length).Style.Font.FontColor = HeaderFg;
                ws.Range(totalRow, 1, totalRow, headers.Length).Style.Font.Bold = true;
                ws.Row(totalRow).Height = 20;
                r++;
            }
            double[] widths = { 32, 14, 16, 18, 12, 18 };
            for (var i = 0; i < widths.Length; i++)
            {
                ws.Column(i + 1).Width = widths[i];
            }

            ApplyPrintSetup(ws, landscape: false, repeatHeaderRow: true);
        }

        private static void BuildByTechnicianSheet(XLWorkbook wb, List<CRIForm> cris)
        {
            var ws = wb.Worksheets.Add("Par technicien");

            string[] headers = { "Technicien", "Email", "Nb interventions", "Durée totale (h)", "Durée moyenne (h)", "Résolus", "Taux résolution (%)" };
            for (var i = 0; i < headers.Length; i++)
            {
                ws.Cell(1, i + 1).Value = headers[i];
            }
            StyleHeader(ws.Range(1, 1, 1, headers.Length));
            ws.SheetView.FreezeRows(1);

            var groups = cris
                .GroupBy(c => new
                {
                    c.TechnicianId,
                    Name = c.Technician != null ? $"{c.Technician.FirstName} {c.Technician.LastName}".Trim() : c.TechnicianId.ToString(),
                    Email = c.Technician?.Email ?? "-"
                })
                .Select(g =>
                {
                    var count = g.Count();
                    var totalMinutes = g.Sum(c => c.DureeMinutes ?? 0);
                    var resolus = g.Count(c => c.ResolutionStatus == "resolu" || c.ProjectStatus == "termine");
                    return new
                    {
                        g.Key.Name,
                        g.Key.Email,
                        Count = count,
                        TotalHours = Math.Round(totalMinutes / 60.0, 2),
                        AvgHours = count > 0 ? Math.Round(totalMinutes / (double)count / 60.0, 2) : 0.0,
                        Resolus = resolus,
                        Taux = count > 0 ? Math.Round(resolus / (double)count * 100.0, 1) : 0.0,
                    };
                })
                .OrderByDescending(x => x.Count)
                .ToList();

            var r = 2;
            foreach (var g in groups)
            {
                if (r % 2 == 0)
                {
                    ws.Range(r, 1, r, headers.Length).Style.Fill.BackgroundColor = ZebraBg;
                }
                ws.Cell(r, 1).Value = g.Name;
                ws.Cell(r, 2).Value = g.Email;
                ws.Cell(r, 3).Value = g.Count;
                ws.Cell(r, 4).Value = g.TotalHours;
                ws.Cell(r, 5).Value = g.AvgHours;
                ws.Cell(r, 6).Value = g.Resolus;
                ws.Cell(r, 7).Value = g.Taux;
                var tauxBadge = HighlightForRate(g.Taux);
                ws.Cell(r, 7).Style.Fill.BackgroundColor = tauxBadge.Bg;
                ws.Cell(r, 7).Style.Font.FontColor = tauxBadge.Fg;
                ws.Cell(r, 7).Style.Font.Bold = true;
                ApplyRankBadge(ws.Cell(r, 1), r - 1);
                r++;
            }

            if (groups.Count > 0)
            {
                var lastDataRow = r - 1;
                ws.Range(1, 1, lastDataRow, headers.Length).SetAutoFilter();

                var totalRow = r;
                var totalCount = groups.Sum(g => g.Count);
                var totalHours = groups.Sum(g => g.TotalHours);
                var totalResolus = groups.Sum(g => g.Resolus);
                var totalTaux = totalCount > 0 ? Math.Round(totalResolus / (double)totalCount * 100.0, 1) : 0.0;

                var label = ws.Range(totalRow, 1, totalRow, 2).Merge();
                label.Value = "TOTAL";
                label.Style.Font.Bold = true;
                label.Style.Font.FontColor = HeaderFg;
                label.Style.Fill.BackgroundColor = AccentBg;

                ws.Cell(totalRow, 3).Value = totalCount;
                ws.Cell(totalRow, 4).Value = totalHours;
                ws.Cell(totalRow, 5).Value = totalCount > 0 ? Math.Round(totalHours / totalCount, 2) : 0.0;
                ws.Cell(totalRow, 6).Value = totalResolus;
                ws.Cell(totalRow, 7).Value = totalTaux;
                ws.Range(totalRow, 3, totalRow, headers.Length).Style.Fill.BackgroundColor = AccentBg;
                ws.Range(totalRow, 3, totalRow, headers.Length).Style.Font.FontColor = HeaderFg;
                ws.Range(totalRow, 1, totalRow, headers.Length).Style.Font.Bold = true;
                ws.Row(totalRow).Height = 20;
                r++;
            }
            double[] widths = { 28, 28, 16, 18, 18, 12, 18 };
            for (var i = 0; i < widths.Length; i++)
            {
                ws.Column(i + 1).Width = widths[i];
            }

            ApplyPrintSetup(ws, landscape: true, repeatHeaderRow: true);
        }

        // ──────────────────────────────────────────────────────────
        // Helpers
        // ──────────────────────────────────────────────────────────
        /// <summary>Mise en page impression: orientation, zone d'impression, en-tête/pied avec pagination.</summary>
        private static void ApplyPrintSetup(IXLWorksheet ws, bool landscape, bool repeatHeaderRow, int? lastColumnOverride = null, int? lastRowOverride = null)
        {
            var lastRow = lastRowOverride ?? ws.LastRowUsed()?.RowNumber() ?? 1;
            var lastColumn = lastColumnOverride ?? ws.LastColumnUsed()?.ColumnNumber() ?? 1;

            ws.PageSetup.PageOrientation = landscape ? XLPageOrientation.Landscape : XLPageOrientation.Portrait;
            ws.PageSetup.FitToPages(1, 0);
            ws.PageSetup.Margins.Top = 0.6;
            ws.PageSetup.Margins.Bottom = 0.6;
            ws.PageSetup.Margins.Left = 0.4;
            ws.PageSetup.Margins.Right = 0.4;
            ws.PageSetup.CenterHorizontally = true;
            ws.PageSetup.PrintAreas.Add(1, 1, lastRow, lastColumn);
            if (repeatHeaderRow)
            {
                ws.PageSetup.SetRowsToRepeatAtTop(1, 1);
            }

            ws.PageSetup.Header.Center.AddText("Novadis — Compte-rendu d'intervention", XLHFOccurrence.AllPages);
            ws.PageSetup.Footer.Left.AddText("Document confidentiel — usage interne", XLHFOccurrence.AllPages);
            ws.PageSetup.Footer.Right.AddText(XLHFPredefinedText.PageNumber, XLHFOccurrence.AllPages);
            ws.PageSetup.Footer.Right.AddText(" / ", XLHFOccurrence.AllPages);
            ws.PageSetup.Footer.Right.AddText(XLHFPredefinedText.NumberOfPages, XLHFOccurrence.AllPages);
        }

        private static void StyleHeader(IXLRange range)
        {
            range.Style.Font.Bold = true;
            range.Style.Font.FontColor = HeaderFg;
            range.Style.Fill.BackgroundColor = HeaderBg;
            range.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            range.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
            range.Style.Border.BottomBorderColor = AccentBg;
            range.Worksheet.Row(range.RangeAddress.FirstAddress.RowNumber).Height = 22;
        }

        private static void StyleLabel(IXLCell cell)
        {
            cell.Style.Fill.BackgroundColor = LabelBg;
            cell.Style.Font.Bold = true;
            cell.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
        }

        private static void SectionHeader(IXLWorksheet ws, int row, string text)
        {
            var range = ws.Range(row, 1, row, 4).Merge();
            range.Value = text;
            range.Style.Font.Bold = true;
            range.Style.Font.FontColor = HeaderFg;
            range.Style.Fill.BackgroundColor = AccentBg;
            range.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(row).Height = 20;
        }

        private static void WriteKpi(IXLWorksheet ws, ref int row, string label, object value, (XLColor Bg, XLColor Fg)? highlight = null)
        {
            ws.Cell(row, 1).Value = label; StyleLabel(ws.Cell(row, 1));
            var cell = ws.Cell(row, 2);
            switch (value)
            {
                case int i: cell.Value = i; break;
                case double d: cell.Value = d; break;
                default: cell.Value = value?.ToString() ?? "-"; break;
            }
            cell.Style.Font.Bold = true;
            cell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
            if (highlight.HasValue)
            {
                cell.Style.Fill.BackgroundColor = highlight.Value.Bg;
                cell.Style.Font.FontColor = highlight.Value.Fg;
            }
            row++;
        }

        /// <summary>Distingue visuellement le top 5 (classement déjà trié par nb interventions décroissant).</summary>
        private static void ApplyRankBadge(IXLCell nameCell, int rank)
        {
            switch (rank)
            {
                case 1:
                    nameCell.Value = "🥇 " + nameCell.GetString();
                    nameCell.Style.Fill.BackgroundColor = GoldBg;
                    nameCell.Style.Font.Bold = true;
                    break;
                case 2:
                    nameCell.Value = "🥈 " + nameCell.GetString();
                    nameCell.Style.Fill.BackgroundColor = SilverBg;
                    nameCell.Style.Font.Bold = true;
                    break;
                case 3:
                    nameCell.Value = "🥉 " + nameCell.GetString();
                    nameCell.Style.Fill.BackgroundColor = BronzeBg;
                    nameCell.Style.Font.Bold = true;
                    break;
                case 4:
                case 5:
                    nameCell.Style.Fill.BackgroundColor = TopFiveBg;
                    break;
            }
        }

        private static void WriteTrendKpi(IXLWorksheet ws, ref int row, string label, double current, double previous)
        {
            ws.Cell(row, 1).Value = label; StyleLabel(ws.Cell(row, 1));
            var currentCell = ws.Cell(row, 2);
            currentCell.Value = current;
            currentCell.Style.Font.Bold = true;
            currentCell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;

            ws.Cell(row, 3).Value = "vs période précédente"; StyleLabel(ws.Cell(row, 3));

            var delta = Math.Round(current - previous, 2);
            var deltaPct = previous != 0 ? Math.Round(delta / previous * 100.0, 1) : (current > 0 ? 100.0 : 0.0);
            var arrow = delta > 0 ? "▲" : delta < 0 ? "▼" : "→";
            var deltaCell = ws.Cell(row, 4);
            deltaCell.Value = $"{arrow} {(delta >= 0 ? "+" : "")}{delta} ({(deltaPct >= 0 ? "+" : "")}{deltaPct:0.#}%)";
            deltaCell.Style.Font.Bold = true;
            deltaCell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
            var (bg, fg) = delta > 0 ? (SuccessBg, SuccessFg) : delta < 0 ? (DangerBg, DangerFg) : (NeutralBg, NeutralFg);
            deltaCell.Style.Fill.BackgroundColor = bg;
            deltaCell.Style.Font.FontColor = fg;
            row++;
        }

        /// <summary>Seuils métier: &lt;50% critique, 50-80% à surveiller, &gt;=80% bon.</summary>
        private static (XLColor Bg, XLColor Fg) HighlightForRate(double ratePercent) => ratePercent switch
        {
            >= 80.0 => (SuccessBg, SuccessFg),
            >= 50.0 => (WarningBg, WarningFg),
            _ => (DangerBg, DangerFg),
        };

        private static (XLColor Bg, XLColor Fg) BadgeForStatus(string? status) => status switch
        {
            "Validated" => (SuccessBg, SuccessFg),
            "Submitted" => (WarningBg, WarningFg),
            "Draft" => (NeutralBg, NeutralFg),
            _ => (NeutralBg, NeutralFg),
        };

        private static (XLColor Bg, XLColor Fg) BadgeForResolution(string? resolutionStatus, string? projectStatus)
        {
            if (resolutionStatus == "resolu" || projectStatus == "termine") return (SuccessBg, SuccessFg);
            if (resolutionStatus == "nonResolu" || projectStatus == "suspendu") return (DangerBg, DangerFg);
            if (resolutionStatus == "partiellementResolu" || resolutionStatus == "enAttente" || projectStatus == "enCours") return (WarningBg, WarningFg);
            return (NeutralBg, NeutralFg);
        }

        /// <summary>
        /// Retire la syntaxe Markdown (gras, italique, titres, puces) pour
        /// obtenir du texte brut lisible dans une cellule Excel.
        /// </summary>
        private static string? StripMarkdown(string? input)
        {
            if (string.IsNullOrWhiteSpace(input)) return input;

            var text = input;
            // Puces / listes numérotées en début de ligne
            text = Regex.Replace(text, @"(?m)^\s*[-*+]\s+", "• ");
            text = Regex.Replace(text, @"(?m)^\s*\d+\.\s+", "");
            // Titres (# ..)
            text = Regex.Replace(text, @"(?m)^\s*#{1,6}\s*", "");
            // Gras / italique (**, __, *, _)
            text = Regex.Replace(text, @"(\*\*|__)(.+?)\1", "$2");
            text = Regex.Replace(text, @"(\*|_)(.+?)\1", "$2");
            // Code inline
            text = text.Replace("`", "");

            return text.Trim();
        }

        private static string FormatAddress(CRIForm cri)
        {
            var parts = new[]
            {
                cri.ClientAddress,
                cri.CodePostal,
                cri.Ville,
                cri.Pays,
            }.Where(p => !string.IsNullOrWhiteSpace(p));
            var joined = string.Join(", ", parts);
            return string.IsNullOrWhiteSpace(joined) ? "-" : joined;
        }

        private static string FormatDuration(CRIForm cri)
        {
            if (cri.DureeMinutes.HasValue && cri.DureeMinutes.Value > 0)
            {
                var h = cri.DureeMinutes.Value / 60;
                var m = cri.DureeMinutes.Value % 60;
                return $"{h}h{m:D2}";
            }
            if (cri.Duration.HasValue)
            {
                return $"{cri.Duration.Value:0.##}h";
            }
            return "-";
        }

        private static PeriodRange ComputeRange(ExportPeriod period, DateTime referenceDate)
        {
            var date = referenceDate.Date;
            return period switch
            {
                ExportPeriod.Day => new PeriodRange(
                    DateTime.SpecifyKind(date, DateTimeKind.Utc),
                    DateTime.SpecifyKind(date.AddDays(1), DateTimeKind.Utc),
                    $"Journée du {date:dd/MM/yyyy}"),
                ExportPeriod.Week => BuildWeekRange(date),
                ExportPeriod.Month => new PeriodRange(
                    DateTime.SpecifyKind(new DateTime(date.Year, date.Month, 1), DateTimeKind.Utc),
                    DateTime.SpecifyKind(new DateTime(date.Year, date.Month, 1).AddMonths(1), DateTimeKind.Utc),
                    $"Mois de {new DateTime(date.Year, date.Month, 1):MMMM yyyy}"),
                ExportPeriod.Year => new PeriodRange(
                    DateTime.SpecifyKind(new DateTime(date.Year, 1, 1), DateTimeKind.Utc),
                    DateTime.SpecifyKind(new DateTime(date.Year + 1, 1, 1), DateTimeKind.Utc),
                    $"Année {date.Year}"),
                _ => throw new ArgumentOutOfRangeException(nameof(period))
            };
        }

        private static PeriodRange ComputePreviousRange(ExportPeriod period, DateTime referenceDate)
        {
            var previousReferenceDate = period switch
            {
                ExportPeriod.Day => referenceDate.AddDays(-1),
                ExportPeriod.Week => referenceDate.AddDays(-7),
                ExportPeriod.Month => referenceDate.AddMonths(-1),
                ExportPeriod.Year => referenceDate.AddYears(-1),
                _ => referenceDate,
            };
            return ComputeRange(period, previousReferenceDate);
        }

        private static PeriodRange BuildWeekRange(DateTime date)
        {
            // Semaine ISO (lundi = début)
            var diff = ((int)date.DayOfWeek + 6) % 7; // lundi = 0
            var monday = date.AddDays(-diff);
            var nextMonday = monday.AddDays(7);
            return new PeriodRange(
                DateTime.SpecifyKind(monday, DateTimeKind.Utc),
                DateTime.SpecifyKind(nextMonday, DateTimeKind.Utc),
                $"Semaine du {monday:dd/MM/yyyy} au {nextMonday.AddDays(-1):dd/MM/yyyy}");
        }

        private static string PeriodSlug(ExportPeriod period) => period switch
        {
            ExportPeriod.Day => "jour",
            ExportPeriod.Week => "semaine",
            ExportPeriod.Month => "mois",
            ExportPeriod.Year => "annee",
            _ => "periode"
        };

        private static string PeriodLabel(ExportPeriod period) => period switch
        {
            ExportPeriod.Day => "Jour",
            ExportPeriod.Week => "Semaine",
            ExportPeriod.Month => "Mois",
            ExportPeriod.Year => "Année",
            _ => "Période"
        };
    }
}
