import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'owner_journey_model.freezed.dart';
part 'owner_journey_model.g.dart';

@freezed
class OwnerJourneyModel with _$OwnerJourneyModel {
  const factory OwnerJourneyModel({
    String? id,
    required String salonId,
    required String ownerId,
    @Default(false) bool stepSalonInfoDone,
    DateTime? stepSalonInfoDoneAt,
    @Default(false) bool stepFirstServiceDone,
    DateTime? stepFirstServiceDoneAt,
    @Default(false) bool stepTeamDone,
    DateTime? stepTeamDoneAt,
    @Default(false) bool stepHoursDone,
    DateTime? stepHoursDoneAt,
    @Default(false) bool stepFirstBookingDone,
    DateTime? stepFirstBookingDoneAt,
    @Default(0) int completedSteps,
    @Default(0) int completionPct,
    @Default(false) bool isComplete,
    DateTime? completedAt,
  }) = _OwnerJourneyModel;

  factory OwnerJourneyModel.fromSupabase(Map<String, dynamic> json) =>
      OwnerJourneyModel.fromJson(json);

  factory OwnerJourneyModel.fromJson(Map<String, dynamic> json) =>
      _$OwnerJourneyModelFromJson(json);
}

@freezed
class JourneyStep with _$JourneyStep {
  const factory JourneyStep({
    required int index,
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) = _JourneyStep;
}

extension OwnerJourneyModelX on OwnerJourneyModel {
  bool isStepDone(String key) => switch (key) {
    'salon_info' => stepSalonInfoDone,
    'first_service' => stepFirstServiceDone,
    'team' => stepTeamDone,
    'hours' => stepHoursDone,
    'first_booking' => stepFirstBookingDone,
    _ => false,
  };

  static const List<JourneyStep> steps = [
    JourneyStep(
      index: 0,
      key: 'salon_info',
      title: 'Complétez votre salon',
      subtitle: 'Nom, description, photos de profil',
      icon: Icons.store_outlined,
      route: '/owner/salon/edit',
    ),
    JourneyStep(
      index: 1,
      key: 'first_service',
      title: 'Ajoutez votre premier service',
      subtitle: 'Définissez vos prestations et prix en FBu',
      icon: Icons.content_cut_outlined,
      route: '/owner/services',
    ),
    JourneyStep(
      index: 2,
      key: 'team',
      title: 'Configurez votre équipe',
      subtitle: 'Invitez vos collaborateurs ou confirmez le mode Solo',
      icon: Icons.people_outline,
      route: '/owner/staff',
    ),
    JourneyStep(
      index: 3,
      key: 'hours',
      title: 'Définissez vos horaires',
      subtitle: 'Quand êtes-vous ouvert ?',
      icon: Icons.schedule_outlined,
      route: '/owner/availability',
    ),
    JourneyStep(
      index: 4,
      key: 'first_booking',
      title: 'Recevez votre premier RDV',
      subtitle: 'Partagez votre profil avec vos clients',
      icon: Icons.calendar_today_outlined,
      route: '/owner/share',
    ),
  ];
}
