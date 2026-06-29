import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';

class SavedAddressesPage extends ConsumerStatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  ConsumerState<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends ConsumerState<SavedAddressesPage> {
  bool _isLoading = true;
  List<AddressModel> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    try {
      final list = await repo.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDeleteAddress(AddressModel address) async {
    final confirm = await AppDialog.show(
      context,
      title: 'Remove Address?',
      message: 'Are you sure you want to delete this address from LNDRY details?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final repo = ref.read(customerRepositoryProvider);
      try {
        await repo.deleteAddress(address.id);
        _loadAddresses();
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Saved Addresses', style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.go(AppRoutes.profile),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Loading saved addresses...')
            : _addresses.isEmpty
                ? AppEmptyState(
                    icon: AppIcons.locationOutlined,
                    title: 'No Saved Addresses',
                    subtitle: 'Save your flat or office details to order laundry collections instantly.',
                    actionLabel: 'Pin New Address',
                    onAction: () => context.push(AppRoutes.mapAddress),
                  )
                : Column(
                    children: [
                      // List items
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                          itemCount: _addresses.length,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (context, idx) {
                            final addr = _addresses[idx];

                            return AppCard.outlined(
                              padding: EdgeInsets.all(AppSpacing.md.r),
                              child: Row(
                                children: [
                                  Icon(
                                    addr.type == AddressType.home
                                        ? AppIcons.homeOutlined
                                        : AppIcons.store,
                                    color: AppColors.primary,
                                    size: 24.r,
                                  ),
                                  const Gap(16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(addr.type.label, style: AppTypography.labelLarge),
                                            if (addr.isDefault) ...[
                                              const Gap(8),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 6.w,
                                                  vertical: 2.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryContainer,
                                                  borderRadius: BorderRadius.circular(AppRadius.tag.r),
                                                ),
                                                child: Text(
                                                  'DEFAULT',
                                                  style: AppTypography.badge.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const Gap(4),
                                        Text(
                                          '${addr.line1}, ${addr.city}',
                                          style: AppTypography.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(16),
                                  IconButton(
                                    icon: const Icon(AppIcons.delete, color: AppColors.error),
                                    onPressed: () => _onDeleteAddress(addr),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Add address CTA button
                      Padding(
                        padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                        child: AppButton(
                          label: 'Pin New Address',
                          onPressed: () => context.push(AppRoutes.mapAddress),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
