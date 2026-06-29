import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/billing/invoice_model.dart';
import 'package:kynza/core/models/billing/subscription_plan_model.dart';

void main() {
  group('SubscriptionPlanModelX.periodLabel', () {
    test('lifetime plan reads "à vie"', () {
      const plan = SubscriptionPlanModel(
        key: 'free',
        name: 'Gratuit',
        tagline: 'Pour démarrer',
        period: 'lifetime',
      );
      expect(plan.periodLabel, 'à vie');
    });

    test('monthly plan reads "/ mois"', () {
      const plan = SubscriptionPlanModel(
        key: 'pro',
        name: 'Pro',
        tagline: 'Pour grandir',
        period: 'month',
      );
      expect(plan.periodLabel, '/ mois');
    });

    test('yearly plan reads "/ an"', () {
      const plan = SubscriptionPlanModel(
        key: 'premium',
        name: 'Premium',
        tagline: 'Pour les établis',
        period: 'year',
      );
      expect(plan.periodLabel, '/ an');
    });
  });

  group('InvoiceModelX', () {
    test('isPending true and isPaid false for a fresh invoice', () {
      const invoice = InvoiceModel(
        salonId: 's1',
        planKey: 'pro',
        amountBif: 45000,
        reference: 'KYNZA-ABC123',
      );
      expect(invoice.isPending, isTrue);
      expect(invoice.isPaid, isFalse);
    });

    test('isPaid true and isPending false once settled', () {
      const invoice = InvoiceModel(
        salonId: 's1',
        planKey: 'pro',
        amountBif: 45000,
        reference: 'KYNZA-ABC123',
        status: 'paid',
      );
      expect(invoice.isPaid, isTrue);
      expect(invoice.isPending, isFalse);
    });

    test('neither pending nor paid once void', () {
      const invoice = InvoiceModel(
        salonId: 's1',
        planKey: 'pro',
        amountBif: 45000,
        reference: 'KYNZA-ABC123',
        status: 'void',
      );
      expect(invoice.isPending, isFalse);
      expect(invoice.isPaid, isFalse);
    });
  });
}
