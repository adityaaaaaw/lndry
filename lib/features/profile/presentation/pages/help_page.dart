import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<_FaqItem> faqs = const [
      _FaqItem(
        q: 'What is the turnaround time for delivery?',
        a: 'Most of our laundry vendors return clothes clean, folded, and ironed within 24 to 48 hours. Estimated delivery dates are shown on your order tracking timeline.',
      ),
      _FaqItem(
        q: 'How do I pay for my order?',
        a: 'LNDRY supports completely secure cashless payments using our built-in Razorpay gateway. You can pay via UPI (GPay, Paytm), Cards, Net Banking, or choose Cash on Delivery.',
      ),
      _FaqItem(
        q: 'Can I cancel my scheduled pickup?',
        a: 'Yes. Pickups can be cancelled free of charge at any time before the delivery partner is dispatched. Tap on your order details and click Cancel.',
      ),
      _FaqItem(
        q: 'What if my clothes are damaged?',
        a: 'We select only certified laundry partners. In case of any dispute or rare garment damage, contact our help support details below, and we will compensate you.',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('Help & FAQs', style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.go(AppRoutes.profile),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingH.w,
            vertical: AppSpacing.pagePaddingV.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact details header
              AppCard.outlined(
                backgroundColor: AppColors.primaryContainer.withOpacity(0.12),
                borderColor: AppColors.primary.withOpacity(0.3),
                child: Column(
                  children: [
                    Icon(AppIcons.info, color: AppColors.primary, size: 28.r),
                    const Gap(12),
                    Text('Need immediate help?',
                        style: AppTypography.titleMedium),
                    const Gap(6),
                    Text(
                      'Contact LNDRY Support via Phone or Email. Operating 9:00 AM to 8:00 PM daily.',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outlined(
                            label: 'Call Us',
                            icon: const Icon(AppIcons.phone, size: 16),
                            onPressed: () => AppSnackBar.showInfo(
                                context, 'Mock Call: +91 9876543210'),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: AppButton.outlined(
                            label: 'Email Support',
                            icon: const Icon(AppIcons.email, size: 16),
                            onPressed: () => AppSnackBar.showInfo(
                                context, 'Mock Email: support@lndry.com'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(24),

              Text('Frequently Asked Questions',
                  style: AppTypography.titleMedium),
              const Gap(12),

              // FAQ Accordions
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: faqs.length,
                separatorBuilder: (_, __) => const Gap(10),
                itemBuilder: (context, idx) {
                  final faq = faqs[idx];

                  return AppCard.outlined(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(faq.q, style: AppTypography.labelLarge),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text(
                            faq.a,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;
}
