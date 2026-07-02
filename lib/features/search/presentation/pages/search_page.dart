import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/repositories/base_repository.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  String _activeFilter =
      'nearest'; // nearest, top_rated, available, express, price
  bool _isLoading = false;
  List<VendorModel> _vendors = [];

  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    try {
      final repo = ref.read(customerRepositoryProvider);
      final cats = await repo.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  void _loadVendors() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    final response = await repo.getVendors(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      params: const PaginationParams(pageSize: 20),
    );

    var list = response.items;

    // Apply filters
    if (_activeFilter == 'top_rated') {
      list.sort(
          (a, b) => (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0));
    } else if (_activeFilter == 'available') {
      list = list.where((v) => v.isOpen).toList();
    } else if (_activeFilter == 'express') {
      list = list.where((v) => (v.estimatedTurnaroundHours) <= 24).toList();
    } else if (_activeFilter == 'price') {
      list = list.where((v) => v.minOrderAmount <= 100).toList();
    }

    if (mounted) {
      setState(() {
        _vendors = list;
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _activeFilter = filter;
    });
    _loadVendors();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Text(
                    'Filter Partners By',
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.textBlack),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.navigation_rounded),
                  title: const Text('Nearest'),
                  onTap: () {
                    _onFilterChanged('nearest');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.star),
                  title: const Text('Top Rated'),
                  onTap: () {
                    _onFilterChanged('top_rated');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.circle, color: AppColors.secondary),
                  title: const Text('Available Today'),
                  onTap: () {
                    _onFilterChanged('available');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text('Express'),
                  onTap: () {
                    _onFilterChanged('express');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.tag),
                  title: const Text('Under ₹100/kg'),
                  onTap: () {
                    _onFilterChanged('price');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Custom Pixel-Perfect Top Header ──────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular back button
                      GestureDetector(
                        onTap: () {
                          final navShell = StatefulNavigationShell.of(context);
                          navShell.goBranch(0); // Sibling home tab
                        },
                        child: Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.outline.withOpacity(0.5)),
                            boxShadow: AppElevation.low,
                          ),
                          child: Icon(
                            AppIcons.back,
                            color: AppColors.textBlack,
                            size: 16.r,
                          ),
                        ),
                      ),
                      // Title & Subtitle details
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Explore services',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack,
                                fontSize: 17.sp,
                              ),
                            ),
                            const Gap(2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      context.push(AppRoutes.mapAddress),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Select address',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      Icon(
                                        AppIcons.chevronDown,
                                        size: 14.r,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Circular map button
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.vendorListing),
                        child: Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.outline.withOpacity(0.5)),
                            boxShadow: AppElevation.low,
                          ),
                          child: Icon(
                            AppIcons.map,
                            color: AppColors.textBlack,
                            size: 18.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),

                  // ── 2. Search Box with Integrated Mic & Adjacent Filter ─────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full.r),
                            border: Border.all(
                                color: AppColors.outline.withOpacity(0.5)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => _loadVendors(),
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textBlack),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 12.h),
                              hintText: 'Search laundry, service or vendor',
                              hintStyle: AppTypography.inputHint.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.textMuted,
                              ),
                              prefixIcon: Icon(AppIcons.search,
                                  color: AppColors.textSecondary, size: 20.r),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.mic,
                                    color: AppColors.primary, size: 20.r),
                                onPressed: () {
                                  AppSnackBar.showInfo(
                                      context, 'Voice search triggered.');
                                },
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(context),
                        child: Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.filter,
                            color: AppColors.primary,
                            size: 22.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),

                  Text(
                    'Choose a service',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const Gap(16),

                  // ── 3. Category Grid (loaded from backend) ────────────────────
                  if (_categories.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 2.1,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];

                        return GestureDetector(
                          onTap: () => context.go('/category/${cat.id}'),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                  AppRadius.compactCard.r),
                              boxShadow: AppElevation.low,
                              border: Border.all(
                                  color: AppColors.outline.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                // Graphic
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Container(
                                    width: 44.r,
                                    height: 44.r,
                                    color: AppColors.primaryContainer
                                        .withOpacity(0.3),
                                    child: cat.imageUrl != null &&
                                            cat.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            cat.imageUrl!,
                                            width: 44.r,
                                            height: 44.r,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                              AppIcons.laundry,
                                              color: AppColors.primary
                                                  .withOpacity(0.15),
                                              size: 24.r,
                                            ),
                                          )
                                        : Icon(
                                            AppIcons.laundry,
                                            color: AppColors.primary
                                                .withOpacity(0.15),
                                            size: 24.r,
                                          ),
                                  ),
                                ),
                                const Gap(8),
                                // Details Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        cat.name,
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textBlack,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Gap(2),
                                      Text(
                                        cat.description,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Action circle button
                                Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(AppIcons.forward,
                                      color: AppColors.primary, size: 8.r),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const Gap(24),

                  // ── 4. Horizontal Quick Filter Chips ─────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Nearest',
                          icon: Icons.navigation_rounded,
                          isSelected: _activeFilter == 'nearest',
                          onTap: () => _onFilterChanged('nearest'),
                        ),
                        const Gap(8),
                        _FilterChip(
                          label: 'Top rated',
                          icon: AppIcons.star,
                          isSelected: _activeFilter == 'top_rated',
                          onTap: () => _onFilterChanged('top_rated'),
                        ),
                        const Gap(8),
                        _FilterChip(
                          label: 'Available today',
                          icon: Icons.circle,
                          iconColor: AppColors.secondary,
                          isSelected: _activeFilter == 'available',
                          onTap: () => _onFilterChanged('available'),
                        ),
                        const Gap(8),
                        _FilterChip(
                          label: 'Express',
                          icon: Icons.flash_on,
                          isSelected: _activeFilter == 'express',
                          onTap: () => _onFilterChanged('express'),
                        ),
                        const Gap(8),
                        _FilterChip(
                          label: 'Under ₹100/kg',
                          icon: AppIcons.tag,
                          isSelected: _activeFilter == 'price',
                          onTap: () => _onFilterChanged('price'),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // ── 5. List Title and Details ────────────────────────────────
                  Text(
                    'Laundry partners near you',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '${_vendors.length} verified partners',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const Gap(16),

                  // ── 6. Partners List view ────────────────────────────────────
                  _isLoading
                      ? ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (_, __) =>
                              const AppSkeletonCard(height: 120),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _vendors.length,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (context, idx) {
                            final vendor = _vendors[idx];
                            return _ListVendorCard(
                              vendor: vendor,
                              onTap: () => context.go('/vendor/${vendor.id}'),
                            );
                          },
                        ),
                  const Gap(80),
                ],
              ),
            ),

            // ── 7. Map View Sticky Rounded Button ──────────────────────────────
            Positioned(
              right: 20.w,
              bottom: 20.h,
              child: FloatingActionButton.extended(
                onPressed: () => context.go(AppRoutes.vendorListing),
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full.r),
                  side: BorderSide(color: AppColors.outline.withOpacity(0.5)),
                ),
                icon: Icon(AppIcons.location,
                    color: AppColors.primary, size: 16.r),
                label: Text(
                  'Map view',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Quick Filter Chip Widget ────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outline.withOpacity(0.6),
          ),
          boxShadow: isSelected ? AppElevation.low : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12.r,
                color: isSelected
                    ? AppColors.white
                    : (iconColor ?? AppColors.textSecondary),
              ),
              const Gap(6),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.white : AppColors.textBlack,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable list card mapping partners exactly matching reference UI ────────

class _ListVendorCard extends StatelessWidget {
  const _ListVendorCard({required this.vendor, required this.onTap});
  final VendorModel vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double displayDistance =
        vendor.distanceKm ?? ((vendor.id.hashCode.abs() % 20) + 5) / 10;
    final isLuxe = vendor.name == 'Luxe Fabric Care';

    return AppCard.outlined(
      onTap: onTap,
      padding: EdgeInsets.all(12.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store front logo circular avatar
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              color: AppColors.textBlack,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                AppIcons.laundry,
                color: const Color(0xFFFBD38D), // gold branding hanger
                size: 24.r,
              ),
            ),
          ),
          const Gap(12),
          // Details content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      vendor.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                        fontSize: 14.sp,
                      ),
                    ),
                    const Gap(6),
                    // Specific design verified badges
                    if (vendor.isVerified) ...[
                      if (isLuxe)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius:
                                BorderRadius.circular(AppRadius.tag.r),
                          ),
                          child: Text(
                            'Verified',
                            style: AppTypography.badge.copyWith(
                              color: AppColors.secondary,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Icon(Icons.verified,
                            color: AppColors.primary, size: 14.r),
                    ],
                    const Gap(6),
                    // Specific Luxe 15% discount badge
                    if (isLuxe)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEE),
                          borderRadius: BorderRadius.circular(AppRadius.tag.r),
                        ),
                        child: Text(
                          '15% OFF',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap(4),
                // Rating row
                Row(
                  children: [
                    Icon(AppIcons.star, color: Colors.amber, size: 12.r),
                    const Gap(2),
                    Text(
                      '${vendor.averageRating ?? 4.8}  •  ${displayDistance.toStringAsFixed(1)} km',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                // Pricing
                Text(
                  'From ${vendor.minOrderAmount.toCurrency}/kg',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
                const Gap(2),
                // Turnarounds
                Text(
                  'Next pickup: 5:30 PM  •  Delivery: Tomorrow',
                  style: AppTypography.caption.copyWith(
                    fontSize: 9.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                const Gap(8),
                // Service tags row
                Row(
                  children: [
                    _MiniTag(label: isLuxe ? 'Wash & Fold' : 'Laundry'),
                    const Gap(4),
                    _MiniTag(label: isLuxe ? 'Dry Cleaning' : 'Ironing'),
                    const Gap(4),
                    _MiniTag(label: isLuxe ? 'Steam Press' : 'Shoe Care'),
                  ],
                ),
              ],
            ),
          ),
          const Gap(8),
          // Heart outline and chevron button column
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                AppIcons.favoriteOutlined,
                color: AppColors.textSecondary,
                size: 20.r,
              ),
              const Gap(32),
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.forward,
                  color: AppColors.primary,
                  size: 10.r,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Service Tag Chip Widget ──────────────────────────────────────────────────

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4.r),
        border:
            Border.all(color: AppColors.outline.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 8.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
