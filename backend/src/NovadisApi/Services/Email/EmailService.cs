using System.Net;
using System.Net.Mail;
using Azure.Identity;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Graph;
using Microsoft.Graph.Models;
using Microsoft.Graph.Users.Item.SendMail;

namespace NovadisApi.Services.Email
{
    public interface IEmailService
    {
        Task SendAuthCodeEmailAsync(string toEmail, string code, string magicLink);
        Task SendWelcomeEmailAsync(string toEmail, string firstName);
        Task SendEmailAsync(string toEmail, string subject, string htmlBody);
    }

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;
        private readonly IWebHostEnvironment _env;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger, IWebHostEnvironment env)
        {
            _configuration = configuration;
            _logger = logger;
            _env = env;
        }

        /// <summary>
        /// Envoie un email avec le code d'authentification et le magic link
        /// </summary>
        public async Task SendAuthCodeEmailAsync(string toEmail, string code, string magicLink)
        {
            var subject = "Votre code de connexion Novadis CRI";
            
            var htmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                   color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
        .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
        .code-box {{ background: white; border: 2px dashed #667eea; padding: 20px; 
                     text-align: center; font-size: 32px; font-weight: bold; 
                     letter-spacing: 8px; margin: 20px 0; border-radius: 8px; }}
        .button {{ display: inline-block; background: #667eea; color: white; 
                   padding: 15px 30px; text-decoration: none; border-radius: 5px; 
                   margin: 20px 0; font-weight: bold; }}
        .footer {{ text-align: center; color: #888; font-size: 12px; margin-top: 30px; }}
        .warning {{ background: #fff3cd; border-left: 4px solid #ffc107; 
                    padding: 15px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🔐 Connexion à Novadis CRI</h1>
        </div>
        <div class='content'>
            <p>Bonjour,</p>
            <p>Vous avez demandé à vous connecter à l'application Novadis CRI.</p>
            
            <h3>Option 1 : Connexion rapide (recommandé)</h3>
            <p style='text-align: center;'>
                <a href='{magicLink}' class='button'>🚀 Se connecter directement</a>
            </p>
            
            <h3>Option 2 : Code de vérification</h3>
            <p>Si le bouton ne fonctionne pas, entrez ce code dans l'application :</p>
            <div class='code-box'>{code}</div>
            
            <div class='warning'>
                <strong>⚠️ Sécurité :</strong>
                <ul>
                    <li>Ce code expire dans <strong>10 minutes</strong></li>
                    <li>Ne partagez jamais ce code avec personne</li>
                    <li>Novadis ne vous demandera jamais ce code par téléphone</li>
                </ul>
            </div>
            
            <p>Si vous n'avez pas demandé cette connexion, ignorez cet email.</p>
        </div>
        <div class='footer'>
            <p>© {DateTime.Now.Year} Novadis - Application CRI</p>
            <p>Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
        </div>
    </div>
</body>
</html>";

            if (_env.IsDevelopment())
            {
                _logger.LogInformation("================================================");
                _logger.LogInformation("🔐 [DEV ONLY] VOTRE CODE DE CONNEXION : {Code}", code);
                _logger.LogInformation("================================================");
            }

            await SendEmailAsync(toEmail, subject, htmlBody);
        }

        /// <summary>
        /// Envoie un email de bienvenue
        /// </summary>
        public async Task SendWelcomeEmailAsync(string toEmail, string firstName)
        {
            var subject = "Bienvenue sur Novadis CRI";
            
            var htmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
</head>
<body style='font-family: Arial, sans-serif;'>
    <div style='max-width: 600px; margin: 0 auto; padding: 20px;'>
        <h2 style='color: #667eea;'>Bienvenue {firstName} ! 👋</h2>
        <p>Votre compte Novadis CRI a été créé avec succès.</p>
        <p>Vous pouvez maintenant vous connecter à l'application mobile pour gérer vos Comptes Rendus d'Intervention.</p>
        <p>Pour toute question, contactez votre responsable.</p>
        <p style='margin-top: 30px; color: #888; font-size: 12px;'>
            © {DateTime.Now.Year} Novadis
        </p>
    </div>
</body>
</html>";

            await SendEmailAsync(toEmail, subject, htmlBody);
        }

        /// <summary>
        /// Méthode générique d'envoi d'email
        /// </summary>
        public async Task SendEmailAsync(string toEmail, string subject, string htmlBody)
        {
            try
            {
                // En mode développement, on peut rediriger tous les emails vers une boîte de test
                var devOverrideEmail = _configuration["Email:DevOverrideEmail"];
                if (_env.IsDevelopment() && !string.IsNullOrEmpty(devOverrideEmail))
                {
                    _logger.LogInformation("🔄 [DEV MODE] Redirection de l'email de {OriginalTo} vers {OverrideTo}", toEmail, devOverrideEmail);
                    toEmail = devOverrideEmail;
                }

                var tenantId = _configuration["Email:TenantId"];
                var clientId = _configuration["Email:ClientId"];
                var clientSecret = _configuration["Email:ClientSecret"];
                var fromEmail = _configuration["Email:FromAddress"];

                if (string.IsNullOrEmpty(tenantId) || string.IsNullOrEmpty(clientId)
                    || string.IsNullOrEmpty(clientSecret) || string.IsNullOrEmpty(fromEmail))
                {
                    // Hors développement : ne jamais écrire le corps (code OTP, lien) dans les
                    // logs ni simuler un envoi réussi — l'échec doit remonter à l'appelant.
                    if (!_env.IsDevelopment())
                        throw new InvalidOperationException("Microsoft Graph n'est pas configuré : envoi d'e-mail impossible.");

                    _logger.LogWarning("⚠️ Microsoft Graph not configured. Mocking email send to {Email}", toEmail);
                    _logger.LogInformation("📧 Email Subject: {Subject}", subject);
                    _logger.LogInformation("📝 Email Body: {Body}", htmlBody);
                    return;
                }

                var credential = new ClientSecretCredential(tenantId, clientId, clientSecret);
                var graphClient = new GraphServiceClient(credential, new[] { "https://graph.microsoft.com/.default" });

                var message = new Message
                {
                    Subject = subject,
                    Body = new ItemBody
                    {
                        ContentType = BodyType.Html,
                        Content = htmlBody
                    },
                    ToRecipients = new List<Recipient>
                    {
                        new Recipient { EmailAddress = new EmailAddress { Address = toEmail } }
                    }
                };

                var sendMailBody = new SendMailPostRequestBody
                {
                    Message = message,
                    SaveToSentItems = false
                };

                await graphClient.Users[fromEmail].SendMail.PostAsync(sendMailBody);

                _logger.LogInformation("Email sent successfully to {Email} via Microsoft Graph", toEmail);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email to {Email}", toEmail);

                // En développement, si l'envoi échoue (SMTP mal configuré, firewall, etc.), 
                // on loggue le body pour permettre au dév de continuer.
                if (_env.IsDevelopment())
                {
                     _logger.LogWarning("⚠️ [DEV MODE] Email sending failed but suppressed. Mocking email content.");
                     _logger.LogInformation("📧 Email Subject: {Subject}", subject);
                     _logger.LogInformation("📝 Email Body: {Body}", htmlBody);
                     return; // On ne throw PAS l'exception pour que le login réussisse
                }
                
                throw;
            }
        }
    }
}
