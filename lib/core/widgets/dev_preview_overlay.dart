import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design/design_system.dart';
import '../../config/env.dart';

/// Floating Developer Preview mode helper overlay.
/// Allows rapid screen-by-screen navigation during UI review and testing.
class DevPreviewOverlay extends StatefulWidget {
  const DevPreviewOverlay({super.key});

  @override
  State<DevPreviewOverlay> createState() => _DevPreviewOverlayState();
}

class _DevPreviewOverlayState extends State<DevPreviewOverlay> {
  bool _isCollapsed = true;

  void _navigateTo(BuildContext context, String path) {
    setState(() => _isCollapsed = true);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.showDevPreviewOverlay) return const SizedBox.shrink();

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: 16.w,
              bottom: 80.h, // Positioned above main bottom tabs
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!_isCollapsed)
                    Container(
                      width: 260.w,
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.inverseSurface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(AppRadius.lg.r),
                        boxShadow: AppElevation.high,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'DEV PREVIEW PANEL',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                onPressed: () => setState(() => _isCollapsed = true),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 12),
                          SizedBox(
                            height: 250.h,
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                _buildShortcutTile(context, 'Home Dashboard', AppRoutes.home, Icons.home),
                                _buildShortcutTile(context, 'Search & Filters', AppRoutes.search, Icons.search),
                                _buildShortcutTile(context, 'Service Categories', '/category/wash_fold', Icons.category),
                                _buildShortcutTile(context, 'Vendor Discovery', AppRoutes.vendorListing, Icons.storefront),
                                _buildShortcutTile(context, 'Vendor Details', '/vendor/vendor_1', Icons.local_laundry_service),
                                _buildShortcutTile(context, 'Shopping Cart', AppRoutes.cart, Icons.shopping_cart),
                                _buildShortcutTile(context, 'Checkout Page', AppRoutes.checkout, Icons.payment),
                                _buildShortcutTile(context, 'Order Confirmation', '/checkout/confirmation/ord_123', Icons.check_circle),
                                _buildShortcutTile(context, 'My Orders list', AppRoutes.orders, Icons.receipt_long),
                                _buildShortcutTile(context, 'Profile Settings', AppRoutes.profile, Icons.person),
                                _buildShortcutTile(context, 'Notification Logs', AppRoutes.notifications, Icons.notifications),
                                _buildShortcutTile(context, 'App Settings', AppRoutes.settings, Icons.settings),
                                _buildShortcutTile(context, 'Help & FAQ Support', AppRoutes.help, Icons.help),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Main trigger Floating Button
                  GestureDetector(
                    onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: _isCollapsed ? AppColors.primary : AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.full.r),
                        boxShadow: AppElevation.medium,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCollapsed ? Icons.developer_mode : Icons.close,
                            color: Colors.white,
                            size: 18.r,
                          ),
                          const Gap(6),
                          Text(
                            _isCollapsed ? 'Dev Mode' : 'Close',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutTile(BuildContext context, String label, String path, IconData icon) {
    return InkWell(
      onTap: () => _navigateTo(context, path),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 16.r),
            const Gap(8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white54, size: 14.r),
          ],
        ),
      ),
    );
  }
}
