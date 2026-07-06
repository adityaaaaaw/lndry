import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../widgets/listing_vendor_card.dart';

class VendorListingPage extends ConsumerStatefulWidget {
  const VendorListingPage({super.key});

  @override
  ConsumerState<VendorListingPage> createState() => _VendorListingPageState();
}

class _VendorListingPageState extends ConsumerState<VendorListingPage> {
  bool _isLoading = true;
  List<VendorModel> _allVendors = [];
  List<VendorModel> _filteredVendors = [];

  // Sorting options
  String _activeSort =
      'rating'; // rating, distance, price_low, price_high, value, available

  // Filter states
  bool _filterVerifiedOnly = false;
  bool _filterAvailableOnly = false;
  double _maxDistance = 10.0;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  void _loadVendors() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    final response = await repo.getVendors(
      params: const PaginationParams(pageSize: 40),
    );

    if (mounted) {
      setState(() {
        _allVendors = response.items;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    var list = List<VendorModel>.from(_allVendors);

    // Apply Filter: Available Now
    if (_filterAvailableOnly || _activeSort == 'available') {
      list = list.where((v) => v.isOpen).toList();
    }

    // Apply Filter: Verified Only
    if (_filterVerifiedOnly) {
      list = list.where((v) => v.isVerified).toList();
    }

    // Apply Filter: Max Distance
    list = list.where((v) {
      final double distance =
          v.distanceKm ?? ((v.id.hashCode.abs() % 40) + 10) / 10;
      return distance <= _maxDistance;
    }).toList();

    // Apply Sorting
    switch (_activeSort) {
      case 'rating':
        list.sort((a, b) =>
            (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0));
        break;
      case 'distance':
        list.sort((a, b) {
          final double distA =
              a.distanceKm ?? ((a.id.hashCode.abs() % 40) + 10) / 10;
          final double distB =
              b.distanceKm ?? ((b.id.hashCode.abs() % 40) + 10) / 10;
          return distA.compareTo(distB);
        });
        break;
      case 'price_low':
        list.sort((a, b) => a.minOrderAmount.compareTo(b.minOrderAmount));
        break;
      case 'price_high':
        list.sort((a, b) => b.minOrderAmount.compareTo(a.minOrderAmount));
        break;
      case 'value':
        list.sort((a, b) {
          final valA = (a.averageRating ?? 0.0) / (a.minOrderAmount + 1);
          final valB = (b.averageRating ?? 0.0) / (b.minOrderAmount + 1);
          return valB
              .compareTo(valA); // Higher rating relative to lower price first
        });
        break;
      default:
        break;
    }

    setState(() {
      _filteredVendors = list;
    });
  }

  void _showFilterSheet() {
    AppBottomSheet.show<void>(
      context: context,
      title: 'Filter Laundries',
      primaryActionLabel: 'Apply Filters',
      onPrimaryAction: () {
        _applyFiltersAndSort();
        Navigator.of(context).pop();
      },
      secondaryActionLabel: 'Clear All',
      onSecondaryAction: () {
        setState(() {
          _filterVerifiedOnly = false;
          _filterAvailableOnly = false;
          _maxDistance = 10.0;
        });
        _applyFiltersAndSort();
        Navigator.of(context).pop();
      },
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sort options header
            Text('Sort By', style: AppTypography.labelMedium),
            const Gap(12),
            _FilterSortOption(
              label: 'Best Rating',
              icon: AppIcons.star,
              isSelected: _activeSort == 'rating',
              onTap: () {
                setModalState(() {});
                setState(() => _activeSort = 'rating');
              },
            ),
            _FilterSortOption(
              label: 'Nearest First',
              icon: AppIcons.location,
              isSelected: _activeSort == 'distance',
              onTap: () {
                setModalState(() {});
                setState(() => _activeSort = 'distance');
              },
            ),
            _FilterSortOption(
              label: 'Price: Low to High',
              icon: AppIcons.upi,
              isSelected: _activeSort == 'price_low',
              onTap: () {
                setModalState(() {});
                setState(() => _activeSort = 'price_low');
              },
            ),
            _FilterSortOption(
              label: 'Price: High to Low',
              icon: AppIcons.upi,
              isSelected: _activeSort == 'price_high',
              onTap: () {
                setModalState(() {});
                setState(() => _activeSort = 'price_high');
              },
            ),
            _FilterSortOption(
              label: 'Available Now',
              icon: AppIcons.clock,
              isSelected: _activeSort == 'available',
              onTap: () {
                setModalState(() {});
                setState(() => _activeSort = 'available');
              },
            ),
            const Gap(16),
            const AppDivider(),
            const Gap(16),

            // Verified switch
            SwitchListTile.adaptive(
              title: Text('Verified Partners Only',
                  style: AppTypography.bodyMedium),
              subtitle: Text(
                'Show laundry vendors verified by LNDRY',
                style: AppTypography.caption,
              ),
              value: _filterVerifiedOnly,
              onChanged: (val) {
                setModalState(() => _filterVerifiedOnly = val);
                setState(() => _filterVerifiedOnly = val);
              },
            ),
            const AppDivider(),

            // Available Now switch
            SwitchListTile.adaptive(
              title: Text('Available Now', style: AppTypography.bodyMedium),
              value: _filterAvailableOnly,
              onChanged: (val) {
                setModalState(() => _filterAvailableOnly = val);
                setState(() => _filterAvailableOnly = val);
              },
            ),
            const AppDivider(),
            const Gap(16),

            // Distance slider
            Text('Maximum Distance', style: AppTypography.labelMedium),
            Row(
              children: [
                Expanded(
                  child: Slider.adaptive(
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: '${_maxDistance.toStringAsFixed(0)} km',
                    value: _maxDistance,
                    onChanged: (val) {
                      setModalState(() => _maxDistance = val);
                      setState(() => _maxDistance = val);
                    },
                  ),
                ),
                Text(
                  '${_maxDistance.toStringAsFixed(0)} km',
                  style: AppTypography.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Laundry Partners', style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          // FIX #3: Filter icon opens _showFilterSheet
          IconButton(
            icon: const Icon(AppIcons.filter),
            onPressed: _showFilterSheet,
          ),
        ],
        backgroundColor: theme.brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable Sorting Header chips ──────────────────────────────
            Container(
              height: 48.h,
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _SortChip(
                    label: 'Best Rating',
                    icon: AppIcons.star,
                    isSelected: _activeSort == 'rating',
                    onTap: () {
                      setState(() => _activeSort = 'rating');
                      _applyFiltersAndSort();
                    },
                  ),
                  const Gap(8),
                  _SortChip(
                    label: 'Nearest',
                    icon: AppIcons.location,
                    isSelected: _activeSort == 'distance',
                    onTap: () {
                      setState(() => _activeSort = 'distance');
                      _applyFiltersAndSort();
                    },
                  ),
                  const Gap(8),
                  _SortChip(
                    label: 'Price: Low to High',
                    icon: AppIcons.upi,
                    isSelected: _activeSort == 'price_low',
                    onTap: () {
                      setState(() => _activeSort = 'price_low');
                      _applyFiltersAndSort();
                    },
                  ),
                  const Gap(8),
                  _SortChip(
                    label: 'Price: High to Low',
                    icon: AppIcons.upi,
                    isSelected: _activeSort == 'price_high',
                    onTap: () {
                      setState(() => _activeSort = 'price_high');
                      _applyFiltersAndSort();
                    },
                  ),
                  const Gap(8),
                  _SortChip(
                    label: 'Value for Money',
                    icon: AppIcons.tag,
                    isSelected: _activeSort == 'value',
                    onTap: () {
                      setState(() => _activeSort = 'value');
                      _applyFiltersAndSort();
                    },
                  ),
                  const Gap(8),
                  _SortChip(
                    label: 'Available Now',
                    icon: AppIcons.clock,
                    isSelected: _activeSort == 'available',
                    onTap: () {
                      setState(() => _activeSort = 'available');
                      _applyFiltersAndSort();
                    },
                  ),
                ],
              ),
            ),
            const Gap(12),

            // ── Vendors List ─────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? ListView.separated(
                      padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (_, __) =>
                          const AppSkeletonCard(height: 240),
                    )
                  : _filteredVendors.isEmpty
                      ? AppEmptyState(
                          icon: AppIcons.store,
                          title: 'No Matching Laundries',
                          subtitle:
                              'Try adjusting your filters or sorting configurations to find matching laundry vendors.',
                          actionLabel: 'Clear All Filters',
                          onAction: () {
                            setState(() {
                              _activeSort = 'rating';
                              _filterVerifiedOnly = false;
                              _filterAvailableOnly = false;
                              _maxDistance = 10.0;
                            });
                            _loadVendors();
                          },
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.pagePaddingH.w,
                          ),
                          itemCount: _filteredVendors.length,
                          separatorBuilder: (_, __) => const Gap(16),
                          itemBuilder: (context, idx) {
                            final vendor = _filteredVendors[idx];
                            // FIX #1: Use context.push() instead of context.go()
                            return ListingVendorCard(
                              vendor: vendor,
                              onTap: () => context.push('/vendor/${vendor.id}'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widget: sort option row inside the filter sheet ──────────────────

class _FilterSortOption extends StatelessWidget {
  const _FilterSortOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 18.r,
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(AppIcons.done, size: 18.r, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

// ── Private widget: horizontal sort chip ─────────────────────────────────────

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.chip.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14.r,
                color:
                    isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const Gap(6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
