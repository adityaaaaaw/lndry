import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../repositories/repositories.dart';

class MyReviewsPage extends ConsumerStatefulWidget {
  const MyReviewsPage({super.key});

  @override
  ConsumerState<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends ConsumerState<MyReviewsPage> {
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(customerRepositoryProvider).getMyReviews();
      if (mounted) {
        setState(() {
          _reviews = result.items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editReview(ReviewModel review) async {
    var rating = review.vendorRating;
    final controller = TextEditingController(text: review.comment ?? '');

    final shouldSave = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Edit Review',
      primaryActionLabel: 'Save Review',
      onPrimaryAction: () => Navigator.of(context).pop(true),
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.warning,
                  ),
                  onPressed: () => setModalState(() => rating = index + 1),
                ),
              ),
            ),
            AppTextField(
              label: 'Comment',
              hint: 'Share your experience',
              controller: controller,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true) return;
    try {
      await ref.read(customerRepositoryProvider).updateReview(
            review.id,
            vendorRating: rating,
            comment:
                controller.text.trim().isEmpty ? null : controller.text.trim(),
          );
      await _loadReviews();
      if (mounted) AppSnackBar.showSuccess(context, 'Review updated.');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete Review',
      message: 'Delete this review permanently?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(customerRepositoryProvider).deleteReview(review.id);
      await _loadReviews();
      if (mounted) AppSnackBar.showSuccess(context, 'Review deleted.');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Reviews', style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Loading reviews...')
            : _reviews.isEmpty
                ? const AppEmptyState(
                    icon: Icons.star_border_rounded,
                    title: 'No Reviews Yet',
                    subtitle:
                        'Your vendor and delivery reviews will appear here.',
                  )
                : RefreshIndicator(
                    onRefresh: _loadReviews,
                    child: ListView.separated(
                      padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, __) => Gap(AppSpacing.cardGap.h),
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return AppCard.outlined(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Order #${review.orderId.length >= 8 ? review.orderId.substring(review.orderId.length - 8).toUpperCase() : review.orderId.toUpperCase()}',
                                      style: AppTypography.labelLarge,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (star) => Icon(
                                        star < review.vendorRating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: AppColors.warning,
                                        size: 18.r,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (review.comment != null &&
                                  review.comment!.isNotEmpty) ...[
                                Gap(AppSpacing.sm.h),
                                Text(
                                  review.comment!,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                              Gap(AppSpacing.sm.h),
                              Text(
                                review.createdAt.toDateString,
                                style: AppTypography.caption,
                              ),
                              Gap(AppSpacing.sm.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _editReview(review),
                                    child: Text('Edit', style: AppTypography.labelMedium),
                                  ),
                                  TextButton(
                                    onPressed: () => _deleteReview(review),
                                    child: Text('Delete', style: AppTypography.labelMedium.copyWith(color: AppColors.error)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
