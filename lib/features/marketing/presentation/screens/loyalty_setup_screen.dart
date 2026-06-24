import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/loyalty/loyalty_program_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../loyalty/application/providers/loyalty_providers.dart';

final _loyaltyStatsProvider = FutureProvider.autoDispose
    .family<_LoyaltyStats, String>((ref, salonId) async {
      final cards = await ref
          .read(loyaltyRepositoryProvider)
          .getSalonCards(salonId);
      final totalStamps = cards.fold<int>(
        0,
        (sum, c) => sum + c.totalStampsEarned,
      );
      final totalRedeemed = cards.fold<int>(
        0,
        (sum, c) => sum + c.totalRedeemed,
      );
      final topIds = cards.take(5).map((c) => c.clientId).toList();
      var topClients = <Map<String, dynamic>>[];
      if (topIds.isNotEmpty) {
        final rows = await SupabaseService.from(
          'users',
        ).select('id, full_name, avatar_url').inFilter('id', topIds);
        final byId = {for (final r in rows) r['id'] as String: r};
        topClients = [
          for (final card in cards.take(5))
            {
              'cardId': card.id,
              'fullName': byId[card.clientId]?['full_name'] ?? 'Client',
              'avatarUrl': byId[card.clientId]?['avatar_url'],
              'stamps': card.stampsCount,
            },
        ];
      }
      return _LoyaltyStats(
        totalCards: cards.length,
        totalStampsGiven: totalStamps,
        totalRedeemed: totalRedeemed,
        topClients: topClients,
      );
    });

class _LoyaltyStats {
  const _LoyaltyStats({
    required this.totalCards,
    required this.totalStampsGiven,
    required this.totalRedeemed,
    required this.topClients,
  });

  final int totalCards;
  final int totalStampsGiven;
  final int totalRedeemed;
  final List<Map<String, dynamic>> topClients;
}

class LoyaltySetupScreen extends ConsumerWidget {
  const LoyaltySetupScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(loyaltyProgramProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Programme Fidélité')),
      body: programAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 400),
        ),
        error: (_, __) => KynzaErrorState(
          message: 'Impossible de charger le programme.',
          onRetry: () => ref.invalidate(loyaltyProgramProvider(salonId)),
        ),
        data: (program) => _LoyaltyForm(salonId: salonId, program: program),
      ),
    );
  }
}

class _LoyaltyForm extends ConsumerStatefulWidget {
  const _LoyaltyForm({required this.salonId, required this.program});

  final String salonId;
  final LoyaltyProgramModel? program;

  @override
  ConsumerState<_LoyaltyForm> createState() => _LoyaltyFormState();
}

class _LoyaltyFormState extends ConsumerState<_LoyaltyForm> {
  late int _stampsRequired = widget.program?.stampsRequired ?? 10;
  late final _rewardCtrl = TextEditingController(
    text: widget.program?.rewardDescription,
  );
  late final _valueCtrl = TextEditingController(
    text:
        widget.program?.rewardValueBif == null ||
            widget.program!.rewardValueBif == 0
        ? ''
        : widget.program!.rewardValueBif.toString(),
  );
  late bool _isActive = widget.program?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _rewardCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rewardCtrl.text.trim().isEmpty) {
      showKynzaToast(
        context,
        message: 'Décrivez la récompense offerte.',
        level: ToastLevel.warning,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(loyaltyNotifierProvider.notifier)
          .setupProgram(
            LoyaltyProgramModel(
              id: widget.program?.id,
              salonId: widget.salonId,
              stampsRequired: _stampsRequired,
              rewardDescription: _rewardCtrl.text.trim(),
              rewardValueBif: int.tryParse(_valueCtrl.text.trim()) ?? 0,
              isActive: _isActive,
            ),
          );
      if (mounted) {
        showKynzaToast(
          context,
          message: 'Programme enregistré !',
          level: ToastLevel.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : "Échec de l'enregistrement.",
          level: ToastLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(_loyaltyStatsProvider(widget.salonId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (widget.program == null) ...[
          const KynzaEmptyState(
            icon: Icons.star_outline,
            title: 'Fidélisez vos clients',
            subtitle:
                "Offrez des tampons à chaque visite. À la X ème visite, "
                'offrez une récompense.',
            ctaLabel: 'Configurer mon programme',
            onCta: _noop,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        const Text('Tampons requis', style: AppTypography.h3),
        Slider(
          value: _stampsRequired.toDouble(),
          min: 1,
          max: 20,
          divisions: 19,
          activeColor: AppColors.primary,
          label: '$_stampsRequired',
          onChanged: (v) => setState(() => _stampsRequired = v.round()),
        ),
        Text(
          'Après $_stampsRequired visites, votre client reçoit une récompense.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        KynzaTextField(
          label: 'Description de la récompense *',
          hint: 'ex: 1 coupe offerte',
          controller: _rewardCtrl,
        ),
        const SizedBox(height: AppSpacing.lg),
        KynzaTextField(
          label: 'Valeur en FBu (optionnel)',
          controller: _valueCtrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        if ((int.tryParse(_valueCtrl.text.trim()) ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              CurrencyFormatter.formatBif(
                int.tryParse(_valueCtrl.text.trim()) ?? 0,
              ),
              style: AppTypography.amountSm,
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Programme actif', style: AppTypography.h3),
          value: _isActive,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => setState(() => _isActive = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        KynzaButton(label: 'Enregistrer', isLoading: _saving, onPressed: _save),
        const SizedBox(height: AppSpacing.xxl),
        const Text('Aperçu carte client', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        _CardPreview(stampsRequired: _stampsRequired),
        if (widget.program != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          const Text('Statistiques', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          statsAsync.when(
            loading: () => const KynzaSkeleton(height: 120),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _StatsSection(
              salonId: widget.salonId,
              stampsRequired: _stampsRequired,
              stats: stats,
            ),
          ),
        ],
      ],
    );
  }
}

void _noop() {}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.stampsRequired});

  final int stampsRequired;

  @override
  Widget build(BuildContext context) {
    const filled = 3;
    final shown = filled.clamp(0, stampsRequired);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$stampsRequired tampons requis',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < stampsRequired; i++)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < shown ? AppColors.primary : null,
                    border: i < shown
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.star,
                    size: 14,
                    color: i < shown ? AppColors.background : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Plus que ${stampsRequired - shown} visites pour la récompense !',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection({
    required this.salonId,
    required this.stampsRequired,
    required this.stats,
  });

  final String salonId;
  final int stampsRequired;
  final _LoyaltyStats stats;

  Future<void> _redeem(
    BuildContext context,
    WidgetRef ref,
    String cardId,
    String clientName,
  ) async {
    final confirmed = await showKynzaConfirmDialog(
      context,
      title: 'Valider la récompense ?',
      message:
          '$clientName a atteint $stampsRequired tampons. Ses tampons '
          'seront remis à zéro.',
      confirmLabel: 'Valider',
      isDestructive: false,
    );
    if (!confirmed) return;
    try {
      await ref
          .read(loyaltyNotifierProvider.notifier)
          .redeemReward(salonId, cardId);
      ref.invalidate(_loyaltyStatsProvider(salonId));
      if (context.mounted) {
        showKynzaToast(
          context,
          message: 'Récompense validée pour $clientName !',
          level: ToastLevel.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : 'Échec de la validation.',
          level: ToastLevel.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(label: 'Cartes', value: '${stats.totalCards}'),
            ),
            Expanded(
              child: _StatTile(
                label: 'Tampons donnés',
                value: '${stats.totalStampsGiven}',
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Récompenses',
                value: '${stats.totalRedeemed}',
              ),
            ),
          ],
        ),
        if (stats.topClients.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const Text('Clients les plus fidèles', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          for (final client in stats.topClients)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: KynzaCard(
                child: Row(
                  children: [
                    KynzaAvatar(
                      fullName: client['fullName'] as String,
                      avatarUrl: client['avatarUrl'] as String?,
                      size: AvatarSize.sm,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        client['fullName'] as String,
                        style: AppTypography.h3,
                      ),
                    ),
                    Text(
                      '${client['stamps']} tampons',
                      style: AppTypography.bodySmall,
                    ),
                    if ((client['stamps'] as int) >= stampsRequired &&
                        client['cardId'] != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      KynzaButton(
                        label: 'Valider',
                        height: 32,
                        width: 90,
                        onPressed: () => _redeem(
                          context,
                          ref,
                          client['cardId'] as String,
                          client['fullName'] as String,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.amountMd),
        Text(
          label,
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
