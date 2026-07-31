# Conventions de code — CRI Novadis 2.0

## Nommage

### Dart (Frontend)

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Fichiers | `snake_case.dart` | `cri_projet_controller.dart` |
| Classes | `PascalCase` | `CriProjetFormNotifier`, `CriRemoteRepository` |
| Méthodes / variables | `camelCase` | `saveDraft()`, `isLoading`, `lastAutoSave` |
| Membres privés | `_camelCase` | `_uuid`, `_db`, `_remoteRepo` |
| Constantes | `camelCase` (convention Dart) | `defaultTimeout` |
| Enums — type | `PascalCase` | `ProjectPhase`, `ProjetInterventionType` |
| Enums — valeurs | `camelCase` | `ProjectPhase.etude`, `.enCours`, `.cloture` |
| Providers Riverpod | `camelCaseProvider` | `criProjetFormProvider`, `appDatabaseProvider` |
| State classes | `[Feature]FormState` | `CriProjetFormState` |
| Routes (constantes) | `static const String` + `camelCase` | `static const String criForm = '/cri-form'` |
| Noms de route GoRouter | `kebab-case` | `'cri-new-projet'`, `'site-dashboard'` |

### C# (Backend)

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Fichiers | `PascalCase.cs` | `CRIController.cs`, `JwtService.cs` |
| Classes / méthodes | `PascalCase` | `GetMyCRIs()`, `CreateCRI()` |
| Champs privés | `_camelCase` | `_context`, `_logger`, `_authService` |
| Variables locales | `camelCase` | `userId`, `existing`, `photosDir` |
| Interfaces | `IPascalCase` | `IJwtService`, `IEmailService` |
| Contrôleurs | `[Entité]Controller` | `CRIController`, `AuthController` |
| DTOs | `[Nom]Dto` | `UserDto`, `AuthResponseDto` |

---

## Architecture

### Frontend — Feature-based

```
features/[nom]/
├── screens/        # Pages complètes (routes GoRouter)
├── widgets/        # Composants spécifiques à la feature
├── controllers/    # StateNotifier (logique métier)
├── data/           # Données statiques de la feature (modèles de saisie, listes…)
└── pages/          # Alias de screens si distincts
```

- **State** : Riverpod — `StateNotifierProvider` + classe `[Feature]State` immutable avec `copyWith()`
- **Navigation** : GoRouter — routes déclarées dans `AppRouter` avec constantes statiques
- **Réseau** : Dio singleton via `dioProvider` — intercepteur JWT + auto-refresh
- **Offline** : Drift (SQLite) — tables dans `data/local/`
- **Modèles** : `toJson()` / `fromJson()` manuels (pas de code-gen pour les modèles réseau)
- **Widgets** : constructeurs `const` systématiques, `super.key`

### Backend — MVC

```
Controllers/ → Services (interface + impl) → NovadisDbContext → PostgreSQL
```

- **DI** : `AddScoped<IInterface, Impl>()` dans `Program.cs`
- **Réponse API** : toujours `ApiResponse<T>.SuccessResponse(data)` / `ErrorResponse(msg)`
- **Auth** : `[Authorize]` au niveau classe + `[AllowAnonymous]` par action si besoin
- **Rôles** : `[RoleAuthorize("Admin")]` ou vérification inline `User.IsInRole("Admin")`
- **User ID** : `User.FindFirst(ClaimTypes.NameIdentifier)?.Value` via helper `GetCurrentUserId()`

---

## Gestion des erreurs

### Frontend

```dart
// Pattern repository — retourne toujours un type safe, jamais d'exception
Future<List<String>> getTechnicians() async {
  try {
    final response = await _dio.get('/users/technicians');
    return (response.data['data'] as List).map<String>((e) => ...).toList();
  } on DioException catch (e) {
    debugPrint('Erreur récupération techniciens: ${_handleError(e)}');
    return [];  // fallback silencieux
  }
}

// Extraction du message d'erreur API
String _handleError(DioException e) {
  return e.response?.data?['message'] ?? e.message ?? 'Erreur inconnue';
}
```

- Les repositories ne lèvent jamais d'exception — ils retournent des valeurs par défaut (liste vide, `null`)
- `debugPrint` pour les erreurs non-critiques (recherches, autocomplétion)
- Pas de crash — fallback gracieux systématique

### Backend

```csharp
// Pattern action controller
[HttpGet("{id}")]
public async Task<IActionResult> GetCRI(Guid id)
{
    try
    {
        // ...
        return Ok(ApiResponse<CRIForm>.SuccessResponse(cri));
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Erreur récupération CRI {Id}", id);
        return StatusCode(500, ApiResponse<object>.ErrorResponse("Erreur interne"));
    }
}
```

- Chaque action wrappée dans `try/catch`
- Log structuré : `_logger.LogError(ex, "message {Param}", param)`
- Jamais de stacktrace au client
- Audit trail : `AuditLog` pour les actions d'authentification

---

## Patterns de réponse API

```csharp
return Ok(ApiResponse<T>.SuccessResponse(data));           // 200
return Ok(ApiResponse<T>.SuccessResponse(data, "msg"));    // 200 avec message
return BadRequest(ApiResponse<T>.ErrorResponse("msg"));    // 400
return Unauthorized(ApiResponse<T>.ErrorResponse("msg"));  // 401
return NotFound(ApiResponse<T>.ErrorResponse("msg"));      // 404
return Forbid();                                           // 403 (pas de wrapper)
return StatusCode(500, ApiResponse<T>.ErrorResponse("msg")); // 500
```

Format JSON systématique :
```json
{ "success": true, "data": <T>, "message": "string?", "errors": [] }
```

Pagination via headers HTTP : `X-Total-Count`, `X-Page`, `X-Page-Size`, `X-Total-Pages`

---

## Thème / Design System (Frontend)

Police : **Inter** (Google Fonts) pour tous les styles de texte.

Tous les tokens sont dans la classe statique `AppTheme` (`core/theme/app_theme.dart`).

### Espacement (base 4px)

```dart
AppTheme.space4   // 4px
AppTheme.space8   // 8px
AppTheme.space12  // 12px
AppTheme.space16  // 16px
AppTheme.space20  // 20px
AppTheme.space24  // 24px
AppTheme.space32  // 32px
AppTheme.space40  // 40px
AppTheme.space48  // 48px
AppTheme.space64  // 64px
```

### Border radius

```dart
AppTheme.radiusSm    // 6px
AppTheme.radiusMd    // 8px
AppTheme.radiusLg    // 12px
AppTheme.radiusXl    // 16px
AppTheme.radiusFull  // 999px (pill)
```

### Couleurs sémantiques (adaptatives light/dark)

```dart
AppTheme.primary         // Noir Novadis (#1A1A1A)
AppTheme.primaryBlue     // Bleu logo (#8BB8E8)
AppTheme.background      // Fond principal
AppTheme.surface         // Fond carte/panel
AppTheme.surfaceVariant  // Fond variante
AppTheme.textPrimary     // Texte principal
AppTheme.textSecondary   // Texte secondaire
AppTheme.success / .warning / .error / .info
```

Mécanisme light/dark : interpolation via `AppTheme.themeT` (0.0 = light, 1.0 = dark).  
Ne jamais utiliser de couleurs hardcodées — toujours passer par `AppTheme`.

### Animations

```dart
AppTheme.animFast    // 150ms
AppTheme.animNormal  // 250ms
AppTheme.animSlow    // 350ms
```

### Ombres

```dart
AppTheme.shadowSm  // légère
AppTheme.shadowMd  // standard
AppTheme.shadowLg  // forte
```

---

## Commentaires

### Backend (C#)

```csharp
/// <summary>📧 POST /api/auth/login — Demander un code OTP</summary>
```

- XML doc (`/// <summary>`) sur tous les endpoints publics
- Émojis pour repérage visuel : 📧 email, ✅ succès, ⚠️ avertissement
- Commentaires inline en **français**

### Frontend (Dart)

- `///` uniquement sur les classes et méthodes publiques complexes
- Commentaires inline en **français**
- Pas de commentaire sur l'évident

---

## Configuration backend

Structure `appsettings.json` :

```json
{
  "ConnectionStrings": { "DefaultConnection": "" },
  "Jwt": { "SecretKey", "Issuer", "Audience", "ExpiryMinutes", "RefreshExpiryDays" },
  "Email": { "SmtpHost", "SmtpPort", "Username", "Password", "FromAddress", "FromName" },
  "Auth": { "CodeExpiryMinutes", "MagicLinkExpiryMinutes", "MaxFailedAttempts", "LockoutDurationMinutes" },
  "Retention": { "AuditLogDays", "AuthAttemptDays", "RevokedTokenDays" },
  "Cors": { "AllowedOrigins": [] }
}
```

Valeurs sensibles dans `.env` (jamais committé) — chargé via `DotNetEnv` au démarrage.

---

## Git

### Branches

| Préfixe | Usage |
|---------|-------|
| `feature/xxx` | Nouvelle fonctionnalité |
| `fix/xxx` | Correction de bug |
| `doc_xxx` | Documentation uniquement |
| `dev` | Branche d'intégration — déclenche les déploiements |
| `master` | Production |

### CI/CD triggers

- Push ou PR sur `dev` → tests CI + déploiement API (si backend modifié) + déploiement Vercel
- Push ou PR sur `master` → tests CI uniquement

### Endpoints dev-only

Les endpoints de debug sont protégés par compilation conditionnelle :

```csharp
#if !DEBUG
[ApiExplorerSettings(IgnoreApi = true)]
#endif
public async Task<IActionResult> GetLastCode(string email)
{
#if !DEBUG
    return NotFound();
#else
    _logger.LogWarning("⚠️ DEV ENDPOINT utilisé pour {Email}", email);
    // implémentation
#endif
}
```

### Taille des fichiers upload

Limite globale : **50 MB** (`[RequestSizeLimit(52_428_800)]`)  
Types MIME autorisés pour les photos : `image/jpeg`, `image/jpg`, `image/png`, `image/webp`
