// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CriServiceTableTable extends CriServiceTable
    with TableInfo<$CriServiceTableTable, CriService> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CriServiceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _interventionDateMeta =
      const VerificationMeta('interventionDate');
  @override
  late final GeneratedColumn<DateTime> interventionDate =
      GeneratedColumn<DateTime>('intervention_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _ticketNumberMeta =
      const VerificationMeta('ticketNumber');
  @override
  late final GeneratedColumn<String> ticketNumber = GeneratedColumn<String>(
      'ticket_number', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _clientNameMeta =
      const VerificationMeta('clientName');
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
      'client_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _siteMeta = const VerificationMeta('site');
  @override
  late final GeneratedColumn<String> site = GeneratedColumn<String>(
      'site', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _villeMeta = const VerificationMeta('ville');
  @override
  late final GeneratedColumn<String> ville = GeneratedColumn<String>(
      'ville', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _codePostalMeta =
      const VerificationMeta('codePostal');
  @override
  late final GeneratedColumn<String> codePostal = GeneratedColumn<String>(
      'code_postal', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paysMeta = const VerificationMeta('pays');
  @override
  late final GeneratedColumn<String> pays = GeneratedColumn<String>(
      'pays', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientContactMeta =
      const VerificationMeta('clientContact');
  @override
  late final GeneratedColumn<String> clientContact = GeneratedColumn<String>(
      'client_contact', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _requestTypeMeta =
      const VerificationMeta('requestType');
  @override
  late final GeneratedColumn<String> requestType = GeneratedColumn<String>(
      'request_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestDescriptionMeta =
      const VerificationMeta('requestDescription');
  @override
  late final GeneratedColumn<String> requestDescription =
      GeneratedColumn<String>('request_description', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contratTypeMeta =
      const VerificationMeta('contratType');
  @override
  late final GeneratedColumn<String> contratType = GeneratedColumn<String>(
      'contrat_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _systemTypesMeta =
      const VerificationMeta('systemTypes');
  @override
  late final GeneratedColumn<String> systemTypes = GeneratedColumn<String>(
      'system_types', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _diagnosticPerformedMeta =
      const VerificationMeta('diagnosticPerformed');
  @override
  late final GeneratedColumn<String> diagnosticPerformed =
      GeneratedColumn<String>('diagnostic_performed', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _identifiedCauseMeta =
      const VerificationMeta('identifiedCause');
  @override
  late final GeneratedColumn<String> identifiedCause = GeneratedColumn<String>(
      'identified_cause', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionsPerformedMeta =
      const VerificationMeta('actionsPerformed');
  @override
  late final GeneratedColumn<String> actionsPerformed = GeneratedColumn<String>(
      'actions_performed', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _replacedPartsMeta =
      const VerificationMeta('replacedParts');
  @override
  late final GeneratedColumn<String> replacedParts = GeneratedColumn<String>(
      'replaced_parts', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _interventionDurationMinutesMeta =
      const VerificationMeta('interventionDurationMinutes');
  @override
  late final GeneratedColumn<int> interventionDurationMinutes =
      GeneratedColumn<int>('intervention_duration_minutes', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _resolutionStatusMeta =
      const VerificationMeta('resolutionStatus');
  @override
  late final GeneratedColumn<String> resolutionStatus = GeneratedColumn<String>(
      'resolution_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _testsPerformedMeta =
      const VerificationMeta('testsPerformed');
  @override
  late final GeneratedColumn<String> testsPerformed = GeneratedColumn<String>(
      'tests_performed', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recommendationsMeta =
      const VerificationMeta('recommendations');
  @override
  late final GeneratedColumn<String> recommendations = GeneratedColumn<String>(
      'recommendations', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cybersecurityRecommendationsMeta =
      const VerificationMeta('cybersecurityRecommendations');
  @override
  late final GeneratedColumn<String> cybersecurityRecommendations =
      GeneratedColumn<String>(
          'cybersecurity_recommendations', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _additionalInterventionRequiredMeta =
      const VerificationMeta('additionalInterventionRequired');
  @override
  late final GeneratedColumn<bool> additionalInterventionRequired =
      GeneratedColumn<bool>(
          'additional_intervention_required', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("additional_intervention_required" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _followUpDateMeta =
      const VerificationMeta('followUpDate');
  @override
  late final GeneratedColumn<DateTime> followUpDate = GeneratedColumn<DateTime>(
      'follow_up_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _followUpCommentsMeta =
      const VerificationMeta('followUpComments');
  @override
  late final GeneratedColumn<String> followUpComments = GeneratedColumn<String>(
      'follow_up_comments', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _devisARealiserMeta =
      const VerificationMeta('devisARealiser');
  @override
  late final GeneratedColumn<bool> devisARealiser = GeneratedColumn<bool>(
      'devis_a_realiser', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("devis_a_realiser" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _facturableMeta =
      const VerificationMeta('facturable');
  @override
  late final GeneratedColumn<bool> facturable = GeneratedColumn<bool>(
      'facturable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("facturable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _photosMeta = const VerificationMeta('photos');
  @override
  late final GeneratedColumn<String> photos = GeneratedColumn<String>(
      'photos', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _technicianNameMeta =
      const VerificationMeta('technicianName');
  @override
  late final GeneratedColumn<String> technicianName = GeneratedColumn<String>(
      'technician_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _technicianSignatureMeta =
      const VerificationMeta('technicianSignature');
  @override
  late final GeneratedColumn<String> technicianSignature =
      GeneratedColumn<String>('technician_signature', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientSignatureMeta =
      const VerificationMeta('clientSignature');
  @override
  late final GeneratedColumn<String> clientSignature = GeneratedColumn<String>(
      'client_signature', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _isDraftMeta =
      const VerificationMeta('isDraft');
  @override
  late final GeneratedColumn<bool> isDraft = GeneratedColumn<bool>(
      'is_draft', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_draft" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        interventionDate,
        startTime,
        endTime,
        endDate,
        ticketNumber,
        clientName,
        site,
        address,
        ville,
        codePostal,
        pays,
        clientContact,
        phone,
        email,
        requestType,
        requestDescription,
        contratType,
        systemTypes,
        diagnosticPerformed,
        identifiedCause,
        actionsPerformed,
        replacedParts,
        interventionDurationMinutes,
        resolutionStatus,
        testsPerformed,
        recommendations,
        cybersecurityRecommendations,
        additionalInterventionRequired,
        followUpDate,
        followUpComments,
        devisARealiser,
        facturable,
        photos,
        technicianName,
        technicianSignature,
        clientSignature,
        createdAt,
        updatedAt,
        syncStatus,
        isDraft
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cri_service';
  @override
  VerificationContext validateIntegrity(Insertable<CriService> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('intervention_date')) {
      context.handle(
          _interventionDateMeta,
          interventionDate.isAcceptableOrUnknown(
              data['intervention_date']!, _interventionDateMeta));
    } else if (isInserting) {
      context.missing(_interventionDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('ticket_number')) {
      context.handle(
          _ticketNumberMeta,
          ticketNumber.isAcceptableOrUnknown(
              data['ticket_number']!, _ticketNumberMeta));
    }
    if (data.containsKey('client_name')) {
      context.handle(
          _clientNameMeta,
          clientName.isAcceptableOrUnknown(
              data['client_name']!, _clientNameMeta));
    } else if (isInserting) {
      context.missing(_clientNameMeta);
    }
    if (data.containsKey('site')) {
      context.handle(
          _siteMeta, site.isAcceptableOrUnknown(data['site']!, _siteMeta));
    } else if (isInserting) {
      context.missing(_siteMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('ville')) {
      context.handle(
          _villeMeta, ville.isAcceptableOrUnknown(data['ville']!, _villeMeta));
    }
    if (data.containsKey('code_postal')) {
      context.handle(
          _codePostalMeta,
          codePostal.isAcceptableOrUnknown(
              data['code_postal']!, _codePostalMeta));
    }
    if (data.containsKey('pays')) {
      context.handle(
          _paysMeta, pays.isAcceptableOrUnknown(data['pays']!, _paysMeta));
    }
    if (data.containsKey('client_contact')) {
      context.handle(
          _clientContactMeta,
          clientContact.isAcceptableOrUnknown(
              data['client_contact']!, _clientContactMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('request_type')) {
      context.handle(
          _requestTypeMeta,
          requestType.isAcceptableOrUnknown(
              data['request_type']!, _requestTypeMeta));
    } else if (isInserting) {
      context.missing(_requestTypeMeta);
    }
    if (data.containsKey('request_description')) {
      context.handle(
          _requestDescriptionMeta,
          requestDescription.isAcceptableOrUnknown(
              data['request_description']!, _requestDescriptionMeta));
    } else if (isInserting) {
      context.missing(_requestDescriptionMeta);
    }
    if (data.containsKey('contrat_type')) {
      context.handle(
          _contratTypeMeta,
          contratType.isAcceptableOrUnknown(
              data['contrat_type']!, _contratTypeMeta));
    }
    if (data.containsKey('system_types')) {
      context.handle(
          _systemTypesMeta,
          systemTypes.isAcceptableOrUnknown(
              data['system_types']!, _systemTypesMeta));
    }
    if (data.containsKey('diagnostic_performed')) {
      context.handle(
          _diagnosticPerformedMeta,
          diagnosticPerformed.isAcceptableOrUnknown(
              data['diagnostic_performed']!, _diagnosticPerformedMeta));
    }
    if (data.containsKey('identified_cause')) {
      context.handle(
          _identifiedCauseMeta,
          identifiedCause.isAcceptableOrUnknown(
              data['identified_cause']!, _identifiedCauseMeta));
    }
    if (data.containsKey('actions_performed')) {
      context.handle(
          _actionsPerformedMeta,
          actionsPerformed.isAcceptableOrUnknown(
              data['actions_performed']!, _actionsPerformedMeta));
    } else if (isInserting) {
      context.missing(_actionsPerformedMeta);
    }
    if (data.containsKey('replaced_parts')) {
      context.handle(
          _replacedPartsMeta,
          replacedParts.isAcceptableOrUnknown(
              data['replaced_parts']!, _replacedPartsMeta));
    }
    if (data.containsKey('intervention_duration_minutes')) {
      context.handle(
          _interventionDurationMinutesMeta,
          interventionDurationMinutes.isAcceptableOrUnknown(
              data['intervention_duration_minutes']!,
              _interventionDurationMinutesMeta));
    } else if (isInserting) {
      context.missing(_interventionDurationMinutesMeta);
    }
    if (data.containsKey('resolution_status')) {
      context.handle(
          _resolutionStatusMeta,
          resolutionStatus.isAcceptableOrUnknown(
              data['resolution_status']!, _resolutionStatusMeta));
    } else if (isInserting) {
      context.missing(_resolutionStatusMeta);
    }
    if (data.containsKey('tests_performed')) {
      context.handle(
          _testsPerformedMeta,
          testsPerformed.isAcceptableOrUnknown(
              data['tests_performed']!, _testsPerformedMeta));
    }
    if (data.containsKey('recommendations')) {
      context.handle(
          _recommendationsMeta,
          recommendations.isAcceptableOrUnknown(
              data['recommendations']!, _recommendationsMeta));
    }
    if (data.containsKey('cybersecurity_recommendations')) {
      context.handle(
          _cybersecurityRecommendationsMeta,
          cybersecurityRecommendations.isAcceptableOrUnknown(
              data['cybersecurity_recommendations']!,
              _cybersecurityRecommendationsMeta));
    }
    if (data.containsKey('additional_intervention_required')) {
      context.handle(
          _additionalInterventionRequiredMeta,
          additionalInterventionRequired.isAcceptableOrUnknown(
              data['additional_intervention_required']!,
              _additionalInterventionRequiredMeta));
    }
    if (data.containsKey('follow_up_date')) {
      context.handle(
          _followUpDateMeta,
          followUpDate.isAcceptableOrUnknown(
              data['follow_up_date']!, _followUpDateMeta));
    }
    if (data.containsKey('follow_up_comments')) {
      context.handle(
          _followUpCommentsMeta,
          followUpComments.isAcceptableOrUnknown(
              data['follow_up_comments']!, _followUpCommentsMeta));
    }
    if (data.containsKey('devis_a_realiser')) {
      context.handle(
          _devisARealiserMeta,
          devisARealiser.isAcceptableOrUnknown(
              data['devis_a_realiser']!, _devisARealiserMeta));
    }
    if (data.containsKey('facturable')) {
      context.handle(
          _facturableMeta,
          facturable.isAcceptableOrUnknown(
              data['facturable']!, _facturableMeta));
    }
    if (data.containsKey('photos')) {
      context.handle(_photosMeta,
          photos.isAcceptableOrUnknown(data['photos']!, _photosMeta));
    }
    if (data.containsKey('technician_name')) {
      context.handle(
          _technicianNameMeta,
          technicianName.isAcceptableOrUnknown(
              data['technician_name']!, _technicianNameMeta));
    } else if (isInserting) {
      context.missing(_technicianNameMeta);
    }
    if (data.containsKey('technician_signature')) {
      context.handle(
          _technicianSignatureMeta,
          technicianSignature.isAcceptableOrUnknown(
              data['technician_signature']!, _technicianSignatureMeta));
    }
    if (data.containsKey('client_signature')) {
      context.handle(
          _clientSignatureMeta,
          clientSignature.isAcceptableOrUnknown(
              data['client_signature']!, _clientSignatureMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('is_draft')) {
      context.handle(_isDraftMeta,
          isDraft.isAcceptableOrUnknown(data['is_draft']!, _isDraftMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CriService map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CriService(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      interventionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}intervention_date'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      ticketNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ticket_number']),
      clientName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_name'])!,
      site: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}site'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      ville: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ville']),
      codePostal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code_postal']),
      pays: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pays']),
      clientContact: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_contact']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      requestType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_type'])!,
      requestDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}request_description'])!,
      contratType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contrat_type']),
      systemTypes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}system_types']),
      diagnosticPerformed: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}diagnostic_performed']),
      identifiedCause: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}identified_cause']),
      actionsPerformed: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}actions_performed'])!,
      replacedParts: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}replaced_parts']),
      interventionDurationMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}intervention_duration_minutes'])!,
      resolutionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}resolution_status'])!,
      testsPerformed: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tests_performed']),
      recommendations: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recommendations']),
      cybersecurityRecommendations: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cybersecurity_recommendations']),
      additionalInterventionRequired: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}additional_intervention_required'])!,
      followUpDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}follow_up_date']),
      followUpComments: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}follow_up_comments']),
      devisARealiser: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}devis_a_realiser'])!,
      facturable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}facturable'])!,
      photos: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photos']),
      technicianName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}technician_name'])!,
      technicianSignature: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}technician_signature']),
      clientSignature: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_signature']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      isDraft: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_draft'])!,
    );
  }

  @override
  $CriServiceTableTable createAlias(String alias) {
    return $CriServiceTableTable(attachedDatabase, alias);
  }
}

class CriService extends DataClass implements Insertable<CriService> {
  final String id;
  final DateTime interventionDate;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? endDate;
  final String? ticketNumber;
  final String clientName;
  final String site;
  final String? address;
  final String? ville;
  final String? codePostal;
  final String? pays;
  final String? clientContact;
  final String? phone;
  final String? email;
  final String requestType;
  final String requestDescription;
  final String? contratType;
  final String? systemTypes;
  final String? diagnosticPerformed;
  final String? identifiedCause;
  final String actionsPerformed;
  final String? replacedParts;
  final int interventionDurationMinutes;
  final String resolutionStatus;
  final String? testsPerformed;
  final String? recommendations;
  final String? cybersecurityRecommendations;
  final bool additionalInterventionRequired;
  final DateTime? followUpDate;
  final String? followUpComments;
  final bool devisARealiser;
  final bool facturable;
  final String? photos;
  final String technicianName;
  final String? technicianSignature;
  final String? clientSignature;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;
  final bool isDraft;
  const CriService(
      {required this.id,
      required this.interventionDate,
      required this.startTime,
      required this.endTime,
      this.endDate,
      this.ticketNumber,
      required this.clientName,
      required this.site,
      this.address,
      this.ville,
      this.codePostal,
      this.pays,
      this.clientContact,
      this.phone,
      this.email,
      required this.requestType,
      required this.requestDescription,
      this.contratType,
      this.systemTypes,
      this.diagnosticPerformed,
      this.identifiedCause,
      required this.actionsPerformed,
      this.replacedParts,
      required this.interventionDurationMinutes,
      required this.resolutionStatus,
      this.testsPerformed,
      this.recommendations,
      this.cybersecurityRecommendations,
      required this.additionalInterventionRequired,
      this.followUpDate,
      this.followUpComments,
      required this.devisARealiser,
      required this.facturable,
      this.photos,
      required this.technicianName,
      this.technicianSignature,
      this.clientSignature,
      required this.createdAt,
      this.updatedAt,
      required this.syncStatus,
      required this.isDraft});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['intervention_date'] = Variable<DateTime>(interventionDate);
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || ticketNumber != null) {
      map['ticket_number'] = Variable<String>(ticketNumber);
    }
    map['client_name'] = Variable<String>(clientName);
    map['site'] = Variable<String>(site);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || ville != null) {
      map['ville'] = Variable<String>(ville);
    }
    if (!nullToAbsent || codePostal != null) {
      map['code_postal'] = Variable<String>(codePostal);
    }
    if (!nullToAbsent || pays != null) {
      map['pays'] = Variable<String>(pays);
    }
    if (!nullToAbsent || clientContact != null) {
      map['client_contact'] = Variable<String>(clientContact);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['request_type'] = Variable<String>(requestType);
    map['request_description'] = Variable<String>(requestDescription);
    if (!nullToAbsent || contratType != null) {
      map['contrat_type'] = Variable<String>(contratType);
    }
    if (!nullToAbsent || systemTypes != null) {
      map['system_types'] = Variable<String>(systemTypes);
    }
    if (!nullToAbsent || diagnosticPerformed != null) {
      map['diagnostic_performed'] = Variable<String>(diagnosticPerformed);
    }
    if (!nullToAbsent || identifiedCause != null) {
      map['identified_cause'] = Variable<String>(identifiedCause);
    }
    map['actions_performed'] = Variable<String>(actionsPerformed);
    if (!nullToAbsent || replacedParts != null) {
      map['replaced_parts'] = Variable<String>(replacedParts);
    }
    map['intervention_duration_minutes'] =
        Variable<int>(interventionDurationMinutes);
    map['resolution_status'] = Variable<String>(resolutionStatus);
    if (!nullToAbsent || testsPerformed != null) {
      map['tests_performed'] = Variable<String>(testsPerformed);
    }
    if (!nullToAbsent || recommendations != null) {
      map['recommendations'] = Variable<String>(recommendations);
    }
    if (!nullToAbsent || cybersecurityRecommendations != null) {
      map['cybersecurity_recommendations'] =
          Variable<String>(cybersecurityRecommendations);
    }
    map['additional_intervention_required'] =
        Variable<bool>(additionalInterventionRequired);
    if (!nullToAbsent || followUpDate != null) {
      map['follow_up_date'] = Variable<DateTime>(followUpDate);
    }
    if (!nullToAbsent || followUpComments != null) {
      map['follow_up_comments'] = Variable<String>(followUpComments);
    }
    map['devis_a_realiser'] = Variable<bool>(devisARealiser);
    map['facturable'] = Variable<bool>(facturable);
    if (!nullToAbsent || photos != null) {
      map['photos'] = Variable<String>(photos);
    }
    map['technician_name'] = Variable<String>(technicianName);
    if (!nullToAbsent || technicianSignature != null) {
      map['technician_signature'] = Variable<String>(technicianSignature);
    }
    if (!nullToAbsent || clientSignature != null) {
      map['client_signature'] = Variable<String>(clientSignature);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_draft'] = Variable<bool>(isDraft);
    return map;
  }

  CriServiceTableCompanion toCompanion(bool nullToAbsent) {
    return CriServiceTableCompanion(
      id: Value(id),
      interventionDate: Value(interventionDate),
      startTime: Value(startTime),
      endTime: Value(endTime),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      ticketNumber: ticketNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(ticketNumber),
      clientName: Value(clientName),
      site: Value(site),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      ville:
          ville == null && nullToAbsent ? const Value.absent() : Value(ville),
      codePostal: codePostal == null && nullToAbsent
          ? const Value.absent()
          : Value(codePostal),
      pays: pays == null && nullToAbsent ? const Value.absent() : Value(pays),
      clientContact: clientContact == null && nullToAbsent
          ? const Value.absent()
          : Value(clientContact),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      requestType: Value(requestType),
      requestDescription: Value(requestDescription),
      contratType: contratType == null && nullToAbsent
          ? const Value.absent()
          : Value(contratType),
      systemTypes: systemTypes == null && nullToAbsent
          ? const Value.absent()
          : Value(systemTypes),
      diagnosticPerformed: diagnosticPerformed == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosticPerformed),
      identifiedCause: identifiedCause == null && nullToAbsent
          ? const Value.absent()
          : Value(identifiedCause),
      actionsPerformed: Value(actionsPerformed),
      replacedParts: replacedParts == null && nullToAbsent
          ? const Value.absent()
          : Value(replacedParts),
      interventionDurationMinutes: Value(interventionDurationMinutes),
      resolutionStatus: Value(resolutionStatus),
      testsPerformed: testsPerformed == null && nullToAbsent
          ? const Value.absent()
          : Value(testsPerformed),
      recommendations: recommendations == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendations),
      cybersecurityRecommendations:
          cybersecurityRecommendations == null && nullToAbsent
              ? const Value.absent()
              : Value(cybersecurityRecommendations),
      additionalInterventionRequired: Value(additionalInterventionRequired),
      followUpDate: followUpDate == null && nullToAbsent
          ? const Value.absent()
          : Value(followUpDate),
      followUpComments: followUpComments == null && nullToAbsent
          ? const Value.absent()
          : Value(followUpComments),
      devisARealiser: Value(devisARealiser),
      facturable: Value(facturable),
      photos:
          photos == null && nullToAbsent ? const Value.absent() : Value(photos),
      technicianName: Value(technicianName),
      technicianSignature: technicianSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(technicianSignature),
      clientSignature: clientSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(clientSignature),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      syncStatus: Value(syncStatus),
      isDraft: Value(isDraft),
    );
  }

  factory CriService.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CriService(
      id: serializer.fromJson<String>(json['id']),
      interventionDate: serializer.fromJson<DateTime>(json['interventionDate']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      ticketNumber: serializer.fromJson<String?>(json['ticketNumber']),
      clientName: serializer.fromJson<String>(json['clientName']),
      site: serializer.fromJson<String>(json['site']),
      address: serializer.fromJson<String?>(json['address']),
      ville: serializer.fromJson<String?>(json['ville']),
      codePostal: serializer.fromJson<String?>(json['codePostal']),
      pays: serializer.fromJson<String?>(json['pays']),
      clientContact: serializer.fromJson<String?>(json['clientContact']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      requestType: serializer.fromJson<String>(json['requestType']),
      requestDescription:
          serializer.fromJson<String>(json['requestDescription']),
      contratType: serializer.fromJson<String?>(json['contratType']),
      systemTypes: serializer.fromJson<String?>(json['systemTypes']),
      diagnosticPerformed:
          serializer.fromJson<String?>(json['diagnosticPerformed']),
      identifiedCause: serializer.fromJson<String?>(json['identifiedCause']),
      actionsPerformed: serializer.fromJson<String>(json['actionsPerformed']),
      replacedParts: serializer.fromJson<String?>(json['replacedParts']),
      interventionDurationMinutes:
          serializer.fromJson<int>(json['interventionDurationMinutes']),
      resolutionStatus: serializer.fromJson<String>(json['resolutionStatus']),
      testsPerformed: serializer.fromJson<String?>(json['testsPerformed']),
      recommendations: serializer.fromJson<String?>(json['recommendations']),
      cybersecurityRecommendations:
          serializer.fromJson<String?>(json['cybersecurityRecommendations']),
      additionalInterventionRequired:
          serializer.fromJson<bool>(json['additionalInterventionRequired']),
      followUpDate: serializer.fromJson<DateTime?>(json['followUpDate']),
      followUpComments: serializer.fromJson<String?>(json['followUpComments']),
      devisARealiser: serializer.fromJson<bool>(json['devisARealiser']),
      facturable: serializer.fromJson<bool>(json['facturable']),
      photos: serializer.fromJson<String?>(json['photos']),
      technicianName: serializer.fromJson<String>(json['technicianName']),
      technicianSignature:
          serializer.fromJson<String?>(json['technicianSignature']),
      clientSignature: serializer.fromJson<String?>(json['clientSignature']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDraft: serializer.fromJson<bool>(json['isDraft']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'interventionDate': serializer.toJson<DateTime>(interventionDate),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'ticketNumber': serializer.toJson<String?>(ticketNumber),
      'clientName': serializer.toJson<String>(clientName),
      'site': serializer.toJson<String>(site),
      'address': serializer.toJson<String?>(address),
      'ville': serializer.toJson<String?>(ville),
      'codePostal': serializer.toJson<String?>(codePostal),
      'pays': serializer.toJson<String?>(pays),
      'clientContact': serializer.toJson<String?>(clientContact),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'requestType': serializer.toJson<String>(requestType),
      'requestDescription': serializer.toJson<String>(requestDescription),
      'contratType': serializer.toJson<String?>(contratType),
      'systemTypes': serializer.toJson<String?>(systemTypes),
      'diagnosticPerformed': serializer.toJson<String?>(diagnosticPerformed),
      'identifiedCause': serializer.toJson<String?>(identifiedCause),
      'actionsPerformed': serializer.toJson<String>(actionsPerformed),
      'replacedParts': serializer.toJson<String?>(replacedParts),
      'interventionDurationMinutes':
          serializer.toJson<int>(interventionDurationMinutes),
      'resolutionStatus': serializer.toJson<String>(resolutionStatus),
      'testsPerformed': serializer.toJson<String?>(testsPerformed),
      'recommendations': serializer.toJson<String?>(recommendations),
      'cybersecurityRecommendations':
          serializer.toJson<String?>(cybersecurityRecommendations),
      'additionalInterventionRequired':
          serializer.toJson<bool>(additionalInterventionRequired),
      'followUpDate': serializer.toJson<DateTime?>(followUpDate),
      'followUpComments': serializer.toJson<String?>(followUpComments),
      'devisARealiser': serializer.toJson<bool>(devisARealiser),
      'facturable': serializer.toJson<bool>(facturable),
      'photos': serializer.toJson<String?>(photos),
      'technicianName': serializer.toJson<String>(technicianName),
      'technicianSignature': serializer.toJson<String?>(technicianSignature),
      'clientSignature': serializer.toJson<String?>(clientSignature),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDraft': serializer.toJson<bool>(isDraft),
    };
  }

  CriService copyWith(
          {String? id,
          DateTime? interventionDate,
          DateTime? startTime,
          DateTime? endTime,
          Value<DateTime?> endDate = const Value.absent(),
          Value<String?> ticketNumber = const Value.absent(),
          String? clientName,
          String? site,
          Value<String?> address = const Value.absent(),
          Value<String?> ville = const Value.absent(),
          Value<String?> codePostal = const Value.absent(),
          Value<String?> pays = const Value.absent(),
          Value<String?> clientContact = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          String? requestType,
          String? requestDescription,
          Value<String?> contratType = const Value.absent(),
          Value<String?> systemTypes = const Value.absent(),
          Value<String?> diagnosticPerformed = const Value.absent(),
          Value<String?> identifiedCause = const Value.absent(),
          String? actionsPerformed,
          Value<String?> replacedParts = const Value.absent(),
          int? interventionDurationMinutes,
          String? resolutionStatus,
          Value<String?> testsPerformed = const Value.absent(),
          Value<String?> recommendations = const Value.absent(),
          Value<String?> cybersecurityRecommendations = const Value.absent(),
          bool? additionalInterventionRequired,
          Value<DateTime?> followUpDate = const Value.absent(),
          Value<String?> followUpComments = const Value.absent(),
          bool? devisARealiser,
          bool? facturable,
          Value<String?> photos = const Value.absent(),
          String? technicianName,
          Value<String?> technicianSignature = const Value.absent(),
          Value<String?> clientSignature = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent(),
          String? syncStatus,
          bool? isDraft}) =>
      CriService(
        id: id ?? this.id,
        interventionDate: interventionDate ?? this.interventionDate,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        endDate: endDate.present ? endDate.value : this.endDate,
        ticketNumber:
            ticketNumber.present ? ticketNumber.value : this.ticketNumber,
        clientName: clientName ?? this.clientName,
        site: site ?? this.site,
        address: address.present ? address.value : this.address,
        ville: ville.present ? ville.value : this.ville,
        codePostal: codePostal.present ? codePostal.value : this.codePostal,
        pays: pays.present ? pays.value : this.pays,
        clientContact:
            clientContact.present ? clientContact.value : this.clientContact,
        phone: phone.present ? phone.value : this.phone,
        email: email.present ? email.value : this.email,
        requestType: requestType ?? this.requestType,
        requestDescription: requestDescription ?? this.requestDescription,
        contratType: contratType.present ? contratType.value : this.contratType,
        systemTypes: systemTypes.present ? systemTypes.value : this.systemTypes,
        diagnosticPerformed: diagnosticPerformed.present
            ? diagnosticPerformed.value
            : this.diagnosticPerformed,
        identifiedCause: identifiedCause.present
            ? identifiedCause.value
            : this.identifiedCause,
        actionsPerformed: actionsPerformed ?? this.actionsPerformed,
        replacedParts:
            replacedParts.present ? replacedParts.value : this.replacedParts,
        interventionDurationMinutes:
            interventionDurationMinutes ?? this.interventionDurationMinutes,
        resolutionStatus: resolutionStatus ?? this.resolutionStatus,
        testsPerformed:
            testsPerformed.present ? testsPerformed.value : this.testsPerformed,
        recommendations: recommendations.present
            ? recommendations.value
            : this.recommendations,
        cybersecurityRecommendations: cybersecurityRecommendations.present
            ? cybersecurityRecommendations.value
            : this.cybersecurityRecommendations,
        additionalInterventionRequired: additionalInterventionRequired ??
            this.additionalInterventionRequired,
        followUpDate:
            followUpDate.present ? followUpDate.value : this.followUpDate,
        followUpComments: followUpComments.present
            ? followUpComments.value
            : this.followUpComments,
        devisARealiser: devisARealiser ?? this.devisARealiser,
        facturable: facturable ?? this.facturable,
        photos: photos.present ? photos.value : this.photos,
        technicianName: technicianName ?? this.technicianName,
        technicianSignature: technicianSignature.present
            ? technicianSignature.value
            : this.technicianSignature,
        clientSignature: clientSignature.present
            ? clientSignature.value
            : this.clientSignature,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        isDraft: isDraft ?? this.isDraft,
      );
  CriService copyWithCompanion(CriServiceTableCompanion data) {
    return CriService(
      id: data.id.present ? data.id.value : this.id,
      interventionDate: data.interventionDate.present
          ? data.interventionDate.value
          : this.interventionDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      ticketNumber: data.ticketNumber.present
          ? data.ticketNumber.value
          : this.ticketNumber,
      clientName:
          data.clientName.present ? data.clientName.value : this.clientName,
      site: data.site.present ? data.site.value : this.site,
      address: data.address.present ? data.address.value : this.address,
      ville: data.ville.present ? data.ville.value : this.ville,
      codePostal:
          data.codePostal.present ? data.codePostal.value : this.codePostal,
      pays: data.pays.present ? data.pays.value : this.pays,
      clientContact: data.clientContact.present
          ? data.clientContact.value
          : this.clientContact,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      requestType:
          data.requestType.present ? data.requestType.value : this.requestType,
      requestDescription: data.requestDescription.present
          ? data.requestDescription.value
          : this.requestDescription,
      contratType:
          data.contratType.present ? data.contratType.value : this.contratType,
      systemTypes:
          data.systemTypes.present ? data.systemTypes.value : this.systemTypes,
      diagnosticPerformed: data.diagnosticPerformed.present
          ? data.diagnosticPerformed.value
          : this.diagnosticPerformed,
      identifiedCause: data.identifiedCause.present
          ? data.identifiedCause.value
          : this.identifiedCause,
      actionsPerformed: data.actionsPerformed.present
          ? data.actionsPerformed.value
          : this.actionsPerformed,
      replacedParts: data.replacedParts.present
          ? data.replacedParts.value
          : this.replacedParts,
      interventionDurationMinutes: data.interventionDurationMinutes.present
          ? data.interventionDurationMinutes.value
          : this.interventionDurationMinutes,
      resolutionStatus: data.resolutionStatus.present
          ? data.resolutionStatus.value
          : this.resolutionStatus,
      testsPerformed: data.testsPerformed.present
          ? data.testsPerformed.value
          : this.testsPerformed,
      recommendations: data.recommendations.present
          ? data.recommendations.value
          : this.recommendations,
      cybersecurityRecommendations: data.cybersecurityRecommendations.present
          ? data.cybersecurityRecommendations.value
          : this.cybersecurityRecommendations,
      additionalInterventionRequired:
          data.additionalInterventionRequired.present
              ? data.additionalInterventionRequired.value
              : this.additionalInterventionRequired,
      followUpDate: data.followUpDate.present
          ? data.followUpDate.value
          : this.followUpDate,
      followUpComments: data.followUpComments.present
          ? data.followUpComments.value
          : this.followUpComments,
      devisARealiser: data.devisARealiser.present
          ? data.devisARealiser.value
          : this.devisARealiser,
      facturable:
          data.facturable.present ? data.facturable.value : this.facturable,
      photos: data.photos.present ? data.photos.value : this.photos,
      technicianName: data.technicianName.present
          ? data.technicianName.value
          : this.technicianName,
      technicianSignature: data.technicianSignature.present
          ? data.technicianSignature.value
          : this.technicianSignature,
      clientSignature: data.clientSignature.present
          ? data.clientSignature.value
          : this.clientSignature,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      isDraft: data.isDraft.present ? data.isDraft.value : this.isDraft,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CriService(')
          ..write('id: $id, ')
          ..write('interventionDate: $interventionDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('endDate: $endDate, ')
          ..write('ticketNumber: $ticketNumber, ')
          ..write('clientName: $clientName, ')
          ..write('site: $site, ')
          ..write('address: $address, ')
          ..write('ville: $ville, ')
          ..write('codePostal: $codePostal, ')
          ..write('pays: $pays, ')
          ..write('clientContact: $clientContact, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('requestType: $requestType, ')
          ..write('requestDescription: $requestDescription, ')
          ..write('contratType: $contratType, ')
          ..write('systemTypes: $systemTypes, ')
          ..write('diagnosticPerformed: $diagnosticPerformed, ')
          ..write('identifiedCause: $identifiedCause, ')
          ..write('actionsPerformed: $actionsPerformed, ')
          ..write('replacedParts: $replacedParts, ')
          ..write('interventionDurationMinutes: $interventionDurationMinutes, ')
          ..write('resolutionStatus: $resolutionStatus, ')
          ..write('testsPerformed: $testsPerformed, ')
          ..write('recommendations: $recommendations, ')
          ..write(
              'cybersecurityRecommendations: $cybersecurityRecommendations, ')
          ..write(
              'additionalInterventionRequired: $additionalInterventionRequired, ')
          ..write('followUpDate: $followUpDate, ')
          ..write('followUpComments: $followUpComments, ')
          ..write('devisARealiser: $devisARealiser, ')
          ..write('facturable: $facturable, ')
          ..write('photos: $photos, ')
          ..write('technicianName: $technicianName, ')
          ..write('technicianSignature: $technicianSignature, ')
          ..write('clientSignature: $clientSignature, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDraft: $isDraft')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        interventionDate,
        startTime,
        endTime,
        endDate,
        ticketNumber,
        clientName,
        site,
        address,
        ville,
        codePostal,
        pays,
        clientContact,
        phone,
        email,
        requestType,
        requestDescription,
        contratType,
        systemTypes,
        diagnosticPerformed,
        identifiedCause,
        actionsPerformed,
        replacedParts,
        interventionDurationMinutes,
        resolutionStatus,
        testsPerformed,
        recommendations,
        cybersecurityRecommendations,
        additionalInterventionRequired,
        followUpDate,
        followUpComments,
        devisARealiser,
        facturable,
        photos,
        technicianName,
        technicianSignature,
        clientSignature,
        createdAt,
        updatedAt,
        syncStatus,
        isDraft
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CriService &&
          other.id == this.id &&
          other.interventionDate == this.interventionDate &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.endDate == this.endDate &&
          other.ticketNumber == this.ticketNumber &&
          other.clientName == this.clientName &&
          other.site == this.site &&
          other.address == this.address &&
          other.ville == this.ville &&
          other.codePostal == this.codePostal &&
          other.pays == this.pays &&
          other.clientContact == this.clientContact &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.requestType == this.requestType &&
          other.requestDescription == this.requestDescription &&
          other.contratType == this.contratType &&
          other.systemTypes == this.systemTypes &&
          other.diagnosticPerformed == this.diagnosticPerformed &&
          other.identifiedCause == this.identifiedCause &&
          other.actionsPerformed == this.actionsPerformed &&
          other.replacedParts == this.replacedParts &&
          other.interventionDurationMinutes ==
              this.interventionDurationMinutes &&
          other.resolutionStatus == this.resolutionStatus &&
          other.testsPerformed == this.testsPerformed &&
          other.recommendations == this.recommendations &&
          other.cybersecurityRecommendations ==
              this.cybersecurityRecommendations &&
          other.additionalInterventionRequired ==
              this.additionalInterventionRequired &&
          other.followUpDate == this.followUpDate &&
          other.followUpComments == this.followUpComments &&
          other.devisARealiser == this.devisARealiser &&
          other.facturable == this.facturable &&
          other.photos == this.photos &&
          other.technicianName == this.technicianName &&
          other.technicianSignature == this.technicianSignature &&
          other.clientSignature == this.clientSignature &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.isDraft == this.isDraft);
}

class CriServiceTableCompanion extends UpdateCompanion<CriService> {
  final Value<String> id;
  final Value<DateTime> interventionDate;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<DateTime?> endDate;
  final Value<String?> ticketNumber;
  final Value<String> clientName;
  final Value<String> site;
  final Value<String?> address;
  final Value<String?> ville;
  final Value<String?> codePostal;
  final Value<String?> pays;
  final Value<String?> clientContact;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String> requestType;
  final Value<String> requestDescription;
  final Value<String?> contratType;
  final Value<String?> systemTypes;
  final Value<String?> diagnosticPerformed;
  final Value<String?> identifiedCause;
  final Value<String> actionsPerformed;
  final Value<String?> replacedParts;
  final Value<int> interventionDurationMinutes;
  final Value<String> resolutionStatus;
  final Value<String?> testsPerformed;
  final Value<String?> recommendations;
  final Value<String?> cybersecurityRecommendations;
  final Value<bool> additionalInterventionRequired;
  final Value<DateTime?> followUpDate;
  final Value<String?> followUpComments;
  final Value<bool> devisARealiser;
  final Value<bool> facturable;
  final Value<String?> photos;
  final Value<String> technicianName;
  final Value<String?> technicianSignature;
  final Value<String?> clientSignature;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<String> syncStatus;
  final Value<bool> isDraft;
  final Value<int> rowid;
  const CriServiceTableCompanion({
    this.id = const Value.absent(),
    this.interventionDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.endDate = const Value.absent(),
    this.ticketNumber = const Value.absent(),
    this.clientName = const Value.absent(),
    this.site = const Value.absent(),
    this.address = const Value.absent(),
    this.ville = const Value.absent(),
    this.codePostal = const Value.absent(),
    this.pays = const Value.absent(),
    this.clientContact = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.requestType = const Value.absent(),
    this.requestDescription = const Value.absent(),
    this.contratType = const Value.absent(),
    this.systemTypes = const Value.absent(),
    this.diagnosticPerformed = const Value.absent(),
    this.identifiedCause = const Value.absent(),
    this.actionsPerformed = const Value.absent(),
    this.replacedParts = const Value.absent(),
    this.interventionDurationMinutes = const Value.absent(),
    this.resolutionStatus = const Value.absent(),
    this.testsPerformed = const Value.absent(),
    this.recommendations = const Value.absent(),
    this.cybersecurityRecommendations = const Value.absent(),
    this.additionalInterventionRequired = const Value.absent(),
    this.followUpDate = const Value.absent(),
    this.followUpComments = const Value.absent(),
    this.devisARealiser = const Value.absent(),
    this.facturable = const Value.absent(),
    this.photos = const Value.absent(),
    this.technicianName = const Value.absent(),
    this.technicianSignature = const Value.absent(),
    this.clientSignature = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CriServiceTableCompanion.insert({
    required String id,
    required DateTime interventionDate,
    required DateTime startTime,
    required DateTime endTime,
    this.endDate = const Value.absent(),
    this.ticketNumber = const Value.absent(),
    required String clientName,
    required String site,
    this.address = const Value.absent(),
    this.ville = const Value.absent(),
    this.codePostal = const Value.absent(),
    this.pays = const Value.absent(),
    this.clientContact = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    required String requestType,
    required String requestDescription,
    this.contratType = const Value.absent(),
    this.systemTypes = const Value.absent(),
    this.diagnosticPerformed = const Value.absent(),
    this.identifiedCause = const Value.absent(),
    required String actionsPerformed,
    this.replacedParts = const Value.absent(),
    required int interventionDurationMinutes,
    required String resolutionStatus,
    this.testsPerformed = const Value.absent(),
    this.recommendations = const Value.absent(),
    this.cybersecurityRecommendations = const Value.absent(),
    this.additionalInterventionRequired = const Value.absent(),
    this.followUpDate = const Value.absent(),
    this.followUpComments = const Value.absent(),
    this.devisARealiser = const Value.absent(),
    this.facturable = const Value.absent(),
    this.photos = const Value.absent(),
    required String technicianName,
    this.technicianSignature = const Value.absent(),
    this.clientSignature = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        interventionDate = Value(interventionDate),
        startTime = Value(startTime),
        endTime = Value(endTime),
        clientName = Value(clientName),
        site = Value(site),
        requestType = Value(requestType),
        requestDescription = Value(requestDescription),
        actionsPerformed = Value(actionsPerformed),
        interventionDurationMinutes = Value(interventionDurationMinutes),
        resolutionStatus = Value(resolutionStatus),
        technicianName = Value(technicianName);
  static Insertable<CriService> custom({
    Expression<String>? id,
    Expression<DateTime>? interventionDate,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<DateTime>? endDate,
    Expression<String>? ticketNumber,
    Expression<String>? clientName,
    Expression<String>? site,
    Expression<String>? address,
    Expression<String>? ville,
    Expression<String>? codePostal,
    Expression<String>? pays,
    Expression<String>? clientContact,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? requestType,
    Expression<String>? requestDescription,
    Expression<String>? contratType,
    Expression<String>? systemTypes,
    Expression<String>? diagnosticPerformed,
    Expression<String>? identifiedCause,
    Expression<String>? actionsPerformed,
    Expression<String>? replacedParts,
    Expression<int>? interventionDurationMinutes,
    Expression<String>? resolutionStatus,
    Expression<String>? testsPerformed,
    Expression<String>? recommendations,
    Expression<String>? cybersecurityRecommendations,
    Expression<bool>? additionalInterventionRequired,
    Expression<DateTime>? followUpDate,
    Expression<String>? followUpComments,
    Expression<bool>? devisARealiser,
    Expression<bool>? facturable,
    Expression<String>? photos,
    Expression<String>? technicianName,
    Expression<String>? technicianSignature,
    Expression<String>? clientSignature,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<bool>? isDraft,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (interventionDate != null) 'intervention_date': interventionDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (endDate != null) 'end_date': endDate,
      if (ticketNumber != null) 'ticket_number': ticketNumber,
      if (clientName != null) 'client_name': clientName,
      if (site != null) 'site': site,
      if (address != null) 'address': address,
      if (ville != null) 'ville': ville,
      if (codePostal != null) 'code_postal': codePostal,
      if (pays != null) 'pays': pays,
      if (clientContact != null) 'client_contact': clientContact,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (requestType != null) 'request_type': requestType,
      if (requestDescription != null) 'request_description': requestDescription,
      if (contratType != null) 'contrat_type': contratType,
      if (systemTypes != null) 'system_types': systemTypes,
      if (diagnosticPerformed != null)
        'diagnostic_performed': diagnosticPerformed,
      if (identifiedCause != null) 'identified_cause': identifiedCause,
      if (actionsPerformed != null) 'actions_performed': actionsPerformed,
      if (replacedParts != null) 'replaced_parts': replacedParts,
      if (interventionDurationMinutes != null)
        'intervention_duration_minutes': interventionDurationMinutes,
      if (resolutionStatus != null) 'resolution_status': resolutionStatus,
      if (testsPerformed != null) 'tests_performed': testsPerformed,
      if (recommendations != null) 'recommendations': recommendations,
      if (cybersecurityRecommendations != null)
        'cybersecurity_recommendations': cybersecurityRecommendations,
      if (additionalInterventionRequired != null)
        'additional_intervention_required': additionalInterventionRequired,
      if (followUpDate != null) 'follow_up_date': followUpDate,
      if (followUpComments != null) 'follow_up_comments': followUpComments,
      if (devisARealiser != null) 'devis_a_realiser': devisARealiser,
      if (facturable != null) 'facturable': facturable,
      if (photos != null) 'photos': photos,
      if (technicianName != null) 'technician_name': technicianName,
      if (technicianSignature != null)
        'technician_signature': technicianSignature,
      if (clientSignature != null) 'client_signature': clientSignature,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDraft != null) 'is_draft': isDraft,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CriServiceTableCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? interventionDate,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<DateTime?>? endDate,
      Value<String?>? ticketNumber,
      Value<String>? clientName,
      Value<String>? site,
      Value<String?>? address,
      Value<String?>? ville,
      Value<String?>? codePostal,
      Value<String?>? pays,
      Value<String?>? clientContact,
      Value<String?>? phone,
      Value<String?>? email,
      Value<String>? requestType,
      Value<String>? requestDescription,
      Value<String?>? contratType,
      Value<String?>? systemTypes,
      Value<String?>? diagnosticPerformed,
      Value<String?>? identifiedCause,
      Value<String>? actionsPerformed,
      Value<String?>? replacedParts,
      Value<int>? interventionDurationMinutes,
      Value<String>? resolutionStatus,
      Value<String?>? testsPerformed,
      Value<String?>? recommendations,
      Value<String?>? cybersecurityRecommendations,
      Value<bool>? additionalInterventionRequired,
      Value<DateTime?>? followUpDate,
      Value<String?>? followUpComments,
      Value<bool>? devisARealiser,
      Value<bool>? facturable,
      Value<String?>? photos,
      Value<String>? technicianName,
      Value<String?>? technicianSignature,
      Value<String?>? clientSignature,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<String>? syncStatus,
      Value<bool>? isDraft,
      Value<int>? rowid}) {
    return CriServiceTableCompanion(
      id: id ?? this.id,
      interventionDate: interventionDate ?? this.interventionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      endDate: endDate ?? this.endDate,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      clientName: clientName ?? this.clientName,
      site: site ?? this.site,
      address: address ?? this.address,
      ville: ville ?? this.ville,
      codePostal: codePostal ?? this.codePostal,
      pays: pays ?? this.pays,
      clientContact: clientContact ?? this.clientContact,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      requestType: requestType ?? this.requestType,
      requestDescription: requestDescription ?? this.requestDescription,
      contratType: contratType ?? this.contratType,
      systemTypes: systemTypes ?? this.systemTypes,
      diagnosticPerformed: diagnosticPerformed ?? this.diagnosticPerformed,
      identifiedCause: identifiedCause ?? this.identifiedCause,
      actionsPerformed: actionsPerformed ?? this.actionsPerformed,
      replacedParts: replacedParts ?? this.replacedParts,
      interventionDurationMinutes:
          interventionDurationMinutes ?? this.interventionDurationMinutes,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      testsPerformed: testsPerformed ?? this.testsPerformed,
      recommendations: recommendations ?? this.recommendations,
      cybersecurityRecommendations:
          cybersecurityRecommendations ?? this.cybersecurityRecommendations,
      additionalInterventionRequired:
          additionalInterventionRequired ?? this.additionalInterventionRequired,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpComments: followUpComments ?? this.followUpComments,
      devisARealiser: devisARealiser ?? this.devisARealiser,
      facturable: facturable ?? this.facturable,
      photos: photos ?? this.photos,
      technicianName: technicianName ?? this.technicianName,
      technicianSignature: technicianSignature ?? this.technicianSignature,
      clientSignature: clientSignature ?? this.clientSignature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDraft: isDraft ?? this.isDraft,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (interventionDate.present) {
      map['intervention_date'] = Variable<DateTime>(interventionDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (ticketNumber.present) {
      map['ticket_number'] = Variable<String>(ticketNumber.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (site.present) {
      map['site'] = Variable<String>(site.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (ville.present) {
      map['ville'] = Variable<String>(ville.value);
    }
    if (codePostal.present) {
      map['code_postal'] = Variable<String>(codePostal.value);
    }
    if (pays.present) {
      map['pays'] = Variable<String>(pays.value);
    }
    if (clientContact.present) {
      map['client_contact'] = Variable<String>(clientContact.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (requestType.present) {
      map['request_type'] = Variable<String>(requestType.value);
    }
    if (requestDescription.present) {
      map['request_description'] = Variable<String>(requestDescription.value);
    }
    if (contratType.present) {
      map['contrat_type'] = Variable<String>(contratType.value);
    }
    if (systemTypes.present) {
      map['system_types'] = Variable<String>(systemTypes.value);
    }
    if (diagnosticPerformed.present) {
      map['diagnostic_performed'] = Variable<String>(diagnosticPerformed.value);
    }
    if (identifiedCause.present) {
      map['identified_cause'] = Variable<String>(identifiedCause.value);
    }
    if (actionsPerformed.present) {
      map['actions_performed'] = Variable<String>(actionsPerformed.value);
    }
    if (replacedParts.present) {
      map['replaced_parts'] = Variable<String>(replacedParts.value);
    }
    if (interventionDurationMinutes.present) {
      map['intervention_duration_minutes'] =
          Variable<int>(interventionDurationMinutes.value);
    }
    if (resolutionStatus.present) {
      map['resolution_status'] = Variable<String>(resolutionStatus.value);
    }
    if (testsPerformed.present) {
      map['tests_performed'] = Variable<String>(testsPerformed.value);
    }
    if (recommendations.present) {
      map['recommendations'] = Variable<String>(recommendations.value);
    }
    if (cybersecurityRecommendations.present) {
      map['cybersecurity_recommendations'] =
          Variable<String>(cybersecurityRecommendations.value);
    }
    if (additionalInterventionRequired.present) {
      map['additional_intervention_required'] =
          Variable<bool>(additionalInterventionRequired.value);
    }
    if (followUpDate.present) {
      map['follow_up_date'] = Variable<DateTime>(followUpDate.value);
    }
    if (followUpComments.present) {
      map['follow_up_comments'] = Variable<String>(followUpComments.value);
    }
    if (devisARealiser.present) {
      map['devis_a_realiser'] = Variable<bool>(devisARealiser.value);
    }
    if (facturable.present) {
      map['facturable'] = Variable<bool>(facturable.value);
    }
    if (photos.present) {
      map['photos'] = Variable<String>(photos.value);
    }
    if (technicianName.present) {
      map['technician_name'] = Variable<String>(technicianName.value);
    }
    if (technicianSignature.present) {
      map['technician_signature'] = Variable<String>(technicianSignature.value);
    }
    if (clientSignature.present) {
      map['client_signature'] = Variable<String>(clientSignature.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDraft.present) {
      map['is_draft'] = Variable<bool>(isDraft.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CriServiceTableCompanion(')
          ..write('id: $id, ')
          ..write('interventionDate: $interventionDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('endDate: $endDate, ')
          ..write('ticketNumber: $ticketNumber, ')
          ..write('clientName: $clientName, ')
          ..write('site: $site, ')
          ..write('address: $address, ')
          ..write('ville: $ville, ')
          ..write('codePostal: $codePostal, ')
          ..write('pays: $pays, ')
          ..write('clientContact: $clientContact, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('requestType: $requestType, ')
          ..write('requestDescription: $requestDescription, ')
          ..write('contratType: $contratType, ')
          ..write('systemTypes: $systemTypes, ')
          ..write('diagnosticPerformed: $diagnosticPerformed, ')
          ..write('identifiedCause: $identifiedCause, ')
          ..write('actionsPerformed: $actionsPerformed, ')
          ..write('replacedParts: $replacedParts, ')
          ..write('interventionDurationMinutes: $interventionDurationMinutes, ')
          ..write('resolutionStatus: $resolutionStatus, ')
          ..write('testsPerformed: $testsPerformed, ')
          ..write('recommendations: $recommendations, ')
          ..write(
              'cybersecurityRecommendations: $cybersecurityRecommendations, ')
          ..write(
              'additionalInterventionRequired: $additionalInterventionRequired, ')
          ..write('followUpDate: $followUpDate, ')
          ..write('followUpComments: $followUpComments, ')
          ..write('devisARealiser: $devisARealiser, ')
          ..write('facturable: $facturable, ')
          ..write('photos: $photos, ')
          ..write('technicianName: $technicianName, ')
          ..write('technicianSignature: $technicianSignature, ')
          ..write('clientSignature: $clientSignature, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDraft: $isDraft, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CriProjetTableTable extends CriProjetTable
    with TableInfo<$CriProjetTableTable, CriProjet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CriProjetTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _interventionDateMeta =
      const VerificationMeta('interventionDate');
  @override
  late final GeneratedColumn<DateTime> interventionDate =
      GeneratedColumn<DateTime>('intervention_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _clientNameMeta =
      const VerificationMeta('clientName');
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
      'client_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _siteMeta = const VerificationMeta('site');
  @override
  late final GeneratedColumn<String> site = GeneratedColumn<String>(
      'site', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _villeMeta = const VerificationMeta('ville');
  @override
  late final GeneratedColumn<String> ville = GeneratedColumn<String>(
      'ville', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _codePostalMeta =
      const VerificationMeta('codePostal');
  @override
  late final GeneratedColumn<String> codePostal = GeneratedColumn<String>(
      'code_postal', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paysMeta = const VerificationMeta('pays');
  @override
  late final GeneratedColumn<String> pays = GeneratedColumn<String>(
      'pays', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientContactMeta =
      const VerificationMeta('clientContact');
  @override
  late final GeneratedColumn<String> clientContact = GeneratedColumn<String>(
      'client_contact', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _projectNameMeta =
      const VerificationMeta('projectName');
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
      'project_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectNumberMeta =
      const VerificationMeta('projectNumber');
  @override
  late final GeneratedColumn<String> projectNumber = GeneratedColumn<String>(
      'project_number', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _projectPhaseMeta =
      const VerificationMeta('projectPhase');
  @override
  late final GeneratedColumn<String> projectPhase = GeneratedColumn<String>(
      'project_phase', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _interventionTypeMeta =
      const VerificationMeta('interventionType');
  @override
  late final GeneratedColumn<String> interventionType = GeneratedColumn<String>(
      'intervention_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workDescriptionMeta =
      const VerificationMeta('workDescription');
  @override
  late final GeneratedColumn<String> workDescription = GeneratedColumn<String>(
      'work_description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _materialsUsedMeta =
      const VerificationMeta('materialsUsed');
  @override
  late final GeneratedColumn<String> materialsUsed = GeneratedColumn<String>(
      'materials_used', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _problemsEncounteredMeta =
      const VerificationMeta('problemsEncountered');
  @override
  late final GeneratedColumn<String> problemsEncountered =
      GeneratedColumn<String>('problems_encountered', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _solutionsProvidedMeta =
      const VerificationMeta('solutionsProvided');
  @override
  late final GeneratedColumn<String> solutionsProvided =
      GeneratedColumn<String>('solutions_provided', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _softwaresMeta =
      const VerificationMeta('softwares');
  @override
  late final GeneratedColumn<String> softwares = GeneratedColumn<String>(
      'softwares', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionsToDoMeta =
      const VerificationMeta('actionsToDo');
  @override
  late final GeneratedColumn<String> actionsToDo = GeneratedColumn<String>(
      'actions_to_do', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextInterventionDateMeta =
      const VerificationMeta('nextInterventionDate');
  @override
  late final GeneratedColumn<DateTime> nextInterventionDate =
      GeneratedColumn<DateTime>('next_intervention_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _projectStatusMeta =
      const VerificationMeta('projectStatus');
  @override
  late final GeneratedColumn<String> projectStatus = GeneratedColumn<String>(
      'project_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photosMeta = const VerificationMeta('photos');
  @override
  late final GeneratedColumn<String> photos = GeneratedColumn<String>(
      'photos', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _technicianNameMeta =
      const VerificationMeta('technicianName');
  @override
  late final GeneratedColumn<String> technicianName = GeneratedColumn<String>(
      'technician_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _technicianSignatureMeta =
      const VerificationMeta('technicianSignature');
  @override
  late final GeneratedColumn<String> technicianSignature =
      GeneratedColumn<String>('technician_signature', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientSignatureMeta =
      const VerificationMeta('clientSignature');
  @override
  late final GeneratedColumn<String> clientSignature = GeneratedColumn<String>(
      'client_signature', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientCommentsMeta =
      const VerificationMeta('clientComments');
  @override
  late final GeneratedColumn<String> clientComments = GeneratedColumn<String>(
      'client_comments', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _isDraftMeta =
      const VerificationMeta('isDraft');
  @override
  late final GeneratedColumn<bool> isDraft = GeneratedColumn<bool>(
      'is_draft', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_draft" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        interventionDate,
        startTime,
        endTime,
        endDate,
        clientName,
        site,
        address,
        ville,
        codePostal,
        pays,
        clientContact,
        phone,
        email,
        projectName,
        projectNumber,
        projectPhase,
        interventionType,
        workDescription,
        materialsUsed,
        problemsEncountered,
        solutionsProvided,
        softwares,
        actionsToDo,
        nextInterventionDate,
        projectStatus,
        photos,
        technicianName,
        technicianSignature,
        clientSignature,
        clientComments,
        createdAt,
        updatedAt,
        syncStatus,
        isDraft
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cri_projet';
  @override
  VerificationContext validateIntegrity(Insertable<CriProjet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('intervention_date')) {
      context.handle(
          _interventionDateMeta,
          interventionDate.isAcceptableOrUnknown(
              data['intervention_date']!, _interventionDateMeta));
    } else if (isInserting) {
      context.missing(_interventionDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('client_name')) {
      context.handle(
          _clientNameMeta,
          clientName.isAcceptableOrUnknown(
              data['client_name']!, _clientNameMeta));
    } else if (isInserting) {
      context.missing(_clientNameMeta);
    }
    if (data.containsKey('site')) {
      context.handle(
          _siteMeta, site.isAcceptableOrUnknown(data['site']!, _siteMeta));
    } else if (isInserting) {
      context.missing(_siteMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('ville')) {
      context.handle(
          _villeMeta, ville.isAcceptableOrUnknown(data['ville']!, _villeMeta));
    }
    if (data.containsKey('code_postal')) {
      context.handle(
          _codePostalMeta,
          codePostal.isAcceptableOrUnknown(
              data['code_postal']!, _codePostalMeta));
    }
    if (data.containsKey('pays')) {
      context.handle(
          _paysMeta, pays.isAcceptableOrUnknown(data['pays']!, _paysMeta));
    }
    if (data.containsKey('client_contact')) {
      context.handle(
          _clientContactMeta,
          clientContact.isAcceptableOrUnknown(
              data['client_contact']!, _clientContactMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('project_name')) {
      context.handle(
          _projectNameMeta,
          projectName.isAcceptableOrUnknown(
              data['project_name']!, _projectNameMeta));
    } else if (isInserting) {
      context.missing(_projectNameMeta);
    }
    if (data.containsKey('project_number')) {
      context.handle(
          _projectNumberMeta,
          projectNumber.isAcceptableOrUnknown(
              data['project_number']!, _projectNumberMeta));
    } else if (isInserting) {
      context.missing(_projectNumberMeta);
    }
    if (data.containsKey('project_phase')) {
      context.handle(
          _projectPhaseMeta,
          projectPhase.isAcceptableOrUnknown(
              data['project_phase']!, _projectPhaseMeta));
    } else if (isInserting) {
      context.missing(_projectPhaseMeta);
    }
    if (data.containsKey('intervention_type')) {
      context.handle(
          _interventionTypeMeta,
          interventionType.isAcceptableOrUnknown(
              data['intervention_type']!, _interventionTypeMeta));
    } else if (isInserting) {
      context.missing(_interventionTypeMeta);
    }
    if (data.containsKey('work_description')) {
      context.handle(
          _workDescriptionMeta,
          workDescription.isAcceptableOrUnknown(
              data['work_description']!, _workDescriptionMeta));
    } else if (isInserting) {
      context.missing(_workDescriptionMeta);
    }
    if (data.containsKey('materials_used')) {
      context.handle(
          _materialsUsedMeta,
          materialsUsed.isAcceptableOrUnknown(
              data['materials_used']!, _materialsUsedMeta));
    }
    if (data.containsKey('problems_encountered')) {
      context.handle(
          _problemsEncounteredMeta,
          problemsEncountered.isAcceptableOrUnknown(
              data['problems_encountered']!, _problemsEncounteredMeta));
    }
    if (data.containsKey('solutions_provided')) {
      context.handle(
          _solutionsProvidedMeta,
          solutionsProvided.isAcceptableOrUnknown(
              data['solutions_provided']!, _solutionsProvidedMeta));
    }
    if (data.containsKey('softwares')) {
      context.handle(_softwaresMeta,
          softwares.isAcceptableOrUnknown(data['softwares']!, _softwaresMeta));
    }
    if (data.containsKey('actions_to_do')) {
      context.handle(
          _actionsToDoMeta,
          actionsToDo.isAcceptableOrUnknown(
              data['actions_to_do']!, _actionsToDoMeta));
    }
    if (data.containsKey('next_intervention_date')) {
      context.handle(
          _nextInterventionDateMeta,
          nextInterventionDate.isAcceptableOrUnknown(
              data['next_intervention_date']!, _nextInterventionDateMeta));
    }
    if (data.containsKey('project_status')) {
      context.handle(
          _projectStatusMeta,
          projectStatus.isAcceptableOrUnknown(
              data['project_status']!, _projectStatusMeta));
    } else if (isInserting) {
      context.missing(_projectStatusMeta);
    }
    if (data.containsKey('photos')) {
      context.handle(_photosMeta,
          photos.isAcceptableOrUnknown(data['photos']!, _photosMeta));
    }
    if (data.containsKey('technician_name')) {
      context.handle(
          _technicianNameMeta,
          technicianName.isAcceptableOrUnknown(
              data['technician_name']!, _technicianNameMeta));
    } else if (isInserting) {
      context.missing(_technicianNameMeta);
    }
    if (data.containsKey('technician_signature')) {
      context.handle(
          _technicianSignatureMeta,
          technicianSignature.isAcceptableOrUnknown(
              data['technician_signature']!, _technicianSignatureMeta));
    }
    if (data.containsKey('client_signature')) {
      context.handle(
          _clientSignatureMeta,
          clientSignature.isAcceptableOrUnknown(
              data['client_signature']!, _clientSignatureMeta));
    }
    if (data.containsKey('client_comments')) {
      context.handle(
          _clientCommentsMeta,
          clientComments.isAcceptableOrUnknown(
              data['client_comments']!, _clientCommentsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('is_draft')) {
      context.handle(_isDraftMeta,
          isDraft.isAcceptableOrUnknown(data['is_draft']!, _isDraftMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CriProjet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CriProjet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      interventionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}intervention_date'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      clientName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_name'])!,
      site: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}site'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      ville: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ville']),
      codePostal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code_postal']),
      pays: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pays']),
      clientContact: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_contact']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      projectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_name'])!,
      projectNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_number'])!,
      projectPhase: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_phase'])!,
      interventionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}intervention_type'])!,
      workDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}work_description'])!,
      materialsUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}materials_used']),
      problemsEncountered: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}problems_encountered']),
      solutionsProvided: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}solutions_provided']),
      softwares: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}softwares']),
      actionsToDo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actions_to_do']),
      nextInterventionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}next_intervention_date']),
      projectStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_status'])!,
      photos: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photos']),
      technicianName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}technician_name'])!,
      technicianSignature: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}technician_signature']),
      clientSignature: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_signature']),
      clientComments: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_comments']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      isDraft: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_draft'])!,
    );
  }

  @override
  $CriProjetTableTable createAlias(String alias) {
    return $CriProjetTableTable(attachedDatabase, alias);
  }
}

class CriProjet extends DataClass implements Insertable<CriProjet> {
  final String id;
  final DateTime interventionDate;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? endDate;
  final String clientName;
  final String site;
  final String? address;
  final String? ville;
  final String? codePostal;
  final String? pays;
  final String? clientContact;
  final String? phone;
  final String? email;
  final String projectName;
  final String projectNumber;
  final String projectPhase;
  final String interventionType;
  final String workDescription;
  final String? materialsUsed;
  final String? problemsEncountered;
  final String? solutionsProvided;
  final String? softwares;
  final String? actionsToDo;
  final DateTime? nextInterventionDate;
  final String projectStatus;
  final String? photos;
  final String technicianName;
  final String? technicianSignature;
  final String? clientSignature;
  final String? clientComments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;
  final bool isDraft;
  const CriProjet(
      {required this.id,
      required this.interventionDate,
      required this.startTime,
      required this.endTime,
      this.endDate,
      required this.clientName,
      required this.site,
      this.address,
      this.ville,
      this.codePostal,
      this.pays,
      this.clientContact,
      this.phone,
      this.email,
      required this.projectName,
      required this.projectNumber,
      required this.projectPhase,
      required this.interventionType,
      required this.workDescription,
      this.materialsUsed,
      this.problemsEncountered,
      this.solutionsProvided,
      this.softwares,
      this.actionsToDo,
      this.nextInterventionDate,
      required this.projectStatus,
      this.photos,
      required this.technicianName,
      this.technicianSignature,
      this.clientSignature,
      this.clientComments,
      required this.createdAt,
      this.updatedAt,
      required this.syncStatus,
      required this.isDraft});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['intervention_date'] = Variable<DateTime>(interventionDate);
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['client_name'] = Variable<String>(clientName);
    map['site'] = Variable<String>(site);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || ville != null) {
      map['ville'] = Variable<String>(ville);
    }
    if (!nullToAbsent || codePostal != null) {
      map['code_postal'] = Variable<String>(codePostal);
    }
    if (!nullToAbsent || pays != null) {
      map['pays'] = Variable<String>(pays);
    }
    if (!nullToAbsent || clientContact != null) {
      map['client_contact'] = Variable<String>(clientContact);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['project_name'] = Variable<String>(projectName);
    map['project_number'] = Variable<String>(projectNumber);
    map['project_phase'] = Variable<String>(projectPhase);
    map['intervention_type'] = Variable<String>(interventionType);
    map['work_description'] = Variable<String>(workDescription);
    if (!nullToAbsent || materialsUsed != null) {
      map['materials_used'] = Variable<String>(materialsUsed);
    }
    if (!nullToAbsent || problemsEncountered != null) {
      map['problems_encountered'] = Variable<String>(problemsEncountered);
    }
    if (!nullToAbsent || solutionsProvided != null) {
      map['solutions_provided'] = Variable<String>(solutionsProvided);
    }
    if (!nullToAbsent || softwares != null) {
      map['softwares'] = Variable<String>(softwares);
    }
    if (!nullToAbsent || actionsToDo != null) {
      map['actions_to_do'] = Variable<String>(actionsToDo);
    }
    if (!nullToAbsent || nextInterventionDate != null) {
      map['next_intervention_date'] = Variable<DateTime>(nextInterventionDate);
    }
    map['project_status'] = Variable<String>(projectStatus);
    if (!nullToAbsent || photos != null) {
      map['photos'] = Variable<String>(photos);
    }
    map['technician_name'] = Variable<String>(technicianName);
    if (!nullToAbsent || technicianSignature != null) {
      map['technician_signature'] = Variable<String>(technicianSignature);
    }
    if (!nullToAbsent || clientSignature != null) {
      map['client_signature'] = Variable<String>(clientSignature);
    }
    if (!nullToAbsent || clientComments != null) {
      map['client_comments'] = Variable<String>(clientComments);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_draft'] = Variable<bool>(isDraft);
    return map;
  }

  CriProjetTableCompanion toCompanion(bool nullToAbsent) {
    return CriProjetTableCompanion(
      id: Value(id),
      interventionDate: Value(interventionDate),
      startTime: Value(startTime),
      endTime: Value(endTime),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      clientName: Value(clientName),
      site: Value(site),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      ville:
          ville == null && nullToAbsent ? const Value.absent() : Value(ville),
      codePostal: codePostal == null && nullToAbsent
          ? const Value.absent()
          : Value(codePostal),
      pays: pays == null && nullToAbsent ? const Value.absent() : Value(pays),
      clientContact: clientContact == null && nullToAbsent
          ? const Value.absent()
          : Value(clientContact),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      projectName: Value(projectName),
      projectNumber: Value(projectNumber),
      projectPhase: Value(projectPhase),
      interventionType: Value(interventionType),
      workDescription: Value(workDescription),
      materialsUsed: materialsUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(materialsUsed),
      problemsEncountered: problemsEncountered == null && nullToAbsent
          ? const Value.absent()
          : Value(problemsEncountered),
      solutionsProvided: solutionsProvided == null && nullToAbsent
          ? const Value.absent()
          : Value(solutionsProvided),
      softwares: softwares == null && nullToAbsent
          ? const Value.absent()
          : Value(softwares),
      actionsToDo: actionsToDo == null && nullToAbsent
          ? const Value.absent()
          : Value(actionsToDo),
      nextInterventionDate: nextInterventionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextInterventionDate),
      projectStatus: Value(projectStatus),
      photos:
          photos == null && nullToAbsent ? const Value.absent() : Value(photos),
      technicianName: Value(technicianName),
      technicianSignature: technicianSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(technicianSignature),
      clientSignature: clientSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(clientSignature),
      clientComments: clientComments == null && nullToAbsent
          ? const Value.absent()
          : Value(clientComments),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      syncStatus: Value(syncStatus),
      isDraft: Value(isDraft),
    );
  }

  factory CriProjet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CriProjet(
      id: serializer.fromJson<String>(json['id']),
      interventionDate: serializer.fromJson<DateTime>(json['interventionDate']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      clientName: serializer.fromJson<String>(json['clientName']),
      site: serializer.fromJson<String>(json['site']),
      address: serializer.fromJson<String?>(json['address']),
      ville: serializer.fromJson<String?>(json['ville']),
      codePostal: serializer.fromJson<String?>(json['codePostal']),
      pays: serializer.fromJson<String?>(json['pays']),
      clientContact: serializer.fromJson<String?>(json['clientContact']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      projectName: serializer.fromJson<String>(json['projectName']),
      projectNumber: serializer.fromJson<String>(json['projectNumber']),
      projectPhase: serializer.fromJson<String>(json['projectPhase']),
      interventionType: serializer.fromJson<String>(json['interventionType']),
      workDescription: serializer.fromJson<String>(json['workDescription']),
      materialsUsed: serializer.fromJson<String?>(json['materialsUsed']),
      problemsEncountered:
          serializer.fromJson<String?>(json['problemsEncountered']),
      solutionsProvided:
          serializer.fromJson<String?>(json['solutionsProvided']),
      softwares: serializer.fromJson<String?>(json['softwares']),
      actionsToDo: serializer.fromJson<String?>(json['actionsToDo']),
      nextInterventionDate:
          serializer.fromJson<DateTime?>(json['nextInterventionDate']),
      projectStatus: serializer.fromJson<String>(json['projectStatus']),
      photos: serializer.fromJson<String?>(json['photos']),
      technicianName: serializer.fromJson<String>(json['technicianName']),
      technicianSignature:
          serializer.fromJson<String?>(json['technicianSignature']),
      clientSignature: serializer.fromJson<String?>(json['clientSignature']),
      clientComments: serializer.fromJson<String?>(json['clientComments']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDraft: serializer.fromJson<bool>(json['isDraft']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'interventionDate': serializer.toJson<DateTime>(interventionDate),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'clientName': serializer.toJson<String>(clientName),
      'site': serializer.toJson<String>(site),
      'address': serializer.toJson<String?>(address),
      'ville': serializer.toJson<String?>(ville),
      'codePostal': serializer.toJson<String?>(codePostal),
      'pays': serializer.toJson<String?>(pays),
      'clientContact': serializer.toJson<String?>(clientContact),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'projectName': serializer.toJson<String>(projectName),
      'projectNumber': serializer.toJson<String>(projectNumber),
      'projectPhase': serializer.toJson<String>(projectPhase),
      'interventionType': serializer.toJson<String>(interventionType),
      'workDescription': serializer.toJson<String>(workDescription),
      'materialsUsed': serializer.toJson<String?>(materialsUsed),
      'problemsEncountered': serializer.toJson<String?>(problemsEncountered),
      'solutionsProvided': serializer.toJson<String?>(solutionsProvided),
      'softwares': serializer.toJson<String?>(softwares),
      'actionsToDo': serializer.toJson<String?>(actionsToDo),
      'nextInterventionDate':
          serializer.toJson<DateTime?>(nextInterventionDate),
      'projectStatus': serializer.toJson<String>(projectStatus),
      'photos': serializer.toJson<String?>(photos),
      'technicianName': serializer.toJson<String>(technicianName),
      'technicianSignature': serializer.toJson<String?>(technicianSignature),
      'clientSignature': serializer.toJson<String?>(clientSignature),
      'clientComments': serializer.toJson<String?>(clientComments),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDraft': serializer.toJson<bool>(isDraft),
    };
  }

  CriProjet copyWith(
          {String? id,
          DateTime? interventionDate,
          DateTime? startTime,
          DateTime? endTime,
          Value<DateTime?> endDate = const Value.absent(),
          String? clientName,
          String? site,
          Value<String?> address = const Value.absent(),
          Value<String?> ville = const Value.absent(),
          Value<String?> codePostal = const Value.absent(),
          Value<String?> pays = const Value.absent(),
          Value<String?> clientContact = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          String? projectName,
          String? projectNumber,
          String? projectPhase,
          String? interventionType,
          String? workDescription,
          Value<String?> materialsUsed = const Value.absent(),
          Value<String?> problemsEncountered = const Value.absent(),
          Value<String?> solutionsProvided = const Value.absent(),
          Value<String?> softwares = const Value.absent(),
          Value<String?> actionsToDo = const Value.absent(),
          Value<DateTime?> nextInterventionDate = const Value.absent(),
          String? projectStatus,
          Value<String?> photos = const Value.absent(),
          String? technicianName,
          Value<String?> technicianSignature = const Value.absent(),
          Value<String?> clientSignature = const Value.absent(),
          Value<String?> clientComments = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent(),
          String? syncStatus,
          bool? isDraft}) =>
      CriProjet(
        id: id ?? this.id,
        interventionDate: interventionDate ?? this.interventionDate,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        endDate: endDate.present ? endDate.value : this.endDate,
        clientName: clientName ?? this.clientName,
        site: site ?? this.site,
        address: address.present ? address.value : this.address,
        ville: ville.present ? ville.value : this.ville,
        codePostal: codePostal.present ? codePostal.value : this.codePostal,
        pays: pays.present ? pays.value : this.pays,
        clientContact:
            clientContact.present ? clientContact.value : this.clientContact,
        phone: phone.present ? phone.value : this.phone,
        email: email.present ? email.value : this.email,
        projectName: projectName ?? this.projectName,
        projectNumber: projectNumber ?? this.projectNumber,
        projectPhase: projectPhase ?? this.projectPhase,
        interventionType: interventionType ?? this.interventionType,
        workDescription: workDescription ?? this.workDescription,
        materialsUsed:
            materialsUsed.present ? materialsUsed.value : this.materialsUsed,
        problemsEncountered: problemsEncountered.present
            ? problemsEncountered.value
            : this.problemsEncountered,
        solutionsProvided: solutionsProvided.present
            ? solutionsProvided.value
            : this.solutionsProvided,
        softwares: softwares.present ? softwares.value : this.softwares,
        actionsToDo: actionsToDo.present ? actionsToDo.value : this.actionsToDo,
        nextInterventionDate: nextInterventionDate.present
            ? nextInterventionDate.value
            : this.nextInterventionDate,
        projectStatus: projectStatus ?? this.projectStatus,
        photos: photos.present ? photos.value : this.photos,
        technicianName: technicianName ?? this.technicianName,
        technicianSignature: technicianSignature.present
            ? technicianSignature.value
            : this.technicianSignature,
        clientSignature: clientSignature.present
            ? clientSignature.value
            : this.clientSignature,
        clientComments:
            clientComments.present ? clientComments.value : this.clientComments,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        isDraft: isDraft ?? this.isDraft,
      );
  CriProjet copyWithCompanion(CriProjetTableCompanion data) {
    return CriProjet(
      id: data.id.present ? data.id.value : this.id,
      interventionDate: data.interventionDate.present
          ? data.interventionDate.value
          : this.interventionDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      clientName:
          data.clientName.present ? data.clientName.value : this.clientName,
      site: data.site.present ? data.site.value : this.site,
      address: data.address.present ? data.address.value : this.address,
      ville: data.ville.present ? data.ville.value : this.ville,
      codePostal:
          data.codePostal.present ? data.codePostal.value : this.codePostal,
      pays: data.pays.present ? data.pays.value : this.pays,
      clientContact: data.clientContact.present
          ? data.clientContact.value
          : this.clientContact,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      projectName:
          data.projectName.present ? data.projectName.value : this.projectName,
      projectNumber: data.projectNumber.present
          ? data.projectNumber.value
          : this.projectNumber,
      projectPhase: data.projectPhase.present
          ? data.projectPhase.value
          : this.projectPhase,
      interventionType: data.interventionType.present
          ? data.interventionType.value
          : this.interventionType,
      workDescription: data.workDescription.present
          ? data.workDescription.value
          : this.workDescription,
      materialsUsed: data.materialsUsed.present
          ? data.materialsUsed.value
          : this.materialsUsed,
      problemsEncountered: data.problemsEncountered.present
          ? data.problemsEncountered.value
          : this.problemsEncountered,
      solutionsProvided: data.solutionsProvided.present
          ? data.solutionsProvided.value
          : this.solutionsProvided,
      softwares: data.softwares.present ? data.softwares.value : this.softwares,
      actionsToDo:
          data.actionsToDo.present ? data.actionsToDo.value : this.actionsToDo,
      nextInterventionDate: data.nextInterventionDate.present
          ? data.nextInterventionDate.value
          : this.nextInterventionDate,
      projectStatus: data.projectStatus.present
          ? data.projectStatus.value
          : this.projectStatus,
      photos: data.photos.present ? data.photos.value : this.photos,
      technicianName: data.technicianName.present
          ? data.technicianName.value
          : this.technicianName,
      technicianSignature: data.technicianSignature.present
          ? data.technicianSignature.value
          : this.technicianSignature,
      clientSignature: data.clientSignature.present
          ? data.clientSignature.value
          : this.clientSignature,
      clientComments: data.clientComments.present
          ? data.clientComments.value
          : this.clientComments,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      isDraft: data.isDraft.present ? data.isDraft.value : this.isDraft,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CriProjet(')
          ..write('id: $id, ')
          ..write('interventionDate: $interventionDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('endDate: $endDate, ')
          ..write('clientName: $clientName, ')
          ..write('site: $site, ')
          ..write('address: $address, ')
          ..write('ville: $ville, ')
          ..write('codePostal: $codePostal, ')
          ..write('pays: $pays, ')
          ..write('clientContact: $clientContact, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('projectName: $projectName, ')
          ..write('projectNumber: $projectNumber, ')
          ..write('projectPhase: $projectPhase, ')
          ..write('interventionType: $interventionType, ')
          ..write('workDescription: $workDescription, ')
          ..write('materialsUsed: $materialsUsed, ')
          ..write('problemsEncountered: $problemsEncountered, ')
          ..write('solutionsProvided: $solutionsProvided, ')
          ..write('softwares: $softwares, ')
          ..write('actionsToDo: $actionsToDo, ')
          ..write('nextInterventionDate: $nextInterventionDate, ')
          ..write('projectStatus: $projectStatus, ')
          ..write('photos: $photos, ')
          ..write('technicianName: $technicianName, ')
          ..write('technicianSignature: $technicianSignature, ')
          ..write('clientSignature: $clientSignature, ')
          ..write('clientComments: $clientComments, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDraft: $isDraft')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        interventionDate,
        startTime,
        endTime,
        endDate,
        clientName,
        site,
        address,
        ville,
        codePostal,
        pays,
        clientContact,
        phone,
        email,
        projectName,
        projectNumber,
        projectPhase,
        interventionType,
        workDescription,
        materialsUsed,
        problemsEncountered,
        solutionsProvided,
        softwares,
        actionsToDo,
        nextInterventionDate,
        projectStatus,
        photos,
        technicianName,
        technicianSignature,
        clientSignature,
        clientComments,
        createdAt,
        updatedAt,
        syncStatus,
        isDraft
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CriProjet &&
          other.id == this.id &&
          other.interventionDate == this.interventionDate &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.endDate == this.endDate &&
          other.clientName == this.clientName &&
          other.site == this.site &&
          other.address == this.address &&
          other.ville == this.ville &&
          other.codePostal == this.codePostal &&
          other.pays == this.pays &&
          other.clientContact == this.clientContact &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.projectName == this.projectName &&
          other.projectNumber == this.projectNumber &&
          other.projectPhase == this.projectPhase &&
          other.interventionType == this.interventionType &&
          other.workDescription == this.workDescription &&
          other.materialsUsed == this.materialsUsed &&
          other.problemsEncountered == this.problemsEncountered &&
          other.solutionsProvided == this.solutionsProvided &&
          other.softwares == this.softwares &&
          other.actionsToDo == this.actionsToDo &&
          other.nextInterventionDate == this.nextInterventionDate &&
          other.projectStatus == this.projectStatus &&
          other.photos == this.photos &&
          other.technicianName == this.technicianName &&
          other.technicianSignature == this.technicianSignature &&
          other.clientSignature == this.clientSignature &&
          other.clientComments == this.clientComments &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.isDraft == this.isDraft);
}

class CriProjetTableCompanion extends UpdateCompanion<CriProjet> {
  final Value<String> id;
  final Value<DateTime> interventionDate;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<DateTime?> endDate;
  final Value<String> clientName;
  final Value<String> site;
  final Value<String?> address;
  final Value<String?> ville;
  final Value<String?> codePostal;
  final Value<String?> pays;
  final Value<String?> clientContact;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String> projectName;
  final Value<String> projectNumber;
  final Value<String> projectPhase;
  final Value<String> interventionType;
  final Value<String> workDescription;
  final Value<String?> materialsUsed;
  final Value<String?> problemsEncountered;
  final Value<String?> solutionsProvided;
  final Value<String?> softwares;
  final Value<String?> actionsToDo;
  final Value<DateTime?> nextInterventionDate;
  final Value<String> projectStatus;
  final Value<String?> photos;
  final Value<String> technicianName;
  final Value<String?> technicianSignature;
  final Value<String?> clientSignature;
  final Value<String?> clientComments;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<String> syncStatus;
  final Value<bool> isDraft;
  final Value<int> rowid;
  const CriProjetTableCompanion({
    this.id = const Value.absent(),
    this.interventionDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.endDate = const Value.absent(),
    this.clientName = const Value.absent(),
    this.site = const Value.absent(),
    this.address = const Value.absent(),
    this.ville = const Value.absent(),
    this.codePostal = const Value.absent(),
    this.pays = const Value.absent(),
    this.clientContact = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.projectName = const Value.absent(),
    this.projectNumber = const Value.absent(),
    this.projectPhase = const Value.absent(),
    this.interventionType = const Value.absent(),
    this.workDescription = const Value.absent(),
    this.materialsUsed = const Value.absent(),
    this.problemsEncountered = const Value.absent(),
    this.solutionsProvided = const Value.absent(),
    this.softwares = const Value.absent(),
    this.actionsToDo = const Value.absent(),
    this.nextInterventionDate = const Value.absent(),
    this.projectStatus = const Value.absent(),
    this.photos = const Value.absent(),
    this.technicianName = const Value.absent(),
    this.technicianSignature = const Value.absent(),
    this.clientSignature = const Value.absent(),
    this.clientComments = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CriProjetTableCompanion.insert({
    required String id,
    required DateTime interventionDate,
    required DateTime startTime,
    required DateTime endTime,
    this.endDate = const Value.absent(),
    required String clientName,
    required String site,
    this.address = const Value.absent(),
    this.ville = const Value.absent(),
    this.codePostal = const Value.absent(),
    this.pays = const Value.absent(),
    this.clientContact = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    required String projectName,
    required String projectNumber,
    required String projectPhase,
    required String interventionType,
    required String workDescription,
    this.materialsUsed = const Value.absent(),
    this.problemsEncountered = const Value.absent(),
    this.solutionsProvided = const Value.absent(),
    this.softwares = const Value.absent(),
    this.actionsToDo = const Value.absent(),
    this.nextInterventionDate = const Value.absent(),
    required String projectStatus,
    this.photos = const Value.absent(),
    required String technicianName,
    this.technicianSignature = const Value.absent(),
    this.clientSignature = const Value.absent(),
    this.clientComments = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        interventionDate = Value(interventionDate),
        startTime = Value(startTime),
        endTime = Value(endTime),
        clientName = Value(clientName),
        site = Value(site),
        projectName = Value(projectName),
        projectNumber = Value(projectNumber),
        projectPhase = Value(projectPhase),
        interventionType = Value(interventionType),
        workDescription = Value(workDescription),
        projectStatus = Value(projectStatus),
        technicianName = Value(technicianName);
  static Insertable<CriProjet> custom({
    Expression<String>? id,
    Expression<DateTime>? interventionDate,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<DateTime>? endDate,
    Expression<String>? clientName,
    Expression<String>? site,
    Expression<String>? address,
    Expression<String>? ville,
    Expression<String>? codePostal,
    Expression<String>? pays,
    Expression<String>? clientContact,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? projectName,
    Expression<String>? projectNumber,
    Expression<String>? projectPhase,
    Expression<String>? interventionType,
    Expression<String>? workDescription,
    Expression<String>? materialsUsed,
    Expression<String>? problemsEncountered,
    Expression<String>? solutionsProvided,
    Expression<String>? softwares,
    Expression<String>? actionsToDo,
    Expression<DateTime>? nextInterventionDate,
    Expression<String>? projectStatus,
    Expression<String>? photos,
    Expression<String>? technicianName,
    Expression<String>? technicianSignature,
    Expression<String>? clientSignature,
    Expression<String>? clientComments,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<bool>? isDraft,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (interventionDate != null) 'intervention_date': interventionDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (endDate != null) 'end_date': endDate,
      if (clientName != null) 'client_name': clientName,
      if (site != null) 'site': site,
      if (address != null) 'address': address,
      if (ville != null) 'ville': ville,
      if (codePostal != null) 'code_postal': codePostal,
      if (pays != null) 'pays': pays,
      if (clientContact != null) 'client_contact': clientContact,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (projectName != null) 'project_name': projectName,
      if (projectNumber != null) 'project_number': projectNumber,
      if (projectPhase != null) 'project_phase': projectPhase,
      if (interventionType != null) 'intervention_type': interventionType,
      if (workDescription != null) 'work_description': workDescription,
      if (materialsUsed != null) 'materials_used': materialsUsed,
      if (problemsEncountered != null)
        'problems_encountered': problemsEncountered,
      if (solutionsProvided != null) 'solutions_provided': solutionsProvided,
      if (softwares != null) 'softwares': softwares,
      if (actionsToDo != null) 'actions_to_do': actionsToDo,
      if (nextInterventionDate != null)
        'next_intervention_date': nextInterventionDate,
      if (projectStatus != null) 'project_status': projectStatus,
      if (photos != null) 'photos': photos,
      if (technicianName != null) 'technician_name': technicianName,
      if (technicianSignature != null)
        'technician_signature': technicianSignature,
      if (clientSignature != null) 'client_signature': clientSignature,
      if (clientComments != null) 'client_comments': clientComments,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDraft != null) 'is_draft': isDraft,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CriProjetTableCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? interventionDate,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<DateTime?>? endDate,
      Value<String>? clientName,
      Value<String>? site,
      Value<String?>? address,
      Value<String?>? ville,
      Value<String?>? codePostal,
      Value<String?>? pays,
      Value<String?>? clientContact,
      Value<String?>? phone,
      Value<String?>? email,
      Value<String>? projectName,
      Value<String>? projectNumber,
      Value<String>? projectPhase,
      Value<String>? interventionType,
      Value<String>? workDescription,
      Value<String?>? materialsUsed,
      Value<String?>? problemsEncountered,
      Value<String?>? solutionsProvided,
      Value<String?>? softwares,
      Value<String?>? actionsToDo,
      Value<DateTime?>? nextInterventionDate,
      Value<String>? projectStatus,
      Value<String?>? photos,
      Value<String>? technicianName,
      Value<String?>? technicianSignature,
      Value<String?>? clientSignature,
      Value<String?>? clientComments,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<String>? syncStatus,
      Value<bool>? isDraft,
      Value<int>? rowid}) {
    return CriProjetTableCompanion(
      id: id ?? this.id,
      interventionDate: interventionDate ?? this.interventionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      endDate: endDate ?? this.endDate,
      clientName: clientName ?? this.clientName,
      site: site ?? this.site,
      address: address ?? this.address,
      ville: ville ?? this.ville,
      codePostal: codePostal ?? this.codePostal,
      pays: pays ?? this.pays,
      clientContact: clientContact ?? this.clientContact,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      projectName: projectName ?? this.projectName,
      projectNumber: projectNumber ?? this.projectNumber,
      projectPhase: projectPhase ?? this.projectPhase,
      interventionType: interventionType ?? this.interventionType,
      workDescription: workDescription ?? this.workDescription,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      problemsEncountered: problemsEncountered ?? this.problemsEncountered,
      solutionsProvided: solutionsProvided ?? this.solutionsProvided,
      softwares: softwares ?? this.softwares,
      actionsToDo: actionsToDo ?? this.actionsToDo,
      nextInterventionDate: nextInterventionDate ?? this.nextInterventionDate,
      projectStatus: projectStatus ?? this.projectStatus,
      photos: photos ?? this.photos,
      technicianName: technicianName ?? this.technicianName,
      technicianSignature: technicianSignature ?? this.technicianSignature,
      clientSignature: clientSignature ?? this.clientSignature,
      clientComments: clientComments ?? this.clientComments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDraft: isDraft ?? this.isDraft,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (interventionDate.present) {
      map['intervention_date'] = Variable<DateTime>(interventionDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (site.present) {
      map['site'] = Variable<String>(site.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (ville.present) {
      map['ville'] = Variable<String>(ville.value);
    }
    if (codePostal.present) {
      map['code_postal'] = Variable<String>(codePostal.value);
    }
    if (pays.present) {
      map['pays'] = Variable<String>(pays.value);
    }
    if (clientContact.present) {
      map['client_contact'] = Variable<String>(clientContact.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (projectNumber.present) {
      map['project_number'] = Variable<String>(projectNumber.value);
    }
    if (projectPhase.present) {
      map['project_phase'] = Variable<String>(projectPhase.value);
    }
    if (interventionType.present) {
      map['intervention_type'] = Variable<String>(interventionType.value);
    }
    if (workDescription.present) {
      map['work_description'] = Variable<String>(workDescription.value);
    }
    if (materialsUsed.present) {
      map['materials_used'] = Variable<String>(materialsUsed.value);
    }
    if (problemsEncountered.present) {
      map['problems_encountered'] = Variable<String>(problemsEncountered.value);
    }
    if (solutionsProvided.present) {
      map['solutions_provided'] = Variable<String>(solutionsProvided.value);
    }
    if (softwares.present) {
      map['softwares'] = Variable<String>(softwares.value);
    }
    if (actionsToDo.present) {
      map['actions_to_do'] = Variable<String>(actionsToDo.value);
    }
    if (nextInterventionDate.present) {
      map['next_intervention_date'] =
          Variable<DateTime>(nextInterventionDate.value);
    }
    if (projectStatus.present) {
      map['project_status'] = Variable<String>(projectStatus.value);
    }
    if (photos.present) {
      map['photos'] = Variable<String>(photos.value);
    }
    if (technicianName.present) {
      map['technician_name'] = Variable<String>(technicianName.value);
    }
    if (technicianSignature.present) {
      map['technician_signature'] = Variable<String>(technicianSignature.value);
    }
    if (clientSignature.present) {
      map['client_signature'] = Variable<String>(clientSignature.value);
    }
    if (clientComments.present) {
      map['client_comments'] = Variable<String>(clientComments.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDraft.present) {
      map['is_draft'] = Variable<bool>(isDraft.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CriProjetTableCompanion(')
          ..write('id: $id, ')
          ..write('interventionDate: $interventionDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('endDate: $endDate, ')
          ..write('clientName: $clientName, ')
          ..write('site: $site, ')
          ..write('address: $address, ')
          ..write('ville: $ville, ')
          ..write('codePostal: $codePostal, ')
          ..write('pays: $pays, ')
          ..write('clientContact: $clientContact, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('projectName: $projectName, ')
          ..write('projectNumber: $projectNumber, ')
          ..write('projectPhase: $projectPhase, ')
          ..write('interventionType: $interventionType, ')
          ..write('workDescription: $workDescription, ')
          ..write('materialsUsed: $materialsUsed, ')
          ..write('problemsEncountered: $problemsEncountered, ')
          ..write('solutionsProvided: $solutionsProvided, ')
          ..write('softwares: $softwares, ')
          ..write('actionsToDo: $actionsToDo, ')
          ..write('nextInterventionDate: $nextInterventionDate, ')
          ..write('projectStatus: $projectStatus, ')
          ..write('photos: $photos, ')
          ..write('technicianName: $technicianName, ')
          ..write('technicianSignature: $technicianSignature, ')
          ..write('clientSignature: $clientSignature, ')
          ..write('clientComments: $clientComments, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDraft: $isDraft, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportedDocumentTableTable extends ExportedDocumentTable
    with TableInfo<$ExportedDocumentTableTable, ExportedDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportedDocumentTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _criIdMeta = const VerificationMeta('criId');
  @override
  late final GeneratedColumn<String> criId = GeneratedColumn<String>(
      'cri_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileTypeMeta =
      const VerificationMeta('fileType');
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
      'file_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _exportTypeMeta =
      const VerificationMeta('exportType');
  @override
  late final GeneratedColumn<String> exportType = GeneratedColumn<String>(
      'export_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sharedAtMeta =
      const VerificationMeta('sharedAt');
  @override
  late final GeneratedColumn<DateTime> sharedAt = GeneratedColumn<DateTime>(
      'shared_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        criId,
        filename,
        filePath,
        fileType,
        fileSize,
        exportType,
        metadata,
        createdAt,
        sharedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exported_document_table';
  @override
  VerificationContext validateIntegrity(Insertable<ExportedDocument> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cri_id')) {
      context.handle(
          _criIdMeta, criId.isAcceptableOrUnknown(data['cri_id']!, _criIdMeta));
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(_fileTypeMeta,
          fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta));
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('export_type')) {
      context.handle(
          _exportTypeMeta,
          exportType.isAcceptableOrUnknown(
              data['export_type']!, _exportTypeMeta));
    } else if (isInserting) {
      context.missing(_exportTypeMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('shared_at')) {
      context.handle(_sharedAtMeta,
          sharedAt.isAcceptableOrUnknown(data['shared_at']!, _sharedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportedDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportedDocument(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      criId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cri_id']),
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_type'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      exportType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}export_type'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      sharedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}shared_at']),
    );
  }

  @override
  $ExportedDocumentTableTable createAlias(String alias) {
    return $ExportedDocumentTableTable(attachedDatabase, alias);
  }
}

class ExportedDocument extends DataClass
    implements Insertable<ExportedDocument> {
  final int id;
  final String? criId;
  final String filename;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String exportType;
  final String? metadata;
  final DateTime createdAt;
  final DateTime? sharedAt;
  const ExportedDocument(
      {required this.id,
      this.criId,
      required this.filename,
      required this.filePath,
      required this.fileType,
      required this.fileSize,
      required this.exportType,
      this.metadata,
      required this.createdAt,
      this.sharedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || criId != null) {
      map['cri_id'] = Variable<String>(criId);
    }
    map['filename'] = Variable<String>(filename);
    map['file_path'] = Variable<String>(filePath);
    map['file_type'] = Variable<String>(fileType);
    map['file_size'] = Variable<int>(fileSize);
    map['export_type'] = Variable<String>(exportType);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || sharedAt != null) {
      map['shared_at'] = Variable<DateTime>(sharedAt);
    }
    return map;
  }

  ExportedDocumentTableCompanion toCompanion(bool nullToAbsent) {
    return ExportedDocumentTableCompanion(
      id: Value(id),
      criId:
          criId == null && nullToAbsent ? const Value.absent() : Value(criId),
      filename: Value(filename),
      filePath: Value(filePath),
      fileType: Value(fileType),
      fileSize: Value(fileSize),
      exportType: Value(exportType),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      sharedAt: sharedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedAt),
    );
  }

  factory ExportedDocument.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportedDocument(
      id: serializer.fromJson<int>(json['id']),
      criId: serializer.fromJson<String?>(json['criId']),
      filename: serializer.fromJson<String>(json['filename']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileType: serializer.fromJson<String>(json['fileType']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      exportType: serializer.fromJson<String>(json['exportType']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sharedAt: serializer.fromJson<DateTime?>(json['sharedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'criId': serializer.toJson<String?>(criId),
      'filename': serializer.toJson<String>(filename),
      'filePath': serializer.toJson<String>(filePath),
      'fileType': serializer.toJson<String>(fileType),
      'fileSize': serializer.toJson<int>(fileSize),
      'exportType': serializer.toJson<String>(exportType),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sharedAt': serializer.toJson<DateTime?>(sharedAt),
    };
  }

  ExportedDocument copyWith(
          {int? id,
          Value<String?> criId = const Value.absent(),
          String? filename,
          String? filePath,
          String? fileType,
          int? fileSize,
          String? exportType,
          Value<String?> metadata = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> sharedAt = const Value.absent()}) =>
      ExportedDocument(
        id: id ?? this.id,
        criId: criId.present ? criId.value : this.criId,
        filename: filename ?? this.filename,
        filePath: filePath ?? this.filePath,
        fileType: fileType ?? this.fileType,
        fileSize: fileSize ?? this.fileSize,
        exportType: exportType ?? this.exportType,
        metadata: metadata.present ? metadata.value : this.metadata,
        createdAt: createdAt ?? this.createdAt,
        sharedAt: sharedAt.present ? sharedAt.value : this.sharedAt,
      );
  ExportedDocument copyWithCompanion(ExportedDocumentTableCompanion data) {
    return ExportedDocument(
      id: data.id.present ? data.id.value : this.id,
      criId: data.criId.present ? data.criId.value : this.criId,
      filename: data.filename.present ? data.filename.value : this.filename,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      exportType:
          data.exportType.present ? data.exportType.value : this.exportType,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sharedAt: data.sharedAt.present ? data.sharedAt.value : this.sharedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportedDocument(')
          ..write('id: $id, ')
          ..write('criId: $criId, ')
          ..write('filename: $filename, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('fileSize: $fileSize, ')
          ..write('exportType: $exportType, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('sharedAt: $sharedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, criId, filename, filePath, fileType,
      fileSize, exportType, metadata, createdAt, sharedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportedDocument &&
          other.id == this.id &&
          other.criId == this.criId &&
          other.filename == this.filename &&
          other.filePath == this.filePath &&
          other.fileType == this.fileType &&
          other.fileSize == this.fileSize &&
          other.exportType == this.exportType &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.sharedAt == this.sharedAt);
}

class ExportedDocumentTableCompanion extends UpdateCompanion<ExportedDocument> {
  final Value<int> id;
  final Value<String?> criId;
  final Value<String> filename;
  final Value<String> filePath;
  final Value<String> fileType;
  final Value<int> fileSize;
  final Value<String> exportType;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime?> sharedAt;
  const ExportedDocumentTableCompanion({
    this.id = const Value.absent(),
    this.criId = const Value.absent(),
    this.filename = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.exportType = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sharedAt = const Value.absent(),
  });
  ExportedDocumentTableCompanion.insert({
    this.id = const Value.absent(),
    this.criId = const Value.absent(),
    required String filename,
    required String filePath,
    required String fileType,
    required int fileSize,
    required String exportType,
    this.metadata = const Value.absent(),
    required DateTime createdAt,
    this.sharedAt = const Value.absent(),
  })  : filename = Value(filename),
        filePath = Value(filePath),
        fileType = Value(fileType),
        fileSize = Value(fileSize),
        exportType = Value(exportType),
        createdAt = Value(createdAt);
  static Insertable<ExportedDocument> custom({
    Expression<int>? id,
    Expression<String>? criId,
    Expression<String>? filename,
    Expression<String>? filePath,
    Expression<String>? fileType,
    Expression<int>? fileSize,
    Expression<String>? exportType,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? sharedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (criId != null) 'cri_id': criId,
      if (filename != null) 'filename': filename,
      if (filePath != null) 'file_path': filePath,
      if (fileType != null) 'file_type': fileType,
      if (fileSize != null) 'file_size': fileSize,
      if (exportType != null) 'export_type': exportType,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (sharedAt != null) 'shared_at': sharedAt,
    });
  }

  ExportedDocumentTableCompanion copyWith(
      {Value<int>? id,
      Value<String?>? criId,
      Value<String>? filename,
      Value<String>? filePath,
      Value<String>? fileType,
      Value<int>? fileSize,
      Value<String>? exportType,
      Value<String?>? metadata,
      Value<DateTime>? createdAt,
      Value<DateTime?>? sharedAt}) {
    return ExportedDocumentTableCompanion(
      id: id ?? this.id,
      criId: criId ?? this.criId,
      filename: filename ?? this.filename,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      exportType: exportType ?? this.exportType,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (criId.present) {
      map['cri_id'] = Variable<String>(criId.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (exportType.present) {
      map['export_type'] = Variable<String>(exportType.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sharedAt.present) {
      map['shared_at'] = Variable<DateTime>(sharedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportedDocumentTableCompanion(')
          ..write('id: $id, ')
          ..write('criId: $criId, ')
          ..write('filename: $filename, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('fileSize: $fileSize, ')
          ..write('exportType: $exportType, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('sharedAt: $sharedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CriServiceTableTable criServiceTable =
      $CriServiceTableTable(this);
  late final $CriProjetTableTable criProjetTable = $CriProjetTableTable(this);
  late final $ExportedDocumentTableTable exportedDocumentTable =
      $ExportedDocumentTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [criServiceTable, criProjetTable, exportedDocumentTable];
}

typedef $$CriServiceTableTableCreateCompanionBuilder = CriServiceTableCompanion
    Function({
  required String id,
  required DateTime interventionDate,
  required DateTime startTime,
  required DateTime endTime,
  Value<DateTime?> endDate,
  Value<String?> ticketNumber,
  required String clientName,
  required String site,
  Value<String?> address,
  Value<String?> ville,
  Value<String?> codePostal,
  Value<String?> pays,
  Value<String?> clientContact,
  Value<String?> phone,
  Value<String?> email,
  required String requestType,
  required String requestDescription,
  Value<String?> contratType,
  Value<String?> systemTypes,
  Value<String?> diagnosticPerformed,
  Value<String?> identifiedCause,
  required String actionsPerformed,
  Value<String?> replacedParts,
  required int interventionDurationMinutes,
  required String resolutionStatus,
  Value<String?> testsPerformed,
  Value<String?> recommendations,
  Value<String?> cybersecurityRecommendations,
  Value<bool> additionalInterventionRequired,
  Value<DateTime?> followUpDate,
  Value<String?> followUpComments,
  Value<bool> devisARealiser,
  Value<bool> facturable,
  Value<String?> photos,
  required String technicianName,
  Value<String?> technicianSignature,
  Value<String?> clientSignature,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<String> syncStatus,
  Value<bool> isDraft,
  Value<int> rowid,
});
typedef $$CriServiceTableTableUpdateCompanionBuilder = CriServiceTableCompanion
    Function({
  Value<String> id,
  Value<DateTime> interventionDate,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<DateTime?> endDate,
  Value<String?> ticketNumber,
  Value<String> clientName,
  Value<String> site,
  Value<String?> address,
  Value<String?> ville,
  Value<String?> codePostal,
  Value<String?> pays,
  Value<String?> clientContact,
  Value<String?> phone,
  Value<String?> email,
  Value<String> requestType,
  Value<String> requestDescription,
  Value<String?> contratType,
  Value<String?> systemTypes,
  Value<String?> diagnosticPerformed,
  Value<String?> identifiedCause,
  Value<String> actionsPerformed,
  Value<String?> replacedParts,
  Value<int> interventionDurationMinutes,
  Value<String> resolutionStatus,
  Value<String?> testsPerformed,
  Value<String?> recommendations,
  Value<String?> cybersecurityRecommendations,
  Value<bool> additionalInterventionRequired,
  Value<DateTime?> followUpDate,
  Value<String?> followUpComments,
  Value<bool> devisARealiser,
  Value<bool> facturable,
  Value<String?> photos,
  Value<String> technicianName,
  Value<String?> technicianSignature,
  Value<String?> clientSignature,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<String> syncStatus,
  Value<bool> isDraft,
  Value<int> rowid,
});

class $$CriServiceTableTableFilterComposer
    extends Composer<_$AppDatabase, $CriServiceTableTable> {
  $$CriServiceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get interventionDate => $composableBuilder(
      column: $table.interventionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ticketNumber => $composableBuilder(
      column: $table.ticketNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get site => $composableBuilder(
      column: $table.site, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ville => $composableBuilder(
      column: $table.ville, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codePostal => $composableBuilder(
      column: $table.codePostal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pays => $composableBuilder(
      column: $table.pays, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientContact => $composableBuilder(
      column: $table.clientContact, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestDescription => $composableBuilder(
      column: $table.requestDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contratType => $composableBuilder(
      column: $table.contratType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemTypes => $composableBuilder(
      column: $table.systemTypes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diagnosticPerformed => $composableBuilder(
      column: $table.diagnosticPerformed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifiedCause => $composableBuilder(
      column: $table.identifiedCause,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionsPerformed => $composableBuilder(
      column: $table.actionsPerformed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get replacedParts => $composableBuilder(
      column: $table.replacedParts, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get interventionDurationMinutes => $composableBuilder(
      column: $table.interventionDurationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resolutionStatus => $composableBuilder(
      column: $table.resolutionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get testsPerformed => $composableBuilder(
      column: $table.testsPerformed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recommendations => $composableBuilder(
      column: $table.recommendations,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cybersecurityRecommendations => $composableBuilder(
      column: $table.cybersecurityRecommendations,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get additionalInterventionRequired => $composableBuilder(
      column: $table.additionalInterventionRequired,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get followUpDate => $composableBuilder(
      column: $table.followUpDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get followUpComments => $composableBuilder(
      column: $table.followUpComments,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get devisARealiser => $composableBuilder(
      column: $table.devisARealiser,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get facturable => $composableBuilder(
      column: $table.facturable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photos => $composableBuilder(
      column: $table.photos, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get technicianName => $composableBuilder(
      column: $table.technicianName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get technicianSignature => $composableBuilder(
      column: $table.technicianSignature,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientSignature => $composableBuilder(
      column: $table.clientSignature,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDraft => $composableBuilder(
      column: $table.isDraft, builder: (column) => ColumnFilters(column));
}

class $$CriServiceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CriServiceTableTable> {
  $$CriServiceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get interventionDate => $composableBuilder(
      column: $table.interventionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ticketNumber => $composableBuilder(
      column: $table.ticketNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get site => $composableBuilder(
      column: $table.site, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ville => $composableBuilder(
      column: $table.ville, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codePostal => $composableBuilder(
      column: $table.codePostal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pays => $composableBuilder(
      column: $table.pays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientContact => $composableBuilder(
      column: $table.clientContact,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestDescription => $composableBuilder(
      column: $table.requestDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contratType => $composableBuilder(
      column: $table.contratType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemTypes => $composableBuilder(
      column: $table.systemTypes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diagnosticPerformed => $composableBuilder(
      column: $table.diagnosticPerformed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifiedCause => $composableBuilder(
      column: $table.identifiedCause,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionsPerformed => $composableBuilder(
      column: $table.actionsPerformed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get replacedParts => $composableBuilder(
      column: $table.replacedParts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get interventionDurationMinutes => $composableBuilder(
      column: $table.interventionDurationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resolutionStatus => $composableBuilder(
      column: $table.resolutionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get testsPerformed => $composableBuilder(
      column: $table.testsPerformed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recommendations => $composableBuilder(
      column: $table.recommendations,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cybersecurityRecommendations =>
      $composableBuilder(
          column: $table.cybersecurityRecommendations,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get additionalInterventionRequired =>
      $composableBuilder(
          column: $table.additionalInterventionRequired,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get followUpDate => $composableBuilder(
      column: $table.followUpDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get followUpComments => $composableBuilder(
      column: $table.followUpComments,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get devisARealiser => $composableBuilder(
      column: $table.devisARealiser,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get facturable => $composableBuilder(
      column: $table.facturable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photos => $composableBuilder(
      column: $table.photos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get technicianName => $composableBuilder(
      column: $table.technicianName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get technicianSignature => $composableBuilder(
      column: $table.technicianSignature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientSignature => $composableBuilder(
      column: $table.clientSignature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDraft => $composableBuilder(
      column: $table.isDraft, builder: (column) => ColumnOrderings(column));
}

class $$CriServiceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CriServiceTableTable> {
  $$CriServiceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get interventionDate => $composableBuilder(
      column: $table.interventionDate, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get ticketNumber => $composableBuilder(
      column: $table.ticketNumber, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => column);

  GeneratedColumn<String> get site =>
      $composableBuilder(column: $table.site, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get ville =>
      $composableBuilder(column: $table.ville, builder: (column) => column);

  GeneratedColumn<String> get codePostal => $composableBuilder(
      column: $table.codePostal, builder: (column) => column);

  GeneratedColumn<String> get pays =>
      $composableBuilder(column: $table.pays, builder: (column) => column);

  GeneratedColumn<String> get clientContact => $composableBuilder(
      column: $table.clientContact, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => column);

  GeneratedColumn<String> get requestDescription => $composableBuilder(
      column: $table.requestDescription, builder: (column) => column);

  GeneratedColumn<String> get contratType => $composableBuilder(
      column: $table.contratType, builder: (column) => column);

  GeneratedColumn<String> get systemTypes => $composableBuilder(
      column: $table.systemTypes, builder: (column) => column);

  GeneratedColumn<String> get diagnosticPerformed => $composableBuilder(
      column: $table.diagnosticPerformed, builder: (column) => column);

  GeneratedColumn<String> get identifiedCause => $composableBuilder(
      column: $table.identifiedCause, builder: (column) => column);

  GeneratedColumn<String> get actionsPerformed => $composableBuilder(
      column: $table.actionsPerformed, builder: (column) => column);

  GeneratedColumn<String> get replacedParts => $composableBuilder(
      column: $table.replacedParts, builder: (column) => column);

  GeneratedColumn<int> get interventionDurationMinutes => $composableBuilder(
      column: $table.interventionDurationMinutes, builder: (column) => column);

  GeneratedColumn<String> get resolutionStatus => $composableBuilder(
      column: $table.resolutionStatus, builder: (column) => column);

  GeneratedColumn<String> get testsPerformed => $composableBuilder(
      column: $table.testsPerformed, builder: (column) => column);

  GeneratedColumn<String> get recommendations => $composableBuilder(
      column: $table.recommendations, builder: (column) => column);

  GeneratedColumn<String> get cybersecurityRecommendations =>
      $composableBuilder(
          column: $table.cybersecurityRecommendations,
          builder: (column) => column);

  GeneratedColumn<bool> get additionalInterventionRequired =>
      $composableBuilder(
          column: $table.additionalInterventionRequired,
          builder: (column) => column);

  GeneratedColumn<DateTime> get followUpDate => $composableBuilder(
      column: $table.followUpDate, builder: (column) => column);

  GeneratedColumn<String> get followUpComments => $composableBuilder(
      column: $table.followUpComments, builder: (column) => column);

  GeneratedColumn<bool> get devisARealiser => $composableBuilder(
      column: $table.devisARealiser, builder: (column) => column);

  GeneratedColumn<bool> get facturable => $composableBuilder(
      column: $table.facturable, builder: (column) => column);

  GeneratedColumn<String> get photos =>
      $composableBuilder(column: $table.photos, builder: (column) => column);

  GeneratedColumn<String> get technicianName => $composableBuilder(
      column: $table.technicianName, builder: (column) => column);

  GeneratedColumn<String> get technicianSignature => $composableBuilder(
      column: $table.technicianSignature, builder: (column) => column);

  GeneratedColumn<String> get clientSignature => $composableBuilder(
      column: $table.clientSignature, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<bool> get isDraft =>
      $composableBuilder(column: $table.isDraft, builder: (column) => column);
}

class $$CriServiceTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CriServiceTableTable,
    CriService,
    $$CriServiceTableTableFilterComposer,
    $$CriServiceTableTableOrderingComposer,
    $$CriServiceTableTableAnnotationComposer,
    $$CriServiceTableTableCreateCompanionBuilder,
    $$CriServiceTableTableUpdateCompanionBuilder,
    (
      CriService,
      BaseReferences<_$AppDatabase, $CriServiceTableTable, CriService>
    ),
    CriService,
    PrefetchHooks Function()> {
  $$CriServiceTableTableTableManager(
      _$AppDatabase db, $CriServiceTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CriServiceTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CriServiceTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CriServiceTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> interventionDate = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String?> ticketNumber = const Value.absent(),
            Value<String> clientName = const Value.absent(),
            Value<String> site = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> ville = const Value.absent(),
            Value<String?> codePostal = const Value.absent(),
            Value<String?> pays = const Value.absent(),
            Value<String?> clientContact = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String> requestType = const Value.absent(),
            Value<String> requestDescription = const Value.absent(),
            Value<String?> contratType = const Value.absent(),
            Value<String?> systemTypes = const Value.absent(),
            Value<String?> diagnosticPerformed = const Value.absent(),
            Value<String?> identifiedCause = const Value.absent(),
            Value<String> actionsPerformed = const Value.absent(),
            Value<String?> replacedParts = const Value.absent(),
            Value<int> interventionDurationMinutes = const Value.absent(),
            Value<String> resolutionStatus = const Value.absent(),
            Value<String?> testsPerformed = const Value.absent(),
            Value<String?> recommendations = const Value.absent(),
            Value<String?> cybersecurityRecommendations = const Value.absent(),
            Value<bool> additionalInterventionRequired = const Value.absent(),
            Value<DateTime?> followUpDate = const Value.absent(),
            Value<String?> followUpComments = const Value.absent(),
            Value<bool> devisARealiser = const Value.absent(),
            Value<bool> facturable = const Value.absent(),
            Value<String?> photos = const Value.absent(),
            Value<String> technicianName = const Value.absent(),
            Value<String?> technicianSignature = const Value.absent(),
            Value<String?> clientSignature = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<bool> isDraft = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CriServiceTableCompanion(
            id: id,
            interventionDate: interventionDate,
            startTime: startTime,
            endTime: endTime,
            endDate: endDate,
            ticketNumber: ticketNumber,
            clientName: clientName,
            site: site,
            address: address,
            ville: ville,
            codePostal: codePostal,
            pays: pays,
            clientContact: clientContact,
            phone: phone,
            email: email,
            requestType: requestType,
            requestDescription: requestDescription,
            contratType: contratType,
            systemTypes: systemTypes,
            diagnosticPerformed: diagnosticPerformed,
            identifiedCause: identifiedCause,
            actionsPerformed: actionsPerformed,
            replacedParts: replacedParts,
            interventionDurationMinutes: interventionDurationMinutes,
            resolutionStatus: resolutionStatus,
            testsPerformed: testsPerformed,
            recommendations: recommendations,
            cybersecurityRecommendations: cybersecurityRecommendations,
            additionalInterventionRequired: additionalInterventionRequired,
            followUpDate: followUpDate,
            followUpComments: followUpComments,
            devisARealiser: devisARealiser,
            facturable: facturable,
            photos: photos,
            technicianName: technicianName,
            technicianSignature: technicianSignature,
            clientSignature: clientSignature,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            isDraft: isDraft,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime interventionDate,
            required DateTime startTime,
            required DateTime endTime,
            Value<DateTime?> endDate = const Value.absent(),
            Value<String?> ticketNumber = const Value.absent(),
            required String clientName,
            required String site,
            Value<String?> address = const Value.absent(),
            Value<String?> ville = const Value.absent(),
            Value<String?> codePostal = const Value.absent(),
            Value<String?> pays = const Value.absent(),
            Value<String?> clientContact = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            required String requestType,
            required String requestDescription,
            Value<String?> contratType = const Value.absent(),
            Value<String?> systemTypes = const Value.absent(),
            Value<String?> diagnosticPerformed = const Value.absent(),
            Value<String?> identifiedCause = const Value.absent(),
            required String actionsPerformed,
            Value<String?> replacedParts = const Value.absent(),
            required int interventionDurationMinutes,
            required String resolutionStatus,
            Value<String?> testsPerformed = const Value.absent(),
            Value<String?> recommendations = const Value.absent(),
            Value<String?> cybersecurityRecommendations = const Value.absent(),
            Value<bool> additionalInterventionRequired = const Value.absent(),
            Value<DateTime?> followUpDate = const Value.absent(),
            Value<String?> followUpComments = const Value.absent(),
            Value<bool> devisARealiser = const Value.absent(),
            Value<bool> facturable = const Value.absent(),
            Value<String?> photos = const Value.absent(),
            required String technicianName,
            Value<String?> technicianSignature = const Value.absent(),
            Value<String?> clientSignature = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<bool> isDraft = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CriServiceTableCompanion.insert(
            id: id,
            interventionDate: interventionDate,
            startTime: startTime,
            endTime: endTime,
            endDate: endDate,
            ticketNumber: ticketNumber,
            clientName: clientName,
            site: site,
            address: address,
            ville: ville,
            codePostal: codePostal,
            pays: pays,
            clientContact: clientContact,
            phone: phone,
            email: email,
            requestType: requestType,
            requestDescription: requestDescription,
            contratType: contratType,
            systemTypes: systemTypes,
            diagnosticPerformed: diagnosticPerformed,
            identifiedCause: identifiedCause,
            actionsPerformed: actionsPerformed,
            replacedParts: replacedParts,
            interventionDurationMinutes: interventionDurationMinutes,
            resolutionStatus: resolutionStatus,
            testsPerformed: testsPerformed,
            recommendations: recommendations,
            cybersecurityRecommendations: cybersecurityRecommendations,
            additionalInterventionRequired: additionalInterventionRequired,
            followUpDate: followUpDate,
            followUpComments: followUpComments,
            devisARealiser: devisARealiser,
            facturable: facturable,
            photos: photos,
            technicianName: technicianName,
            technicianSignature: technicianSignature,
            clientSignature: clientSignature,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            isDraft: isDraft,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CriServiceTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CriServiceTableTable,
    CriService,
    $$CriServiceTableTableFilterComposer,
    $$CriServiceTableTableOrderingComposer,
    $$CriServiceTableTableAnnotationComposer,
    $$CriServiceTableTableCreateCompanionBuilder,
    $$CriServiceTableTableUpdateCompanionBuilder,
    (
      CriService,
      BaseReferences<_$AppDatabase, $CriServiceTableTable, CriService>
    ),
    CriService,
    PrefetchHooks Function()>;
typedef $$CriProjetTableTableCreateCompanionBuilder = CriProjetTableCompanion
    Function({
  required String id,
  required DateTime interventionDate,
  required DateTime startTime,
  required DateTime endTime,
  Value<DateTime?> endDate,
  required String clientName,
  required String site,
  Value<String?> address,
  Value<String?> ville,
  Value<String?> codePostal,
  Value<String?> pays,
  Value<String?> clientContact,
  Value<String?> phone,
  Value<String?> email,
  required String projectName,
  required String projectNumber,
  required String projectPhase,
  required String interventionType,
  required String workDescription,
  Value<String?> materialsUsed,
  Value<String?> problemsEncountered,
  Value<String?> solutionsProvided,
  Value<String?> softwares,
  Value<String?> actionsToDo,
  Value<DateTime?> nextInterventionDate,
  required String projectStatus,
  Value<String?> photos,
  required String technicianName,
  Value<String?> technicianSignature,
  Value<String?> clientSignature,
  Value<String?> clientComments,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<String> syncStatus,
  Value<bool> isDraft,
  Value<int> rowid,
});
typedef $$CriProjetTableTableUpdateCompanionBuilder = CriProjetTableCompanion
    Function({
  Value<String> id,
  Value<DateTime> interventionDate,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<DateTime?> endDate,
  Value<String> clientName,
  Value<String> site,
  Value<String?> address,
  Value<String?> ville,
  Value<String?> codePostal,
  Value<String?> pays,
  Value<String?> clientContact,
  Value<String?> phone,
  Value<String?> email,
  Value<String> projectName,
  Value<String> projectNumber,
  Value<String> projectPhase,
  Value<String> interventionType,
  Value<String> workDescription,
  Value<String?> materialsUsed,
  Value<String?> problemsEncountered,
  Value<String?> solutionsProvided,
  Value<String?> softwares,
  Value<String?> actionsToDo,
  Value<DateTime?> nextInterventionDate,
  Value<String> projectStatus,
  Value<String?> photos,
  Value<String> technicianName,
  Value<String?> technicianSignature,
  Value<String?> clientSignature,
  Value<String?> clientComments,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<String> syncStatus,
  Value<bool> isDraft,
  Value<int> rowid,
});

class $$CriProjetTableTableFilterComposer
    extends Composer<_$AppDatabase, $CriProjetTableTable> {
  $$CriProjetTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get interventionDate => $composableBuilder(
      column: $table.interventionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get site => $composableBuilder(
      column: $table.site, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ville => $composableBuilder(
      column: $table.ville, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codePostal => $composableBuilder(
      column: $table.codePostal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pays => $composableBuilder(
      column: $table.pays, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientContact => $composableBuilder(
      column: $table.clientContact, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectNumber => $composableBuilder(
      column: $table.projectNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectPhase => $composableBuilder(
      column: $table.projectPhase, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get interventionType => $composableBuilder(
      column: $table.interventionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workDescription => $composableBuilder(
      column: $table.workDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get materialsUsed => $composableBuilder(
      column: $table.materialsUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get problemsEncountered => $composableBuilder(
      column: $table.problemsEncountered,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solutionsProvided => $composableBuilder(
      column: $table.solutionsProvided,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get softwares => $composableBuilder(
      column: $table.softwares, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionsToDo => $composableBuilder(
      column: $table.actionsToDo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextInterventionDate => $composableBuilder(
      column: $table.nextInterventionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectStatus => $composableBuilder(
      column: $table.projectStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photos => $composableBuilder(
      column: $table.photos, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get technicianName => $composableBuilder(
      column: $table.technicianName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get technicianSignature => $composableBuilder(
      column: $table.technicianSignature,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientSignature => $composableBuilder(
      column: $table.clientSignature,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientComments => $composableBuilder(
      column: $table.clientComments,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDraft => $composableBuilder(
      column: $table.isDraft, builder: (column) => ColumnFilters(column));
}

class $$CriProjetTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CriProjetTableTable> {
  $$CriProjetTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get interventionDate => $composableBuilder(
      column: $table.interventionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get site => $composableBuilder(
      column: $table.site, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ville => $composableBuilder(
      column: $table.ville, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codePostal => $composableBuilder(
      column: $table.codePostal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pays => $composableBuilder(
      column: $table.pays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientContact => $composableBuilder(
      column: $table.clientContact,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectNumber => $composableBuilder(
      column: $table.projectNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectPhase => $composableBuilder(
      column: $table.projectPhase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get interventionType => $composableBuilder(
      column: $table.interventionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workDescription => $composableBuilder(
      column: $table.workDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get materialsUsed => $composableBuilder(
      column: $table.materialsUsed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get problemsEncountered => $composableBuilder(
      column: $table.problemsEncountered,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solutionsProvided => $composableBuilder(
      column: $table.solutionsProvided,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get softwares => $composableBuilder(
      column: $table.softwares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionsToDo => $composableBuilder(
      column: $table.actionsToDo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextInterventionDate => $composableBuilder(
      column: $table.nextInterventionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectStatus => $composableBuilder(
      column: $table.projectStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photos => $composableBuilder(
      column: $table.photos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get technicianName => $composableBuilder(
      column: $table.technicianName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get technicianSignature => $composableBuilder(
      column: $table.technicianSignature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientSignature => $composableBuilder(
      column: $table.clientSignature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientComments => $composableBuilder(
      column: $table.clientComments,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDraft => $composableBuilder(
      column: $table.isDraft, builder: (column) => ColumnOrderings(column));
}

class $$CriProjetTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CriProjetTableTable> {
  $$CriProjetTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get interventionDate => $composableBuilder(
      column: $table.interventionDate, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => column);

  GeneratedColumn<String> get site =>
      $composableBuilder(column: $table.site, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get ville =>
      $composableBuilder(column: $table.ville, builder: (column) => column);

  GeneratedColumn<String> get codePostal => $composableBuilder(
      column: $table.codePostal, builder: (column) => column);

  GeneratedColumn<String> get pays =>
      $composableBuilder(column: $table.pays, builder: (column) => column);

  GeneratedColumn<String> get clientContact => $composableBuilder(
      column: $table.clientContact, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => column);

  GeneratedColumn<String> get projectNumber => $composableBuilder(
      column: $table.projectNumber, builder: (column) => column);

  GeneratedColumn<String> get projectPhase => $composableBuilder(
      column: $table.projectPhase, builder: (column) => column);

  GeneratedColumn<String> get interventionType => $composableBuilder(
      column: $table.interventionType, builder: (column) => column);

  GeneratedColumn<String> get workDescription => $composableBuilder(
      column: $table.workDescription, builder: (column) => column);

  GeneratedColumn<String> get materialsUsed => $composableBuilder(
      column: $table.materialsUsed, builder: (column) => column);

  GeneratedColumn<String> get problemsEncountered => $composableBuilder(
      column: $table.problemsEncountered, builder: (column) => column);

  GeneratedColumn<String> get solutionsProvided => $composableBuilder(
      column: $table.solutionsProvided, builder: (column) => column);

  GeneratedColumn<String> get softwares =>
      $composableBuilder(column: $table.softwares, builder: (column) => column);

  GeneratedColumn<String> get actionsToDo => $composableBuilder(
      column: $table.actionsToDo, builder: (column) => column);

  GeneratedColumn<DateTime> get nextInterventionDate => $composableBuilder(
      column: $table.nextInterventionDate, builder: (column) => column);

  GeneratedColumn<String> get projectStatus => $composableBuilder(
      column: $table.projectStatus, builder: (column) => column);

  GeneratedColumn<String> get photos =>
      $composableBuilder(column: $table.photos, builder: (column) => column);

  GeneratedColumn<String> get technicianName => $composableBuilder(
      column: $table.technicianName, builder: (column) => column);

  GeneratedColumn<String> get technicianSignature => $composableBuilder(
      column: $table.technicianSignature, builder: (column) => column);

  GeneratedColumn<String> get clientSignature => $composableBuilder(
      column: $table.clientSignature, builder: (column) => column);

  GeneratedColumn<String> get clientComments => $composableBuilder(
      column: $table.clientComments, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<bool> get isDraft =>
      $composableBuilder(column: $table.isDraft, builder: (column) => column);
}

class $$CriProjetTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CriProjetTableTable,
    CriProjet,
    $$CriProjetTableTableFilterComposer,
    $$CriProjetTableTableOrderingComposer,
    $$CriProjetTableTableAnnotationComposer,
    $$CriProjetTableTableCreateCompanionBuilder,
    $$CriProjetTableTableUpdateCompanionBuilder,
    (CriProjet, BaseReferences<_$AppDatabase, $CriProjetTableTable, CriProjet>),
    CriProjet,
    PrefetchHooks Function()> {
  $$CriProjetTableTableTableManager(
      _$AppDatabase db, $CriProjetTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CriProjetTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CriProjetTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CriProjetTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> interventionDate = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String> clientName = const Value.absent(),
            Value<String> site = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> ville = const Value.absent(),
            Value<String?> codePostal = const Value.absent(),
            Value<String?> pays = const Value.absent(),
            Value<String?> clientContact = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String> projectName = const Value.absent(),
            Value<String> projectNumber = const Value.absent(),
            Value<String> projectPhase = const Value.absent(),
            Value<String> interventionType = const Value.absent(),
            Value<String> workDescription = const Value.absent(),
            Value<String?> materialsUsed = const Value.absent(),
            Value<String?> problemsEncountered = const Value.absent(),
            Value<String?> solutionsProvided = const Value.absent(),
            Value<String?> softwares = const Value.absent(),
            Value<String?> actionsToDo = const Value.absent(),
            Value<DateTime?> nextInterventionDate = const Value.absent(),
            Value<String> projectStatus = const Value.absent(),
            Value<String?> photos = const Value.absent(),
            Value<String> technicianName = const Value.absent(),
            Value<String?> technicianSignature = const Value.absent(),
            Value<String?> clientSignature = const Value.absent(),
            Value<String?> clientComments = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<bool> isDraft = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CriProjetTableCompanion(
            id: id,
            interventionDate: interventionDate,
            startTime: startTime,
            endTime: endTime,
            endDate: endDate,
            clientName: clientName,
            site: site,
            address: address,
            ville: ville,
            codePostal: codePostal,
            pays: pays,
            clientContact: clientContact,
            phone: phone,
            email: email,
            projectName: projectName,
            projectNumber: projectNumber,
            projectPhase: projectPhase,
            interventionType: interventionType,
            workDescription: workDescription,
            materialsUsed: materialsUsed,
            problemsEncountered: problemsEncountered,
            solutionsProvided: solutionsProvided,
            softwares: softwares,
            actionsToDo: actionsToDo,
            nextInterventionDate: nextInterventionDate,
            projectStatus: projectStatus,
            photos: photos,
            technicianName: technicianName,
            technicianSignature: technicianSignature,
            clientSignature: clientSignature,
            clientComments: clientComments,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            isDraft: isDraft,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime interventionDate,
            required DateTime startTime,
            required DateTime endTime,
            Value<DateTime?> endDate = const Value.absent(),
            required String clientName,
            required String site,
            Value<String?> address = const Value.absent(),
            Value<String?> ville = const Value.absent(),
            Value<String?> codePostal = const Value.absent(),
            Value<String?> pays = const Value.absent(),
            Value<String?> clientContact = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            required String projectName,
            required String projectNumber,
            required String projectPhase,
            required String interventionType,
            required String workDescription,
            Value<String?> materialsUsed = const Value.absent(),
            Value<String?> problemsEncountered = const Value.absent(),
            Value<String?> solutionsProvided = const Value.absent(),
            Value<String?> softwares = const Value.absent(),
            Value<String?> actionsToDo = const Value.absent(),
            Value<DateTime?> nextInterventionDate = const Value.absent(),
            required String projectStatus,
            Value<String?> photos = const Value.absent(),
            required String technicianName,
            Value<String?> technicianSignature = const Value.absent(),
            Value<String?> clientSignature = const Value.absent(),
            Value<String?> clientComments = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<bool> isDraft = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CriProjetTableCompanion.insert(
            id: id,
            interventionDate: interventionDate,
            startTime: startTime,
            endTime: endTime,
            endDate: endDate,
            clientName: clientName,
            site: site,
            address: address,
            ville: ville,
            codePostal: codePostal,
            pays: pays,
            clientContact: clientContact,
            phone: phone,
            email: email,
            projectName: projectName,
            projectNumber: projectNumber,
            projectPhase: projectPhase,
            interventionType: interventionType,
            workDescription: workDescription,
            materialsUsed: materialsUsed,
            problemsEncountered: problemsEncountered,
            solutionsProvided: solutionsProvided,
            softwares: softwares,
            actionsToDo: actionsToDo,
            nextInterventionDate: nextInterventionDate,
            projectStatus: projectStatus,
            photos: photos,
            technicianName: technicianName,
            technicianSignature: technicianSignature,
            clientSignature: clientSignature,
            clientComments: clientComments,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            isDraft: isDraft,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CriProjetTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CriProjetTableTable,
    CriProjet,
    $$CriProjetTableTableFilterComposer,
    $$CriProjetTableTableOrderingComposer,
    $$CriProjetTableTableAnnotationComposer,
    $$CriProjetTableTableCreateCompanionBuilder,
    $$CriProjetTableTableUpdateCompanionBuilder,
    (CriProjet, BaseReferences<_$AppDatabase, $CriProjetTableTable, CriProjet>),
    CriProjet,
    PrefetchHooks Function()>;
typedef $$ExportedDocumentTableTableCreateCompanionBuilder
    = ExportedDocumentTableCompanion Function({
  Value<int> id,
  Value<String?> criId,
  required String filename,
  required String filePath,
  required String fileType,
  required int fileSize,
  required String exportType,
  Value<String?> metadata,
  required DateTime createdAt,
  Value<DateTime?> sharedAt,
});
typedef $$ExportedDocumentTableTableUpdateCompanionBuilder
    = ExportedDocumentTableCompanion Function({
  Value<int> id,
  Value<String?> criId,
  Value<String> filename,
  Value<String> filePath,
  Value<String> fileType,
  Value<int> fileSize,
  Value<String> exportType,
  Value<String?> metadata,
  Value<DateTime> createdAt,
  Value<DateTime?> sharedAt,
});

class $$ExportedDocumentTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExportedDocumentTableTable> {
  $$ExportedDocumentTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get criId => $composableBuilder(
      column: $table.criId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exportType => $composableBuilder(
      column: $table.exportType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sharedAt => $composableBuilder(
      column: $table.sharedAt, builder: (column) => ColumnFilters(column));
}

class $$ExportedDocumentTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExportedDocumentTableTable> {
  $$ExportedDocumentTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get criId => $composableBuilder(
      column: $table.criId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exportType => $composableBuilder(
      column: $table.exportType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sharedAt => $composableBuilder(
      column: $table.sharedAt, builder: (column) => ColumnOrderings(column));
}

class $$ExportedDocumentTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExportedDocumentTableTable> {
  $$ExportedDocumentTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get criId =>
      $composableBuilder(column: $table.criId, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get exportType => $composableBuilder(
      column: $table.exportType, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get sharedAt =>
      $composableBuilder(column: $table.sharedAt, builder: (column) => column);
}

class $$ExportedDocumentTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExportedDocumentTableTable,
    ExportedDocument,
    $$ExportedDocumentTableTableFilterComposer,
    $$ExportedDocumentTableTableOrderingComposer,
    $$ExportedDocumentTableTableAnnotationComposer,
    $$ExportedDocumentTableTableCreateCompanionBuilder,
    $$ExportedDocumentTableTableUpdateCompanionBuilder,
    (
      ExportedDocument,
      BaseReferences<_$AppDatabase, $ExportedDocumentTableTable,
          ExportedDocument>
    ),
    ExportedDocument,
    PrefetchHooks Function()> {
  $$ExportedDocumentTableTableTableManager(
      _$AppDatabase db, $ExportedDocumentTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExportedDocumentTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ExportedDocumentTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExportedDocumentTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> criId = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String> fileType = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<String> exportType = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> sharedAt = const Value.absent(),
          }) =>
              ExportedDocumentTableCompanion(
            id: id,
            criId: criId,
            filename: filename,
            filePath: filePath,
            fileType: fileType,
            fileSize: fileSize,
            exportType: exportType,
            metadata: metadata,
            createdAt: createdAt,
            sharedAt: sharedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> criId = const Value.absent(),
            required String filename,
            required String filePath,
            required String fileType,
            required int fileSize,
            required String exportType,
            Value<String?> metadata = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> sharedAt = const Value.absent(),
          }) =>
              ExportedDocumentTableCompanion.insert(
            id: id,
            criId: criId,
            filename: filename,
            filePath: filePath,
            fileType: fileType,
            fileSize: fileSize,
            exportType: exportType,
            metadata: metadata,
            createdAt: createdAt,
            sharedAt: sharedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExportedDocumentTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ExportedDocumentTableTable,
        ExportedDocument,
        $$ExportedDocumentTableTableFilterComposer,
        $$ExportedDocumentTableTableOrderingComposer,
        $$ExportedDocumentTableTableAnnotationComposer,
        $$ExportedDocumentTableTableCreateCompanionBuilder,
        $$ExportedDocumentTableTableUpdateCompanionBuilder,
        (
          ExportedDocument,
          BaseReferences<_$AppDatabase, $ExportedDocumentTableTable,
              ExportedDocument>
        ),
        ExportedDocument,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CriServiceTableTableTableManager get criServiceTable =>
      $$CriServiceTableTableTableManager(_db, _db.criServiceTable);
  $$CriProjetTableTableTableManager get criProjetTable =>
      $$CriProjetTableTableTableManager(_db, _db.criProjetTable);
  $$ExportedDocumentTableTableTableManager get exportedDocumentTable =>
      $$ExportedDocumentTableTableTableManager(_db, _db.exportedDocumentTable);
}
