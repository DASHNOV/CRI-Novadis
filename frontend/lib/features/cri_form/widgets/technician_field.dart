import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// Champ « Technicien intervenant » des formulaires CRI Service et Projet.
///
/// Liste déroulante alimentée par `/Users/technicians` (format `Prénom Nom`).
/// La saisie libre laissait passer l'ordre inverse `Nom Prénom` : le CRI
/// Service l'acceptait, le CRI Projet le refusait via une liste blanche à
/// comparaison exacte — même technicien, même nom, soumission bloquée d'un
/// côté seulement.
///
/// Repli en saisie libre quand [knownTechnicians] est vide (hors ligne, API
/// injoignable) : le formulaire doit rester utilisable sur site sans réseau.
class TechnicianField extends StatelessWidget {
  /// Nom du champ dans le FormBuilder parent (`technicianName_$index`).
  final String name;

  /// Valeur courante issue de `technicianNames[index]`.
  final String? value;

  /// Techniciens connus du serveur. Vide = hors ligne.
  final List<String> knownTechnicians;

  final ValueChanged<String> onChanged;

  const TechnicianField({
    super.key,
    required this.name,
    required this.value,
    required this.knownTechnicians,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = value?.trim() ?? '';

    if (knownTechnicians.isEmpty) {
      return FormBuilderTextField(
        name: name,
        initialValue: current,
        decoration: const InputDecoration(
          hintText: 'Nom du technicien',
          prefixIcon: Icon(Icons.person),
          helperText: 'Liste indisponible (hors ligne) — format : Prénom Nom',
        ),
        validator: FormBuilderValidators.required(
          errorText: 'Nom du technicien requis',
        ),
        onChanged: (v) => onChanged(v ?? ''),
      );
    }

    // Un CRI enregistré avant ce correctif — ou signé par un technicien
    // désactivé depuis — porte un nom absent de la liste. On l'ajoute comme
    // option pour ne pas perdre la valeur ni casser l'assertion du Dropdown.
    final options = List<String>.from(knownTechnicians);
    if (current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }

    return FormBuilderDropdown<String>(
      name: name,
      initialValue: current.isEmpty ? null : current,
      isExpanded: true,
      decoration: const InputDecoration(
        hintText: 'Sélectionner un technicien',
        prefixIcon: Icon(Icons.person),
      ),
      items: options
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(t, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      validator: FormBuilderValidators.required(
        errorText: 'Technicien requis',
      ),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
