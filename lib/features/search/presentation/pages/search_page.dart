import 'package:cached_network_image/cached_network_image.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:lndry/features/home/presentation/providers/home_providers.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../../../shared/widgets/service_icon.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  String _activeFilter = 'nearest'; // nearest, top_rated, available, express, price
  bool _isLoading = false;
  List<VendorModel> _vendors = [];
  List<CategoryModel> _categories = [];

  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadVendors();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) => debugPrint('[SpeechToText] Error: $val'),
        onStatus: (status) {
          if (status == 'listening') {
            setState(() => _isListening = true);
          } else if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[SpeechToText] Init failed: $e');
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      await _speech.initialize();
    }
    
    final hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      if (mounted) {
        AppSnackBar.showError(context, 'Microphone permission is required for voice search.');
      }
      return;
    }

    setState(() {
      _isListening = true;
      _lastWords = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          _searchController.text = _lastWords;
        });
        if (result.finalResult) {
          _loadVendors();
        }
      },
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _speech.stop();
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
    if (mounted) setState(() => _isLoading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final response = await repo.getVendors(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        params: const PaginationParams(pageSize: 20),
      );

      var list = response.items;

      // Apply filters
      if (_activeFilter == 'top_rated') {
        list.sort((a, b) => (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0));
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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                boxShadow: AppElevation.high,
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      const Gap(24),
                      Text(
                        'Filter Partners By',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const Gap(20),
                      // Filter Options
                      _FilterSheetOption(
                        label: 'Nearest',
                        icon: Icons.navigation_rounded,
                        isSelected: _activeFilter == 'nearest',
                        onTap: () {
                          setModalState(() => _activeFilter = 'nearest');
                        },
                      ),
                      _FilterSheetOption(
                        label: 'Top Rated',
                        icon: AppIcons.star,
                        isSelected: _activeFilter == 'top_rated',
                        onTap: () {
                          setModalState(() => _activeFilter = 'top_rated');
                        },
                      ),
                      _FilterSheetOption(
                        label: 'Available Today',
                        icon: Icons.circle_rounded,
                        iconColor: AppColors.secondary,
                        isSelected: _activeFilter == 'available',
                        onTap: () {
                          setModalState(() => _activeFilter = 'available');
                        },
                      ),
                      _FilterSheetOption(
                        label: 'Express (Under 24h)',
                        icon: Icons.flash_on_rounded,
                        isSelected: _activeFilter == 'express',
                        onTap: () {
                          setModalState(() => _activeFilter = 'express');
                        },
                      ),
                      _FilterSheetOption(
                        label: 'Under ₹100/kg',
                        icon: AppIcons.tag,
                        isSelected: _activeFilter == 'price',
                        onTap: () {
                          setModalState(() => _activeFilter = 'price');
                        },
                      ),
                      const Gap(24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() => _activeFilter = 'nearest');
                                _onFilterChanged('nearest');
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.button.r),
                                ),
                                side: BorderSide(color: AppColors.outlineVariant),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                              ),
                              child: Text(
                                'Reset',
                                style: AppTypography.buttonText.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _onFilterChanged(_activeFilter);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.button.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                              ),
                              child: Text(
                                'Apply Filters',
                                style: AppTypography.buttonText.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategorySubtitle(CategoryModel cat) {
    final name = cat.name.toLowerCase();
    if (name.contains('wash & fold') || name.contains('laundry')) {
      return Text(
        'From ₹99/kg',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (name.contains('wash & iron')) {
      return Text(
        'From ₹129/kg',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (name.contains('dry clean')) {
      return Text(
        'From ₹149/item',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (name.contains('steam press') || name.contains('press')) {
      return Text(
        '48 hrs',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    } else if (name.contains('shoe')) {
      return Text(
        'From ₹299',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (name.contains('bag')) {
      return Text(
        'From ₹349',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (name.contains('premium')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          'Express',
          style: AppTypography.badge.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (name.contains('tailoring')) {
      return Text(
        'From ₹199',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      cat.description,
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressAsync = ref.watch(currentAddressProvider);

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
                      // Rounded Square Back Button
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
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColors.outlineVariant),
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
                                addressAsync.when<Widget>(
                                  data: (AddressModel? addr) => Flexible(
                                    child: GestureDetector(
                                      onTap: () => context.push(AppRoutes.mapAddress),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              addr != null
                                                  ? addr.line2 ?? addr.city
                                                  : 'Koramangala, Bengaluru',
                                              style: AppTypography.bodySmall.copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: 12.sp,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Gap(2),
                                          Icon(
                                            AppIcons.chevronDown,
                                            size: 14.r,
                                            color: AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  loading: () => Container(
                                    width: 100.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.shimmerBase,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    'Koramangala, Bengaluru',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Rounded Square Map Button
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.vendorListing),
                        child: Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColors.outlineVariant),
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

                  // ── 2. Search Box & Filter Button ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                AppIcons.search,
                                color: AppColors.textSecondary,
                                size: 20.r,
                              ),
                              const Gap(10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) => _loadVendors(),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textBlack,
                                    fontSize: 14.sp,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                                    hintText: _isListening
                                        ? 'Listening...'
                                        : 'Search laundry, service or vendor',
                                    hintStyle: AppTypography.inputHint.copyWith(
                                      fontSize: 14.sp,
                                      color: _isListening
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontWeight: _isListening
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                  ),
                                ),
                              ),
                              const Gap(8),
                              GestureDetector(
                                onTap: _isListening ? _stopListening : _startListening,
                                child: Icon(
                                  _isListening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                                  color: _isListening ? AppColors.secondary : AppColors.primary,
                                  size: 24.r,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(12),
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(context),
                        child: Container(
                          width: 52.h,
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Center(
                            child: Icon(
                              AppIcons.filter,
                              color: AppColors.primary,
                              size: 20.r,
                            ),
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

                  // ── 3. Category Grid ────────────────────────────────────────
                  if (_categories.isEmpty)
                    const _GridSkeleton()
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
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: AppElevation.low,
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44.r,
                                  height: 44.r,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: cat.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => BrandedServiceIcon(
                                              iconKey: cat.icon,
                                              size: 44.r,
                                              iconSize: 24.r,
                                              backgroundColor: Colors.transparent,
                                            ),
                                          )
                                        : BrandedServiceIcon(
                                            iconKey: cat.icon,
                                            size: 44.r,
                                            iconSize: 24.r,
                                            backgroundColor: Colors.transparent,
                                          ),
                                  ),
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textBlack,
                                          fontSize: 13.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Gap(2),
                                      _buildCategorySubtitle(cat),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(4.r),
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
                          icon: Icons.circle_rounded,
                          iconColor: AppColors.secondary,
                          isSelected: _activeFilter == 'available',
                          onTap: () => _onFilterChanged('available'),
                        ),
                        const Gap(8),
                        _FilterChip(
                          label: 'Express',
                          icon: Icons.flash_on_rounded,
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
                  if (_vendors.isNotEmpty)
                    Text(
                      '${_vendors.length} verified partner${_vendors.length == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    )
                  else
                    Text(
                      'No vendors match your search',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  const Gap(16),

                  // ── 6. Partners List view ────────────────────────────────────
                  _isLoading
                      ? ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (_, __) => const _VendorSkeletonCard(),
                        )
                      : _vendors.isEmpty
                          ? _EmptyState(
                              onReset: () {
                                _searchController.clear();
                                _onFilterChanged('nearest');
                              },
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
                  side: BorderSide(color: AppColors.outlineVariant),
                ),
                icon: Icon(AppIcons.location, color: AppColors.primary, size: 16.r),
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
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
          boxShadow: isSelected ? AppElevation.low : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.r,
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

  Widget _buildTurnaroundText(VendorModel vendor) {
    final isExpress = vendor.estimatedTurnaroundHours <= 24;
    if (isExpress) {
      return Text(
        'Express delivery available',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (vendor.isOpen) {
      return Text(
        'Same-day available',
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      return Text(
        'Next pickup: 5:30 PM  •  Delivery: Tomorrow',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double displayDistance =
        vendor.distanceKm ?? ((vendor.id.hashCode.abs() % 20) + 5) / 10;
    final int reviewCount = (vendor.id.hashCode.abs() % 200) + 40;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppElevation.low,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rounded Square Store Front Logo Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: 72.r,
                    height: 72.r,
                    color: AppColors.shimmerBase,
                    child: vendor.coverImageUrl.isNotNullOrBlank
                        ? CachedNetworkImage(
                            imageUrl: vendor.coverImageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.primaryContainer,
                            child: Icon(
                              AppIcons.store,
                              size: 28.r,
                              color: AppColors.primary,
                            ),
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
                          Flexible(
                            child: Text(
                              vendor.name,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(6),
                          if (vendor.isVerified) ...[
                            Icon(
                              Icons.verified_rounded,
                              color: AppColors.primary,
                              size: 16.r,
                            ),
                          ],
                        ],
                      ),
                      const Gap(4),
                      // Rating & Distance row
                      Row(
                        children: [
                          Icon(AppIcons.star, color: AppColors.rating, size: 13.r),
                          const Gap(3),
                          Expanded(
                            child: Text(
                              '${vendor.averageRating ?? 4.8} ($reviewCount)  •  ${displayDistance.toStringAsFixed(1)} km',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      // Pricing
                      Text(
                        'From ${vendor.minOrderAmount.toCurrency}/kg',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(2),
                      // Turnaround
                      _buildTurnaroundText(vendor),
                      const Gap(8),
                      // Service tags row
                      Wrap(
                        spacing: 4.w,
                        runSpacing: 4.h,
                        children: const [
                          _MiniTag(label: 'Wash & Fold'),
                          _MiniTag(label: 'Dry Cleaning'),
                          _MiniTag(label: 'Steam Press'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                // Action Arrow Button & Favorite Icon
                SizedBox(
                  height: 120.h,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        AppIcons.favoriteOutlined,
                        color: AppColors.textSecondary,
                        size: 20.r,
                      ),
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.forward,
                          color: AppColors.primary,
                          size: 12.r,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        color: AppColors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontSize: 8.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Filter Sheet Option Row ──────────────────────────────────────────────────

class _FilterSheetOption extends StatelessWidget {
  const _FilterSheetOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textBlack,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22.r)
          : null,
      onTap: onTap,
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 0.4.sh),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.store,
                  size: 56.r,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              const Gap(24),
              Text(
                'No partners found',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const Gap(8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  'Try adjusting your filters or search term to find laundry partners nearby.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Gap(32),
              AppButton(
                label: 'Reset filters',
                onPressed: onReset,
                width: 200.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vendor Skeleton Card ─────────────────────────────────────────────────────

class _VendorSkeletonCard extends StatelessWidget {
  const _VendorSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                const Gap(8),
                Container(
                  width: 80.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                const Gap(8),
                Container(
                  width: 60.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                const Gap(8),
                Row(
                  children: List.generate(
                    2,
                    (index) => Container(
                      width: 70.w,
                      height: 18.h,
                      margin: EdgeInsets.only(right: 6.w),
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Skeleton ────────────────────────────────────────────────────────────

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 2.1,
      ),
      itemCount: 4,
      itemBuilder: (context, idx) {
        return Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              const Gap(8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60.w,
                      height: 12.h,
                      color: AppColors.shimmerBase,
                    ),
                    const Gap(4),
                    Container(
                      width: 40.w,
                      height: 10.h,
                      color: AppColors.shimmerBase,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
