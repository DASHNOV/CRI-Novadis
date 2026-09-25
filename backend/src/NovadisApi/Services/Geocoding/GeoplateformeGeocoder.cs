using System.Globalization;
using System.Net.Http.Headers;
using System.Text;

namespace NovadisApi.Services.Geocoding;

/// <summary>Adresse à géocoder ; <see cref="Id"/> sert à relier le résultat.</summary>
public sealed record GeocodingRequest(string Id, string? Adresse, string? CodePostal, string? Ville);

/// <summary>Résultat brut du géocodeur ; coordonnées <c>null</c> si non trouvé.</summary>
public sealed record GeocodingResult(string Id, double? Latitude, double? Longitude, double? Score, string? Type);

public interface IGeocoder
{
    Task<IReadOnlyList<GeocodingResult>> GeocodeAsync(
        IReadOnlyList<GeocodingRequest> requests, CancellationToken ct = default);
}

/// <summary>
/// Géocodage groupé par la Géoplateforme IGN (Base Adresse Nationale), gratuit et
/// sans clé : <c>POST /geocodage/search/csv</c>, un CSV par lot. Service limité à
/// 50 requêtes / s par IP — un lot = une requête.
/// </summary>
public sealed class GeoplateformeGeocoder : IGeocoder
{
    public const string HttpClientName = "geoplateforme";
    public const string DefaultBaseUrl = "https://data.geopf.fr/geocodage/";

    /// <summary>Lignes par requête (le service accepte jusqu'à 200 000 ; on reste modeste).</summary>
    private const int BatchSize = 1000;

    private readonly IHttpClientFactory _httpClientFactory;

    public GeoplateformeGeocoder(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory;
    }

    public async Task<IReadOnlyList<GeocodingResult>> GeocodeAsync(
        IReadOnlyList<GeocodingRequest> requests, CancellationToken ct = default)
    {
        var client = _httpClientFactory.CreateClient(HttpClientName);
        var results = new List<GeocodingResult>(requests.Count);
        foreach (var batch in requests.Chunk(BatchSize))
        {
            using var content = new MultipartFormDataContent();
            var file = new ByteArrayContent(Encoding.UTF8.GetBytes(BuildCsv(batch)));
            file.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
            content.Add(file, "data", "sites.csv");
            content.Add(new StringContent("adresse"), "columns");
            content.Add(new StringContent("ville"), "columns");
            content.Add(new StringContent("cp"), "postcode");

            using var response = await client.PostAsync("search/csv", content, ct);
            response.EnsureSuccessStatusCode();
            results.AddRange(ParseResults(await response.Content.ReadAsStringAsync(ct)));
        }
        return results;
    }

    public static string BuildCsv(IEnumerable<GeocodingRequest> requests)
    {
        var sb = new StringBuilder("id,adresse,cp,ville\n");
        foreach (var r in requests)
            sb.Append(Csv.Escape(r.Id)).Append(',')
              .Append(Csv.Escape(r.Adresse)).Append(',')
              .Append(Csv.Escape(r.CodePostal)).Append(',')
              .Append(Csv.Escape(r.Ville)).Append('\n');
        return sb.ToString();
    }

    /// <summary>
    /// Lit le CSV renvoyé : colonnes d'origine + <c>latitude</c>, <c>longitude</c>,
    /// <c>result_score</c>, <c>result_type</c>, <c>result_status</c> (<c>ok</c> / <c>not-found</c> / <c>error</c>).
    /// </summary>
    public static IEnumerable<GeocodingResult> ParseResults(string csv)
    {
        var rows = Csv.Parse(csv);
        if (rows.Count == 0) yield break;
        var header = rows[0];
        int Col(string name) => header.IndexOf(name);
        int id = Col("id"), lat = Col("latitude"), lon = Col("longitude"),
            score = Col("result_score"), type = Col("result_type"), status = Col("result_status");

        static double? Number(IReadOnlyList<string> row, int i) =>
            i >= 0 && i < row.Count && double.TryParse(row[i], NumberStyles.Float, CultureInfo.InvariantCulture, out var v)
                ? v : null;
        static string? Text(IReadOnlyList<string> row, int i) =>
            i >= 0 && i < row.Count && row[i].Length > 0 ? row[i] : null;

        foreach (var row in rows.Skip(1))
        {
            if (Text(row, id) is not { } rowId) continue;
            var found = Text(row, status) == "ok";
            yield return new GeocodingResult(
                rowId,
                found ? Number(row, lat) : null,
                found ? Number(row, lon) : null,
                found ? Number(row, score) : null,
                found ? Text(row, type) : null);
        }
    }
}

/// <summary>CSV minimal (RFC 4180) : guillemets, virgules et sauts de ligne dans les champs.</summary>
internal static class Csv
{
    public static string Escape(string? value)
    {
        if (string.IsNullOrEmpty(value)) return "";
        return value.IndexOfAny([',', '"', '\n', '\r']) >= 0
            ? $"\"{value.Replace("\"", "\"\"")}\""
            : value;
    }

    public static List<List<string>> Parse(string text)
    {
        var rows = new List<List<string>>();
        var row = new List<string>();
        var field = new StringBuilder();
        var quoted = false;
        for (var i = 0; i < text.Length; i++)
        {
            var c = text[i];
            if (quoted)
            {
                if (c == '"' && i + 1 < text.Length && text[i + 1] == '"') { field.Append('"'); i++; }
                else if (c == '"') quoted = false;
                else field.Append(c);
                continue;
            }
            switch (c)
            {
                case '"': quoted = true; break;
                case ',': row.Add(field.ToString()); field.Clear(); break;
                case '\r': break;
                case '\n':
                    row.Add(field.ToString()); field.Clear();
                    rows.Add(row); row = new List<string>();
                    break;
                default: field.Append(c); break;
            }
        }
        if (field.Length > 0 || row.Count > 0)
        {
            row.Add(field.ToString());
            rows.Add(row);
        }
        return rows;
    }
}
