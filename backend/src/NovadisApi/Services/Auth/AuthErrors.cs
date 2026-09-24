namespace NovadisApi.Services.Auth;

/// <summary>
/// Codes d'erreur métier exposés par <see cref="IAuthService"/>.
/// La couche HTTP les mappe en codes de statut.
/// </summary>
public enum AuthErrorCode
{
    None = 0,
    UserNotFound,
    InvalidCode,
    CodeExpired,
    InvalidToken,
    AccountInactive,
    DeviceNotRecognized,
    EmailDeliveryFailed,
    AccountLocked,
    Unexpected
}

/// <summary>
/// Résultat générique d'une opération métier d'auth.
/// </summary>
public sealed class AuthResult<T>
{
    public bool IsSuccess { get; init; }
    public T? Value { get; init; }
    public AuthErrorCode ErrorCode { get; init; }
    public string? ErrorMessage { get; init; }

    public static AuthResult<T> Success(T value) =>
        new() { IsSuccess = true, Value = value };

    public static AuthResult<T> Failure(AuthErrorCode code, string message) =>
        new() { IsSuccess = false, ErrorCode = code, ErrorMessage = message };
}
