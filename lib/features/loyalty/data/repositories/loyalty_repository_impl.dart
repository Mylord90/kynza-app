import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/loyalty/loyalty_card_model.dart';
import '../../../../core/models/loyalty/loyalty_program_model.dart';
import '../../../../core/models/loyalty/loyalty_qr_token_model.dart';
import '../../../../core/models/loyalty/loyalty_stamp_log_model.dart';
import '../../../../core/services/crash_reporting_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/loyalty_repository.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  static const _programsTable = 'loyalty_programs';
  static const _cardsTable = 'loyalty_cards';
  static const _logsTable = 'loyalty_stamp_logs';
  static const _qrTokensTable = 'loyalty_qr_tokens';

  @override
  Future<LoyaltyProgramModel?> getLoyaltyProgram(String salonId) async {
    final row = await SupabaseService.from(_programsTable)
        .select()
        .eq('salon_id', salonId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return row == null ? null : LoyaltyProgramModel.fromSupabase(row);
  }

  @override
  Future<LoyaltyProgramModel> upsertProgram(LoyaltyProgramModel program) async {
    try {
      final row = await SupabaseService.from(_programsTable)
          .upsert({
            if (program.id != null) 'id': program.id,
            'salon_id': program.salonId,
            'stamps_required': program.stampsRequired,
            'reward_description': program.rewardDescription,
            'reward_value_bif': program.rewardValueBif,
            'is_active': program.isActive,
          }, onConflict: 'salon_id')
          .select()
          .single();
      return LoyaltyProgramModel.fromSupabase(row);
    } catch (_) {
      throw const AppException(
        "Impossible d'enregistrer le programme de fidélité.",
      );
    }
  }

  @override
  Future<LoyaltyCardModel?> getClientCard(
    String salonId,
    String clientId,
  ) async {
    final row = await SupabaseService.from(_cardsTable)
        .select()
        .eq('salon_id', salonId)
        .eq('client_id', clientId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return row == null ? null : LoyaltyCardModel.fromSupabase(row);
  }

  @override
  Future<LoyaltyCardModel> getOrCreateCard(
    String salonId,
    String clientId,
  ) async {
    final existing = await getClientCard(salonId, clientId);
    if (existing != null) return existing;
    try {
      final row = await SupabaseService.from(_cardsTable)
          .upsert({
            'salon_id': salonId,
            'client_id': clientId,
          }, onConflict: 'salon_id,client_id')
          .select()
          .single();
      return LoyaltyCardModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de créer la carte de fidélité.');
    }
  }

  @override
  Future<LoyaltyCardModel> addStamp(String cardId, {String? bookingId}) async {
    late final LoyaltyCardModel card;
    try {
      final row = await SupabaseService.client.rpc(
        'add_loyalty_stamp',
        params: {'p_card_id': cardId, 'p_booking_id': bookingId},
      );
      card = LoyaltyCardModel.fromSupabase(row as Map<String, dynamic>);
    } catch (_) {
      throw const AppException("Impossible d'ajouter le tampon.");
    }

    final program = await getLoyaltyProgram(card.salonId);
    if (program != null && card.stampsCount >= program.stampsRequired) {
      await _notifyRewardAvailable(card, program);
    }
    return card;
  }

  Future<void> _notifyRewardAvailable(
    LoyaltyCardModel card,
    LoyaltyProgramModel program,
  ) async {
    try {
      final salon = await SupabaseService.from(
        'salons',
      ).select('name').eq('id', card.salonId).maybeSingle();
      await SupabaseService.client.functions.invoke(
        'send-notification',
        body: {
          'userId': card.clientId,
          'event': 'loyalty_reward_available',
          'salonId': card.salonId,
          'data': {
            'salon_name': salon?['name'] ?? '',
            'reward': program.rewardDescription,
          },
        },
      );
    } catch (e, st) {
      // Best-effort — a missed push must never block stamp earning.
      CrashReportingService.recordError(e, st);
    }
  }

  @override
  Future<LoyaltyCardModel> redeemReward(String cardId) async {
    try {
      final row = await SupabaseService.client.rpc(
        'redeem_loyalty_reward',
        params: {'p_card_id': cardId},
      );
      return LoyaltyCardModel.fromSupabase(row as Map<String, dynamic>);
    } catch (_) {
      throw const AppException('Impossible de valider la récompense.');
    }
  }

  @override
  Stream<List<LoyaltyCardModel>> getClientCards(String clientId) {
    return SupabaseService.client
        .from(_cardsTable)
        .stream(primaryKey: ['id'])
        .eq('client_id', clientId)
        .map(
          (rows) => rows
              .where((r) => r['deleted_at'] == null)
              .map(LoyaltyCardModel.fromSupabase)
              .toList(),
        );
  }

  @override
  Future<List<LoyaltyCardModel>> getSalonCards(String salonId) async {
    final rows = await SupabaseService.from(_cardsTable)
        .select()
        .eq('salon_id', salonId)
        .isFilter('deleted_at', null)
        .order('stamps_count', ascending: false);
    return rows.map(LoyaltyCardModel.fromSupabase).toList();
  }

  @override
  Future<List<LoyaltyStampLogModel>> getStampLogs(String cardId) async {
    final rows = await SupabaseService.from(
      _logsTable,
    ).select().eq('card_id', cardId).order('created_at', ascending: false);
    return rows.map(LoyaltyStampLogModel.fromSupabase).toList();
  }

  @override
  Future<LoyaltyQrTokenModel> createQrToken(LoyaltyCardModel card) async {
    try {
      final row = await SupabaseService.from(_qrTokensTable)
          .insert({
            'card_id': card.id,
            'salon_id': card.salonId,
            'client_id': card.clientId,
          })
          .select()
          .single();
      return LoyaltyQrTokenModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de générer le QR code.');
    }
  }
}
