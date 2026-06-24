import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/availability_exception_model.dart';
import 'package:kynza/core/models/staff_break_model.dart';
import 'package:kynza/core/models/staff_working_hour_model.dart';

void main() {
  group('AvailabilityExceptionModelX', () {
    test('isMultiDay is false for a single-day exception', () {
      final exception = AvailabilityExceptionModel(
        salonId: 's1',
        exceptionType: 'special_closure',
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 8, 15),
        label: 'Assomption',
      );
      expect(exception.isMultiDay, isFalse);
    });

    test('isMultiDay is true when start and end dates differ', () {
      final exception = AvailabilityExceptionModel(
        salonId: 's1',
        exceptionType: 'vacation',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 10),
        label: 'Vacances annuelles',
      );
      expect(exception.isMultiDay, isTrue);
    });

    test('isPublicHoliday is true only for the public_holiday type', () {
      final holiday = AvailabilityExceptionModel(
        salonId: 's1',
        exceptionType: 'public_holiday',
        startDate: DateTime(2026, 12, 25),
        endDate: DateTime(2026, 12, 25),
        label: 'Noël',
      );
      final vacation = holiday.copyWith(exceptionType: 'vacation');
      expect(holiday.isPublicHoliday, isTrue);
      expect(vacation.isPublicHoliday, isFalse);
    });

    test('typeLabel maps every known exception_type to a French label', () {
      const expected = {
        'holiday': 'Congé',
        'vacation': 'Vacances',
        'special_closure': 'Fermeture spéciale',
        'special_opening': 'Ouverture spéciale',
        'public_holiday': 'Jour férié',
      };
      for (final entry in expected.entries) {
        final model = AvailabilityExceptionModel(
          salonId: 's1',
          exceptionType: entry.key,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 1),
          label: 'x',
        );
        expect(model.typeLabel, entry.value);
      }
    });
  });

  group('StaffWorkingHourModelX', () {
    test('formattedRange shows "Fermé" when isClosed', () {
      const hour = StaffWorkingHourModel(
        staffId: 'st1',
        salonId: 's1',
        dayOfWeek: 6,
        isClosed: true,
      );
      expect(hour.formattedRange, 'Fermé');
    });

    test('formattedRange shows the HH:MM range when open', () {
      const hour = StaffWorkingHourModel(
        staffId: 'st1',
        salonId: 's1',
        dayOfWeek: 0,
        opensAt: '08:00:00',
        closesAt: '18:00:00',
      );
      expect(hour.formattedRange, '08:00 – 18:00');
    });

    test('dayLabel indexes Monday..Sunday from dayOfWeek 0..6', () {
      const monday = StaffWorkingHourModel(
        staffId: 'st1',
        salonId: 's1',
        dayOfWeek: 0,
      );
      const sunday = StaffWorkingHourModel(
        staffId: 'st1',
        salonId: 's1',
        dayOfWeek: 6,
      );
      expect(monday.dayLabel, 'Lundi');
      expect(sunday.dayLabel, 'Dimanche');
    });
  });

  group('StaffBreakModelX', () {
    test('formattedRange shows the HH:MM range', () {
      const lunchBreak = StaffBreakModel(
        staffId: 'st1',
        salonId: 's1',
        dayOfWeek: 0,
        startTime: '12:00:00',
        endTime: '13:00:00',
      );
      expect(lunchBreak.formattedRange, '12:00 – 13:00');
    });
  });
}
