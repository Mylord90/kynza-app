import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/services/share_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../reviews/presentation/widgets/salon_reviews_tab.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../services/application/providers/service_providers.dart';
import '../../application/providers/booking_flow_provider.dart';
import '../widgets/service_booking_card.dart';
import 'practitioner_selection_screen.dart';
import 'service_selection_screen.dart';

class SalonDetailScreen extends ConsumerStatefulWidget {
  const SalonDetailScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends ConsumerState<SalonDetailScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final salonAsync = ref.watch(salonByIdProvider(widget.salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: salonAsync.when(
        loading: () => const KynzaLoaderInline(size: KynzaLoaderSize.large),
        error: (_, __) => KynzaErrorState(
          message: l10n.bookingSalonDetailLoadError,
          onRetry: () => ref.invalidate(salonByIdProvider(widget.salonId)),
        ),
        data: (salon) {
          if (salon == null) {
            return KynzaErrorState(
              message: l10n.bookingSalonNotFound,
              onRetry: () => Navigator.of(context).pop(),
            );
          }
          return Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        tooltip: context.l10n.commonShare,
                        onPressed: () => ShareService.shareSalon(salon),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Hero(
                        tag: 'salon-cover-${salon.id}',
                        child: salon.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: salon.coverUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(color: AppColors.surfaceVariant),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          KynzaAvatar(
                            fullName: salon.name,
                            avatarUrl: salon.logoUrl,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(salon.name, style: AppTypography.h1),
                                if (salon.slogan != null) Text(salon.slogan!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      indicatorColor: AppColors.primary,
                      tabs: [
                        Tab(text: l10n.bookingSalonDetailServicesTab),
                        Tab(text: l10n.bookingSalonDetailInfoTab),
                        Tab(text: l10n.bookingSalonDetailReviewsTab),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _ServicesTab(salon: salon),
                    _InfoTab(salon: salon),
                    SalonReviewsTab(salonId: salon.id),
                  ],
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: KynzaButton(
                  label: l10n.bookingSalonDetailReserveButton,
                  onPressed: () {
                    ref.read(bookingFlowProvider.notifier).selectSalon(salon);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServiceSelectionScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _noop() {}

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab({required this.salon});

  final dynamic salon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final servicesAsync = ref.watch(salonServicesProvider(salon.id as String));

    return servicesAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          88,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaSkeleton(height: 72),
        ),
      ),
      error: (_, __) => KynzaErrorState(
        message: l10n.bookingSalonDetailServicesLoadError,
        onRetry: () =>
            ref.invalidate(salonServicesProvider(salon.id as String)),
      ),
      data: (services) {
        final active = services.where((s) => s.isActive).toList();
        if (active.isEmpty) {
          return KynzaEmptyState(
            icon: Icons.content_cut,
            title: l10n.bookingSelectServiceEmptyTitle,
            subtitle: l10n.bookingSalonDetailServicesEmptySubtitle,
            ctaLabel: l10n.commonBack,
            onCta: _noop,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            88,
          ),
          itemCount: active.length,
          itemBuilder: (context, index) {
            final service = active[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ServiceBookingCard(
                service: service,
                onTap: () {
                  ref.read(bookingFlowProvider.notifier).selectSalon(salon);
                  ref.read(bookingFlowProvider.notifier).selectService(service);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PractitionerSelectionScreen(),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.salon});

  final dynamic salon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (salon.description != null) Text(salon.description as String),
        const SizedBox(height: AppSpacing.lg),
        if (salon.address != null)
          _InfoRow(
            icon: Icons.location_on_outlined,
            text: salon.address as String,
          ),
        if (salon.phone != null)
          _InfoRow(icon: Icons.phone_outlined, text: salon.phone as String),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
