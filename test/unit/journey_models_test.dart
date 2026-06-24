import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/journey/owner_journey_model.dart';

void main() {
  group('OwnerJourneyModelX.steps', () {
    test('lists exactly the 5 onboarding steps in order', () {
      const steps = OwnerJourneyModelX.steps;
      expect(steps.length, 5);
      expect(steps.map((s) => s.key).toList(), [
        'salon_info',
        'first_service',
        'team',
        'hours',
        'first_booking',
      ]);
    });

    test('every step has a unique key', () {
      const steps = OwnerJourneyModelX.steps;
      expect(steps.map((s) => s.key).toSet().length, steps.length);
    });

    test('every step index matches its position in the list', () {
      const steps = OwnerJourneyModelX.steps;
      for (var i = 0; i < steps.length; i++) {
        expect(steps[i].index, i);
      }
    });
  });

  group('OwnerJourneyModelX.isStepDone', () {
    test('reflects each boolean flag for its matching key', () {
      const journey = OwnerJourneyModel(
        salonId: 's1',
        ownerId: 'o1',
        stepSalonInfoDone: true,
        stepFirstServiceDone: true,
        stepTeamDone: false,
        stepHoursDone: true,
        stepFirstBookingDone: false,
      );
      expect(journey.isStepDone('salon_info'), isTrue);
      expect(journey.isStepDone('first_service'), isTrue);
      expect(journey.isStepDone('team'), isFalse);
      expect(journey.isStepDone('hours'), isTrue);
      expect(journey.isStepDone('first_booking'), isFalse);
    });

    test('returns false for a key that does not exist', () {
      const journey = OwnerJourneyModel(salonId: 's1', ownerId: 'o1');
      expect(journey.isStepDone('not_a_real_step'), isFalse);
    });

    test('all steps report done once every flag is true', () {
      const journey = OwnerJourneyModel(
        salonId: 's1',
        ownerId: 'o1',
        stepSalonInfoDone: true,
        stepFirstServiceDone: true,
        stepTeamDone: true,
        stepHoursDone: true,
        stepFirstBookingDone: true,
      );
      for (final step in OwnerJourneyModelX.steps) {
        expect(journey.isStepDone(step.key), isTrue);
      }
    });
  });
}
