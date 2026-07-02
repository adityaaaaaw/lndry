import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../shared/widgets/domain_cards.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/repositories/base_repository.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key, required this.categoryId});
  final String categoryId;

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  bool _isLoading = true;
  CategoryModel? _category;
  List<VendorModel> _vendors = [];

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  void _loadCategoryData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);

    // Fetch categories to find details
    final cats = await repo.getCategories();
    final currentCat = cats.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => CategoryModel(
        id: widget.categoryId,
        name: 'Service Details',
        description: 'Browse local providers',
        icon: 'tag',
      ),
    );

    // Fetch vendors offering this category
    final response = await repo.getVendors(
      categoryId: widget.categoryId,
      params: const PaginationParams(pageSize: 20),
    );

    if (mounted) {
      setState(() {
        _category = currentCat;
        _vendors = response.items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_category?.name ?? 'Category Details',
            style: AppTypography.titleLarge),
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
        backgroundColor: theme.brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? ListView.separated(
                padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                itemCount: 3,
                separatorBuilder: (_, __) => const Gap(16),
                itemBuilder: (_, __) => const AppSkeletonCard(height: 240),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Description Header ─────────────────────────────────────
                  if (_category != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePaddingH.w,
                        vertical: AppSpacing.pagePaddingV.h,
                      ),
                      color: theme.brightness == Brightness.dark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.primaryContainer.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _category!.description,
                            style: AppTypography.bodyMedium,
                          ),
                          const Gap(4),
                          Text(
                            '${_vendors.length} vendors available',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Vendors List ──────────────────────────────────────────
                  Expanded(
                    child: _vendors.isEmpty
                        ? AppEmptyState(
                            icon: AppIcons.store,
                            title: 'No Vendors Available',
                            subtitle:
                                'We couldn\'t find any laundry vendors offering this service in your area currently.',
                            actionLabel: 'Go Back Home',
                            onAction: () => context.go(AppRoutes.home),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                            itemCount: _vendors.length,
                            separatorBuilder: (_, __) => const Gap(16),
                            itemBuilder: (context, idx) {
                              final vendor = _vendors[idx];
                              return VendorCard(
                                vendor: vendor,
                                onTap: () => context.go(
                                  '/vendor/${vendor.id}',
                                ),
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
