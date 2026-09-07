# Stage 1 — Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY NovadisApi.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# Stage 2 — Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# curl : requis par le healthcheck Docker de docker-compose.yml.
# Les images aspnet (Debian slim) n'embarquent ni curl ni wget.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p logs uploads/cri-photos export-storage \
    && chown -R app:app /app

COPY --from=build --chown=app:app /app/publish .

# Utilise l'utilisateur non-root intégré aux images .NET 8+
USER app
EXPOSE 5200

ENTRYPOINT ["dotnet", "NovadisApi.dll"]
