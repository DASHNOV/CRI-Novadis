import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/utils/form_validators.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/features/cri_form/controllers/cri_projet_controller.dart';
import 'package:novadis_cri/features/cri_form/widgets/photo_picker.dart';
import 'package:novadis_cri/features/cri_form/widgets/rich_markdown_field.dart';
import 'package:novadis_cri/features/cri_form/widgets/signature_pad.dart';
import 'package:novadis_cri/features/cri_form/widgets/technician_field.dart';
import 'package:novadis_cri/services/user_api_service.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/data/models/site_model.dart';
import 'package:novadis_cri/features/cri_form/widgets/site_selector.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/features/cri_form/widgets/form_shared_widgets.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Page de formulaire CRI Projet avec 6 sections
class CriProjetFormPage extends ConsumerStatefulWidget {
  final String? criId; // null pour nouveau, string pour édition

  const CriProjetFormPage({super.key, this.criId});

  @override
  ConsumerState<CriProjetFormPage> createState() => _CriProjetFormPageState();
}

class _CriProjetFormPageState extends ConsumerState<CriProjetFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _currentStep = 0;
  final bool _autoSaveEnabled = true;
  bool _isMultiDay = false;
  bool _isMultiDayInitialized = false;

  // Controllers pour auto-complétion des champs à la sélection d'un site
  final _addressController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _paysController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _paysController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initForm();
    });
  }

  void _initForm() {
    final technicianName = ref.read(currentTechnicianNameProvider);
    final controller = ref.read(criProjetFormProvider.notifier);

    if (widget.criId != null) {
      controller.loadCri(widget.criId!);
    } else {
      controller.initNewForm(technicianName: technicianName);
    }

    // Initialiser les controllers avec les valeurs existantes
    final cri = ref.read(criProjetFormProvider).currentCri;
    if (cri != null) {
      _addressController.text = cri.address ?? '';
      _villeController.text = cri.ville ?? '';
      _codePostalController.text = cri.codePostal ?? '';
      _paysController.text = cri.pays ?? '';
    }
  }

  /// Appelé quand un site est sélectionné depuis le dropdown.
  /// Auto-remplit les champs adresse, ville, code postal et pays.
  void _onSiteSelected(SiteModel site) {
    final notifier = ref.read(criProjetFormProvider.notifier);
    notifier.updateClientInfo(
      site: site.nomDuSite,
      address: site.adresse,
      ville: site.ville,
      codePostal: site.codePostal,
      pays: site.pays,
    );

    // Mettre à jour les controllers de texte
    _addressController.text = site.adresse ?? '';
    _villeController.text = site.ville ?? '';
    _codePostalController.text = site.codePostal ?? '';
    _paysController.text = site.pays ?? '';

    // Mettre à jour les champs FormBuilder
    _formKey.currentState?.fields['address']?.didChange(site.adresse ?? '');
    _formKey.currentState?.fields['ville']?.didChange(site.ville ?? '');
    _formKey.currentState?.fields['codePostal']?.didChange(site.codePostal ?? '');
    _formKey.currentState?.fields['pays']?.didChange(site.pays ?? '');
  }

  Future<void> _autoSave() async {
    if (!_autoSaveEnabled) return;
    _formKey.currentState?.save();
    await ref.read(criProjetFormProvider.notifier).saveDraft();
  }

  /// Champs FormBuilder rattachés à chaque étape (pour validation ciblée).
  static const Map<int, List<String>> _stepFields = {
    0: ['interventionDate', 'startTime', 'endTime', 'endDate'],
    1: ['clientName', 'address', 'ville', 'codePostal', 'pays', 'clientContact', 'phone', 'email'],
    2: ['projectName', 'projectNumber', 'softwares'],
    3: ['interventionType', 'workDescription'],
    4: [],
  };

  /// Valide uniquement les champs de l'étape courante.
  bool _validateCurrentStep() {
    final fields = _formKey.currentState?.fields ?? {};
    final names = _stepFields[_currentStep] ?? const <String>[];
    var ok = true;
    for (final name in names) {
      final field = fields[name];
      if (field != null && !field.validate()) {
        ok = false;
      }
    }
    return ok;
  }

  void _showStepValidationError() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veuillez remplir les champs obligatoires avant de continuer'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onStepContinue() {
    if (!_validateCurrentStep()) {
      _showStepValidationError();
      return;
    }
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _autoSave();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  /// Valide tous les champs du formulaire, y compris ceux hors FormBuilder
  String? _validateCompleteForm() {
    final state = ref.read(criProjetFormProvider);
    final cri = state.currentCri;

    if (cri == null) {
      return 'Erreur: formulaire non initialisé';
    }

    // Vérifier qu'au moins un logiciel est sélectionné
    if (cri.softwares.isEmpty) {
      return 'Veuillez sélectionner au moins un logiciel utilisé';
    }

    // Vérifier la signature technicien
    if (cri.technicianSignature == null || cri.technicianSignature!.isEmpty) {
      return 'La signature du technicien est requise';
    }

    return null; // Tout est OK
  }

  Future<void> _submit() async {
    debugPrint('[CRI Projet] _submit() appelé');

    // D'abord valider les champs FormBuilder
    final formValid = _formKey.currentState?.saveAndValidate() ?? false;
    debugPrint('[CRI Projet] FormBuilder validation: $formValid');

    if (!formValid) {
      final fields = _formKey.currentState?.fields ?? {};
      final errorEntries = fields.entries
          .where((e) => e.value.hasError)
          .toList();
      
      debugPrint('[CRI Projet] Champs en erreur: ${errorEntries.map((e) => '${e.key}: ${e.value.errorText}').join(', ')}');

      final errors = errorEntries
          .map((e) => '• ${e.key}: ${e.value.errorText ?? 'invalide'}')
          .toList();
      final message = errors.isEmpty
          ? 'Veuillez corriger les erreurs dans le formulaire'
          : 'Erreurs de validation:\n${errors.join('\n')}';
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.warning,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Ensuite valider les champs personnalisés (signatures)
    final customValidationError = _validateCompleteForm();
    debugPrint('[CRI Projet] Custom validation: ${customValidationError ?? 'OK'}');

    if (customValidationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customValidationError),
            backgroundColor: AppTheme.warning,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Tout est valide, soumettre
    debugPrint('[CRI Projet] Soumission en cours...');
    final success = await ref.read(criProjetFormProvider.notifier).submit();
    debugPrint('[CRI Projet] Résultat soumission: $success');

    if (success && mounted) {
      // Afficher message d'erreur distant éventuel
      final errorMsg = ref.read(criProjetFormProvider).errorMessage;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'CRI Projet enregistré avec succès'),
          backgroundColor: errorMsg != null ? AppTheme.warning : AppTheme.success,
          duration: errorMsg != null
              ? const Duration(seconds: 8)
              : const Duration(seconds: 4),
        ),
      );
      context.pop();
    } else if (mounted) {
      final errorMsg = ref.read(criProjetFormProvider).errorMessage;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Erreur lors de la soumission'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final state = ref.watch(criProjetFormProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const CriFormLoadingScaffold(title: 'CRI Projet');
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildCriFormAppBar(
        context: context,
        title: widget.criId == null ? 'Nouveau CRI Projet' : 'Modifier CRI Projet',
        isDirty: state.isDirty,
        onSaveDraft: () => ref.read(criProjetFormProvider.notifier).saveDraft(),
      ),
      body: Column(
        children: [
          if (widget.criId != null &&
              state.currentCri != null &&
              !state.currentCri!.isDraft)
            _buildSubmittedEditBanner(),
          Expanded(
            child: FormBuilder(
        key: _formKey,
        child: ContentContainer(
          maxWidth: 900,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            onStepTapped: (index) {
              if (index > _currentStep && !_validateCurrentStep()) {
                _showStepValidationError();
                return;
              }
              setState(() => _currentStep = index);
            },
            controlsBuilder: (context, details) => buildCriFormControls(
              context,
              details,
              currentStep: _currentStep,
              lastStep: 4,
              isSaving: state.isSaving,
              onSubmit: _submit,
            ),
            steps: [
              _buildGeneralStep(state, theme),
              _buildClientStep(state, theme),
              _buildProjectStep(state, theme),
              _buildInterventionStep(state, theme),
              _buildValidationStep(state, theme),
            ],
          ),
        ),
      ),
            ),
        ],
      ),
      bottomNavigationBar: CriFormAutoSaveBar(lastAutoSave: state.lastAutoSave),
    );
  }

  /// Bannière d'avertissement affichée lors de l'édition d'un CRI déjà soumis.
  Widget _buildSubmittedEditBanner() {
    return Container(
      width: double.infinity,
      color: AppTheme.warning.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ce CRI a déjà été soumis. Vos modifications seront enregistrées '
              'sur le CRI existant.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section 1: Informations générales
  Step _buildGeneralStep(CriProjetFormState state, ThemeData theme) {
    // Initialisation lazy du switch depuis le modèle chargé
    if (!_isMultiDayInitialized && state.currentCri != null) {
      _isMultiDay = state.currentCri!.endDate != null;
      _isMultiDayInitialized = true;
    }

    return Step(
      title: const Text('Général'),
      subtitle: const Text('Date et heures'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date de début *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderDateTimePicker(
            name: 'interventionDate',
            initialValue: state.currentCri?.interventionDate ?? DateTime.now(),
            decoration: const InputDecoration(
              hintText: 'Date de début',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            inputType: InputType.date,
            format: DateFormat('dd/MM/yyyy'),
            validator: FormBuilderValidators.required(
              errorText: 'Date requise',
            ),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(criProjetFormProvider.notifier)
                    .updateGeneralInfo(interventionDate: value);
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heure début *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                    const SizedBox(height: 8),
                    FormBuilderDateTimePicker(
                      name: 'startTime',
                      initialValue:
                          state.currentCri?.startTime ?? DateTime.now(),
                      decoration: const InputDecoration(
                        hintText: 'Heure début',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      inputType: InputType.time,
                      format: DateFormat('HH:mm'),
                      validator: FormBuilderValidators.required(
                        errorText: 'Requise',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(criProjetFormProvider.notifier)
                              .updateGeneralInfo(startTime: value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heure fin *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                    const SizedBox(height: 8),
                    FormBuilderDateTimePicker(
                      name: 'endTime',
                      initialValue:
                          state.currentCri?.endTime ??
                          DateTime.now().add(const Duration(hours: 1)),
                      decoration: const InputDecoration(
                        hintText: 'Heure fin',
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      inputType: InputType.time,
                      format: DateFormat('HH:mm'),
                      validator: FormBuilderValidators.required(
                        errorText: 'Requise',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(criProjetFormProvider.notifier)
                              .updateGeneralInfo(endTime: value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: _isMultiDay,
                onChanged: (value) {
                  setState(() => _isMultiDay = value);
                  if (!value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateGeneralInfo(clearEndDate: true);
                  } else {
                    final cri = ref.read(criProjetFormProvider).currentCri;
                    final initialEndDate =
                        cri?.endDate ?? cri?.interventionDate ?? DateTime.now();
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateGeneralInfo(endDate: initialEndDate);
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Intervention sur plusieurs jours',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isMultiDay
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date de fin *', style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                        const SizedBox(height: 8),
                        FormBuilderDateTimePicker(
                          name: 'endDate',
                          initialValue: state.currentCri?.endDate ??
                              state.currentCri?.interventionDate ??
                              DateTime.now(),
                          decoration: const InputDecoration(
                            hintText: 'Date de fin',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          inputType: InputType.date,
                          format: DateFormat('dd/MM/yyyy'),
                          validator: FormBuilderValidators.required(
                            errorText: 'Date de fin requise',
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(criProjetFormProvider.notifier)
                                  .updateGeneralInfo(endDate: value);
                            }
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (state.currentCri != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Durée: ${state.currentCri!.formattedDuration}',
                style: TextStyle(
                  color: AppTheme.primaryContent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Section 2: Informations client
  Step _buildClientStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Client'),
      subtitle: const Text('Informations client'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final field1 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom du client *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderField<String>(
                  name: 'clientName',
                  initialValue: state.currentCri?.clientName ?? '',
                  validator: FormBuilderValidators.required(errorText: 'Nom requis'),
                  builder: (FormFieldState<String> field) {
                    return Autocomplete<String>(
                      initialValue: TextEditingValue(text: field.value ?? ''),
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return await ref
                            .read(criRemoteRepositoryProvider)
                            .searchClients(textEditingValue.text);
                      },
                      onSelected: (String selection) {
                        field.didChange(selection);
                        ref
                            .read(criProjetFormProvider.notifier)
                            .updateClientInfo(clientName: selection);
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            if (textEditingController.text != field.value &&
                                field.value != null &&
                                !focusNode.hasFocus) {
                              textEditingController.text = field.value!;
                            }
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Nom du client',
                                prefixIcon: const Icon(Icons.business),
                                errorText: field.errorText,
                              ),
                              textCapitalization: TextCapitalization.words,
                              onChanged: (val) {
                                field.didChange(val);
                                ref
                                    .read(criProjetFormProvider.notifier)
                                    .updateClientInfo(clientName: val);
                              },
                              onSubmitted: (_) => onFieldSubmitted(),
                            );
                          },
                    );
                  },
                ),
              ],
            );
            final field2 = SiteSelector(
              initialValue: state.currentCri?.site ?? '',
              repository: ref.read(criRemoteRepositoryProvider),
              onSiteSelected: _onSiteSelected,
              onSiteTextChanged: (val) {
                ref
                    .read(criProjetFormProvider.notifier)
                    .updateClientInfo(site: val);
              },
            );
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field1),
                  const SizedBox(width: 16),
                  Expanded(child: field2),
                ],
              );
            }
            return Column(children: [field1, const SizedBox(height: 16), field2]);
          }),
          const SizedBox(height: 16),
          Text('Adresse', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'address',
            controller: _addressController,
            initialValue: null,
            decoration: const InputDecoration(
              hintText: 'Adresse',
              prefixIcon: Icon(Icons.home),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateClientInfo(address: value);
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final villeField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ville *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'ville',
                  controller: _villeController,
                  initialValue: null,
                  decoration: const InputDecoration(
                    hintText: 'Ville',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: FormBuilderValidators.required(
                    errorText: 'Ville requise',
                  ),
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateClientInfo(ville: value);
                  },
                ),
              ],
            );
            final codePostalField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code postal', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'codePostal',
                  controller: _codePostalController,
                  initialValue: null,
                  decoration: const InputDecoration(
                    hintText: 'Code postal',
                    prefixIcon: Icon(Icons.markunread_mailbox),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateClientInfo(codePostal: value);
                  },
                ),
              ],
            );
            final paysField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pays', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'pays',
                  controller: _paysController,
                  initialValue: null,
                  decoration: const InputDecoration(
                    hintText: 'Pays',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateClientInfo(pays: value);
                  },
                ),
              ],
            );
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: villeField),
                  const SizedBox(width: 16),
                  Expanded(child: codePostalField),
                  const SizedBox(width: 16),
                  Expanded(child: paysField),
                ],
              );
            }
            return Column(children: [
              villeField,
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: codePostalField),
                const SizedBox(width: 16),
                Expanded(child: paysField),
              ]),
            ]);
          }),
          const SizedBox(height: 16),
          Text('Contact client', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'clientContact',
            initialValue: state.currentCri?.clientContact ?? '',
            decoration: const InputDecoration(
              hintText: 'Contact client',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateClientInfo(clientContact: value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Téléphone', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'phone',
                      initialValue: state.currentCri?.phone ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: CriFormValidators.frenchPhone(),
                      onChanged: (value) {
                        ref
                            .read(criProjetFormProvider.notifier)
                            .updateClientInfo(phone: value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'email',
                      initialValue: state.currentCri?.email ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: CriFormValidators.email(required: false),
                      onChanged: (value) {
                        ref
                            .read(criProjetFormProvider.notifier)
                            .updateClientInfo(email: value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 3: Informations projet
  Step _buildProjectStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Projet'),
      subtitle: const Text('Détails du projet'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final field1 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom du projet *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'projectName',
                  initialValue: state.currentCri?.projectName ?? '',
                  decoration: const InputDecoration(
                    hintText: 'Nom du projet',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  validator: FormBuilderValidators.required(errorText: 'Nom requis'),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateProjectInfo(projectName: value);
                  },
                ),
              ],
            );
            final field2 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Numéro de commande', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'projectNumber',
                  initialValue: state.currentCri?.projectNumber ?? '',
                  decoration: InputDecoration(
                    hintText: 'CCNNNNN',
                    prefixIcon: const Icon(Icons.tag),
                    helperText: 'Format: CCNNNNN (optionnel)',
                    suffixIcon: Tooltip(
                      message: 'Ex: CC09813',
                      child: Icon(
                        Icons.info_outline,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                  validator: CriFormValidators.commandeNumber(),
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateProjectInfo(projectNumber: value);
                  },
                ),
              ],
            );
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field1),
                  const SizedBox(width: 16),
                  Expanded(child: field2),
                ],
              );
            }
            return Column(children: [field1, const SizedBox(height: 16), field2]);
          }),
          const SizedBox(height: 24),
          _buildSoftwaresSection(state),
        ],
      ),
    );
  }

  /// Section "Logiciels utilisés" — sélection multiple + version par logiciel.
  /// Obligatoire : au moins un logiciel doit être sélectionné.
  Widget _buildSoftwaresSection(CriProjetFormState state) {
    final selected = state.currentCri?.softwares ?? const <SoftwareEntry>[];

    return FormBuilderField<List<SoftwareEntry>>(
      name: 'softwares',
      initialValue: selected,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Sélectionnez au moins un logiciel';
        }
        final autre = value.where((e) => e.software == ProjetSoftware.autre);
        if (autre.any((e) => (e.customName ?? '').trim().isEmpty)) {
          return 'Précisez le nom du logiciel pour « Autre »';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Logiciels utilisés *',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(sélection multiple)',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Chips de sélection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProjetSoftware.values.map((sw) {
                final isSelected =
                    selected.any((e) => e.software == sw);
                return FilterChip(
                  label: Text(sw.label),
                  selected: isSelected,
                  onSelected: (v) {
                    final list =
                        List<SoftwareEntry>.from(selected);
                    if (v) {
                      list.add(SoftwareEntry(software: sw));
                    } else {
                      list.removeWhere((e) => e.software == sw);
                    }
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateSoftwares(list);
                    field.didChange(list);
                  },
                );
              }).toList(),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText ?? '',
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            // Pour chaque logiciel sélectionné : champ Version libre.
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Version (facultatif)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...selected.map((entry) {
                final isAutre = entry.software == ProjetSoftware.autre;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pour "Autre" : saisie manuelle du nom du logiciel.
                      if (isAutre) ...[
                        TextFormField(
                          key: const ValueKey('custom-name-autre'),
                          initialValue: entry.customName ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Nom du logiciel *',
                            hintText: 'Précisez le logiciel utilisé',
                            isDense: true,
                            prefixIcon: Icon(Icons.edit_outlined),
                          ),
                          onChanged: (value) {
                            final list = selected.map((e) {
                              if (e.software == entry.software) {
                                return e.copyWith(
                                    customName:
                                        value.isEmpty ? null : value);
                              }
                              return e;
                            }).toList();
                            ref
                                .read(criProjetFormProvider.notifier)
                                .updateSoftwares(list);
                            field.didChange(list);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              entry.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(
                                  'version-${entry.software.name}'),
                              initialValue: entry.version ?? '',
                              decoration: const InputDecoration(
                                hintText: 'Ex: 5.4.2',
                                isDense: true,
                                prefixIcon: Icon(Icons.label_outline),
                              ),
                              onChanged: (value) {
                                final list = selected.map((e) {
                                  if (e.software == entry.software) {
                                    return e.copyWith(
                                        version: value.isEmpty
                                            ? null
                                            : value);
                                  }
                                  return e;
                                }).toList();
                                ref
                                    .read(criProjetFormProvider.notifier)
                                    .updateSoftwares(list);
                                field.didChange(list);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  /// Section 4: Intervention
  Step _buildInterventionStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Intervention'),
      subtitle: const Text('Travaux réalisés'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type d\'intervention *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderDropdown<ProjetInterventionType>(
            name: 'interventionType',
            initialValue:
                state.currentCri?.interventionType ??
                ProjetInterventionType.installationMateriel,
            decoration: const InputDecoration(
              hintText: 'Type d\'intervention',
              prefixIcon: Icon(Icons.category),
            ),
            items: ProjetInterventionType.values.map((type) {
              return DropdownMenuItem(value: type, child: Text(type.label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(criProjetFormProvider.notifier)
                    .updateInterventionInfo(interventionType: value);
              }
            },
          ),
          const SizedBox(height: 16),
          Text('Travail Effectué *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          RichMarkdownField(
            name: 'workDescription',
            label: 'Travail Effectué',
            initialValue: state.currentCri?.workDescription ?? '',
            hintText: 'Description des travaux',
            prefixIcon: Icons.description,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Description requise'),
              FormBuilderValidators.minLength(
                10,
                errorText: 'Minimum 10 caractères',
              ),
            ]),
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateInterventionInfo(workDescription: value);
            },
          ),
        ],
      ),
    );
  }

  /// Section 5: Validation
  Step _buildValidationStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Validation'),
      subtitle: const Text('Signatures et photos'),
      isActive: _currentStep >= 4,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoPicker(
            initialPhotos: state.currentCri?.photos ?? [],
            maxPhotos: 5,
            onPhotosChanged: (photos) {
              ref.read(criProjetFormProvider.notifier).updatePhotos(photos);
            },
          ),
          const SizedBox(height: 24),
          Text('Techniciens intervenants *', style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 8),
          ...List.generate(
            state.currentCri?.technicianNames.length ?? 1,
            (index) {
              final names = state.currentCri?.technicianNames ?? [''];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index > 0) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Technicien ${index + 1}',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (index > 0)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          tooltip: 'Retirer ce technicien',
                          onPressed: () {
                            ref.read(criProjetFormProvider.notifier).removeTechnician(index);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TechnicianField(
                    name: 'technicianName_$index',
                    value: index < names.length ? names[index] : '',
                    knownTechnicians: state.knownTechnicians,
                    onChanged: (value) {
                      ref.read(criProjetFormProvider.notifier).updateTechnicianInfo(technicianName: value, index: index);
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(criProjetFormProvider.notifier).addTechnician();
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter un technicien'),
          ),
          const SizedBox(height: 24),
          // Une seule signature suffit, même avec plusieurs techniciens.
          SignaturePadWidget(
            label: 'Signature technicien *',
            initialSignaturePath: state.currentCri?.technicianSignature,
            savedSignatureBase64: ref.watch(savedSignatureProvider).valueOrNull,
            onSignatureSaved: (path) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateTechnicianSignature(path, index: 0);
            },
          ),
          const SizedBox(height: 24),
          SignaturePadWidget(
            label: 'Signature client',
            initialSignaturePath: state.currentCri?.clientSignature,
            contextMarkdown: state.currentCri?.workDescription,
            onSignatureSaved: (path) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateClientSignature(path);
            },
          ),
          const SizedBox(height: 16),
          Text('Commentaires client', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'clientComments',
            initialValue: state.currentCri?.clientComments ?? '',
            decoration: const InputDecoration(
              hintText: 'Commentaires client',
              prefixIcon: Icon(Icons.comment),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateClientComments(value);
            },
          ),
        ],
      ),
    );
  }
}
