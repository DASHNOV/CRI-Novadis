namespace NovadisApi.Services.Storage
{
    /// <summary>
    /// Stockage des exports sur le filesystem local.
    /// Chemin racine configurable via <c>Storage:RootPath</c> (par défaut <c>./export-storage</c>).
    /// </summary>
    public class LocalFileObjectStorage : IObjectStorageService
    {
        private readonly string _rootPath;
        private readonly Dictionary<string, string> _contentTypes = new()
        {
            [".pdf"] = "application/pdf",
            [".xlsx"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            [".csv"] = "text/csv; charset=utf-8",
        };

        public LocalFileObjectStorage(IConfiguration configuration, IWebHostEnvironment env)
        {
            var configured = configuration["Storage:RootPath"];
            _rootPath = string.IsNullOrWhiteSpace(configured)
                ? Path.Combine(env.ContentRootPath, "export-storage")
                : Path.IsPathRooted(configured) ? configured : Path.Combine(env.ContentRootPath, configured);

            Directory.CreateDirectory(_rootPath);
        }

        public async Task<string> UploadAsync(string objectKey, byte[] bytes, string contentType, CancellationToken ct = default)
        {
            var safePath = ResolveSafePath(objectKey);
            Directory.CreateDirectory(Path.GetDirectoryName(safePath)!);
            await File.WriteAllBytesAsync(safePath, bytes, ct);
            return objectKey;
        }

        public async Task<(byte[] Bytes, string ContentType)> DownloadAsync(string objectKey, CancellationToken ct = default)
        {
            var safePath = ResolveSafePath(objectKey);
            if (!File.Exists(safePath))
            {
                throw new FileNotFoundException($"Objet introuvable: {objectKey}");
            }

            var bytes = await File.ReadAllBytesAsync(safePath, ct);
            var ext = Path.GetExtension(objectKey).ToLowerInvariant();
            var contentType = _contentTypes.TryGetValue(ext, out var mime)
                ? mime
                : "application/octet-stream";
            return (bytes, contentType);
        }

        public Task DeleteAsync(string objectKey, CancellationToken ct = default)
        {
            var safePath = ResolveSafePath(objectKey);
            if (File.Exists(safePath))
            {
                File.Delete(safePath);
            }
            return Task.CompletedTask;
        }

        public Task<bool> ExistsAsync(string objectKey, CancellationToken ct = default)
        {
            return Task.FromResult(File.Exists(ResolveSafePath(objectKey)));
        }

        /// <summary>
        /// Valide la clé et empêche tout path traversal hors de <see cref="_rootPath"/>.
        /// </summary>
        private string ResolveSafePath(string objectKey)
        {
            if (string.IsNullOrWhiteSpace(objectKey))
            {
                throw new ArgumentException("objectKey invalide", nameof(objectKey));
            }

            var normalized = objectKey.Replace('\\', '/').TrimStart('/');
            var combined = Path.GetFullPath(Path.Combine(_rootPath, normalized));
            // Séparateur final obligatoire : sans lui, « export-storage-x/… » passerait
            // le contrôle de préfixe d'« export-storage ».
            var rootFull = Path.TrimEndingDirectorySeparator(Path.GetFullPath(_rootPath))
                + Path.DirectorySeparatorChar;

            if (!combined.StartsWith(rootFull, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Tentative d'accès hors du répertoire de stockage.");
            }

            return combined;
        }
    }
}
