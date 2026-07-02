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

  Future<void> _loadAddresses() async {
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

  Future<void> _onSetDefault(AddressModel address) async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    try {
      await repo.setDefaultAddress(address.id);
      await _loadAddresses();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDeleteAddress(AddressModel address) async {
    final confirm = await AppDialog.show(
      context,
      title: 'Remove Address?',
      message:
          'Are you sure you want to delete this address from LNDRY details?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final repo = ref.read(customerRepositoryProvider);
      try {
        await repo.deleteAddress(address.id);
        await _loadAddresses();
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onEditAddress(AddressModel address) async {
    final line1Controller = TextEditingController(text: address.line1);
    final cityController = TextEditingController(text: address.city);

    await AppBottomSheet.show(
      context: context,
      title: 'Edit Address',
      isScrollControlled: true,
      primaryActionLabel: 'Save',
      onPrimaryAction: () async {
        final newLine1 = line1Controller.text.trim();
        final newCity = cityController.text.trim();

        if (newLine1.isEmpty || newCity.isEmpty) return;

        Navigator.of(context).pop();

        setState(() => _isLoading = true);
        final repo = ref.read(customerRepositoryProvider);
        try {
          await repo.updateAddress(
            address.copyWith(line1: newLine1, city: newCity),
          );
          await _loadAddresses();
        } catch (_) {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Address Line 1',
            hint: 'Flat / building / street',
            controller: line1Controller,
            textCapitalization: TextCapitalization.words,
          ),
          Gap(16.h),
          AppTextField(
            label: 'City',
            hint: 'City',
            controller: cityController,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );

    line1Controller.dispose();
    cityController.dispose();
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
        // FIX 1: use pop() — this page is pushed onto the stack.
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
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
                    subtitle:
                        'Save your flat or office details to order laundry'
                        ' collections instantly.',
                    actionLabel: 'Pin New Address',
                    // FIX 2: correct — push mapAddress for authenticated user.
                    onAction: () => context.push(AppRoutes.mapAddress),
                  )
                : Column(
                    children: [
                      // ── Address list ─────────────────────────────────────
                      Expanded(
                        child: ListView.separated(
                          padding:
                              EdgeInsets.all(AppSpacing.pagePaddingH.w),
                          itemCount: _addresses.length,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (context, idx) {
                            final addr = _addresses[idx];

                            return AppCard.outlined(
                              padding: EdgeInsets.all(AppSpacing.md.r),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Address type icon
                                  Icon(
                                    addr.type == AddressType.home
                                        ? AppIcons.homeOutlined
                                        : AppIcons.store,
                                    color: AppColors.primary,
                                    size: 24.r,
                                  ),
                                  const Gap(16),

                                  // FIX 5: tappable title/detail area → edit sheet
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _onEditAddress(addr),
                                      behavior: HitTestBehavior.opaque,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                addr.type.label,
                                                style:
                                                    AppTypography.labelLarge,
                                              ),
                                              if (addr.isDefault) ...[
                                                const Gap(8),
                                                Container(
                                                  padding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 6.w,
                                                    vertical: 2.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .primaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      AppRadius.tag.r,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'DEFAULT',
                                                    style: AppTypography.badge
                                                        .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                  ),

                                  // FIX 3: Set-as-default button (only when not default)
                                  if (!addr.isDefault)
                                    IconButton(
                                      icon: Icon(
                                        Icons.star_outline_rounded,
                                        color: AppColors.primary,
                                        size: 22.r,
                                      ),
                                      tooltip: 'Set as default',
                                      onPressed: () => _onSetDefault(addr),
                                    ),

                                  // FIX 3 & 4: Delete button
                                  IconButton(
                                    icon: Icon(
                                      AppIcons.delete,
                                      color: AppColors.error,
                                      size: 22.r,
                                    ),
                                    tooltip: 'Delete address',
                                    onPressed: () =>
                                        _onDeleteAddress(addr),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Add address CTA ──────────────────────────────────
                      Padding(
                        padding:
                            EdgeInsets.all(AppSpacing.pagePaddingH.w),
                        child: AppButton(
                          label: 'Pin New Address',
                          // FIX 2: correct — push for authenticated add.
                          onPressed: () =>
                              context.push(AppRoutes.mapAddress),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
