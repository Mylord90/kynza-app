import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/marketing/promotion_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../services/application/providers/service_providers.dart';
import '../../application/providers/marketing_providers.dart';

class PromotionCenterScreen extends ConsumerStatefulWidget {
  const PromotionCenterScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<PromotionCenterScreen> createState() =>
      _PromotionCenterScreenState();
}

class _PromotionCenterScreenState extends ConsumerState<PromotionCenterScreen> {
  bool _showExpired = false;

  void _openForm({PromotionModel? initial}) {
    showKynzaBottomSheet(
      context,
      builder: (_) =>
          _PromotionFormSheet(salonId: widget.salonId, initial: initial),
    );
  }

  Future<void> _deactivate(PromotionModel promo) async {
    final confirmed = await showKynzaConfirmDialog(
      context,
      title: 'Désactiver cette promotion ?',
      message: '${promo.title} ne sera plus visible des clients.',
      confirmLabel: 'Désactiver',
    );
    if (!confirmed) return;
    await ref
        .read(marketingNotifierProvider.notifier)
        .deactivatePromotion(promo.id!);
  }

  Future<void> _share(PromotionModel promo) async {
    final salon = await ref.read(salonByIdProvider(widget.salonId).future);
    if (salon == null) return;
    await ShareService.sharePromotion(salon, promo);
  }

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(promotionsProvider(widget.salonId));
    final servicesAsync = ref.watch(salonServicesProvider(widget.salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Promotions'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openForm()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Actives')),
                ButtonSegment(value: true, label: Text('Expirées')),
              ],
              selected: {_showExpired},
              onSelectionChanged: (s) => setState(() => _showExpired = s.first),
            ),
          ),
          Expanded(
            child: promotionsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 3,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: KynzaSkeleton(height: 120),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: 'Impossible de charger vos promotions.',
                onRetry: () =>
                    ref.invalidate(promotionsProvider(widget.salonId)),
              ),
              data: (promos) {
                final filtered = promos
                    .where((p) => _showExpired ? !p.isLive : p.isLive)
                    .toList();
                if (filtered.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.local_offer_outlined,
                    title: _showExpired
                        ? 'Aucune promotion expirée'
                        : 'Aucune promotion active',
                    subtitle: _showExpired
                        ? ''
                        : 'Créez votre première offre pour attirer vos clients.',
                    ctaLabel: 'Créer ma première promotion',
                    onCta: () => _openForm(),
                  );
                }
                final services = servicesAsync.valueOrNull ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final promo = filtered[index];
                    final service = services
                        .where((s) => s.id == promo.serviceId)
                        .firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _PromotionCard(
                        promo: promo,
                        serviceName: service?.name,
                        onShare: () => _share(promo),
                        onDeactivate: promo.isLive
                            ? () => _deactivate(promo)
                            : null,
                        onEdit: () => _openForm(initial: promo),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promo,
    required this.serviceName,
    required this.onShare,
    required this.onDeactivate,
    required this.onEdit,
  });

  final PromotionModel promo;
  final String? serviceName;
  final VoidCallback onShare;
  final VoidCallback? onDeactivate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(promo.title, style: AppTypography.h3)),
              KynzaBadge(
                label: promo.formattedDiscount,
                variant: KynzaBadgeVariant.gold,
              ),
            ],
          ),
          if (promo.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(promo.description!, style: AppTypography.bodySmall),
          ],
          if (serviceName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Service : $serviceName', style: AppTypography.bodySmall),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${promo.currentUses}${promo.maxUses != null ? ' / ${promo.maxUses}' : ''} utilisation(s)'
            " · jusqu'au ${DateFormat('dd/MM/yyyy').format(promo.endsAt)}",
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: KynzaButton(
                  label: 'Partager',
                  height: 40,
                  variant: KynzaButtonVariant.secondary,
                  onPressed: onShare,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: KynzaButton(
                  label: 'Modifier',
                  height: 40,
                  variant: KynzaButtonVariant.ghost,
                  onPressed: onEdit,
                ),
              ),
              if (onDeactivate != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: KynzaButton(
                    label: 'Désactiver',
                    height: 40,
                    variant: KynzaButtonVariant.destructive,
                    onPressed: onDeactivate,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionFormSheet extends ConsumerStatefulWidget {
  const _PromotionFormSheet({required this.salonId, this.initial});

  final String salonId;
  final PromotionModel? initial;

  @override
  ConsumerState<_PromotionFormSheet> createState() =>
      _PromotionFormSheetState();
}

class _PromotionFormSheetState extends ConsumerState<_PromotionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _titleCtrl = TextEditingController(text: widget.initial?.title);
  late final _descCtrl = TextEditingController(
    text: widget.initial?.description,
  );
  late final _valueCtrl = TextEditingController(
    text: widget.initial?.discountValue.toString(),
  );
  late final _maxUsesCtrl = TextEditingController(
    text: widget.initial?.maxUses?.toString(),
  );
  late String _promoCode = widget.initial?.promoCode ?? '';
  late DiscountType _discountType =
      widget.initial?.discountType ?? DiscountType.percent;
  ServiceModel? _selectedService;
  late DateTime _startsAt = widget.initial?.startsAt ?? DateTime.now();
  late DateTime _endsAt =
      widget.initial?.endsAt ?? DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  void _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    final code = List.generate(
      4,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    setState(() => _promoCode = 'KYNZA-$code');
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startsAt : _endsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => isStart ? _startsAt = picked : _endsAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endsAt.isBefore(_startsAt)) {
      showKynzaToast(
        context,
        message: 'La date de fin doit être après la date de début.',
        level: ToastLevel.warning,
      );
      return;
    }
    setState(() => _saving = true);
    final promo = PromotionModel(
      id: widget.initial?.id,
      salonId: widget.salonId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      discountType: _discountType,
      discountValue: int.tryParse(_valueCtrl.text.trim()) ?? 0,
      serviceId: _selectedService?.id,
      maxUses: int.tryParse(_maxUsesCtrl.text.trim()),
      promoCode: _promoCode.isEmpty ? null : _promoCode,
      startsAt: _startsAt,
      endsAt: _endsAt,
      isActive: widget.initial?.isActive ?? true,
    );
    try {
      final notifier = ref.read(marketingNotifierProvider.notifier);
      if (widget.initial == null) {
        await notifier.createPromotion(promo);
      } else {
        await notifier.updatePromotion(promo);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException
              ? e.message
              : 'Échec de l\'enregistrement.',
          level: ToastLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(salonServicesProvider(widget.salonId));
    final value = int.tryParse(_valueCtrl.text.trim()) ?? 0;
    final previewDiscount = _discountType == DiscountType.percent
        ? '-$value%'
        : '-${CurrencyFormatter.formatBif(value)}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.initial == null
                  ? 'Créer une promotion'
                  : 'Modifier la promotion',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _titleCtrl.text.isEmpty
                          ? 'Titre de la promotion'
                          : _titleCtrl.text,
                      style: AppTypography.h3,
                    ),
                  ),
                  KynzaBadge(
                    label: previewDiscount,
                    variant: KynzaBadgeVariant.gold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Titre *',
              controller: _titleCtrl,
              maxLength: 100,
              validator: (v) => Validators.required(v, 'Titre'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Description',
              controller: _descCtrl,
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<DiscountType>(
              segments: const [
                ButtonSegment(
                  value: DiscountType.percent,
                  label: Text('Pourcentage %'),
                ),
                ButtonSegment(
                  value: DiscountType.fixedBif,
                  label: Text('Montant fixe FBu'),
                ),
              ],
              selected: {_discountType},
              onSelectionChanged: (s) =>
                  setState(() => _discountType = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: _discountType == DiscountType.percent
                  ? 'Valeur (%) *'
                  : 'Valeur (FBu) *',
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              validator: (v) => Validators.required(v, 'Valeur'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            servicesAsync.maybeWhen(
              data: (services) => KynzaDropdown<ServiceModel?>(
                label: 'Service ciblé (optionnel)',
                value: _selectedService,
                items: [null, ...services],
                itemLabel: (s) => s?.name ?? 'Tous les services',
                onChanged: (s) => setState(() => _selectedService = s),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(
                      'Début : ${DateFormat('dd/MM/yyyy').format(_startsAt)}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(
                      'Fin : ${DateFormat('dd/MM/yyyy').format(_endsAt)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: "Nombre d'utilisations max (optionnel)",
              controller: _maxUsesCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _promoCode.isEmpty ? 'Aucun code promo' : _promoCode,
                    style: AppTypography.mono,
                  ),
                ),
                TextButton(
                  onPressed: _generateCode,
                  child: const Text('Générer un code'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: widget.initial == null
                  ? 'Créer la promotion'
                  : 'Enregistrer',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
