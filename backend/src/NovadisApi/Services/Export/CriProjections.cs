using System.Linq.Expressions;
using System.Reflection;
using Microsoft.EntityFrameworkCore.Metadata;
using NovadisApi.Models;

namespace NovadisApi.Services.Export
{
    /// <summary>
    /// Projections de <see cref="CRIForm"/> pour les traitements de masse (exports).
    /// </summary>
    public static class CriProjections
    {
        /// <summary>
        /// Colonnes lourdes, inutiles à un export tabulaire : le JSON complet du formulaire
        /// et les deux signatures base64 — l'essentiel du poids d'un CRI.
        /// </summary>
        public static readonly IReadOnlySet<string> HeavyColumns = new HashSet<string>
        {
            nameof(CRIForm.Data),
            nameof(CRIForm.TechnicianSignature),
            nameof(CRIForm.ClientSignature),
        };

        /// <summary>
        /// CRI sans <see cref="HeavyColumns"/>, avec <see cref="CRIForm.Technician"/> et
        /// <see cref="CRIForm.Site"/> chargés. La liste des colonnes est lue dans le modèle
        /// EF, pas écrite à la main : une colonne ajoutée plus tard est incluse d'office,
        /// au lieu d'arriver vide dans l'export sans que rien ne le signale.
        /// Les entités obtenues ne sont pas suivies par le contexte : lecture seule.
        /// </summary>
        public static IQueryable<CRIForm> WithoutHeavyColumns(this IQueryable<CRIForm> query, IModel model)
        {
            var entity = model.FindEntityType(typeof(CRIForm))
                ?? throw new InvalidOperationException("CRIForm absent du modèle EF.");

            var c = Expression.Parameter(typeof(CRIForm), "c");
            var bindings = entity.GetProperties()
                .Where(p => p.PropertyInfo != null && !HeavyColumns.Contains(p.Name))
                .Select(p => (MemberBinding)Expression.Bind(p.PropertyInfo!, Expression.Property(c, p.PropertyInfo!)))
                .Concat(new[] { nameof(CRIForm.Technician), nameof(CRIForm.Site) }
                    .Select(name => typeof(CRIForm).GetProperty(name, BindingFlags.Public | BindingFlags.Instance)!)
                    .Select(nav => (MemberBinding)Expression.Bind(nav, Expression.Property(c, nav))));

            var projection = Expression.Lambda<Func<CRIForm, CRIForm>>(
                Expression.MemberInit(Expression.New(typeof(CRIForm)), bindings), c);

            return query.Select(projection);
        }
    }
}
